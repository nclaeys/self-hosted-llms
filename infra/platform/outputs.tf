output "vllm_status" {
  description = "vLLM Helm release status"
  value       = helm_release.vllm.status
}

output "vllm_model" {
  description = "Model being served by vLLM"
  value       = var.vllm_model
}

output "litellm_status" {
  description = "LiteLLM Helm release status"
  value       = helm_release.litellm.status
}
