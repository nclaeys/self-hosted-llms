terraform {
  required_version = ">= 1.11.4"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.13"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Authentication via environment variables:
#   OVH_APPLICATION_KEY / OVH_APPLICATION_SECRET / OVH_CONSUMER_KEY
#   or OVH_CLIENT_ID / OVH_CLIENT_SECRET (OAuth2)
provider "ovh" {
  endpoint = var.ovh_endpoint
}
