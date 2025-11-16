terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "itz-kevin-dev-terr"
    workspaces {
      name = "platform-infra"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
