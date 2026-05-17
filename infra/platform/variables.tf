variable "kubeconfig_path" {
  description = "Path to the kubeconfig file (written by infra/cluster)"
  type        = string
  default     = "~/.kube/scaleway-eu-llm.yaml"
}

variable "vllm_chart_version" {
  description = "vLLM Helm chart version (check https://vllm-project.github.io/helm-charts)"
  type        = string
  default     = "0.8.3"
}

variable "vllm_model" {
  description = "HuggingFace model ID for vLLM to serve"
  type        = string
  default     = "mistralai/Mistral-7B-Instruct-v0.3"
}

variable "litellm_chart_version" {
  description = "LiteLLM Helm chart version (check https://berriai.github.io/litellm-helm)"
  type        = string
  default     = "1.72.2"
}