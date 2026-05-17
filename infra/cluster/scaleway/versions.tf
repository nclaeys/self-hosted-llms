terraform {
  required_version = ">= 1.11.4"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.75"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
