# Instantiate a blueprint from the previously-created template

resource "apstra_datacenter_blueprint" "dc1_blueprint" {
  name        = "DC1"
  template_id = apstra_template_rack_based.dc1_2racks.id
}

# Assign previously-created ASN resource pools to roles in the fabric

locals { asn_roles = toset(["spine_asns", "leaf_asns"]) }

resource "apstra_datacenter_resource_pool_allocation" "asns" {
  for_each     = local.asn_roles
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  role         = each.key
  pool_ids     = [apstra_asn_pool.asn_pool.id]
}

# Assign previously-created IPv4 loopbacks from the pool
locals { ipv4_roles = toset(["spine_loopback_ips", "leaf_loopback_ips"]) }
resource "apstra_datacenter_resource_pool_allocation" "loopbacks" {
  for_each     = local.ipv4_roles
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  role         = each.key
  pool_ids     = [apstra_ipv4_pool.loopback.id]
}

# Assign previously-created p2p IPs from the pool
resource "apstra_datacenter_resource_pool_allocation" "p2p_links" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  role         = "spine_leaf_link_ips"
  pool_ids     = [apstra_ipv4_pool.p2p.id]
}

# Assign interface maps and deploy mode for leaves
resource "apstra_datacenter_device_allocation" "leaf_devices" {
  depends_on = [apstra_managed_device_ack.device]
  for_each = {
    for k, v in local.devices : k => v.label
    if startswith(v.label, "rack")
  }
  blueprint_id             = apstra_datacenter_blueprint.dc1_blueprint.id
  initial_interface_map_id = apstra_interface_map.vjunos__leaf_2spine_4generic.id
  node_name                = each.value
  device_key               = apstra_managed_device.device[each.key].system_id
  deploy_mode              = "deploy"
}

# Assign interface maps and deploy mode for spines
resource "apstra_datacenter_device_allocation" "spine_devices" {
  depends_on = [apstra_managed_device_ack.device]
  for_each = {
    for k, v in local.devices : k => v.label
    if startswith(v.label, "spine")
  }
  blueprint_id             = apstra_datacenter_blueprint.dc1_blueprint.id
  initial_interface_map_id = apstra_interface_map.vjunos__spine_4leaf_2generic.id
  node_name                = each.value
  device_key               = apstra_managed_device.device[each.key].system_id
  deploy_mode              = "deploy"
}


# Deploy the blueprint.
resource "apstra_blueprint_deployment" "dc1_deployment" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  comment      = "Deployment by Terraform {{.TerraformVersion}}, Apstra provider {{.ProviderVersion}}, User $USER."
  depends_on = [
    # Lots of terraform happens in parallel -- this section forces deployment
    # to wait until resources which modify the blueprint are complete.
    apstra_datacenter_resource_pool_allocation.asns,
    apstra_datacenter_resource_pool_allocation.loopbacks,
    apstra_datacenter_resource_pool_allocation.p2p_links,
    apstra_datacenter_device_allocation.leaf_devices,
    apstra_datacenter_device_allocation.spine_devices,
    apstra_datacenter_virtual_network.vn100,
    apstra_datacenter_virtual_network.vn200,
    apstra_datacenter_routing_zone.vrf100,
    apstra_datacenter_routing_zone.vrf200,
    apstra_datacenter_connectivity_template.dc1_vn100_ct,
    apstra_datacenter_connectivity_template.dc1_vn200_ct,
    apstra_datacenter_connectivity_template_assignments.assign_ct_dc1_vn100_ubuntu_server,
    apstra_datacenter_connectivity_template_assignments.assign_ct_dc1_vn200_ubuntu_server
  ]
}