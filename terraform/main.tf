# Configure core ovh vps server as a docker host

data "ovh_vps" "coreserver" {
  provider     = ovh.ovh_eu
  service_name = "vps-79631ef4.vps.ovh.net"
}

resource "tls_private_key" "terraform_keys" {
  algorithm = "ED25519"
}

locals {
  server_credentials = yamldecode(file("${path.root}/credentials.yml"))["servers"] # this converts all the queues into a list of maps
  coreserver_cred    = lookup(local.server_credentials, data.ovh_vps.coreserver.service_name)
}

resource "null_resource" "coreserver" {
  triggers = {
    datacontent = templatefile("${path.module}/assets/ovh.server.cloud-init.cfgtpl", {
      root_user     = local.coreserver_cred.user,
      root_password = local.coreserver_cred.password
      terraform_pem = tls_private_key.terraform_keys.public_key_openssh
    })
  }

  connection {
    type     = "ssh"
    user     = local.coreserver_cred.user
    password = local.coreserver_cred.password
    host     = data.ovh_vps.coreserver.service_name
  }

  provisioner "file" {
    content     = null_resource.coreserver.triggers.datacontent
    destination = "/tmp/cloud-init.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      # rerun cloud init to reconfigure custom cloudinit.yml file
      "sudo cloud-init clean",
      "sudo cloud-init -f /tmp/cloud-init.yaml -d init --local",
      "sudo cloud-init -f /tmp/cloud-init.yaml -d init",
      "sudo cloud-init -f /tmp/cloud-init.yaml -d modules --mode=config",
      "sudo cloud-init -f /tmp/cloud-init.yaml -d modules --mode=final"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl disable ufw",
      "sudo ufw disable",
      "echo 'y' | sudo ufw reset",
      "sudo ufw default allow outgoing",
      "sudo ufw default deny incoming",
      "sudo ufw allow ssh",
      "sudo ufw allow 80/tcp",
      "sudo ufw allow 443/tcp",
      "echo 'y' | sudo ufw enable",
      "sudo systemctl enable ufw"
    ]
  }
}

resource "local_sensitive_file" "coreserver_access" {
  content         = tls_private_key.terraform_keys.private_key_openssh
  filename        = "${path.cwd}/.ssh_access_key"
  file_permission = "0600"
}

output "terraform_keys" {
  value     = tls_private_key.terraform_keys
  sensitive = true
}

output "coreserver_host" {
  value = data.ovh_vps.coreserver.service_name
}

output "docker_config" {
  value = {
    host     = "ssh://terraform@${data.ovh_vps.coreserver.service_name}:22"
    ssh_opts = ["-i", "${local_sensitive_file.coreserver_access.filename}", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
  }
}