# minimal RouterOS unnumbered eBGP config facing a BIRD host (clab interop test).
# Proves bird(host) <-> RouterOS(CHR) unnumbered + RFC 5549 (enhe). ether2 = link to the bird host.
/ipv6 nd add interface=ether2 ra-interval=3s-5s
/ipv6 nd prefix add prefix=none interface=ether2
/routing bgp instance add as=65100 name=inst1 router-id=10.0.0.100 vrf=main
/routing bgp connection add name=host afi=ip instance=inst1 local.role=ebgp local.address=ether2 remote.as=65110 output.default-originate=always
