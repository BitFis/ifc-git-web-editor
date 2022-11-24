variable "OVH_APPLICATION_KEY" {
  description = "OVH API application key"
  sensitive   = true
}

variable "OVH_APPLICATION_SECRET" {
  description = "OVH API application secret"
  sensitive   = true
}

variable "OVH_CONSUMER_KEY" {
  description = "OVH API consumer key"
  sensitive   = true
}

variable "CLOUDFLATE_API_TOKEN" {
  description = "Cloudflare access token"
  sensitive   = true
}

variable "CLOUDFLARE_ZUERCHER_DEV_ZONE_ID" {
  description = "Cloudflare zone id for zuercher.dev"
  sensitive   = true
}
