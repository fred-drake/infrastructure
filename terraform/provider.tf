terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc4"
    }

    bitwarden-secrets = {
      source = "sebastiaan-dev/bitwarden-secrets"
      version = ">=0.1.2"
    }
  }
}

data "bitwarden-secrets_secret" "proxmox_api_token_id" {
  id = "957e4f2f-307e-4c8d-8e8e-b1f5017ed617"
}

data "bitwarden-secrets_secret" "proxmox_api_token_secret" {
  id = "f388ec7a-06ee-4ef9-a626-b1f5017eecab"
}

# Value is stored in environment variable $TF_VAR_BWS_TOKEN
variable "BWS_TOKEN" {
  type = string
}

provider "proxmox" {
  pm_api_url = "https://medivh.internal.freddrake.com:8006/api2/json"
  pm_api_token_secret = "${data.bitwarden-secrets_secret.proxmox_api_token_secret.value}"
  pm_api_token_id = "${data.bitwarden-secrets_secret.proxmox_api_token_id.value}"
  pm_tls_insecure = false
}

provider "bitwarden-secrets" {
  access_token = "${var.BWS_TOKEN}"
}
