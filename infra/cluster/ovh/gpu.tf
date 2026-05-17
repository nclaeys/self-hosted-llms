resource "kubernetes_namespace" "gpu_operator" {
  metadata {
    name = "gpu-operator"
  }
}

resource "helm_release" "gpu_operator" {
  name       = "gpu-operator"
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = "gpu-operator"
  version    = var.gpu_operator_chart_version
  namespace  = kubernetes_namespace.gpu_operator.metadata[0].name

  set {
    name  = "driver.enabled"
    value = "true"
  }

  set {
    name  = "toolkit.enabled"
    value = "true"
  }

  wait    = true
  timeout = 600
}
