# Create routing zones in Apstra which translate to IP VRFs on the devices

resource "apstra_datacenter_routing_zone" "vrf100" {
  name                = "VRF100"
  blueprint_id        = apstra_datacenter_blueprint.dc1_blueprint.id
  junos_evpn_irb_mode = "symmetric"
}

resource "apstra_datacenter_routing_zone" "vrf200" {
  name                = "VRF200"
  blueprint_id        = apstra_datacenter_blueprint.dc1_blueprint.id
  junos_evpn_irb_mode = "symmetric"
}

# Assign loopbacks for each routing zone

resource "apstra_datacenter_resource_pool_allocation" "vrf100_loopback" {
  blueprint_id    = apstra_datacenter_blueprint.dc1_blueprint.id // adds implicit dependency on blueprint creation
  role            = "leaf_loopback_ips"
  pool_ids        = [apstra_ipv4_pool.evpn_loopback.id]
  routing_zone_id = apstra_datacenter_routing_zone.vrf100.id // adds implicit dependency on RZ creation
}

resource "apstra_datacenter_resource_pool_allocation" "vrf200_loopback" {
  blueprint_id    = apstra_datacenter_blueprint.dc1_blueprint.id // adds implicit dependency on blueprint creation
  role            = "leaf_loopback_ips"
  pool_ids        = [apstra_ipv4_pool.evpn_loopback.id]
  routing_zone_id = apstra_datacenter_routing_zone.vrf200.id // adds implicit dependency on RZ creation
}

# Assign VNI for each routing zone

resource "apstra_datacenter_resource_pool_allocation" "vrf_vni" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id // adds implicit dependency on blueprint creation
  role         = "evpn_l3_vnis"
  pool_ids     = [apstra_vni_pool.vni_pool.id]
}

# create VNs per routing zone

// when attaching VNs to a paired switch (such as ESI LAG), do not use
// individual node IDs for bindings since a pair is represented as one 
// logical node in Apstra's graph db. Instead, use binding constructor
// and find out the node ID for the logical node.

data "apstra_datacenter_virtual_network_binding_constructor" "vn100" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  vlan_id      = 100
  switch_ids = [
    apstra_datacenter_device_allocation.leaf_devices["leaf1"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf2"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf3"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf4"].node_id
  ]
}

data "apstra_datacenter_virtual_network_binding_constructor" "vn200" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  vlan_id      = 200
  switch_ids = [
    apstra_datacenter_device_allocation.leaf_devices["leaf1"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf2"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf3"].node_id,
    apstra_datacenter_device_allocation.leaf_devices["leaf4"].node_id
  ]
}

resource "apstra_datacenter_virtual_network" "vn100" {
  name                         = "VN100"
  blueprint_id                 = apstra_datacenter_blueprint.dc1_blueprint.id
  type                         = "vxlan"
  routing_zone_id              = apstra_datacenter_routing_zone.vrf100.id
  ipv4_connectivity_enabled    = true
  ipv4_virtual_gateway_enabled = true
  ipv4_virtual_gateway         = "192.168.100.1"
  ipv4_subnet                  = "192.168.100.0/24"
  bindings                     = data.apstra_datacenter_virtual_network_binding_constructor.vn100.bindings
}

resource "apstra_datacenter_virtual_network" "vn200" {
  name                         = "VN200"
  blueprint_id                 = apstra_datacenter_blueprint.dc1_blueprint.id
  type                         = "vxlan"
  routing_zone_id              = apstra_datacenter_routing_zone.vrf200.id
  ipv4_connectivity_enabled    = true
  ipv4_virtual_gateway_enabled = true
  ipv4_virtual_gateway         = "192.168.200.1"
  ipv4_subnet                  = "192.168.200.0/24"
  bindings                     = data.apstra_datacenter_virtual_network_binding_constructor.vn200.bindings
}

# Assign VNI from pool

resource "apstra_datacenter_resource_pool_allocation" "vn_vni" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id // adds implicit dependency on blueprint creation
  role         = "vni_virtual_network_ids"
  pool_ids     = [apstra_vni_pool.vni_pool.id]
}

# Create data sources to retrieve IDs of each VN created

data "apstra_datacenter_virtual_network" "vn100" {
  depends_on   = [apstra_datacenter_virtual_network.vn100] // needed otherwise data source will run too early
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  name         = "VN100"
}

data "apstra_datacenter_virtual_network" "vn200" {
  depends_on   = [apstra_datacenter_virtual_network.vn200] // needed otherwise data source will run too early
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  name         = "VN200"
}