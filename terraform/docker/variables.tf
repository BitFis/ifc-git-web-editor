
variable "CLOUDFLARE_CORE_API_KEY" {
  sensitive = true
}

variable "CLOUDFLARE_CORE_EMAIL" {
  sensitive = true
}

variable "CLOUDFLATE_API_TOKEN" {
  description = "Cloudflare access token"
  sensitive   = true
}

variable "CLOUDFLARE_ZUERCHER_DEV_ZONE_ID" {
  description = "Cloudflare zone id for zuercher.dev"
  sensitive   = true
}

variable "GITHUB_DOCKER_REGISTRY_USER" {
  description = "github registry user login"
  sensitive   = true
}

variable "GITHUB_DOCKER_REGISTRY_ACCESS_TOKEN" {
  description = "github registry access token"
  sensitive   = true
}
