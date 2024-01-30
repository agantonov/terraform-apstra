# create fabric resources

resource "apstra_ipv4_pool" "loopback" {
  name = "loopback"
  subnets = [
    { network = "1.1.1.0/24" }
  ]
}

resource "apstra_ipv4_pool" "evpn_loopback" {
  name = "evpn_loopback"
  subnets = [
    { network = "1.1.10.0/24" }
  ]
}

resource "apstra_ipv4_pool" "p2p" {
  name = "p2p"
  subnets = [
    { network = "10.100.0.0/24" }
  ]
}

resource "apstra_asn_pool" "asn_pool" {
  name = "asn_pool"
  ranges = [
    {
      first = 64512
      last  = 64999
    }
  ]
}

resource "apstra_vni_pool" "vni_pool" {
  name = "vni_pool"
  ranges = [
    {
      first = 10000
      last  = 20000
    }
  ]
}
