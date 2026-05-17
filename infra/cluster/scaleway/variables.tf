variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "zone" {
  description = "Scaleway availability zone (GPU instances are available in fr-par-2)"
  type        = string
  default     = "fr-par-2"
}

variable "organisation_id" {
  description = "Scaleway organisation ID"
  type        = string
  default     = "b8e0510f-f68b-4139-8356-9bd7c11164e8"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "eu-llm"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35.2"
}

variable "standard_node_type" {
  description = "Scaleway instance type for CPU nodes (LiteLLM, Open WebUI)"
  type        = string
  default     = "PRO2-S" # 8 vCPU, 16 GB RAM
}

variable "gpu_node_type" {
  description = "Scaleway instance type for GPU node"
  type        = string
  default     = "L4-1-24G" # NVIDIA L4 24 GB VRAM
}

variable "kubeconfig_output_path" {
  description = "Local path to write the cluster kubeconfig"
  type        = string
  default     = "~/.kube/scaleway-eu-llm.yaml"
}
