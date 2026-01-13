# 2025-12-10 09:07:38 by RouterOS 7.20beta4
# software id = SF1Q-LGYJ
#
# model = CCR2116-12G-4S+
# serial number = HF609CW8B20
/interface bridge add name=bridge_local vlan-filtering=yes
/interface bridge add name=bridge_vlan vlan-filtering=yes
/interface ethernet set [ find default-name=ether11 ] disabled=yes
/interface vlan add interface=bridge_vlan name=vlan-p2p-bkk00 vlan-id=110
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK00-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus3 transmit-hash-policy=layer-2-and-3
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK60-LAG slaves=sfp-sfpplus2,sfp-sfpplus4 transmit-hash-policy=layer-2-and-3
/interface vlan add interface=BKK20-LAG name=vlan-400-to-bkk20 vlan-id=400
/interface vlan add interface=BKK20-LAG name=vlan-direct-bkk20 vlan-id=210
/interface list add name=WAN
/interface list add name=LAN
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/port set 0 name=serial0
/routing bgp template set default as=65530
/routing ospf instance add comment="OSPF instance for LocalGW" disabled=no name=ospf-instance-1 originate-default=never router-id=10.155.255.10
/routing ospf instance add comment="OSPFv3 instance for LocalGW" disabled=no name=ospf-instance-v3 originate-default=never router-id=10.155.255.10 version=3
/routing ospf area add disabled=no instance=ospf-instance-1 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/certificate settings set builtin-trust-anchors=not-trusted
/interface bridge port add bridge=bridge_vlan interface=BKK00-LAG
/interface bridge port add bridge=bridge_vlan interface=BKK60-LAG
/interface bridge port add bridge=bridge_vlan frame-types=admit-only-vlan-tagged interface=ether6
/interface bridge port add bridge=bridge_vlan frame-types=admit-only-vlan-tagged interface=ether7
/interface bridge port add bridge=bridge_vlan frame-types=admit-only-vlan-tagged interface=ether8
/interface bridge port add bridge=bridge_vlan disabled=yes frame-types=admit-only-vlan-tagged interface=BKK20-LAG
/interface bridge port add bridge=bridge_vlan interface=vlan-400-to-bkk20
/ipv6 settings set accept-router-advertisements=no
/interface bridge vlan
# BKK20-LAG not a bridge port
add bridge=bridge_vlan tagged=ether6,ether7,ether8,BKK00-LAG,BKK20-LAG,BKK60-LAG vlan-ids=400
/interface bridge vlan add bridge=bridge_vlan untagged=BKK00-LAG,BKK60-LAG,bridge_vlan vlan-ids=1
/interface bridge vlan add bridge=bridge_vlan tagged=BKK00-LAG,bridge_vlan vlan-ids=110
/interface bridge vlan add bridge=bridge_vlan tagged=bridge_vlan vlan-ids=210
/interface list member add interface=bridge_local list=LAN
/interface list member add interface=BKK00-LAG list=WAN
/interface list member add interface=BKK20-LAG list=WAN
/ip address add address=192.168.88.10/24 comment=defconf disabled=yes interface=ether13 network=192.168.88.0
/ip address add address=10.155.255.1 interface=lo network=10.155.255.1
/ip address add address=160.22.181.179 interface=lo network=160.22.181.179
/ip address add address=10.155.255.10 interface=lo network=10.155.255.10
/ip address add address=172.16.110.1/31 interface=vlan-p2p-bkk00 network=172.16.110.0
/ip address add address=172.16.210.1/31 interface=vlan-direct-bkk20 network=172.16.210.0
/ip dns set servers=9.9.9.9,1.0.0.1,8.8.4.4
/ip firewall nat add action=src-nat chain=srcnat out-interface-list=WAN src-address=172.16.0.0/16 to-addresses=160.22.181.179
/ip route add disabled=yes distance=220 gateway=172.16.210.0
/ip route add distance=220 gateway=172.16.110.0
/ip route add blackhole distance=240 dst-address=160.22.181.179
/ip route add blackhole comment=global_ipv4_resources distance=240 dst-address=160.22.180.0/23
/ip route add blackhole comment=global_anycast_v4 distance=240 dst-address=160.22.180.0/24
/ip route add blackhole comment=global_unicast_v4 distance=240 dst-address=160.22.181.0/24
/ipv6 route add distance=220 gateway=fd00:dead:beef:1020::1
/ipv6 route add distance=220 gateway=fd00:dead:beef:10::
/ipv6 route add blackhole distance=240 dst-address=2401:a860:1181::/48
/ipv6 route add blackhole comment=global_ipv6_resources distance=240 dst-address=2401:a860::/32
/ipv6 route add blackhole comment=global_anycast_ipv6 distance=240 dst-address=2401:a860::/36
/ipv6 route add blackhole comment=global_unicast_ipv6 distance=240 dst-address=2401:a860:1000::/36
/ip service set ftp address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ip service set ssh address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.104.169.64/32,160.22.181.181/32
/ip service set telnet address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
/ip service set www address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ip service set www-ssl address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
/ip service set winbox address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
/ip service set api address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ip service set api-ssl address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ipv6 address add address=fd00:dead:beef:10::1/127 advertise=no interface=BKK00-LAG
/ipv6 address add address=fd00:dead:beef::10/128 advertise=no interface=lo
/ipv6 address add address=2401:a860:1181:10::1/127 advertise=no interface=BKK00-LAG
/ipv6 address add address=fd00:dead:beef:2010::1/127 advertise=no interface=BKK20-LAG
/ipv6 address add address=2401:a860:1181:2010::1/127 advertise=no interface=BKK20-LAG
/ipv6 address add address=2401:a860:1181::10/128 advertise=no interface=lo
/routing ospf interface-template add area=backbone comment=loopback-v4 disabled=no networks=10.155.255.10/32 passive
/routing ospf interface-template add area=backbone comment=p2p-bkk00-v4 disabled=no networks=172.16.110.0/31
/routing ospf interface-template add area=backbone comment=p2p-bkk20-v4 disabled=no networks=172.16.210.0/31
/routing ospf interface-template add area=backbone comment=mgmt-subnet disabled=no networks=192.168.88.0/24 passive
/routing ospf interface-template add area=backbone comment=unicast-loopback disabled=no networks=160.22.181.179/32 passive
/routing ospf interface-template add area=backbone-v6 comment=loopback-v6 disabled=no networks=fd00:dead:beef::10/128 passive
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk00-v6 disabled=no interfaces=BKK00-LAG
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk20-v6 disabled=no interfaces=BKK20-LAG
/system identity set name=bkk10
/system routerboard settings set enter-setup-on=delete-key
