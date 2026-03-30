terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = ">= 2.8.0"
    }
  }
}

provider "digitalocean" {
}

locals {
  droplet_names = [
    "haproxy",
    "pg-master",
    "pg-replica",
    "consul1",
    "consul2",
    "consul3"
  ]
}

resource "digitalocean_droplet" "nodes" {
  for_each = toset(local.droplet_names)

  name   = each.key
  image  = var.ubuntu
  region = var.do_ams3
  size   = "s-2vcpu-4gb"

  ssh_keys = [digitalocean_ssh_key.example.id]

  user_data = file("cloudinit.conf")
}
resource "digitalocean_ssh_key" "example" {
  name       = "examplekey"
  public_key = file(var.ssh_key_path)
}


locals {
  droplets = {
    for name, droplet in digitalocean_droplet.nodes :
    name => droplet.ipv4_address
  }

  consul_nodes = {
    for name, ip in local.droplets :
    name => ip if can(regex("consul", name))
  }

  pg_master = {
    for name, ip in local.droplets :
    name => ip if name == "pg-master"
  }

  pg_replica = {
    for name, ip in local.droplets :
    name => ip if name == "pg-replica"
  }

  haproxy = {
    for name, ip in local.droplets :
    name => ip if name == "haproxy"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../inventory.ini"

  content = <<-EOT
[vms]
%{ for name, ip in local.droplets ~}
${name} ansible_host=${ip}
%{ endfor ~}

[pg_master]
%{ for name, ip in local.pg_master ~}
${name} ansible_host=${ip}
%{ endfor ~}

[pg_replica]
%{ for name, ip in local.pg_replica ~}
${name} ansible_host=${ip}
%{ endfor ~}

[consul]
%{ for name, ip in local.consul_nodes ~}
${name} ansible_host=${ip}
%{ endfor ~}

[haproxy_hosts]
%{ for name, ip in local.haproxy ~}
${name} ansible_host=${ip}
%{ endfor ~}

[all:vars]
ansible_user=root
ansible_password={{ root_password }}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}