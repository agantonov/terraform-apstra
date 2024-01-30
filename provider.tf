terraform {
  required_providers {
    apstra = {
      source = "Juniper/apstra"
    }
  }
}

provider "apstra" {
  tls_validation_disabled = true
  experimental            = true
  blueprint_mutex_enabled = false
}
