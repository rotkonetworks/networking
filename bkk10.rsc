# 2025-06-28 11:34:55 by RouterOS 7.20beta4
# software id = SF1Q-LGYJ
#
# model = CCR2116-12G-4S+
# serial number = HF609CW8B20
/interface bridge add name=bridge_local vlan-filtering=yes
/interface bridge add name=vrrp
/interface ethernet set [ find default-name=ether6 ] disabled=yes
/interface ethernet set [ find default-name=ether7 ] disabled=yes
/interface ethernet set [ find default-name=ether8 ] disabled=yes
/interface ethernet set [ find default-name=ether11 ] disabled=yes
/interface vrrp add disabled=yes interface=vrrp name=ibp priority=200 vrid=10
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK00-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus3 transmit-hash-policy=layer-2-and-3
/interface bonding add lacp-rate=1sec mode=802.3ad name=BKK60-LAG slaves=sfp-sfpplus2,sfp-sfpplus4 transmit-hash-policy=layer-2-and-3
/interface list add name=WAN
/interface list add name=LAN
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/port set 0 name=serial0
/routing bgp template set default as=65530
/routing ospf instance add comment="OSPF instance for LocalGW" disabled=no name=ospf-instance-1 originate-default=never router-id=10.155.255.10
/routing ospf instance add comment="OSPFv3 instance for LocalGW" disabled=no name=ospf-instance-v3 originate-default=never router-id=10.155.255.10 version=3
/routing ospf area add disabled=no instance=ospf-instance-1 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/ipv6 settings set accept-router-advertisements=no
/interface list member add interface=bridge_local list=LAN
/interface list member add interface=BKK00-LAG list=WAN
/interface list member add interface=BKK20-LAG list=WAN
/ip address add address=192.168.88.10/24 comment=defconf disabled=yes interface=ether13 network=192.168.88.0
/ip address add address=172.16.210.1/31 interface=BKK20-LAG network=172.16.210.0
/ip address add address=172.16.110.1/31 interface=BKK00-LAG network=172.16.110.0
/ip address add address=10.155.255.1 interface=lo network=10.155.255.1
/ip address add address=160.22.181.179 interface=lo network=160.22.181.179
/ip address add address=160.22.181.181 disabled=yes interface=vrrp network=160.22.181.181
/ip dns set servers=9.9.9.9,1.0.0.1,8.8.4.4
/ip firewall nat add action=src-nat chain=srcnat out-interface-list=!LAN src-address=172.16.0.0/16 to-addresses=160.22.181.179
/ip route add distance=220 gateway=172.16.210.0
/ip route add distance=220 gateway=172.16.110.0
/ip route add blackhole distance=240 dst-address=160.22.181.179
/ipv6 route add distance=220 gateway=fd00:dead:beef:1020::1
/ipv6 route add distance=220 gateway=fd00:dead:beef:10::
/ipv6 route add blackhole distance=240 dst-address=2401:a860:1181::/48
/ip service set ftp address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
/ip service set ssh address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.104.169.64/32,158.140.0.0/16
/ip service set telnet address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 disabled=yes
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
/routing ospf interface-template add area=backbone comment=loopback-v4 disabled=no networks=10.155.255.10/32 passive
/routing ospf interface-template add area=backbone-v6 comment=loopback-v6 disabled=no networks=fd00:dead:beef::10/128 passive
/routing ospf interface-template add area=backbone comment=p2p-bkk00-v4 disabled=no networks=172.16.110.0/31
/routing ospf interface-template add area=backbone comment=p2p-bkk20-v4 disabled=no networks=172.16.210.1/31
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk00-v6-lua disabled=no networks=2401:a860:1181:10::1/127
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk00-v6-gua disabled=no networks=fd00:dead:beef:10::1/127
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk20-v6-lua disabled=no networks=fd00:dead:beef:2010::/127
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk20-v6-gua disabled=no networks=2401:a860:1181:2010::/127
/routing ospf interface-template add area=backbone comment=ibp-v4 disabled=no networks=160.22.181.176/28 passive
/routing ospf interface-template add area=backbone comment=sax-v4 disabled=no networks=160.22.181.169/29 passive
/routing ospf interface-template add area=backbone comment=rotko-infra-v4 disabled=no networks=160.22.181.0/26 passive
/routing ospf interface-template add area=backbone-v6 comment=rotko-anycast-v6 disabled=no networks=2401:a860::/48 passive
/routing ospf interface-template add area=backbone-v6 comment=ibp-unicast-v6 disabled=no networks=2401:a860:1181::/48 passive
/routing ospf interface-template add area=backbone comment=rotko-unicast-v4 disabled=no networks=160.22.181.0/24 passive
/routing ospf interface-template add area=backbone comment=rotko-anycast-v4 disabled=no networks=160.22.180.0/24 passive
/system identity set name=bkk10
/system package update set channel=testing
/system routerboard settings set enter-setup-on=delete-key
