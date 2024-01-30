# create a data source for respective VLANs first
# use tolist() because the data source returns a set. since we expect just one ID
# convert to a list using tolist() and then access the ID via index of 0

data "apstra_datacenter_ct_virtual_network_single" "dc1_vn100_vlan" {
  vn_id  = data.apstra_datacenter_virtual_network.vn100.id
  tagged = true
}

data "apstra_datacenter_ct_virtual_network_single" "dc1_vn200_vlan" {
  vn_id  = data.apstra_datacenter_virtual_network.vn200.id
  tagged = true
}

# create actual CT for this now by attaching the primitive from the data source

resource "apstra_datacenter_connectivity_template" "dc1_vn100_ct" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  name         = "DC1_VN100_VLAN"
  description  = "DC1 VN100 tagged"
  primitives = [
    data.apstra_datacenter_ct_virtual_network_single.dc1_vn100_vlan.primitive
  ]
}

resource "apstra_datacenter_connectivity_template" "dc1_vn200_ct" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  name         = "DC1_VN200_VLAN"
  description  = "DC1 VN200 tagged"
  primitives = [
    data.apstra_datacenter_ct_virtual_network_single.dc1_vn200_vlan.primitive
  ]
}

# gather graph IDs for all interfaces based on their tags assignments 
# which point to the hosts

data "apstra_datacenter_interfaces_by_link_tag" "server_link" {
  blueprint_id = apstra_datacenter_blueprint.dc1_blueprint.id
  tags         = ["ubuntu_server"]
}

# assign CT to application points i.e. the IDs that were determined from previous
# data source that found interfaces by tags

#resource "apstra_datacenter_connectivity_template_assignment" "assign_ct_dc1_vn100_ubuntu_server" {
#  blueprint_id         = apstra_datacenter_blueprint.dc1_blueprint.id
#  for_each             = data.apstra_datacenter_interfaces_by_link_tag.server_link.ids
#  application_point_id = each.key
#  connectivity_template_ids = [
#    apstra_datacenter_connectivity_template.dc1_vn100_ct.id
#  ]
#}

#resource "apstra_datacenter_connectivity_template_assignment" "assign_ct_dc1_vn200_ubuntu_server" {
#  blueprint_id         = apstra_datacenter_blueprint.dc1_blueprint.id
#  for_each             = data.apstra_datacenter_interfaces_by_link_tag.server_link.ids
#  application_point_id = each.key
#  connectivity_template_ids = [
#    apstra_datacenter_connectivity_template.dc1_vn200_ct.id
#  ]
#}

resource "apstra_datacenter_connectivity_template_assignments" "assign_ct_dc1_vn100_ubuntu_server" {
  blueprint_id             = apstra_datacenter_blueprint.dc1_blueprint.id
  connectivity_template_id = apstra_datacenter_connectivity_template.dc1_vn100_ct.id
  application_point_ids    = data.apstra_datacenter_interfaces_by_link_tag.server_link.ids
}

resource "apstra_datacenter_connectivity_template_assignments" "assign_ct_dc1_vn200_ubuntu_server" {
  blueprint_id             = apstra_datacenter_blueprint.dc1_blueprint.id
  connectivity_template_id = apstra_datacenter_connectivity_template.dc1_vn200_ct.id
  application_point_ids    = data.apstra_datacenter_interfaces_by_link_tag.server_link.ids
}
