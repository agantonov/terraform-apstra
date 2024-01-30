terraform {
  required_providers {
    apstra = {
      source = "Juniper/apstra"
    }
  }
}

provider "apstra" {
  #  url                     = "https://server-14a:8443"
  tls_validation_disabled = true
  experimental            = true
  blueprint_mutex_enabled = false
}
