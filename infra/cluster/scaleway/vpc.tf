#10.1.0.0/17 -> 10.1.0.0/20, 10.1.16.0/20, 10.1.32.0/20
resource "scaleway_vpc" "vpc" {
  name           = "scaleway-vpc"
  tags           = local.tags
  enable_routing = true
  region         = var.region
  project_id     = scaleway_account_project.project.id
}

resource "scaleway_vpc_private_network" "private_1" {
  ipv4_subnet {
    subnet = "10.2.0.0/20"
  }
  project_id = scaleway_account_project.project.id
  region     = var.region
  vpc_id     = scaleway_vpc.vpc.id
}

resource "scaleway_vpc_public_gateway_ip" "zone_1" {
  project_id = scaleway_account_project.project.id
  tags       = local.tags
  zone       = var.zone
}

resource "scaleway_vpc_public_gateway" "gw_zone_1" {
  enable_smtp = false
  ip_id       = scaleway_vpc_public_gateway_ip.zone_1.id
  name        = format("%s-gateway", "scwaleway")
  project_id  = scaleway_account_project.project.id
  tags        = local.tags
  type        = "VPC-GW-S"
  zone        = var.zone
}

resource "scaleway_ipam_ip" "this" {
  is_ipv6    = false
  region     = var.region
  project_id = scaleway_account_project.project.id
  address    = "10.2.0.8"

  source {
    private_network_id = scaleway_vpc_private_network.private_1.id
  }
}

resource "scaleway_vpc_gateway_network" "this" {
  enable_masquerade  = true
  gateway_id         = scaleway_vpc_public_gateway.gw_zone_1.id
  private_network_id = scaleway_vpc_private_network.private_1.id
  zone               = var.zone
  cleanup_dhcp       = true

  # This is the new way for configuring a gateway, no more dhcp configuration.
  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.this.id
  }
}