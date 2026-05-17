resource "kubernetes_secret" "hf_token" {
  metadata {
    name      = "hf-token"
    namespace = kubernetes_namespace.vllm.metadata[0].name
  }

  data = {
    "token" = "TO Be replaced"
  }
  type = "Opaque"
}