output "droplet_id" {
  value       = digitalocean_droplet.platform.id
  description = "ID del droplet creado"
}

output "droplet_ip" {
  value       = digitalocean_droplet.platform.ipv4_address
  description = "IP publica del droplet"
}

output "firewall_id" {
  value       = digitalocean_firewall.platform.id
  description = "ID del firewall asociado"
}
