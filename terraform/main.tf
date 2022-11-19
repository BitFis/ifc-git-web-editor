
# locals {
# }

data "ovh_vps" "coreserver" {
  provider     = ovh.ovh_eu
  service_name = "vps-79631ef4.vps.ovh.net"
}

locals {
  server_credentials = yamldecode(file("${path.root}/credentials.yml"))["servers"] # this converts all the queues into a list of maps
  coreserver_cred = lookup(local.server_credentials, "vps-79631ef4.vps.ovh.net")
}

resource "null_resource" "coreserver" {
  triggers = {
    datacontent = templatefile("${path.module}/assets/ovh.server.cloud-init.cfgtpl", {
      root_user     = local.coreserver_cred.user,
      root_password = local.coreserver_cred.password
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
}

output "coreserver_host" {
  value = data.ovh_vps.coreserver.service_name
}
