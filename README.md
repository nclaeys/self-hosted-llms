# Self-Hosted LLMs on EU Cloud

Experiment with running open-weight LLMs on EU-based cloud providers to enable AI coding tools (Claude Code) without routing data through US infrastructure.

## Goal

Give engineers a sanctioned AI coding assistant that keeps data inside EU data centers — eliminating the shadow IT risk of engineers using unauthorized tools.

## Architecture

```
Engineer (Claude Code CLI)
        │ Anthropic API format
        ▼
  LiteLLM Proxy  ──── usage analytics / virtual API keys
        │ OpenAI API format
        ▼
   vLLM (GPU node)
        │
        ▼
  Mistral 7B / Codestral 22B
```

Claude Code points at LiteLLM via `ANTHROPIC_BASE_URL`. LiteLLM translates between Anthropic and OpenAI API formats and handles per-engineer virtual keys.

## Stack

| Component      | Tool                                    | Role                                   |
|----------------|-----------------------------------------|----------------------------------------|
| Inference      | vLLM                                    | GPU inference with continuous batching |
| Proxy          | LiteLLM                                 | API translation + key management       |
| Model          | Mistral 7B (POC) / Codestral 22B (prod) | EU-origin open weights                 |
| Infrastructure | Terraform                               | Cluster + platform provisioning        |

## Cloud Providers

Two provider options are implemented — pick one:

- **OVHcloud** (`infra/cluster/ovh/`) — Managed Kubernetes with GPU node pools, Gravelines FR (`GRA9`). Requires manual NVIDIA GPU Operator install (not pre-configured).
- **Scaleway** (`infra/cluster/scaleway/`) — Kapsule Kubernetes, GPU operator pre-configured.

## Repo Layout

```
infra/
  cluster/
    ovh/        # OVHcloud Managed Kubernetes cluster
    scaleway/   # Scaleway Kapsule cluster
  platform/
    vllm.tf     # vLLM Helm release
    litellm.tf  # LiteLLM Helm release
docs/
  adr/          # Architecture decision records
  plans/        # Implementation plans
```

## Docs

- [Architecture Decision Record](docs/adr/eu-sovereign-llm-adr-2026-04-22.md) — full rationale, trade-offs, and risks
- [Implementation Plan](docs/plans/eu-sovereign-llm-plan-2026-04-22.md) — step-by-step deployment guide
