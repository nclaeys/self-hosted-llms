# https://blog.ovhcloud.com/how-to-serve-llms-with-vllm-and-ovhcloud-ai-deploy/
# https://blog.ovhcloud.com/gpu-for-llm-inferencing-guide/
resource "ovh_cloud_project_kube" "cluster" {
  service_name = var.ovh_service_name
  name         = var.cluster_name
  region       = var.region
  version      = var.kubernetes_version
}

resource "ovh_cloud_project_kube_nodepool" "standard" {
  service_name  = var.ovh_service_name
  kube_id       = ovh_cloud_project_kube.cluster.id
  name          = "${var.cluster_name}-standard"
  flavor_name   = var.standard_node_flavor
  desired_nodes = var.standard_node_count
  min_nodes     = var.standard_node_count
  max_nodes     = var.standard_node_count
}

resource "ovh_cloud_project_kube_nodepool" "gpu" {
  service_name  = var.ovh_service_name
  kube_id       = ovh_cloud_project_kube.cluster.id
  name          = var.gpu_node_pool_name
  flavor_name   = var.gpu_node_flavor
  desired_nodes = var.gpu_node_count
  min_nodes     = var.gpu_node_count
  max_nodes     = var.gpu_node_count
}

resource "local_sensitive_file" "kubeconfig" {
  content         = ovh_cloud_project_kube.cluster.kubeconfig
  filename        = pathexpand(var.kubeconfig_output_path)
  file_permission = "0600"
}
