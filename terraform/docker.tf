# Setup docker

provider "docker" {
  host     = "ssh://terraform@${data.ovh_vps.coreserver.service_name}:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}

resource "docker_image" "nginx" {
  name = "nginx"
}

# dummy webserver
# docker run --name some-nginx -p 80:80 -v /some/content:/usr/share/nginx/html:ro -d nginx
resource "docker_container" "webserver" {
  depends_on = [
    null_resource.coreserver
  ]

  name  = "nginx"
  ports {
    external = 80
    internal = 80
  }
  image = docker_image.nginx.image_id
}
