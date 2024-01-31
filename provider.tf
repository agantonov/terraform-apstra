terraform {
  required_providers {
    apstra = {
      source = "Juniper/apstra"
    }
  }
  backend "http" {}
}

provider "apstra" {
  tls_validation_disabled = true
  experimental            = true
  blueprint_mutex_enabled = false
}
