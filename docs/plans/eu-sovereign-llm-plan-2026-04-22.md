---
problem: "EU-sovereign AI coding tool for organisations"
date: 2026-04-22
adr: "eu-sovereign-llm-adr-2026-04-22.md"
---

# Implementation Plan: EU-Sovereign Self-Hosted LLM

## Summary

Deploy a self-hosted LLM stack on OVHcloud Managed Kubernetes serving Mistral 7B via vLLM, with LiteLLM as the API proxy layer and Claude Code CLI as the primary engineer client. The goal is a fully scripted, reproducible Helm-based setup that organisations with EU data residency requirements can adopt from a single repository.

## Tasks

### Task 1: Provision OVHcloud Managed Kubernetes cluster with GPU node pool

**Files:** `infra/ovh/cluster.tf`

Provision an OVHcloud Managed Kubernetes cluster with two node pools:
- Standard pool: 2× `b2-7` nodes for control workloads (LiteLLM, Open WebUI)
- GPU pool: 1× `t1-45` instance (NVIDIA Tesla V100 16GB VRAM) for vLLM

Use the OVH Terraform provider (`ovh/ovh`). Unlike Scaleway, OVHcloud does **not** pre-configure the NVIDIA GPU operator — Task 2 handles that.

```hcl
terraform {
  required_providers {
    ovh = { source = "ovh/ovh" }
  }
}

resource "ovh_cloud_project_kube" "cluster" {
  service_name = var.ovh_service_name
  name         = "eu-llm-cluster"
  region       = "GRA9"   # Gravelines, France
}

resource "ovh_cloud_project_kube_nodepool" "standard" {
  service_name  = var.ovh_service_name
  kube_id       = ovh_cloud_project_kube.cluster.id
  name          = "standard-pool"
  flavor_name   = "b2-7"
  desired_nodes = 2
  min_nodes     = 2
  max_nodes     = 3
}

resource "ovh_cloud_project_kube_nodepool" "gpu" {
  service_name  = var.ovh_service_name
  kube_id       = ovh_cloud_project_kube.cluster.id
  name          = "gpu-pool"
  flavor_name   = "t1-45"
  desired_nodes = 1
  min_nodes     = 1
  max_nodes     = 1
}
```

**Verify:** `kubectl get nodes -l node.kubernetes.io/instance-type=t1-45`
**Expect:** At least one node in Ready state with GPU label

---

### Task 2: Install NVIDIA GPU operator

**Files:** `infra/gpu-operator/values.yaml`

OVHcloud Managed Kubernetes does not ship with GPU drivers or the NVIDIA device plugin. Deploy the NVIDIA GPU Operator via Helm before any GPU workload.

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator --create-namespace \
  --set driver.enabled=true \
  --set toolkit.enabled=true
```

Wait for all pods in the `gpu-operator` namespace to reach Running/Completed state before proceeding.

**Verify:** `kubectl get pods -n gpu-operator`
**Expect:** All operator pods Running; `kubectl describe node <gpu-node>` shows `nvidia.com/gpu: 1` in Allocatable
**Depends on:** Task 1

---

### Task 3: GPU smoke test

**Files:** `infra/smoke-test/cuda-pod.yaml`

Before deploying vLLM, confirm the GPU operator is working by running a minimal CUDA pod.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cuda-smoke
spec:
  restartPolicy: Never
  containers:
  - name: cuda
    image: nvidia/cuda:12.0-base
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
```

**Verify:** `kubectl logs cuda-smoke`
**Expect:** `nvidia-smi` output showing GPU model and driver version, pod exits with code 0
**Depends on:** Task 2

---

### Task 4: Deploy vLLM serving Mistral 7B

**Files:** `helm/vllm/values.yaml`, `helm/vllm/templates/deployment.yaml`, `helm/vllm/templates/service.yaml`

Deploy vLLM as a Kubernetes Deployment on the GPU node pool. Key configuration:
- Image: `vllm/vllm-openai:latest` (pin to a specific tag for reproducibility)
- Model: `mistralai/Mistral-7B-Instruct-v0.3`
- GPU resource: `nvidia.com/gpu: 1`
- Node selector: targets GPU node pool
- Service: ClusterIP on port 8000 (internal only)
- Hugging Face token as a Kubernetes Secret (for model download)

**Verify:** `kubectl exec -it deploy/vllm -- curl -s http://localhost:8000/v1/models | jq '.data[].id'`
**Expect:** Returns `"mistralai/Mistral-7B-Instruct-v0.3"`
**Depends on:** Task 3

---

### Task 5: Deploy LiteLLM proxy

**Files:** `helm/litellm/values.yaml`, `helm/litellm/config.yaml`, `helm/litellm/templates/deployment.yaml`, `helm/litellm/templates/service.yaml`

Deploy LiteLLM proxy as a Kubernetes Deployment on the standard node pool. Configuration:
- Route model alias `claude-3-5-sonnet` → `http://vllm-service:8000` (Mistral 7B)
- Master key stored as Kubernetes Secret
- SQLite or Postgres backend for virtual key storage and usage logs
- Service: ClusterIP on port 4000, plus a LoadBalancer or Ingress for external engineer access

LiteLLM config file (`config.yaml`):
```yaml
model_list:
  - model_name: claude-3-5-sonnet
    litellm_params:
      model: openai/mistralai/Mistral-7B-Instruct-v0.3
      api_base: http://vllm-service:8000/v1
      api_key: none

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  store_model_in_db: true
```

**Verify:** `curl -s http://litellm-service:4000/health | jq '.status'`
**Expect:** Returns `"healthy"`
**Depends on:** Task 4

---

### Task 6: Issue per-engineer virtual API keys

**Files:** `scripts/create-key.sh`

Create one virtual key per engineer via the LiteLLM admin API. Each key is scoped to the `claude-3-5-sonnet` model alias.

```bash
#!/usr/bin/env bash
ENGINEER=$1
curl -s -X POST http://<litellm-external-ip>:4000/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"alias\": \"$ENGINEER\", \"models\": [\"claude-3-5-sonnet\"]}" \
  | jq '.key'
```

**Verify:** `curl -s http://<litellm-ip>:4000/key/list -H "Authorization: Bearer $LITELLM_MASTER_KEY" | jq '.keys | length'`
**Expect:** Returns count equal to number of engineers provisioned
**Depends on:** Task 5

---

### Task 7: Connect Claude Code CLI

**Files:** `docs/engineer-setup.md`

Engineers configure Claude Code CLI with two environment variables:

```bash
export ANTHROPIC_BASE_URL=http://<litellm-external-ip>:4000
export ANTHROPIC_API_KEY=<virtual-key>
```

Then run `claude` as normal. Claude Code routes to LiteLLM, which translates and forwards to vLLM.

**Verify:** `ANTHROPIC_BASE_URL=http://<litellm-ip>:4000 ANTHROPIC_API_KEY=<key> claude -p "write a hello world in Python"`
**Expect:** Returns valid Python; LiteLLM logs show a successful request attributed to the engineer's key
**Depends on:** Task 6

---

### Task 8: Deploy Open WebUI

**Files:** `helm/openwebui/values.yaml`, `helm/openwebui/templates/deployment.yaml`

Deploy Open WebUI pointing at the LiteLLM OpenAI-compatible endpoint. Configuration:
- `OPENAI_API_BASE_URL`: `http://litellm-service:4000/v1`
- `OPENAI_API_KEY`: dedicated LiteLLM virtual key for Open WebUI
- Expose via Ingress or LoadBalancer for browser access

**Verify:** Open browser → Open WebUI URL → send test message → receive response within 15s
**Expect:** Response from Mistral 7B visible in chat UI
**Depends on:** Task 5

---

### Task 9: Package as Helm umbrella chart

**Files:** `helm/Chart.yaml`, `helm/values.yaml`, `helm/charts/`

Create a Helm umbrella chart with vLLM, LiteLLM, and Open WebUI as sub-charts. A single `helm install` deploys the full stack. The `values.yaml` exposes model selection as a top-level parameter:

```yaml
model:
  name: mistralai/Mistral-7B-Instruct-v0.3  # swap to mistralai/Codestral-22B for production
  alias: claude-3-5-sonnet
  gpuCount: 1
```

**Verify:** `helm install eu-llm ./helm --dry-run --debug 2>&1 | grep -i error`
**Expect:** No errors; dry-run output shows all resources templated correctly
**Depends on:** Tasks 4, 5, 8

---

### Task 10: Write blog post and publish repository

**Files:** `README.md`, `blog-post.md`

Write the architecture walkthrough covering:
1. The EU sovereignty problem (shadow IT risk from unsanctioned tools)
2. Stack decision rationale (why Mistral, why OVHcloud, why vLLM over Ollama)
3. Architecture diagram
4. Step-by-step setup (`helm install` from zero)
5. Upgrade path: Mistral 7B → Codestral 22B → Qwen3-coder 8B
6. Explicit caveat: self-hosting addresses operational control, not legal compliance

**Verify:** `helm install eu-llm ./helm` on a clean OVHcloud cluster; all pods reach Running state; `claude -p "hello"` returns a response
**Expect:** Full stack live from a single command; blog post and repo linked
**Depends on:** Task 9

---

## Definition of Done

- [ ] `kubectl get pods` shows vLLM, LiteLLM, Open WebUI all in Running state
- [ ] `claude -p "write a hello world in Python"` returns valid Python via Mistral 7B
- [ ] Open WebUI accessible in browser and generates responses
- [ ] Per-engineer key creation script documented and tested
- [ ] `helm install eu-llm ./helm` installs cleanly on a fresh cluster
- [ ] Blog post published with link to public GitHub repository
