
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
