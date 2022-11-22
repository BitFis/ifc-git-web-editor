
provider "docker" {
  host     = "ssh://${local.coreserver_cred.user}@${data.ovh_vps.coreserver.service_name}:22"
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null"]
}
