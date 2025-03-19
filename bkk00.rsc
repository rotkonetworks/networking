# 1970-05-25 19:54:47 by RouterOS 7.15.2
# software id = 61HF-9FEH
#
# model = CCR2216-1G-12XS-2XQ
# serial number = HH40ADXHPY7
/interface bridge add name=bridge_local
/interface bonding add lacp-rate=1sec mode=802.3ad name=edge-to-bkk20 slaves=qsfp28-1-1,qsfp28-2-1 transmit-hash-policy=layer-2-and-3
/port set 0 name=serial0
/routing bgp template set default address-families=ip as=142108 input.filter=iBGP-IN multihop=yes nexthop-choice=propagate output.filter-chain=iBGP-OUT .network=ipv4-apnic-rotko router-id=10.155.255.4 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 input.filter=iBGP-IN multihop=yes name=default_v6 nexthop-choice=propagate output.filter-chain=iBGP-OUT .network=ipv6-apnic-rotko .redistribute=connected router-id=10.155.255.4 use-bfd=no
/routing id add id=10.155.255.4 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add disabled=no name=ospf-instance-v2 originate-default=never router-id=10.155.255.4
/routing ospf instance add disabled=no name=ospf-instance-v3 originate-default=never router-id=10.155.255.4 version=3
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/ip address add address=192.168.88.1/24 comment=defconf interface=ether1 network=192.168.88.0
/ip address add address=172.16.30.1/30 interface=edge-to-bkk20 network=172.16.30.0
/ip address add address=160.22.181.180 interface=lo network=160.22.181.180
/ip address add address=10.155.255.4 interface=lo network=10.155.255.4
/ip firewall address-list add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ip route add distance=220 dst-address=0.0.0.0/0 gateway=edge-to-bkk20
/ip route add check-gateway=ping dst-address=0.0.0.0/0 gateway=172.16.30.2
/ip service set telnet address=10.0.0.0/8,192.168.0.0/16,172.16.0.0/12
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=10.0.0.0/8,95.217.216.149/32,2a01:4f9:c012:fbcd::/64,119.76.35.40/32,160.22.181.181/32,125.164.0.0/16,192.168.0.0/16,172.16.0.0/12,172.104.169.64/32,171.101.163.225/32,95.217.134.129/32,160.22.180.0/23
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/ipv6 address add address=fd00:dead:beef:30::1/126 advertise=no interface=edge-to-bkk20
/ipv6 address add address=2401:a860:181::4 interface=edge-to-bkk20
/ipv6 address add address=fd00:dead:beef::30/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::4/128 advertise=no interface=lo
/ipv6 address add address=2401:a860:181::30 interface=lo
/routing bgp connection add input.limit-process-routes-ipv4=2000000 local.address=10.155.255.4 .role=ibgp multihop=yes name=ROTKO-BKK00-TO-BKK20-v4 nexthop-choice=propagate output.keep-sent-attributes=yes .redistribute=connected,bgp remote.address=10.155.255.2 .as=142108 templates=default
/routing bgp connection add address-families=ipv6 as=142108 disabled=no input.filter=iBGP-IN .limit-process-routes-ipv6=2000000 local.address=fd00:dead:beef::4 .role=ibgp multihop=yes name=ROTKO-BKK00-TO-BKK20-v6 nexthop-choice=propagate output.filter-chain=iBGP-OUT .keep-sent-attributes=yes .redistribute=connected,bgp remote.address=fd00:dead:beef::2 .as=142108 router-id=10.155.255.4 templates=default_v6
/routing filter community-ext-list add comment=HGC-not-announce-142108 communities=rt:142108:65404 list=HGC
/routing filter community-large-list add comment="Thailand, Asia, Southeast Asia" communities=142108:1:764,142108:2:142,142108:2:35 list=location
/routing filter community-large-list add comment="Routes learned via iBGP BKK10" communities=142108:16:10 list=ibgp-communities
/routing filter community-large-list add comment="Routes learned via iBGP BKK20" communities=142108:16:20 list=ibgp-communities
/routing filter community-large-list add comment="Routes learned at HGC-SG1 BKK20" communities=142108:16:21 list=hgc-sg-communities
/routing filter community-large-list add comment="Routes learned at HGC-SG2 BKK10" communities=142108:16:11 list=hgc-th-sg-communities
/routing filter community-large-list add comment="Routes learned at HGC-HK1 BKK10" communities=142108:16:12 list=hgc-hk-communities
/routing filter community-large-list add comment="Routes learned at HGC-HK2 BKK20" communities=142108:16:22 list=hgc-th-hk-communities
/routing filter community-large-list add comment="Routes learned at BKNIX BKK10" communities=142108:16:13 list=bknix-communities
/routing filter community-large-list add comment="Routes learned at AMSIX BKK10" communities=142108:16:14 list=amsix-communities
/routing filter community-large-list add comment="Routes learned at AMSIX-BAN BKK20" communities=142108:16:25 list=amsix-ban-communities
/routing filter community-large-list add comment="Routes learned at AMSIX-HK BKK20" communities=142108:16:26 list=amsix-hk-communities
/routing filter community-list add comment=HGC-blackhole communities=9304:8 list=HGC
/routing filter community-list add comment=HGC-local-pref-360 communities=9304:381 list=HGC
/routing filter community-list add comment=HGC-local-pref-380 communities=9304:382 list=HGC
/routing filter community-list add communities=graceful-shutdown list=shutdown
/routing ospf interface-template add area=backbone comment=BKK00-LO disabled=no networks=10.155.255.4
/routing ospf interface-template add area=backbone comment=EDGE-BKK00-BKK20 disabled=no networks=172.16.30.0/30 use-bfd=no
/routing rpki add address=203.159.70.26 comment="Routinator IPv4 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=2001:deb:0:4070::26 comment="Routinator IPv6 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=203.159.70.36 comment="StayRTR IPv4 Secondary" group=rpki.bknix.net port=4323
/routing rpki add address=2001:deb:0:4070::36 comment="StayRTR IPv6 Secondary" group=rpki.bknix.net port=4323
/system identity set name=bkk00
/system note set show-at-login=no
/system routerboard settings set enter-setup-on=delete-key
