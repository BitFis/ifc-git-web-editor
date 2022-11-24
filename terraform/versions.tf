# Define providers and set versions
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.22.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}
