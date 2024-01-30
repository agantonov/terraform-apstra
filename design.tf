# This example creates a logical device with 2x1G ports connected to spines
# and 4x1G ports connected generic systems.

resource "apstra_logical_device" "leaf_2spine_4generic" {
  name = "Leaf__2xSpine_4xGeneric"
  panels = [
    {
      rows    = 2
      columns = 3
      port_groups = [
        {
          port_count = 2
          port_speed = "1G"
          port_roles = ["spine"]
        },
        {
          port_count = 4
          port_speed = "1G"
          port_roles = ["generic"]
        },
      ]
    }
  ]
}

# This example creates a logical device with 4x1G ports connected to leaves
# and 2x1G ports connected generic systems.

resource "apstra_logical_device" "spine_4leaf_2generic" {
  name = "Spine__4xLeaf_2xGeneric"
  panels = [
    {
      rows    = 2
      columns = 3
      port_groups = [
        {
          port_count = 4
          port_speed = "1G"
          port_roles = ["leaf"]
        },
        {
          port_count = 2
          port_speed = "1G"
          port_roles = ["generic"]
        },
      ]
    }
  ]
}

## Interface Maps
locals {
  vJunos_if_map = [
    { # map logical 1/1 - 1/6 to physical ge-0/0/0 to ge-0/0/5     
      # this is a vJunos-switch device
      ld_panel       = 1
      ld_first_port  = 1
      phy_prefix     = "ge-0/0/"
      phy_first_port = 0
      count          = 6
    }
  ]
  vJunos_interfaces = [
    for map in local.vJunos_if_map : [
      for i in range(map.count) : {
        logical_device_port     = format("%d/%d", map.ld_panel, map.ld_first_port + i)
        physical_interface_name = format("%s%d", map.phy_prefix, map.phy_first_port + i)
      }
    ]
  ]
}

# Create interface map for Leaf__2xSpine_4xGeneric

resource "apstra_interface_map" "vjunos__leaf_2spine_4generic" {
  name              = "vJunos-switch____Leaf__2xSpine_4xGeneric"
  logical_device_id = apstra_logical_device.leaf_2spine_4generic.id
  device_profile_id = "vJunos-switch"
  interfaces        = flatten([local.vJunos_interfaces])
}

# Create interface map for Spine__4xLeaf_2xGeneric

resource "apstra_interface_map" "vjunos__spine_4leaf_2generic" {
  name              = "vJunos-switch____Spine__4xLeaf_2xGeneric"
  logical_device_id = apstra_logical_device.spine_4leaf_2generic.id
  device_profile_id = "vJunos-switch"
  interfaces        = flatten([local.vJunos_interfaces])
}

## Create rack

resource "apstra_rack_type" "rack_2leaf_esi" {
  name                       = "Rack_2xLeaf_ESI"
  description                = "Created by Terraform"
  fabric_connectivity_design = "l3clos"
  leaf_switches = { // leaf switches are a map keyed by switch name, so
    leaf_switch = { // "leaf switch" on this line is the name used by links targeting this switch.
      logical_device_id   = apstra_logical_device.leaf_2spine_4generic.id
      spine_link_count    = 1
      spine_link_speed    = "1G"
      redundancy_protocol = "esi"
    }
  }
  generic_systems = {
    server = {
      count             = 1
      logical_device_id = "AOS-2x1-1"
      links = {
        link = {
          speed              = "1G"
          target_switch_name = "leaf_switch"
          lag_mode           = "lacp_active"
          tag_ids            = [apstra_tag.interface_tags["ubuntu_server"].id]
        }
      }
    }
  }
}

# Create template

resource "apstra_template_rack_based" "dc1_2racks" {
  name                     = "DC1-2xRacks"
  asn_allocation_scheme    = "unique"
  overlay_control_protocol = "evpn"
  spine = {
    logical_device_id = apstra_logical_device.spine_4leaf_2generic.id
    count             = 2
  }
  rack_infos = {
    (apstra_rack_type.rack_2leaf_esi.id) = { count = 2 }
  }
}