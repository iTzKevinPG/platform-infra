variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Region del datacenter"
  type        = string
  default     = "sfo3"
}

variable "droplet_size" {
  description = "Plan/tamano del droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "droplet_image" {
  description = "Imagen base del droplet"
  type        = string
  default     = "docker-20-04"
}

variable "droplet_name" {
  description = "Nombre del droplet"
  type        = string
  default     = "platform-droplet"
}

variable "project_tags" {
  description = "Tags aplicados al droplet"
  type        = list(string)
  default     = ["platform", "portfolio"]
}

variable "ssh_key_name" {
  description = "Nombre con el que se registrara la clave SSH en DO"
  type        = string
  default     = "platform-key"
}

variable "ssh_public_key" {
  description = "Contenido literal de la clave publica (usado en Terraform Cloud)"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Ruta local a la clave publica (solo para ejecuciones locales)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "firewall_name" {
  description = "Nombre del firewall"
  type        = string
  default     = "platform-firewall"
}

variable "droplet_user_data" {
  description = "Contenido cloud-init/user-data opcional para bootstrap"
  type        = string
  default     = ""
}
