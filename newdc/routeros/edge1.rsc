# edge1 AS142108 — RouterOS BGP UNNUMBERED to sw1 (verified working, RouterOS 7.23.1)
/ipv6 nd add interface=ether2 ra-interval=3s-5s
/ipv6 nd prefix add prefix=none interface=ether2
/routing bgp instance add as=142108 name=inst1 router-id=10.0.0.11 vrf=main
/routing bgp connection add name=sw1 afi=ip instance=inst1 local.role=ebgp local.address=ether2 remote.as=65100
