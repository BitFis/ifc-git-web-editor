# Configure providers

provider "ovh" {
  alias              = "ovh_eu"
  endpoint           = "ovh-eu"
  application_key    = var.OVH_APPLICATION_KEY
  application_secret = var.OVH_APPLICATION_SECRET
  consumer_key       = var.OVH_CONSUMER_KEY
}
