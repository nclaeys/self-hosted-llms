variable "ovh_endpoint" {
  description = "OVH API endpoint"
  type        = string
  default     = "ovh-ca"
}

output "gpu_operator_status" {
  description = "GPU operator Helm release status"
  value       = helm_release.gpu_operator.status
}

output "gpu_operator_version" {
  description = "GPU operator Helm chart version deployed"
  value       = helm_release.gpu_operator.version
}

variable "gpu_operator_chart_version" {
  description = "NVIDIA GPU Operator Helm chart version"
  type        = string
  default     = "v24.9.1"
}

variable "gpu_node_pool_name" {
  description = "OVH node pool name used as the 'nodepool' label for GPU node selection"
  type        = string
  default     = "eu-llm-gpu"
}

variable "ovh_service_name" {
  description = "OVH Cloud project ID (service name)"
  default = "93325710cc8b45bf9a1074e55aa9243c"
}

variable "region" {
  description = "OVH region (GRA9 = Gravelines, France)"
  type        = string
  default     = "GRA9"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "eu-llm"
}

variable "kubernetes_version" {
  description = "Kubernetes minor version (e.g. '1.31')"
  type        = string
  default     = "1.35"
}

variable "standard_node_flavor" {
  description = "OVH flavor for CPU nodes (LiteLLM, Open WebUI)"
  type        = string
  default     = "b2-7"
}

variable "standard_node_count" {
  description = "Number of CPU nodes"
  type        = number
  default     = 2
}

variable "gpu_node_flavor" {
  description = "OVH flavor for GPU node (Tesla V100 16GB)"
  type        = string
  default     = "RTX5000-28" #32 gb vram
  #"t1-45" what I actually want but I do not have a high enough quota for it.
}

variable "gpu_node_count" {
  description = "Number of GPU nodes"
  type        = number
  default     = 1
}

variable "kubeconfig_output_path" {
  description = "Local path to write the cluster kubeconfig"
  type        = string
  default     = "~/.kube/ovh-eu-llm.yaml"
}
