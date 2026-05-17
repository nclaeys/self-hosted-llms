output "cluster_id" {
  description = "OVHcloud Kubernetes cluster ID"
  value       = ovh_cloud_project_kube.cluster.id
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = ovh_cloud_project_kube.cluster.name
}

output "kubeconfig_path" {
  description = "Path to the written kubeconfig file"
  value       = local_sensitive_file.kubeconfig.filename
}

output "kubeconfig" {
  description = "Raw kubeconfig (sensitive)"
  value       = ovh_cloud_project_kube.cluster.kubeconfig
  sensitive   = true
}

output "standard_nodepool_id" {
  description = "Standard node pool ID"
  value       = ovh_cloud_project_kube_nodepool.standard.id
}

output "gpu_nodepool_id" {
  description = "GPU node pool ID"
  value       = ovh_cloud_project_kube_nodepool.gpu.id
}
