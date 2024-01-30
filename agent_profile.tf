# This example creates an Agent Profile 
resource "apstra_agent_profile" "junos-sw-profile" {
  name     = "junos-sw-profile"
  platform = "junos"
}