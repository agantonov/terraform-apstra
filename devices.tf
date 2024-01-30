# Devices to be onboarded

locals {
  devices = {
    leaf1 = {
      label   = "rack_2xleaf_esi_001_leaf1",
      mgmt_ip = "172.20.20.21"
    },
    leaf2 = {
      label   = "rack_2xleaf_esi_001_leaf2",
      mgmt_ip = "172.20.20.22"
    },
    leaf3 = {
      label   = "rack_2xleaf_esi_002_leaf1",
      mgmt_ip = "172.20.20.23"
    },
    leaf4 = {
      label   = "rack_2xleaf_esi_002_leaf2",
      mgmt_ip = "172.20.20.24"
    },
    spine1 = {
      label   = "spine1",
      mgmt_ip = "172.20.20.25"
    },
    spine2 = {
      label   = "spine2",
      mgmt_ip = "172.20.20.26"
    }
  }
}

# Look up the details of the Agent Profile to which we've added a username and password.

data "apstra_agent_profile" "junos-agent-profile" {
  name = "junos-sw-profile"
}

# Create off-box agents for all Junos devices without ack'ing them 

resource "apstra_managed_device" "device" {
  for_each         = local.devices
  agent_profile_id = data.apstra_agent_profile.junos-agent-profile.id
  management_ip    = each.value.mgmt_ip
  off_box          = true
}

# Gather details of every individual agent ID

data "apstra_agent" "agent" {
  for_each = apstra_managed_device.device
  agent_id = each.value.agent_id
}

# Ack each agent with the derived SN (passed into device_key)

resource "apstra_managed_device_ack" "device" {
  for_each   = data.apstra_agent.agent
  agent_id   = each.value.agent_id
  device_key = each.value.device_key
}