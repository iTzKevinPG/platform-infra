locals {
  droplet_user_data_value = var.droplet_user_data != "" ? var.droplet_user_data : null
}

resource "digitalocean_droplet" "platform" {
  name       = var.droplet_name
  region     = var.region
  size       = var.droplet_size
  image      = var.droplet_image
  ssh_keys   = [data.digitalocean_ssh_key.platform.fingerprint]
  backups    = false
  ipv6       = true
  monitoring = true
  tags       = var.project_tags
  user_data  = local.droplet_user_data_value
}
