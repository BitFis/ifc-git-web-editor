# Configure dns endpoint

provider "cloudflare" {
  api_token = var.CLOUDFLATE_API_TOKEN
}

resource "cloudflare_record" "www" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "www"
  value   = data.ovh_vps.coreserver.service_name
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "main" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  value   = data.ovh_vps.coreserver.service_name
  name    = "@"
  type    = "CNAME"
  proxied = true
}