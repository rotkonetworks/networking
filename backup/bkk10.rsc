# 2025-07-04 05:17:53 by RouterOS 7.20beta4
# software id = SF1Q-LGYJ
#
# model = CCR2116-12G-4S+
# serial number = HF609CW8B20
/interface bridge
add name=bridge-vlan vlan-filtering=yes
add name=bridge_local vlan-filtering=yes
add name=vrrp
/interface ethernet
set [ find default-name=ether8 ] comment=BKK08-ENO1
set [ find default-name=ether11 ] disabled=yes
/interface vrrp
add disabled=yes interface=vrrp name=ibp priority=200 vrid=10
/interface vlan
add interface=bridge-vlan name=vlan300 vlan-id=300
add interface=bridge-vlan name=vlan400-bgp vlan-id=400
/interface bonding
add lacp-rate=1sec mode=802.3ad name=BKK00-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
add lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus3 transmit-hash-policy=layer-2-and-3
add lacp-rate=1sec mode=802.3ad name=BKK60-LAG slaves=sfp-sfpplus2,sfp-sfpplus4 transmit-hash-policy=\
    layer-2-and-3
/interface list
add name=WAN
add name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/port
set 0 name=serial0
/routing bgp template
set default as=65530
/routing ospf instance
add comment="OSPF instance for LocalGW" disabled=no name=ospf-instance-1 originate-default=never router-id=\
    10.155.255.10
add comment="OSPFv3 instance for LocalGW" disabled=no name=ospf-instance-v3 originate-default=never router-id=\
    10.155.255.10 version=3
/routing ospf area
add disabled=no instance=ospf-instance-1 name=backbone
add disabled=no instance=ospf-instance-v3 name=backbone-v6
/interface bridge port
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=ether6
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=ether7
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=BKK00-LAG
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=BKK20-LAG
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=BKK60-LAG
add bridge=bridge-vlan frame-types=admit-only-vlan-tagged interface=ether8
/ipv6 settings
set accept-router-advertisements=no
/interface bridge vlan
add bridge=bridge-vlan tagged=BKK00-LAG,BKK20-LAG,BKK60-LAG,ether6,ether7,ether8 vlan-ids=400
add bridge=bridge-vlan tagged=BKK20-LAG,BKK00-LAG vlan-ids=300
/interface list member
add interface=bridge_local list=LAN
add interface=BKK00-LAG list=WAN
add interface=BKK20-LAG list=WAN
/ip address
add address=192.168.88.10/24 comment=defconf disabled=yes interface=ether13 network=192.168.88.0
add address=172.16.210.1/31 disabled=yes interface=BKK20-LAG network=172.16.210.0
add address=172.16.110.1/31 disabled=yes interface=BKK00-LAG network=172.16.110.0
add address=10.155.255.1 interface=lo network=10.155.255.1
add address=160.22.181.179 interface=lo network=160.22.181.179
add address=160.22.181.181 disabled=yes interface=vrrp network=160.22.181.181
add address=10.155.254.10/24 comment="BGP RR VLAN" interface=vlan400-bgp network=10.155.254.0
add address=172.16.110.1/31 interface=vlan300 network=172.16.110.0
/ip dns
set servers=9.9.9.9,1.0.0.1,8.8.4.4
/ip firewall nat
add action=src-nat chain=srcnat out-interface-list=!LAN src-address=172.16.0.0/16 to-addresses=160.22.181.179
/ip route
add distance=220 gateway=172.16.210.0
add distance=220 gateway=172.16.110.0
add blackhole distance=240 dst-address=160.22.181.179
/ipv6 route
add distance=220 gateway=fd00:dead:beef:1020::1
add distance=220 gateway=fd00:dead:beef:10::
add blackhole distance=240 dst-address=2401:a860:1181::/48
/ip service
set ftp address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
set ssh address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.104.169.64/32,158.140.0.0/16
set telnet address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
set www address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
set www-ssl address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
set winbox address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
set api address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
set api-ssl address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ipv6 address
add address=fd00:dead:beef:10::1/127 advertise=no interface=vlan300
add address=fd00:dead:beef::10/128 advertise=no interface=lo
add address=2401:a860:1181:10::1/127 advertise=no interface=vlan300
add address=fd00:dead:beef:2010::1/127 advertise=no disabled=yes interface=BKK20-LAG
add address=2401:a860:1181:2010::1/127 advertise=no disabled=yes interface=BKK20-LAG
add address=fd00:155:254::10 interface=vlan400-bgp
/routing ospf interface-template
add area=backbone comment=loopback-v4 disabled=no networks=10.155.255.10/32 passive
add area=backbone-v6 comment=loopback-v6 disabled=no networks=fd00:dead:beef::10/128 passive
add area=backbone comment=p2p-bkk00-v4 disabled=no networks=172.16.110.0/31
add area=backbone comment=p2p-bkk20-v4 disabled=no networks=172.16.210.1/31
add area=backbone-v6 comment=p2p-bkk00-v6-lua disabled=no networks=2401:a860:1181:10::/127
add area=backbone-v6 comment=p2p-bkk00-v6-gua disabled=no networks=fd00:dead:beef:10::/127
add area=backbone-v6 comment=p2p-bkk20-v6-lua disabled=no networks=fd00:dead:beef:2010::/127
add area=backbone-v6 comment=p2p-bkk20-v6-gua disabled=no networks=2401:a860:1181:2010::/127
add area=backbone comment=ibp-v4 disabled=no networks=160.22.181.176/28 passive
add area=backbone comment=sax-v4 disabled=no networks=160.22.181.169/29 passive
add area=backbone comment=rotko-infra-v4 disabled=no networks=160.22.181.0/26 passive
add area=backbone-v6 comment=rotko-anycast-v6 disabled=no networks=2401:a860::/48 passive
add area=backbone-v6 comment=ibp-unicast-v6 disabled=no networks=2401:a860:1181::/48 passive
add area=backbone comment=rotko-unicast-v4 disabled=no networks=160.22.181.0/24 passive
add area=backbone comment=rotko-anycast-v4 disabled=no networks=160.22.180.0/24 passive
/system clock
set time-zone-name=America/Chicago
/system identity
set name=bkk10
/system package update
set channel=testing
/system routerboard settings
set enter-setup-on=delete-key
