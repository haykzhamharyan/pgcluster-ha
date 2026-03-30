output "droplet_ips" {
  value = {
    for name, droplet in digitalocean_droplet.nodes :
    name => droplet.ipv4_address
  }
}

