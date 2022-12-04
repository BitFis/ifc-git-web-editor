
resource "random_password" "keycloak" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "keycloak_db" {
  length           = 32
  special          = true
  override_special = "_%@"
}

locals {
  keycloak = {
    user     = "nimda"
    password = random_password.keycloak.result

    postgres = {
      db       = "keycloak"
      user     = "keycloak"
      password = random_password.keycloak_db.result
    }
  }
}

resource "docker_image" "keycloak" {
  name = "quay.io/keycloak/keycloak:20.0.1"
}

resource "docker_image" "postgres" {
  name = "postgres:15"
}

resource "docker_network" "keycloak_network" {
  name = "keycloak_network"
}

resource "cloudflare_record" "keycloak" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "auth"
  value   = local.coreserver.host
  type    = "CNAME"
  proxied = true
}

# resource "docker_container" "keycloak_db" {
#   name = "keycloak_db"
#
# }

resource "docker_container" "keycloak" {
  name  = "keycloak"
  image = docker_image.keycloak.image_id

  command = ["start",
    # "--optimized", ??
    "--proxy=edge",
    "--hostname-strict=true"
  ]
  env = [
    "KEYCLOAK_ADMIN=${local.keycloak.user}",
    "KEYCLOAK_ADMIN_PASSWORD=${local.keycloak.password}",
    "KC_HOSTNAME_URL=https://auth.zuercher.dev/",
    "PROXY_ADDRESS_FORWARDING=true"
  ]

  # networks_advanced {
  #   name = docker_network.keycloak_network.id
  # }

  networks_advanced {
    name = docker_network.traefik.id
  }

  # todo persistent storage ...

  dynamic "labels" {
    for_each = {
      "traefik.http.routers.keycloak.tls.certresolver"          = "le"
      "traefik.http.routers.keycloak.tls"                       = true
      "traefik.http.routers.keycloak.rule"                      = "Host(`auth.zuercher.dev`)"
      "traefik.http.services.keycloak.loadbalancer.server.port" = 8080
    }
    content {
      label = labels.key
      value = labels.value
    }
  }
}

output "keycloak" {
  value = {
    user     = local.keycloak.user
    password = local.keycloak.password
  }
  sensitive = true
}
