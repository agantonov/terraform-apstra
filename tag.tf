# Creates tags
locals {
  servers = toset([
    "ubuntu_server"
  ])
}

resource "apstra_tag" "interface_tags" {
  for_each = local.servers
  name     = each.key
}
