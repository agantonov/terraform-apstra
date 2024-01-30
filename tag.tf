# this example creates a tags named after enterprise teams
# responsible for various data center asset types.
locals {
  servers = toset([
    "ubuntu_server"
  ])
}

resource "apstra_tag" "interface_tags" {
  for_each = local.servers
  name     = each.key
}