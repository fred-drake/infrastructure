terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }

    bitwarden-secrets = {
      source  = "sebastiaan-dev/bitwarden-secrets"
      version = ">=0.1.2"
    }

    hyperv = {
      source  = "taliesins/hyperv"
      version = "1.2.1"
    }
  }
}

data "bitwarden-secrets_secret" "proxmox_api_token_id" {
  id = "957e4f2f-307e-4c8d-8e8e-b1f5017ed617"
}

data "bitwarden-secrets_secret" "proxmox_api_token_secret" {
  id = "f388ec7a-06ee-4ef9-a626-b1f5017eecab"
}

data "bitwarden-secrets_secret" "hyperv_password" {
  id = "87fd6ad5-ff36-4fcb-acd6-b27a0144e8e1"
}

data "bitwarden-secrets_secret" "hyperv_username" {
  id = "a281493a-4f2a-4974-9930-b27a0144b5b2"
}

# Value is stored in environment variable $TF_VAR_BWS_TOKEN
variable "BWS_TOKEN" {
  type = string
}

provider "proxmox" {
  pm_api_url          = "https://anduin.internal.freddrake.com:8006/api2/json"
  pm_api_token_secret = data.bitwarden-secrets_secret.proxmox_api_token_secret.value
  pm_api_token_id     = data.bitwarden-secrets_secret.proxmox_api_token_id.value
  pm_tls_insecure     = false
}

provider "bitwarden-secrets" {
  access_token = var.BWS_TOKEN
}

provider "hyperv" {
  user            = "tofu"
  password        = "tofu"
  host            = "192.168.30.58"
  port            = 5986
  https           = true
  insecure        = true
  tls_server_name = ""
  cacert_path     = ""
  key_path        = ""
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
}
