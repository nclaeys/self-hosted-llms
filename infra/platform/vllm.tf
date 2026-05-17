resource "kubernetes_namespace" "vllm" {
  metadata {
    name = "vllm"
  }
}

# https://docs.vllm.ai/en/latest/deployment/integrations/production-stack/
resource "helm_release" "vllm" {
  name       = "vllm"
  repository = "https://vllm-project.github.io/production-stack" #https://docs.vllm.ai/projects/production-stack/en/latest/deployment/helm.html
  chart      = "vllm"
  version    = var.vllm_chart_version
  namespace  = kubernetes_namespace.vllm.metadata[0].name

  values = [<<EOF
servingEngineSpec:
  modelSpec:
  - name: "llama3"
    repository: "vllm/vllm-openai"
    tag: "latest"
    modelURL: "meta-llama/Llama-3.1-8B-Instruct"
    replicaCount: 1

    requestCPU: 10
    requestMemory: "16Gi"
    requestGPU: 1

    pvcStorage: "50Gi"

    vllmConfig:
      enableChunkedPrefill: false
      enablePrefixCaching: false
      maxModelLen: 16384
      dtype: "bfloat16"
      extraArgs: ["--gpu-memory-utilization", "0.8"]

    hf_token: ""
EOF
  ]

  wait    = false
  timeout = 900
}
