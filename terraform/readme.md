# Infrastructure Configuration

Provide configuration information about the infrastructure used.

## Install Terrafrom

For debian / ubuntu following can be run:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

Check the [offical documentation for other systems](https://developer.hashicorp.com/terraform/downloads).

## Setup

Configure the credentials.yml from credentials.yml.example file and .env from .env.example file.

```bash
terraform apply
cd docker
terraform apply
```

## Development

Test cloud init config files:

```bash
cloud-init --file cloud-init.yaml single --name runcmd --frequency=always
cloud-init --file cloud-init.yaml single --name scripts_user --frequency=always
```

## TODO

- [ ] Setup fail2ban
