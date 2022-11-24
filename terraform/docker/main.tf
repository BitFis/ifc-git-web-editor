# Define providers and set versions
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

data "terraform_remote_state" "docker_server" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

variable "CLOUDFLARE_CORE_API_KEY" {
  sensitive = true
}

variable "CLOUDFLARE_CORE_EMAIL" {
  sensitive = true
}

locals {
  docker_config = data.terraform_remote_state.docker_server.outputs.docker_config
}

provider "docker" {
  host     = local.docker_config.host
  ssh_opts = local.docker_config.ssh_opts
}

resource "docker_image" "nginx" {
  name = "nginx"
}

resource "docker_image" "traefik" {
  name = "traefik:2.8"
}

resource "docker_image" "keycloak" {
  name = "quay.io/keycloak/keycloak:20.0.1"
}

resource "random_password" "keycloak" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "docker_container" "whoami" {
  image = "containous/whoami"

  name = "simple-service"

  labels {
    label = "traefik.http.routers.whoami.rule"
    value = "Host(`test.zuercher.dev`)"
  }
  labels {
    label = "traefik.http.routers.whoami.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.whoami.tls.certresolver"
    value = "le"
  }
}

resource "docker_container" "traefik" {
  name  = "traefik"
  image = docker_image.traefik.image_id

  ports {
    external = 80
    internal = 80
  }
  ports {
    external = 443
    internal = 443
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  env = [
    "CF_API_EMAIL=${var.CLOUDFLARE_CORE_EMAIL}",
    "CF_API_KEY=${var.CLOUDFLARE_CORE_API_KEY}"
  ]

  command = [
    "--providers.docker=true",
    "--api=true",
    "--entrypoints.web.address=:80",
    "--entrypoints.web.http.redirections.entryPoint.to=websecure",
    "--entrypoints.web.http.redirections.entryPoint.scheme=https",
    "--entrypoints.websecure.address=:443",
    "--certificatesresolvers.le.acme.dnschallenge=true",
    "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare",
    "--entrypoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
  ]
}

 resource "docker_container" "keycloak" {
     name = "keycloak"
     image = docker_image.keycloak.image_id

     command = ["start-dev"]
     env = [
        "KEYCLOAK_ADMIN=nimda",
        "KEYCLOAK_ADMIN_PASSWORD=${random_password.keycloak.result}",
        "KC_HOSTNAME_URL=https://keycloak.zuercher.dev/",
        "PROXY_ADDRESS_FORWARDING=true"
    ]

    labels {
        label = "traefik.http.routers.keycloak.rule"
        value = "Host(`keycloak.zuercher.dev`)"
    }

    labels {
        label = "traefik.http.routers.keycloak.tls"
        value = true
    }

    labels {
        label = "traefik.http.routers.keycloak.tls.certresolver"
        value = "le"
    }
}

output "keycloak_password" {
  value     = random_password.keycloak.result
  sensitive = true
}
