# sw1 AS65100 — RouterOS BGP UNNUMBERED to edge1 (verified working, RouterOS 7.23.1)
/ipv6 nd add interface=ether2 ra-interval=3s-5s
/ipv6 nd prefix add prefix=none interface=ether2
/ip firewall address-list add list=SVC address=203.0.113.10/32
/ip route add blackhole dst-address=203.0.113.10/32
/routing bgp instance add as=65100 name=inst1 router-id=10.0.0.100 vrf=main
/routing bgp connection add name=edge afi=ip instance=inst1 local.role=ebgp local.address=ether2 remote.as=142108 output.network=SVC
