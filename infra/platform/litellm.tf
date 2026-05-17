resource "kubernetes_namespace" "litellm" {
  metadata {
    name = "litellm"
  }
}

resource "helm_release" "litellm" {
  name       = "litellm"
  repository = "https://berriai.github.io/litellm-helm"
  chart      = "litellm"
  version    = var.litellm_chart_version
  namespace  = kubernetes_namespace.litellm.metadata[0].name

  values = [<<EOF
proxy_config:
  model_list:
    - model_name: "claude-3-5-sonnet-20241022"
      litellm_params:
        # openai/ prefix tells LiteLLM to use the OpenAI-compatible endpoint.
        # The model name after the prefix must match what vLLM exposes
        # (i.e. the HuggingFace model ID passed to vLLM).
        model: "openai/${var.vllm_model}"
        api_base: "http://vllm.vllm.svc.cluster.local:8000/v1"
        api_key: "dummy"
  service:
    type: "LoadBalancer"
    port: 4000
EOF
]
  timeout    = 300
  depends_on = [helm_release.vllm]
}
