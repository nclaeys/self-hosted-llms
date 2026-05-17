locals {
  tags       = ["terraform", "demo"]
}
resource "scaleway_k8s_cluster" "cluster" {
  name    = var.cluster_name
  type    = "kapsule"
  version = var.kubernetes_version
  cni     = "cilium"
  region  = var.region
  private_network_id = scaleway_vpc_private_network.private_1.id

  delete_additional_resources = false
}

provider "scaleway" {
  alias = "tmp"
}

resource scaleway_account_project "project" {
  provider = scaleway.tmp
  name     = "self-hosted-llms"
  organization_id = var.organisation_id
}

provider "scaleway" {
  project_id = scaleway_account_project.project.id
  region     = var.region
}

resource "scaleway_k8s_pool" "standard" {
  cluster_id = scaleway_k8s_cluster.cluster.id
  name       = "${var.cluster_name}-standard"
  node_type  = var.standard_node_type
  size       = 1
  min_size   = 1
  max_size   = 1
  zone       = var.zone
}

resource "scaleway_k8s_pool" "gpu" {
  cluster_id = scaleway_k8s_cluster.cluster.id
  name       = "${var.cluster_name}-gpu"
  node_type  = var.gpu_node_type
  size       = 1
  min_size   = 1
  max_size   = 1
  zone       = var.zone

  tags = ["taint=nvidia.com/gpu=true:NoSchedule"]
}

resource "local_sensitive_file" "kubeconfig" {
  content         = scaleway_k8s_cluster.cluster.kubeconfig[0].config_file
  filename        = pathexpand(var.kubeconfig_output_path)
  file_permission = "0600"
}
