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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

data "terraform_remote_state" "docker_server" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

locals {
  docker_config = data.terraform_remote_state.docker_server.outputs.docker_config
  coreserver = {
    host = data.terraform_remote_state.docker_server.outputs.coreserver_host
  }
}

provider "docker" {
  host     = local.docker_config.host
  ssh_opts = local.docker_config.ssh_opts

  registry_auth {
    address  = "ghcr.io"
    username = var.GITHUB_DOCKER_REGISTRY_USER
    password = var.GITHUB_DOCKER_REGISTRY_ACCESS_TOKEN
  }
}

provider "cloudflare" {
  api_token = var.CLOUDFLATE_API_TOKEN
}

resource "cloudflare_record" "traefik" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "traefik"
  value   = local.coreserver.host
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "login" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "login"
  value   = local.coreserver.host
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "check" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "check"
  value   = local.coreserver.host
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "ifc" {
  zone_id = var.CLOUDFLARE_ZUERCHER_DEV_ZONE_ID
  name    = "ifc"
  value   = local.coreserver.host
  type    = "CNAME"
  proxied = true
}

resource "docker_image" "nginx" {
  name = "nginx"
}

resource "docker_image" "traefik" {
  name = "traefik:2.8"
}

resource "docker_container" "whoami" {
  image = "containous/whoami"

  name = "simple-service"

  dynamic "labels" {
    for_each = {
      "traefik.http.routers.whoami.rule"                      = "Host(`test.zuercher.dev`)"
      "traefik.http.routers.whoami.tls"                       = true
      "traefik.http.routers.whoami.tls.certresolver"          = "le"
      "traefik.http.services.whoami.loadbalancer.server.port" = 80
    }
    content {
      label = labels.key
      value = labels.value
    }
  }

  networks_advanced {
    name = docker_network.traefik.id
  }
}

resource "docker_container" "check" {
  image = "containous/whoami"

  name = "check-service"

  dynamic "labels" {
    for_each = {
      "traefik.http.routers.check.rule"                      = "Host(`check.zuercher.dev`)"
      "traefik.http.routers.check.tls"                       = true
      "traefik.http.routers.check.tls.certresolver"          = "le"
      "traefik.http.services.check.loadbalancer.server.port" = 80
    }
    content {
      label = labels.key
      value = labels.value
    }
  }

  networks_advanced {
    name = docker_network.traefik.id
  }
}

resource "docker_container" "ifceditor" {
  image = "ghcr.io/bitfis/ifc-git-web-editor/ui"

  name = "ifceditor"

  dynamic "labels" {
    for_each = {
      "traefik.http.routers.ifceditor.rule"                      = "Host(`ifc.zuercher.dev`)"
      "traefik.http.routers.ifceditor.tls"                       = true
      "traefik.http.routers.ifceditor.tls.certresolver"          = "le"
      "traefik.http.services.ifceditor.loadbalancer.server.port" = 80
      "traefik.http.routers.ifceditor.middlewares"               = "traefik-forward-auth"
    }
    content {
      label = labels.key
      value = labels.value
    }
  }

  networks_advanced {
    name = docker_network.traefik.id
  }
}

resource "docker_network" "traefik" {
  name     = "traefik"
  internal = true
}

resource "docker_network" "ingress" {
  name     = "ingress"
  internal = false
}

resource "docker_container" "traefik-forward-auth" {
  name  = "traefik-forward-auth"
  image = "thomseddon/traefik-forward-auth:2"

  depends_on = [
    docker_container.keycloak
  ]

  env = [
    "SECRET=something-random",
    "INSECURE_COOKIE=true",
    "PROVIDERS_OIDC_ISSUER_URL=https://auth.zuercher.dev/realms/demo",
    "PROVIDERS_OIDC_CLIENT_ID=test-ocid-client",
    "PROVIDERS_OIDC_CLIENT_SECRET=SdhNUQwZRN3LRuLpunkyiHfwhhKsvE9D",
    "DEFAULT_PROVIDER=oidc",
    # "LOG_LEVEL=debug",
  ]

  networks_advanced {
    name = docker_network.traefik.id
  }
  networks_advanced {
    name = docker_network.ingress.id
  }

  dynamic "labels" {
    for_each = {
      "traefik.http.middlewares.traefik-forward-auth.forwardauth.address"             = "http://traefik-forward-auth:4181"
      "traefik.http.middlewares.traefik-forward-auth.forwardauth.authResponseHeaders" = "X-Forwarded-User"
      "traefik.http.services.traefik-forward-auth.loadbalancer.server.port"           = 4181
    }
    content {
      label = labels.key
      value = labels.value
    }
  }
}


resource "docker_container" "watch-tower" {
  name  = "watch-tower"
  image = "containrrr/watchtower:latest"

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  env = [
    "REPO_USER=${var.GITHUB_DOCKER_REGISTRY_USER}",
    "REPO_PASS=${var.GITHUB_DOCKER_REGISTRY_ACCESS_TOKEN}"
  ]

  command = [
    "ifceditor",
    "--interval", "30" # interval to check set to 30s
  ]
}

resource "docker_container" "traefik" {
  name  = "traefik"
  image = docker_image.traefik.image_id

  dynamic "ports" {
    for_each = [80, 443]
    content {
      external = ports.value
      internal = ports.value
    }
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  # Traefik storage for verified cerificates
  mounts {
    target = "/acme.json"
    source = "/etc/traefik/acme.json"
    type   = "bind"
  }
  volumes {
    host_path      = "/etc/traefik/acme"
    container_path = "/etc/traefik/acme"
  }

  networks_advanced {
    name = docker_network.ingress.id
  }
  networks_advanced {
    name = docker_network.traefik.id
  }

  env = [
    "CF_API_EMAIL=${var.CLOUDFLARE_CORE_EMAIL}",
    "CF_API_KEY=${var.CLOUDFLARE_CORE_API_KEY}"
  ]

  command = [
    "--providers.docker=true",
    "--providers.docker.network=traefik",
    # "--providers.docker.exposedByDefault=false",
    "--api=true",
    "--api.insecure=true",
    "--entrypoints.web.address=:80",
    "--entrypoints.web.http.redirections.entryPoint.to=websecure",
    "--entrypoints.web.http.redirections.entryPoint.scheme=https",
    "--entrypoints.websecure.address=:443",
    "--certificatesresolvers.le.acme.email=lucien@zuercher.io",
    "--certificatesresolvers.le.acme.storage=acme.json",
    "--certificatesresolvers.le.acme.dnschallenge=true",
    "--certificatesresolvers.le.acme.dnschallenge.resolvers[0]=1.1.1.1:53",
    "--certificatesresolvers.le.acme.dnschallenge.resolvers[1]=1.0.0.1:53",
    "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare",
    "--entrypoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12",
    # TMP, use staging environment to stest
    "--certificatesresolvers.le.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory",
  ]

  dynamic "labels" {
    for_each = {
      "traefik.http.routers.traefik.rule"                      = "Host(`traefik.zuercher.dev`)"
      "traefik.http.routers.traefik.middlewares"               = "traefik-forward-auth"
      "traefik.http.routers.traefik.tls"                       = true
      "traefik.http.routers.traefik.tls.certresolver"          = "le"
      "traefik.http.services.traefik.loadbalancer.server.port" = 8080
    }
    content {
      label = labels.key
      value = labels.value
    }
  }
}
