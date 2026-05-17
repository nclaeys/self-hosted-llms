output "cluster_id" {
  description = "Scaleway Kapsule cluster ID"
  value       = scaleway_k8s_cluster.cluster.id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = scaleway_k8s_cluster.cluster.name
}

output "kubeconfig_path" {
  description = "Path to the written kubeconfig file"
  value       = local_sensitive_file.kubeconfig.filename
}

output "kubeconfig" {
  description = "Raw kubeconfig (sensitive)"
  value       = scaleway_k8s_cluster.cluster.kubeconfig[0].config_file
  sensitive   = true
}
