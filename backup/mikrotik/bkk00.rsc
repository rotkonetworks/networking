# 2026-01-04 14:12:34 by RouterOS 7.19.4
# software id = 61HF-9FEH
#
# model = CCR2216-1G-12XS-2XQ
# serial number = HH40ADXHPY7
/interface bridge add name=bridge_vlan vlan-filtering=yes
/interface ethernet set [ find default-name=ether1 ] comment=mgmt
/interface ethernet set [ find default-name=qsfp28-1-1 ] comment=EDGE-BKK20-LAG
/interface ethernet set [ find default-name=qsfp28-2-1 ] comment=EDGE-BKK20-LAG
/interface ethernet set [ find default-name=sfp28-2 ] advertise=10G-baseSR-LR comment="HGC-HK-MMR-A-XXX ORIGINAL-MAC=F4:1E:57:4B:D7:1D" mac-address=78:9A:18:80:E2:E4
/interface ethernet set [ find default-name=sfp28-4 ] advertise=10G-baseSR-LR comment="BKNIX-core7,8-MMRB ORIGINAL-MAC-F4:1E:57:4B:D7:1F" mac-address=78:9A:18:80:E2:E6
/interface ethernet set [ find default-name=sfp28-5 ] advertise=10G-baseCR comment=BKK10-LAG
/interface ethernet set [ find default-name=sfp28-11 ] advertise=10G-baseCR comment=BKK50-LAG
/interface wireguard add listen-port=51820 mtu=1420 name=wg_rotko
/interface vlan add interface=bridge_vlan name=vlan-400 vlan-id=400
/interface bonding add comment=WAN mode=802.3ad mtu=1514 name=AMSIX-LAG slaves=sfp28-2 transmit-hash-policy=layer-3-and-4
/interface bonding add comment=bkk10-sfp28-5 lacp-rate=1sec mode=802.3ad name=BKK10-LAG slaves=sfp28-5 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=100G-EDGE-TO-BKK20 lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=qsfp28-1-1 transmit-hash-policy=layer-2-and-3
/interface bonding add mode=802.3ad name=BKK30-LAG slaves=qsfp28-2-1
/interface bonding add comment=bkk50-sfp28-11 lacp-rate=1sec mode=802.3ad name=BKK50-LAG slaves=sfp28-11 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=WAN mode=802.3ad mtu=1514 name=BKNIX-LAG slaves=sfp28-4 transmit-hash-policy=layer-3-and-4
/interface vlan add interface=AMSIX-LAG name=EU-AMS-IX-vlan3995 vlan-id=3995
/interface vlan add interface=AMSIX-LAG name=HK-HGC-IPTx-vlan2519 vlan-id=2519
/interface vlan add interface=AMSIX-LAG name=SG-HGC-IPTx-backup-vlan2518 vlan-id=2518
/interface vlan add interface=vlan-400 name=qnq-400-100 vlan-id=100
/interface vlan add interface=vlan-400 name=qnq-400-106 vlan-id=106
/interface vlan add interface=vlan-400 name=qnq-400-107 vlan-id=107
/interface vlan add disabled=yes interface=vlan-400 name=qnq-400-108 vlan-id=108
/interface vlan add interface=vlan-400 name=qnq-400-116 vlan-id=116
/interface vlan add interface=vlan-400 name=qnq-400-117 vlan-id=117
/interface vlan add interface=vlan-400 name=qnq-400-118 vlan-id=118
/interface vlan add interface=vlan-400 name=qnq-400-200 vlan-id=200
/interface bonding add mode=active-backup name=BKK06-LAG slaves=qnq-400-106,qnq-400-116
/interface bonding add mode=active-backup name=BKK07-LAG slaves=qnq-400-107,qnq-400-117
/interface bonding add mode=active-backup name=BKK08-LAG slaves=qnq-400-108,qnq-400-118
/interface list add name=LAN
/interface list add name=WAN
/ip pool add name=dhcp_pool ranges=192.168.69.50-192.168.69.70
/ip smb users set [ find default=yes ] disabled=yes
/port set 0 name=serial0
/routing bgp template set default as=142108 router-id=10.155.255.4
/routing id add id=10.155.255.4 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add disabled=no name=ospf-instance-v2 originate-default=always router-id=10.155.255.4
/routing ospf instance add disabled=no name=ospf-instance-v3 originate-default=always router-id=10.155.255.4 version=3
/routing ospf instance add disabled=no name=default redistribute=connected router-id=10.155.255.4
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/routing table add fib name=rt_latency
/routing bgp template add afi=ipv6 as=142108 input.filter=iBGP-IN-v6 multihop=yes name=IBGP-ROTKO-v6 nexthop-choice=force-self output.filter-chain=iBGP-OUT-v6 .network=ipv6-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=BKNIX-IN-v4 name=BKNIX-v4 nexthop-choice=default output.as-override=no .filter-chain=BKNIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=BKNIX-IN-v6 name=BKNIX-v6 nexthop-choice=default output.as-override=no .filter-chain=BKNIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=HGC-HK-IN-v4 multihop=yes name=IPTX-HGC-HK-v4 nexthop-choice=default output.as-override=no .filter-chain=HGC-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=HGC-HK-IN-v6 multihop=yes name=IPTX-HGC-HK-v6 nexthop-choice=default output.as-override=no .filter-chain=HGC-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=AMSIX-IN-v4 name=AMSIX-v4 nexthop-choice=default output.as-override=no .filter-chain=AMSIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=AMSIX-IN-v6 name=AMSIX-v6 nexthop-choice=default output.as-override=no .filter-chain=AMSIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=HGC-SG-IN-v6 multihop=yes name=HGC-TH-SG-v6 nexthop-choice=default output.as-override=no .filter-chain=HGC-SG-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=HGC-SG-IN-v4 multihop=yes name=HGC-TH-SG-v4 nexthop-choice=default output.as-override=no .filter-chain=HGC-SG-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.4 routing-table=main
/routing bgp template add add-path-out=all afi=ip as=142108 input.filter=RR-CLIENT-IN-v4 name=RR-CLIENTS-v4 nexthop-choice=propagate output.filter-chain=RR-CLIENT-OUT-v4 .network=ipv4-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ipv6 as=142108 input.filter=RR-CLIENT-IN-v6 name=RR-CLIENTS-v6 nexthop-choice=default output.filter-chain=RR-CLIENT-OUT-v6 .network=ipv6-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.4 routing-table=main
/routing bgp template add afi=ip as=142108 input.filter=iBGP-IN-v4 multihop=yes name=IBGP-ROTKO-v4 nexthop-choice=force-self output.filter-chain=iBGP-OUT-v4 .network=ipv4-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.4 routing-table=main
/user group add name=mktxp_group policy=ssh,read,winbox,api,!local,!telnet,!ftp,!reboot,!write,!policy,!test,!password,!web,!sniff,!sensitive,!romon,!rest-api
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=vlan out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface-list=WAN
/interface bridge filter add action=drop chain=forward comment="Block inbound RA/NS/NA multicasts from WAN" dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward comment="RA-Guard & NDP-Guard for WANLAN" dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward comment="RA-Guard  block external RAs" dst-mac-address=33:33:00:00:00:01/FF:FF:FF:FF:FF:FF in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=vlan out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface-list=WAN
/interface bridge filter add action=drop chain=forward comment="Block inbound RA/NS/NA multicasts from WAN" dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward comment="RA-Guard & NDP-Guard for WANLAN" dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward comment="RA-Guard  block external RAs" dst-mac-address=33:33:00:00:00:01/FF:FF:FF:FF:FF:FF in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward out-interface-list=WAN
/interface bridge port add bridge=bridge_vlan interface=BKK10-LAG
/interface bridge port add bridge=bridge_vlan frame-types=admit-only-vlan-tagged interface=BKK30-LAG
/interface ethernet switch l3hw-settings
# ipv6 neighbor configuration has changed, please restart the device in order to apply the new settings
set autorestart=yes ipv6-hw=yes
/ip firewall connection tracking
# ipv6 neighbor configuration has changed, please restart the device in order to apply the new settings
set enabled=no loose-tcp-tracking=no udp-timeout=10s
/ip neighbor discovery-settings
# ipv6 neighbor configuration has changed, please restart the device in order to apply the new settings
set discover-interval=1m mode=rx-only
/ip settings
# ipv6 neighbor configuration has changed, please restart the device in order to apply the new settings
set secure-redirects=no send-redirects=no tcp-syncookies=yes
/ipv6 settings
# ipv6 neighbor configuration has changed, please restart the device in order to apply the new settings
set accept-redirects=no accept-router-advertisements=no max-neighbor-entries=8192 soft-max-neighbor-entries=8191
/interface bridge vlan add bridge=bridge_vlan tagged=BKK30-LAG,BKK10-LAG vlan-ids=400
/interface bridge vlan add bridge=bridge_vlan untagged=bridge_vlan,BKK10-LAG vlan-ids=1
/interface ethernet switch set 0 l3-hw-offloading=yes qos-hw-offloading=yes
/interface list member add interface=ether1 list=LAN
/interface list member add interface=BKK10-LAG list=LAN
/interface list member add interface=BKK50-LAG list=LAN
/interface list member add interface=wg_rotko list=LAN
/interface list member add interface=AMSIX-LAG list=WAN
/interface list member add interface=BKNIX-LAG list=WAN
/interface list member add interface=HK-HGC-IPTx-vlan2519 list=WAN
/interface list member add interface=EU-AMS-IX-vlan3995 list=WAN
/interface list member add interface=SG-HGC-IPTx-backup-vlan2518 list=WAN
/interface list member add interface=sfp28-2 list=WAN
/interface list member add interface=sfp28-4 list=WAN
/interface list member add interface=BKK20-LAG list=LAN
/interface list member add interface=qsfp28-1-1 list=LAN
/interface list member add interface=qsfp28-2-1 list=LAN
/interface list member add interface=vlan-400 list=LAN
/interface list member add interface=qnq-400-106 list=LAN
/interface list member add interface=qnq-400-107 list=LAN
/interface list member add interface=qnq-400-108 list=LAN
/interface wireguard peers add allowed-address=172.31.0.1/32 interface=wg_rotko name=laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.20/32 interface=wg_rotko name=bkk20 public-key="/09ofEbIM1qjlq7xM/R0KfJMQ8R/UR9aHaph70FTp30="
/interface wireguard peers add allowed-address=172.31.0.2/32 interface=wg_rotko name=gatus public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.31.0.50/32 endpoint-address=172.16.10.2 endpoint-port=51820 interface=wg_rotko name=bkk50 public-key="HSEVRjXj7x7jSVy8A9YQducW6BNme/a19/o5CA/KrUI="
/interface wireguard peers add allowed-address=172.31.0.4/32 interface=wg_rotko name=bgpctl public-key="Vy/FwO7pVn27ZwA1HnllqcIGBLPHh426JtfBlQopfgY="
/interface wireguard peers add allowed-address=172.31.0.6/32 interface=wg_rotko name=bkk06 public-key="kVfcladp4l87PsMtzLmfgBU4aumgQDC/dKOfa8NSbxk="
/interface wireguard peers add allowed-address=172.31.0.7/32 interface=wg_rotko name=bkk07 public-key="4CGbVHKfkhiyga53lFaydcweOe0vgozADvXdJApyEiM="
/interface wireguard peers add allowed-address=172.31.0.8/32 interface=wg_rotko name=bkk08 public-key="HWIsnsm+CY6ul6kX1+llsUT1JZ5IdzxOunjIAhoTvkk="
/interface wireguard peers add allowed-address=172.31.0.3/32 interface=wg_rotko name=bkk03 public-key="sigpCqPiAg6Ro1deiaGWQg+Zk3iHx18UInq7jyBVuWY="
/interface wireguard peers add allowed-address=172.31.0.9/32 comment=bkk09 interface=wg_rotko name=peer12 public-key="ohFfKug5RQ07GGOjOwxeJR17c3NVBaLFXlEf6Tiizhs="
/interface wireguard peers add allowed-address=172.31.0.11/32 comment=bkk11-validator interface=wg_rotko name=peer13 public-key="OF8k2YrVl1Rg42MvhhJAFgkG3fmWlji5eZadWuLdZUc="
/interface wireguard peers add allowed-address=172.31.0.12/32 comment=bkk12-validator interface=wg_rotko name=peer14 public-key="Lkd/T8OD+udQnOzRYVPCg7/44H8s+wGDBGOscy6HoB4="
/interface wireguard peers add allowed-address=172.31.0.13/32 comment=bkk13-validator interface=wg_rotko name=peer15 public-key="tTVnDs307swj3aV1CbM/a18epWCooPKDLwa/Aa9W4xM="
/ip address add address=192.168.88.100/24 comment=defconf interface=ether1 network=192.168.88.0
/ip address add address=172.16.30.1/30 interface=BKK20-LAG network=172.16.30.0
/ip address add address=160.22.181.180 interface=lo network=160.22.181.180
/ip address add address=10.155.255.4 interface=lo network=10.155.255.4
/ip address add address=203.159.68.168/23 comment=BKNIX-V4 interface=BKNIX-LAG network=203.159.68.0
/ip address add address=118.143.211.186/29 interface=HK-HGC-IPTx-vlan2519 network=118.143.211.184
/ip address add address=10.25.1.126/24 interface=EU-AMS-IX-vlan3995 network=10.25.1.0
/ip address add address=80.249.212.139/21 interface=EU-AMS-IX-vlan3995 network=80.249.208.0
/ip address add address=103.168.174.182/30 interface=SG-HGC-IPTx-backup-vlan2518 network=103.168.174.180
/ip address add address=172.16.10.1/30 interface=BKK50-LAG network=172.16.10.0
/ip address add address=172.31.0.100/16 interface=wg_rotko network=172.31.0.0
/ip address add address=172.16.50.0/31 interface=BKK50-LAG network=172.16.50.0
/ip address add address=10.155.254.100/24 comment="BGP RR VLAN" interface=vlan-400 network=10.155.254.0
/ip address add address=10.155.254.100 interface=lo network=10.155.254.100
/ip address add address=172.16.110.0/31 interface=BKK10-LAG network=172.16.110.0
/ip address add address=10.155.100.1/16 interface=qnq-400-100 network=10.155.0.0
/ip address add address=10.155.100.1/24 interface=qnq-400-100 network=10.155.100.0
/ip address add address=10.155.106.0/31 interface=BKK06-LAG network=10.155.106.0
/ip address add address=10.155.107.0/31 interface=BKK07-LAG network=10.155.107.0
/ip address add address=10.155.108.0/31 interface=BKK08-LAG network=10.155.108.0
/ip dns set allow-remote-requests=yes cache-max-ttl=1d cache-size=4096KiB max-concurrent-queries=50 max-concurrent-tcp-sessions=10 max-udp-packet-size=512 servers=8.8.8.8,9.9.9.9,1.1.1.1
/ip dns static add address=159.148.147.251 disabled=yes name=download.mikrotik.com type=A
/ip dns static add address=159.148.147.251 disabled=yes name=upgrade.mikrotik.com type=A
/ip firewall address-list add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ip firewall address-list add address=10.0.0.0/8 list=internal-ipv4
/ip firewall address-list add address=192.168.88.0/24 list=mgmt-ipv4
/ip firewall address-list add address=160.22.180.0/24 list=ibp-anycast-ipv4
/ip firewall address-list add address=160.22.181.0/24 list=rotko-unicast-ipv4
/ip firewall address-list add address=203.159.68.0/23 list=bknix-ipv4
/ip firewall address-list add address=203.159.68.168 list=bknix-rotko-address
/ip firewall address-list add address=118.143.211.184/29 list=HK-HGC-vlan2519
/ip firewall address-list add address=118.143.234.72/29 list=HK-SG-vlan2520
/ip firewall address-list add address=0.0.0.0/8 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=172.16.0.0/12 comment=RFC6890 disabled=yes list=not_in_internet
/ip firewall address-list add address=192.168.0.0/16 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=10.0.0.0/8 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=169.254.0.0/16 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=127.0.0.0/8 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=224.0.0.0/4 comment=Multicast list=not_in_internet
/ip firewall address-list add address=198.18.0.0/15 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=192.0.0.0/24 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=192.0.2.0/24 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=198.51.100.0/24 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=203.0.113.0/24 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=100.64.0.0/10 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=240.0.0.0/4 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=192.88.99.0/24 comment="6to4 relay Anycast [RFC 3068]" list=not_in_internet
/ip firewall address-list add address=255.255.255.255 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=127.0.0.0/8 comment="RAW Filtering - RFC6890" list=bad_ipv4
/ip firewall address-list add address=192.0.0.0/24 comment="RAW Filtering - RFC6890" list=bad_ipv4
/ip firewall address-list add address=192.0.2.0/24 comment="RAW Filtering - RFC6890 documentation" list=bad_ipv4
/ip firewall address-list add address=198.51.100.0/24 comment="RAW Filtering - RFC6890 documentation" list=bad_ipv4
/ip firewall address-list add address=203.0.113.0/24 comment="RAW Filtering - RFC6890 documentation" list=bad_ipv4
/ip firewall address-list add address=240.0.0.0/4 comment="RAW Filtering - RFC6890 reserved" list=bad_ipv4
/ip firewall address-list add address=224.0.0.0/4 comment="RAW Filtering - multicast" list=bad_src_ipv4
/ip firewall address-list add address=255.255.255.255 comment="RAW Filtering - RFC6890" list=bad_src_ipv4
/ip firewall address-list add address=0.0.0.0/8 comment="RAW Filtering - RFC6890" list=bad_dst_ipv4
/ip firewall address-list add address=224.0.0.0/4 comment="RAW Filtering - multicast" list=bad_dst_ipv4
/ip firewall address-list add address=0.0.0.0/8 comment="RFC 1122: This host on this network" list=ipv4-bogons
/ip firewall address-list add address=10.0.0.0/8 comment="RFC 1918: Private network" list=ipv4-bogons
/ip firewall address-list add address=100.64.0.0/10 comment="RFC 6598: Shared address space" list=ipv4-bogons
/ip firewall address-list add address=127.0.0.0/8 comment="RFC 1122: Loopback" list=ipv4-bogons
/ip firewall address-list add address=169.254.0.0/16 comment="RFC 3927: Link-local" list=ipv4-bogons
/ip firewall address-list add address=172.16.0.0/12 comment="RFC 1918: Private network" list=ipv4-bogons
/ip firewall address-list add address=192.0.0.0/24 comment="RFC 6890: Reserved by IETF" list=ipv4-bogons
/ip firewall address-list add address=192.0.2.0/24 comment="RFC 5737: Documentation" list=ipv4-bogons
/ip firewall address-list add address=192.168.0.0/16 comment="RFC 1918: Private network" list=ipv4-bogons
/ip firewall address-list add address=198.51.100.0/24 comment="RFC 5737: Documentation" list=ipv4-bogons
/ip firewall address-list add address=203.0.113.0/24 comment="RFC 5737: Documentation" list=ipv4-bogons
/ip firewall address-list add address=224.0.0.0/4 comment="RFC 1112: Multicast" list=ipv4-bogons
/ip firewall address-list add address=240.0.0.0/4 comment="RFC 1112: Reserved for future use" list=ipv4-bogons
/ip firewall address-list add address=80.249.212.139 list=bgp-loopback-ips
/ip firewall address-list add address=203.159.68.168 list=bgp-loopback-ips
/ip firewall address-list add address=118.143.211.186 list=bgp-loopback-ips
/ip firewall address-list add address=10.155.255.4 list=bgp-loopback-ips
/ip firewall address-list add address=80.249.208.0/21 comment="AMS-IX IXP Range" list=bgp-peers
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX IXP Range" list=bgp-peers
/ip firewall address-list add address=118.143.211.184/29 comment="HGC IXP Range" list=bgp-peers
/ip firewall address-list add address=10.25.1.0/24 comment="EU-AMS-IX IXP Range" list=bgp-peers
/ip firewall address-list add address=172.16.30.0/30 comment="BKK20 IXP Range" list=bgp-peers
/ip firewall address-list add address=172.16.50.0/30 comment="BKK50 IXP Range" list=bgp-peers
/ip firewall address-list add address=172.16.40.0/30 comment="BKK10 IXP Range" list=bgp-peers
/ip firewall address-list add address=10.155.255.0/24 list=ROTKO-LOCAL-v4
/ip firewall address-list add address=0.0.0.0/0 list=all-addresses
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA block" list=our-networks
/ip firewall address-list add address=10.0.0.0/8 list=mgmt-ipv4
/ip firewall address-list add address=10.0.0.0/8 list=lan_subnets
/ip firewall address-list add address=192.168.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.31.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.16.0.0/16 list=lan_subnets
/ip firewall address-list add address=10.155.255.2 comment="BKK20 Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.100.140.31 comment="AMSIX BKK Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.247.139.76 comment="AMSIX HK Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=118.143.234.74 comment="HGC SG Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.168.174.178 comment="HGC HK Backup Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=118.143.234.72/29 comment="HGC SG Range" list=bgp-peers
/ip firewall address-list add address=103.100.140.0/24 comment="BKK AMS-IX Range" list=bgp-peers
/ip firewall address-list add address=103.247.139.0/24 comment="HK AMS-IX Range" list=bgp-peers
/ip firewall address-list add address=103.168.174.176/29 comment="HK Backup Range" list=bgp-peers
/ip firewall address-list add address=172.16.20.0/30 comment="BKK50 Link Range" list=bgp-peers
/ip firewall address-list add address=172.16.10.0/30 comment="BKK10 Link Range" list=bgp-peers
/ip firewall address-list add address=10.0.0.0/8 list=dns-clients
/ip firewall address-list add address=172.16.0.0/12 list=dns-clients
/ip firewall address-list add address=192.168.0.0/16 list=dns-clients
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX peering LAN" list=ix-peering-lans
/ip firewall address-list add address=103.100.140.0/24 comment="BKK AMS-IX peering LAN" list=ix-peering-lans
/ip firewall address-list add address=103.247.139.0/24 comment="HK AMS-IX peering LAN" list=ix-peering-lans
/ip firewall address-list add address=80.249.208.0/21 comment="EU AMS-IX peering LAN" list=ix-peering-lans
/ip firewall address-list add address=160.22.181.0/24 list=our-networks
/ip firewall address-list add address=160.22.180.0/24 list=our-networks
/ip firewall address-list add address=172.16.0.0/16 list=dns-clients
/ip firewall address-list add address=10.155.206.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=10.155.207.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=10.155.208.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=160.22.181.176/28 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.168/29 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.181 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.20 list=bkk50-rotko-ranges
/ip firewall mangle add action=fasttrack-connection chain=prerouting disabled=yes
/ip firewall mangle add action=fasttrack-connection chain=output disabled=yes
/ip firewall mangle add action=fasttrack-connection chain=prerouting disabled=yes
/ip firewall mangle add action=fasttrack-connection chain=output disabled=yes
/ip firewall nat add action=dst-nat chain=dstnat comment=temp-bkk13-ipmi dst-address=160.22.181.183 dst-port=8443 protocol=tcp to-addresses=192.168.69.216 to-ports=443
/ip firewall raw add action=drop chain=prerouting comment=SNMP-DANGER dst-port=161,162 in-interface-list=WAN protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass all" port=53 protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass all" port=53 protocol=tcp
/ip firewall raw add action=drop chain=prerouting comment=BCP214-BGP-MAINTENANCE-MODE-AMSIX disabled=yes dst-address=80.249.208.0/21 port=179 protocol=tcp src-address=80.249.208.0/21
/ip firewall raw add action=drop chain=prerouting comment=BCP214-BGP-MAINTENANCE-MODE-BKNIX disabled=yes dst-address=203.159.68.0/23 port=179 protocol=tcp src-address=203.159.68.0/23
/ip firewall raw add action=accept chain=prerouting in-interface-list=!WAN protocol=ospf
/ip firewall raw add action=drop chain=prerouting comment="Drop spoofed our networks from WAN" in-interface-list=WAN src-address-list=our-networks
/ip firewall raw add action=accept chain=prerouting comment=TRANSPARENT disabled=yes
/ip firewall raw add action=drop chain=prerouting comment="Drop bad TCP flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ip firewall raw add action=drop chain=prerouting comment="Drop TCP flag combinations: fin,syn" protocol=tcp tcp-flags=fin,syn
/ip firewall raw add action=drop chain=prerouting comment="Drop TCP flag combinations: fin,rst" protocol=tcp tcp-flags=fin,rst
/ip firewall raw add action=drop chain=prerouting comment="Drop TCP flag combinations: syn,rst" protocol=tcp tcp-flags=syn,rst
/ip firewall raw add action=drop chain=prerouting comment="iSAV: Drop our IPv4 prefixes from WAN" in-interface-list=WAN src-address-list=our-networks
/ip firewall raw add action=drop chain=prerouting comment="lock down open resolver  UDP 53" disabled=yes dst-address-list=rotko-unicast-ipv4 dst-port=53 protocol=udp src-address-list=!dns-clients
/ip firewall raw add action=drop chain=prerouting comment="lock down open resolver  TCP 53" disabled=yes dst-address-list=rotko-unicast-ipv4 dst-port=53 protocol=tcp src-address-list=!dns-clients
/ip firewall raw add action=accept chain=prerouting comment="Allow RPKI traffic" dst-address=203.159.70.0/23 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="Allow OSPF protocol" in-interface-list=!WAN protocol=ospf
/ip firewall raw add action=accept chain=prerouting comment="Allow internal router links" src-address=172.16.0.0/16
/ip firewall raw add action=accept chain=prerouting comment="Allow internal router links" dst-address=172.16.0.0/16
/ip firewall raw add action=accept chain=prerouting comment=wg_rotko src-address=172.31.0.0/16
/ip firewall raw add action=accept chain=prerouting comment="mikrotik monitoring" dst-address=160.22.181.181 dst-port=8728 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="Allow loopback traffic" src-address=127.0.0.0/8
/ip firewall raw add action=accept chain=prerouting comment="Allow loopback traffic" dst-address=127.0.0.0/8
/ip firewall raw add action=accept chain=prerouting comment="Allow BGP loopback traffic SOURCE" src-address-list=bgp-loopback-ips
/ip firewall raw add action=accept chain=prerouting comment="Allow BGP loopback traffic DEST" dst-address-list=bgp-loopback-ips
/ip firewall raw add action=drop chain=prerouting comment="Drop bad src IPs" src-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad dst IPs" dst-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad src IPs" src-address-list=bad_src_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad dst IPs" dst-address-list=bad_dst_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop non-global from WAN" in-interface-list=WAN src-address-list=not_in_internet
/ip firewall raw add action=drop chain=prerouting comment="Drop local if not from LAN" disabled=yes in-interface-list=LAN src-address-list=!lan_subnets
/ip firewall raw add action=drop chain=prerouting comment="Drop bad UDP" port=0 protocol=udp
/ip firewall raw add action=drop chain=prerouting comment="Drop DHCP discover on LAN" dst-address=255.255.255.255 dst-port=67 in-interface-list=LAN protocol=udp src-address=0.0.0.0 src-port=68
/ip firewall raw add action=accept chain=prerouting comment="Accept from LAN" in-interface-list=LAN
/ip firewall raw add action=accept chain=prerouting comment="Allow BGP from IX peers" dst-address-list=bgp-loopback-ips dst-port=179 protocol=tcp src-address-list=bgp-peers
/ip firewall raw add action=accept chain=prerouting comment="BCP194 - Allow established BGP sessions" dst-address-list=bgp-loopback-ips protocol=tcp src-address-list=bgp-peers tcp-flags=ack
/ip firewall raw add action=drop chain=prerouting comment="Block external access to BGP loopbacks" dst-address-list=bgp-loopback-ips in-interface-list=WAN
/ip firewall raw add action=accept chain=prerouting comment="Accept from WAN" in-interface-list=WAN
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add blackhole comment=global_ipv4_resources distance=240 dst-address=160.22.180.0/23
/ip route add distance=220 gateway=172.16.30.2 pref-src=160.22.181.180
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=0.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=172.16.0.0/12
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=192.168.0.0/16
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=10.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=169.254.0.0/16
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=127.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=yes distance=240 dst-address=224.0.0.0/4
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=198.18.0.0/15
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=192.0.0.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=192.0.2.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=198.51.100.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=203.0.113.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=100.64.0.0/10
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=240.0.0.0/4
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no distance=240 dst-address=192.88.99.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (limited broadcast)" disabled=no distance=240 dst-address=255.255.255.255/32
/ip route add blackhole comment=global_anycast_v4 distance=240 dst-address=160.22.181.0/24
/ip route add blackhole comment=global_anycast_v4 distance=240 dst-address=160.22.180.0/24
/ip route add disabled=yes dst-address=160.22.181.254/32 gateway=172.16.10.2
/ip route add comment="bkk50 loopback via p2p" distance=1 dst-address=160.22.181.181/32 gateway=172.16.10.2%BKK50-LAG
/ipv6 route add blackhole comment=global_ipv6_resources distance=240 dst-address=2401:a860::/32
/ipv6 route add blackhole comment="ipv6 ula rfc4193" distance=240 dst-address=fc00::/7
/ipv6 route add blackhole comment="ipv6 site-local deprecated" distance=240 dst-address=fec0::/10
/ipv6 route add blackhole comment="ipv6 discard prefix rfc6666" distance=240 dst-address=100::/64
/ipv6 route add blackhole comment=global_anycast_ipv6 distance=240 dst-address=2401:a860::/36
/ipv6 route add blackhole comment=global_unicast_ipv6 disabled=no distance=240 dst-address=2401:a860:1000::/36
/ip service set ftp address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16 disabled=yes
/ip service set ssh address=10.0.0.0/8,95.217.216.149/32,2a01:4f9:c012:fbcd::/64,119.76.35.40/32,160.22.181.181/32,125.164.0.0/16,192.168.0.0/16,172.16.0.0/12,172.104.169.64/32,171.101.163.225/32,95.217.134.129/32,160.22.180.0/23,158.140.0.0/16,2400:8901::f03c:94ff:fe03:c318/128,172.31.0.0/16
/ip service set telnet address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip service set www address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16
/ip service set www-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 certificate=local-cert disabled=no
/ip service set winbox address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16,104.28.213.0/24 disabled=yes
/ip service set api address=160.22.181.181/32
/ip service set api-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip smb shares set [ find default=yes ] directory=/pub
/ip ssh set forwarding-enabled=local
/ipv6 address add address=fd00:dead:beef:30::1/126 advertise=no interface=BKK20-LAG
/ipv6 address add address=2401:a860:181::100/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::100/128 advertise=no interface=lo
/ipv6 address add address=2001:df5:b881::168 advertise=no comment=BKNIX-V6 interface=BKNIX-LAG
/ipv6 address add address=2403:5000:171:138::2 advertise=no comment="HK IPv6" interface=HK-HGC-IPTx-vlan2519
/ipv6 address add address=2001:7f8:1:0:a500:14:2108:1 advertise=no interface=EU-AMS-IX-vlan3995
/ipv6 address add address=2407:9540:111:8::2/126 advertise=no interface=SG-HGC-IPTx-backup-vlan2518
/ipv6 address add address=2401:a860:1181::100/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::/127 advertise=no interface=BKK20-LAG
/ipv6 address add address=fd00:dead:beef:10::/127 advertise=no comment="ULA P2P to BKK10" interface=bridge_vlan
/ipv6 address add address=fd00:dead:beef:50::/127 advertise=no comment="ULA P2P to BKK50" interface=BKK50-LAG
/ipv6 address add address=2401:a860:1181:2050::1/127 advertise=no comment="Global P2P to BKK20" interface=BKK20-LAG
/ipv6 address add address=2401:a860:1181:10::/127 advertise=no comment="Global P2P to BKK10" interface=bridge_vlan
/ipv6 address add address=2401:a860:1181:50::/127 advertise=no comment="Global P2P to BKK50" interface=BKK50-LAG
/ipv6 address add address=fd00:155:254::100 advertise=no comment="BGP RR VLAN IPv6" interface=vlan-400
/ipv6 address add address=fd00:155:100::1 advertise=no interface=qnq-400-100
/ipv6 address add address=fd00:155:106::/127 advertise=no interface=BKK06-LAG
/ipv6 address add address=fd00:155:107::/127 advertise=no interface=BKK07-LAG
/ipv6 address add address=fd00:155:108::/127 advertise=no interface=BKK08-LAG
/ipv6 firewall address-list add address=2001:df5:b881::/64 list=bknix-ipv6
/ipv6 firewall address-list add address=2001:df5:b881::168/128 list=bknix-rotko-address
/ipv6 firewall address-list add address=2401:a860::/32 list=ipv6-apnic-rotko
/ipv6 firewall address-list add address=2402:b740:15::/48 list=amsix-ipv6
/ipv6 firewall address-list add address=::/128 comment="Unspecified address" list=bogons-v6
/ipv6 firewall address-list add address=::1/128 comment="Loopback address" list=bogons-v6
/ipv6 firewall address-list add address=::ffff:0.0.0.0/96 comment="IPv4-mapped addresses" list=bogons-v6
/ipv6 firewall address-list add address=::/96 comment="IPv4-compatible addresses" list=bogons-v6
/ipv6 firewall address-list add address=100::/64 comment="Discard-only address block" list=bogons-v6
/ipv6 firewall address-list add address=2001::/23 comment="IETF Protocol Assignments" list=bogons-v6
/ipv6 firewall address-list add address=2001::/32 comment=TEREDO list=bogons-v6
/ipv6 firewall address-list add address=2001:2::/48 comment=Benchmarking list=bogons-v6
/ipv6 firewall address-list add address=2001:10::/28 comment=ORCHID list=bogons-v6
/ipv6 firewall address-list add address=fc00::/7 comment=Unique-Local list=bogons-v6
/ipv6 firewall address-list add address=fe80::/10 comment=Link-Local list=bogons-v6
/ipv6 firewall address-list add address=fec0::/10 comment="Site-Local (deprecated)" list=bogons-v6
/ipv6 firewall address-list add address=ff00::/8 comment=Multicast list=bogons-v6
/ipv6 firewall address-list add address=2401:a860:181::10/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2403:5000:171:138::2/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:df5:b881::168/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:7f8:1:0:a500:14:2108:1/128 comment=AMS-IX-BAN-ROTKO-IPV6 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:df5:b881::/64 comment="BKNIX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HGC IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2401:a860:181::10/128 comment="EU-AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:30::/126 comment="BKK20 iBGP" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:40::/126 comment="BKK10 iBGP" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:50::/126 comment="BKK50 iBGP" list=bgp-peers
/ipv6 firewall address-list add comment="Default route for iBGP" list=all-addresses-v6
/ipv6 firewall address-list add address=2401:a860::/32 comment="Our Main IPv6 block" list=our-networks-v6
/ipv6 firewall address-list add address=2401:a860:181::/48 comment=RotkoUNICAST list=our-networks-v6
/ipv6 firewall address-list add address=2001:df5:b881::/48 comment="BKNIX IPv6" list=bgp-peers-v6
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX EU IPv6 Range" list=bgp-peers-v6
/ipv6 firewall address-list add address=2001:df0:296::/64 comment="AMS-IX HK IPv6 Range" list=bgp-peers-v6
/ipv6 firewall address-list add address=2402:b740:15::/48 comment="AMS-IX BKK IPv6 Range" list=bgp-peers-v6
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HGC IPv6 Range" list=bgp-peers-v6
/ipv6 firewall address-list add address=fd00:dead:beef::/48 comment="Internal iBGP Range" list=bgp-peers-v6
/ipv6 firewall address-list add address=2401:a860:181::20/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2402:b740:15:388:a500:14:2108:1/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:df0:296:0:a500:14:2108:1/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:deb:0:4070::26/128 comment="RPKI Validator Primary" list=rpki-validators
/ipv6 firewall address-list add address=2001:deb:0:4070::36/128 comment="RPKI Validator Secondary" list=rpki-validators
/ipv6 firewall address-list add address=2402:b740:15:388::/64 comment="AMS-IX Bangkok Peering LAN" list=exchange-points
/ipv6 firewall address-list add address=2001:df0:296::/64 comment="AMS-IX Hong Kong Peering LAN" list=exchange-points
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX Amsterdam Peering LAN" list=exchange-points
/ipv6 firewall address-list add address=2001:df5:b881::/48 comment="BKNIX Peering LAN" list=exchange-points
/ipv6 firewall address-list add address=2001:deb:0:4070::/64 comment="RPKI Service Network" list=critical-services
/ipv6 firewall address-list add address=2401:a860:169::/48 list=our-networks-v6
/ipv6 firewall address-list add address=fd00:dead:beef::100/128 comment="Main ULA Loopback" list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:7f8:1:0:a500:14:2108:1/128 comment="AMS-IX EU - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=2402:b740:15:388:a500:14:2108:1/128 comment="AMS-IX BKK - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=2001:df0:296:0:a500:14:2108:1/128 comment="AMS-IX HK - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=fd00:155:206::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=fd00:155:207::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=fd00:155:208::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=2401:a860:1181::/48 list=bkk50-rotko-ranges-v6
/ipv6 firewall address-list add address=2401:a860:169::/64 list=bkk50-rotko-ranges-v6
/ipv6 firewall raw add action=drop chain=prerouting comment=SNMP-DANGER dst-port=161,162 in-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-BKNIX disabled=yes dst-address=2001:df5:b881::/64 port=179 protocol=tcp src-address=2001:df5:b881::/64
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-EU disabled=yes dst-address=2001:7f8:1::/64 port=179 protocol=tcp src-address=2001:7f8:1::/64
/ipv6 firewall raw add action=accept chain=prerouting comment=TRANSPARENT disabled=yes
/ipv6 firewall raw add action=drop chain=prerouting comment="Block spoofed exchange loopbacks from WAN" in-interface-list=WAN src-address-list=exchange-only-loopbacks
/ipv6 firewall raw add action=drop chain=prerouting comment="Block spoofed our ip ranges from WAN" in-interface-list=WAN src-address-list=ipv6-apnic-rotko
/ipv6 firewall raw add action=drop chain=prerouting comment="iSAV: Drop our IPv6 prefixes from WAN" in-interface-list=WAN src-address-list=our-networks-v6
/ipv6 firewall raw add action=drop chain=prerouting comment="block inbound RAs" icmp-options=134:0 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=output comment="block outbound RAs" icmp-options=134:0 out-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="Block Redirect from IXP" icmp-options=137:0 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=output comment="Block Redirect to IXP" icmp-options=137:0 out-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="drop port 25 to prevent spam" port=25 protocol=tcp
/ipv6 firewall raw add action=drop chain=prerouting comment="drop port 25 to prevent spam" port=25 protocol=udp
/ipv6 firewall raw add action=drop chain=output comment="Block DHCPv6 to IXP" dst-port=546,547 out-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Block DHCPv6 from IXP" dst-port=546,547 in-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Block DHCP" dst-port=67,68 in-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=drop chain=output comment="Block DHCP" dst-port=67,68 out-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Block PIM" in-interface-list=WAN protocol=pim
/ipv6 firewall raw add action=drop chain=output comment="Block PIM" out-interface-list=WAN protocol=pim
/ipv6 firewall raw add action=accept chain=prerouting dst-address=fd00:dead:beef::/48
/ipv6 firewall raw add action=accept chain=prerouting src-address=fd00:dead:beef::/48
/ipv6 firewall raw add action=accept chain=prerouting headers=frag
/ipv6 firewall raw add action=accept chain=prerouting protocol=ospf
/ipv6 firewall raw add action=accept chain=prerouting comment=allow_bfd dst-port=3784,4784 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting dst-address-list=bgp-peers-v6 dst-port=179 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting protocol=tcp src-address-list=bgp-peers-v6 src-port=179
/ipv6 firewall raw add action=accept chain=prerouting comment=allow_rkpi dst-port=323,4323 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting src-address-list=rpki-validators
/ipv6 firewall raw add action=accept chain=prerouting dst-address-list=rpki-validators
/ipv6 firewall raw add action=accept chain=prerouting dst-port=53 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting dst-port=53 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting dst-port=123 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting dst-port=22 protocol=tcp
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop packets with extension header types 0, 43" headers=hop,route:contains
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop UDP port 0" port=0 protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop hop-limit=1 from WAN" hop-limit=equal:1 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=jump chain=prerouting comment="Check TCP flags" jump-target=bad_tcp protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Accept all link-local ICMPv6" in-interface-list=WAN src-address=fe80::/10
/ipv6 firewall raw add action=jump chain=prerouting comment="Jump to bogon handler" in-interface-list=WAN jump-target=bogon-drop src-address-list=bogons-v6
/ipv6 firewall raw add action=accept chain=prerouting comment="FINAL ACCEPT"
/ipv6 firewall raw add action=log chain=bogon-drop disabled=yes limit=1,5:packet log-prefix=BOGON:
/ipv6 firewall raw add action=drop chain=bogon-drop comment="Drop bogons"
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP port 0 drop" port=0 protocol=tcp
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: no flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+SYN" protocol=tcp tcp-flags=fin,syn
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+RST" protocol=tcp tcp-flags=fin,rst
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN without ACK" protocol=tcp tcp-flags=fin,!ack
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+URG" protocol=tcp tcp-flags=fin,urg
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: SYN+RST" protocol=tcp tcp-flags=syn,rst
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: RST+URG" protocol=tcp tcp-flags=rst,urg
/ipv6 nd set [ find default=yes ] ra-lifetime=none
/routing bgp connection add comment="iBGP peer BKK20" input.filter=IBGP-IN-v4 .limit-process-routes-ipv4=2000000 local.address=10.155.255.4 .role=ibgp multihop=yes name=IBGP-ROTKO-BKK20-v4 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v4 .keep-sent-attributes=yes .redistribute=connected,static,bgp remote.address=10.155.255.2 templates=IBGP-ROTKO-v4
/routing bgp connection add afi=ipv6 comment="iBGP peer BKK20 IPv6" disabled=no input.filter=IBGP-IN-v6 .limit-process-routes-ipv6=2000000 local.address=fd00:dead:beef::100 .role=ibgp multihop=yes name=IBGP-ROTKO-BKK20-v6 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v6 .keep-sent-attributes=yes .redistribute=connected,static,bgp remote.address=fd00:dead:beef::20 .as=142108 templates=IBGP-ROTKO-v6
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv4=200000 keepalive-time=1m local.role=ebgp name=BKNIX-RS0-v4 remote.address=203.159.68.68 .as=63529 templates=BKNIX-v4
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv4=200000 keepalive-time=1m local.role=ebgp name=BKNIX-RS1-v4 remote.address=203.159.68.69 .as=63529 templates=BKNIX-v4
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv6=100000 keepalive-time=1m local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS0-v6 nexthop-choice=default remote.address=2001:df5:b881::68 .as=63529 templates=BKNIX-v6
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv6=100000 keepalive-time=1m local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS1-v6 nexthop-choice=default remote.address=2001:df5:b881::69 .as=63529 templates=BKNIX-v6
/routing bgp connection add disabled=no hold-time=3m input.filter=ROUTEVIEWS-IN-v4 .limit-process-routes-ipv4=10 keepalive-time=1m local.role=ebgp name=RouteViews-BKNIX-v4 output.filter-chain=ROUTEVIEWS-OUT-v4 remote.address=203.159.68.20 .as=6447 templates=BKNIX-v4
/routing bgp connection add disabled=no hold-time=3m input.filter=ROUTEVIEWS-IN-v6 .limit-process-routes-ipv6=10 keepalive-time=1m local.role=ebgp name=RouteViews-BKNIX-v6 output.filter-chain=ROUTEVIEWS-OUT-v6 remote.address=2001:df5:b881::20 .as=6447 templates=BKNIX-v6
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv4=210000 keepalive-time=1m local.role=ebgp name=HE-BKNIX-v4 remote.address=203.159.68.135 .as=6939 templates=BKNIX-v4
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv6=237000 keepalive-time=1m local.role=ebgp name=HE-BKNIX-v6 remote.address=2001:df5:b881::135 .as=6939 templates=BKNIX-v6
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv6=500000 keepalive-time=1m local.address=2403:5000:171:138::2 .role=ebgp name=HGC-HK-PRIMARY-v6 remote.address=2403:5000:171:138::1 .as=9304 templates=IPTX-HGC-HK-v6
/routing bgp connection add disabled=no hold-time=3m input.limit-process-routes-ipv4=1500000 keepalive-time=1m local.address=118.143.211.186 .role=ebgp name=HGC-HK-PRIMARY-v4 remote.address=118.143.211.185 .as=9304 templates=IPTX-HGC-HK-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv4=1000000 keepalive-time=30s local.role=ebgp name=AMSIX-RS1-v4 remote.address=80.249.208.255 .as=6777 templates=AMSIX-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv4=1000000 keepalive-time=30s local.role=ebgp name=AMSIX-RS2-v4 remote.address=80.249.209.0 .as=6777 templates=AMSIX-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv6=1000000 keepalive-time=30s local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS1-v6 remote.address=2001:7f8:1::a500:6777:1 .as=6777 templates=AMSIX-v6
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv6=1000000 keepalive-time=30s local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS2-v6 remote.address=2001:7f8:1::a500:6777:2 .as=6777 templates=AMSIX-v6
/routing bgp connection add afi=ipv6 disabled=no hold-time=3m input.limit-process-routes-ipv6=500000 keepalive-time=1m local.address=2407:9540:111:8::2 .role=ebgp name=HGC-SG-BACKUP-v6 remote.address=2407:9540:111:8::1 .as=142435 templates=HGC-TH-SG-v6
/routing bgp connection add afi=ip disabled=no hold-time=3m input.limit-process-routes-ipv4=1500000 keepalive-time=1m local.role=ebgp name=HGC-SG-BACKUP-v4 remote.address=103.168.174.181 .as=142435 templates=HGC-TH-SG-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv4=1000000 keepalive-time=30s local.role=ebgp name=Cloudflare-AMSIX-v4-1 remote.address=80.249.211.140 .as=13335 templates=AMSIX-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv4=1000000 keepalive-time=30s local.role=ebgp name=Cloudflare-AMSIX-v4-2 remote.address=80.249.210.118 .as=13335 templates=AMSIX-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv6=1000000 keepalive-time=30s local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-1 remote.address=2001:7f8:1::a501:3335:1 .as=13335 templates=AMSIX-v6
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv6=1000000 keepalive-time=30s local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-2 remote.address=2001:7f8:1::a501:3335:2 .as=13335 templates=AMSIX-v6
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv4=210000 keepalive-time=30s local.address=80.249.212.139 .role=ebgp name=HE-AMSIX-v4 remote.address=80.249.209.150 .as=6939 templates=AMSIX-v4
/routing bgp connection add disabled=no hold-time=1m30s input.limit-process-routes-ipv6=237000 keepalive-time=30s local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=HE-AMSIX-v6 remote.address=2001:7f8:1::a500:6939:1 .as=6939 templates=AMSIX-v6
/routing bgp connection add disabled=no local.address=10.155.106.0 .role=ibgp-rr name=rr-client-bkk06-v4 remote.address=10.155.106.1 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add disabled=no local.address=10.155.107.0 .role=ibgp-rr name=rr-client-bkk07-v4 remote.address=10.155.107.1 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add disabled=no local.address=10.155.108.0 .role=ibgp-rr name=rr-client-bkk08-v4 remote.address=10.155.108.1 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:106:: .role=ibgp-rr name=rr-client-bkk06-v6 remote.address=fd00:155:106::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:107:: .role=ibgp-rr name=rr-client-bkk07-v6 remote.address=fd00:155:107::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:108:: .role=ibgp-rr name=rr-client-bkk08-v6 remote.address=fd00:155:108::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ip input.filter=iBGP-IN-v4 local.address=10.155.255.4 .role=ibgp multihop=yes name=ibgp-bkk50-v4 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v4 .redistribute=connected,static,bgp remote.address=10.155.255.3 .as=142108 templates=IBGP-ROTKO-v4
/routing bgp connection add afi=ipv6 input.filter=iBGP-IN-v6 local.address=fd00:dead:beef::100 .role=ibgp multihop=yes name=ibgp-bkk50-v6 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v6 .redistribute=connected,static,bgp remote.address=fd00:dead:beef::50 .as=142108 templates=IBGP-ROTKO-v6
/routing bgp connection add local.address=10.155.100.1 .role=ibgp-rr name=rr-client-bkk08-unified-v4 remote.address=10.155.100.8 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add local.address=fd00:155:100::1 .role=ibgp-rr name=rr-client-bkk08-unified-v6 remote.address=fd00:155:100::8 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add local.address=10.155.100.1 .role=ibgp-rr name=rr-client-bkk07-unified-v4 remote.address=10.155.100.7 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add local.address=fd00:155:100::1 .role=ibgp-rr name=rr-client-bkk07-unified-v6 remote.address=fd00:155:100::7 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add local.address=10.155.100.1 .role=ibgp-rr name=rr-client-bkk06-unified-v4 remote.address=10.155.100.6 .as=142108 templates=RR-CLIENTS-v4
/routing bgp connection add local.address=fd00:155:100::1 .role=ibgp-rr name=rr-client-bkk06-unified-v6 remote.address=fd00:155:100::6 .as=142108 templates=RR-CLIENTS-v6
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
/routing filter community-list add comment="RFC 7999 BLACKHOLE" communities=65535:666 list=blackhole
/routing filter num-list add list=private-asn range=64512-65535
/routing filter num-list add list=private-asn range=4200000000-4294967295
/routing filter num-list add list=my-as range=142108
/routing filter rule add chain=IBGP-IN-v4 rule="if (dst in bkk50-rotko-ranges) { set distance 100; set bgp-local-pref 150; accept; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (dst in bkk50-rotko-ranges-v6) { set distance 100; set bgp-local-pref 150; accept; }"
/routing filter rule add chain=BKNIX-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=BKNIX-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=BKNIX-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=BKNIX-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=BKNIX-OUT-v4 disabled=no rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=AMSIX-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (gw in ibgp-block-gw-v4) { reject; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list bknix-communities) { set bgp-local-pref 200; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-ban-communities) { set bgp-local-pref 190; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-th-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-th-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 100; }"
/routing filter rule add chain=IBGP-IN-v4 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=BKNIX-OUT-v6 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=BKNIX-OUT-v4 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-OUT-v4 rule="set bgp-med 150; set bgp-path-prepend 3; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-OUT-v6 rule="set bgp-med 150; set bgp-path-prepend 3; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in not_in_internet) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in not_in_internet) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in not_in_internet) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in not_in_internet) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Accept route" rule="set bgp-local-pref 200; set bgp-large-communities bknix-communities; accept"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-th-sg-communities; accept"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept"
/routing filter rule add chain=AMSIX-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Accept route" rule="set bgp-local-pref 100; set bgp-large-communities amsix-communities; accept"
/routing filter rule add chain=BKNIX-IN-v6 comment="Accept route" rule="set bgp-local-pref 200; set bgp-large-communities bknix-communities; accept"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-th-sg-communities; accept"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept"
/routing filter rule add chain=AMSIX-IN-v6 comment="Accept route" rule="set bgp-local-pref 100; set bgp-large-communities amsix-communities; accept"
/routing filter rule add chain=graceful-shutdown rule="set bgp-communities graceful-shutdown; set bgp-local-pref 0; accept"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=too-specific rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=bogons rule="if (dst in not_in_internet) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=default rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=RPKI-invalid rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment="TEMP: Accept our prefix" rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=accept-all disabled=yes rule=accept
/routing filter rule add chain=ROUTEVIEWS-IN-v4 comment=discard rule=reject
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=too-specific rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=bogons rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=default rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=RPKI-invalid rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=accept-all rule="accept;"
/routing filter rule add chain=ROUTEVIEWS-IN-v6 comment=discard rule="reject;"
/routing filter rule add chain=IBGP-IN-v6 rule="if (gw in ibgp-block-gw-v6) { reject; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list bknix-communities) { set bgp-local-pref 200; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list amsix-ban-communities) { set bgp-local-pref 190; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list hgc-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list hgc-th-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list hgc-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list hgc-th-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 100; }"
/routing filter rule add chain=IBGP-IN-v6 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=IBGP-OUT-v6 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=graceful-shutdown-out rule="set bgp-communities 65535:65281; accept"
/routing filter rule add chain=IBGP-OUT-v4 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (bgp-network) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="reject;"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="if (bgp-network) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="reject;"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="if (gw in ibgp-block-gw-v4) { reject; }"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="reject;"
/routing filter rule add chain=RR-CLIENT-IN-v6 rule="if (gw in ibgp-block-gw-v6) { reject; }"
/routing filter rule add chain=RR-CLIENT-IN-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-IN-v6 rule="reject;"
/routing filter rule add chain=HE-AMSIX-IN-v4 comment="HE free transit priority" rule="set bgp-local-pref 190; set bgp-large-communities amsix-communities; accept"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="set bgp-weight 1"
/routing ospf interface-template add area=backbone-v6 comment="ULA Loopback" disabled=no networks=fd00:dead:beef::/128 passive
/routing ospf interface-template add area=backbone comment=BKK00-LO disabled=no networks=10.155.255.4 passive
/routing ospf interface-template add area=backbone-v6 comment=EDGE-BKK00-BKK20 disabled=no networks=fd00:dead:beef:30::1/126
/routing ospf interface-template add area=backbone comment=EDGE-BKK00-BKK20 disabled=no networks=172.16.30.0/30
/routing ospf interface-template add area=backbone comment=GUA-LO-v4 disabled=no networks=160.22.181.180/32 passive
/routing ospf interface-template add area=backbone comment=BKK10-v4 disabled=no networks=172.16.110.0/31
/routing ospf interface-template add area=backbone comment=ULA-BKK50-v4 disabled=no networks=172.16.10.0/30
/routing ospf interface-template add area=backbone-v6 comment=EDGE-BKK20-v6 disabled=no networks=fd00:dead:beef::/127
/routing ospf interface-template add area=backbone-v6 comment="ULA P2P BKK50" disabled=no networks=fd00:dead:beef:50::1/127
/routing ospf interface-template add area=backbone-v6 comment="ULA P2P BKK10" disabled=no networks=fd00:dead:beef:10::/127
/routing ospf interface-template add area=backbone-v6 comment="ULA P2P BKK50" disabled=no networks=fd00:dead:beef:50::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK10" disabled=no networks=2401:a860:1181:10::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK50" disabled=no networks=2401:a860:1181:50::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK00" disabled=no networks=2401:a860:1181:50::1/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK20" disabled=no networks=2401:a860:1181:2050::1/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK10" disabled=no networks=2401:a860:1181:10::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK50" disabled=no networks=2401:a860:1181:50::/127
/routing ospf interface-template add area=backbone cost=10 disabled=no networks=10.155.254.0/24 priority=100
/routing ospf interface-template add area=backbone comment="WireGuard wg_rotko" disabled=no networks=172.31.0.0/16 passive
/routing rpki add address=203.159.70.26 comment="Routinator IPv4 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=2001:deb:0:4070::26 comment="Routinator IPv6 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=203.159.70.36 comment="StayRTR IPv4 Secondary" group=rpki.bknix.net port=4323
/routing rpki add address=2001:deb:0:4070::36 comment="StayRTR IPv6 Secondary" group=rpki.bknix.net port=4323
/snmp set enabled=yes trap-version=3
/system clock set time-zone-autodetect=no time-zone-name=Asia/Bangkok
/system identity set name=bkk00
/system logging add topics=bgp,!packet
/system logging add topics=route,bgp,debug
/system logging add action=disk topics=route,bgp,debug
/system ntp client set enabled=yes
/system ntp client servers add address=0.th.pool.ntp.org
/system ntp client servers add address=0.asia.pool.ntp.org
/system ntp client servers add address=1.asia.pool.ntp.org
/system routerboard settings set enter-setup-on=delete-key
/system scheduler add name=restore-on-boot on-event="/system script run on-startup" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system scheduler add name=bcp214-start on-event="/system script run bcp214-start" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=18:05:00
/system scheduler add name=bcp214-block on-event="/system script run bcp214-block" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=18:07:00
/system scheduler add disabled=yes name=bcp214-restore on-event="/system script run bcp214-restore" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-07-31 start-time=17:52:00
/system scheduler add disabled=yes name=reboot on-event="/system script run bcp214-reboot" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-07-31 start-time=17:47:00
/system scheduler add name=bcp214-downgrade on-event="/system script run bcp214-downgrade" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=18:08:00
/system script add dont-require-permissions=no name=bcp214-start owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="# Process all filter rules and find OUT chains\
    \n:foreach ruleId in=[/routing filter rule find] do={\
    \n    :local chainName [/routing filter rule get \$ruleId chain]\
    \n    # Check if chain ends with -OUT-v4 or -OUT-v6\
    \n    :if (\$chainName~\"-OUT-v4\\\$\" or \$chainName~\"-OUT-v6\\\$\") do={\
    \n        # Check if BCP214 rule doesn't already exist\
    \n        :if ([:len [/routing filter rule find where chain=\$chainName comment=\"BCP214\"]] = 0) do={\
    \n            /routing filter rule add chain=\$chainName place-before=0 \\\
    \n                rule=\"jump graceful-shutdown\" comment=\"BCP214\"\
    \n        }\
    \n    }\
    \n}\
    \n:log warning \"BCP214: T-5min - Graceful shutdown started\""
/system script add dont-require-permissions=no name=bcp214-block owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n    /ip firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=no\
    \n    /ipv6 firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=no\
    \n    :log warning \"BCP214: T-0 - BGP blocked\"\
    \n"
/system script add dont-require-permissions=no name=bcp214-restore owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\
    \n    /routing filter rule remove [find comment=\"BCP214\"]\
    \n    /ip firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=yes\
    \n    /ipv6 firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=yes\
    \n    :log warning \"BCP214: Service restored\"\
    \n"
/system script add dont-require-permissions=no name=bcp214-downgrade owner=ansible policy=ftp,reboot,read,write,test,password source="\
    \n      :log warning \"BCP214: triggering package downgrade to previous build\";\
    \n      /system package downgrade\
    \n    "
/system script add dont-require-permissions=no name=bcp214-upgrade owner=ansible policy=ftp,reboot,read,write,test,password source="\
    \n      :log warning \"BCP214: triggering package upgrade\";\
    \n      /system package update download\
    \n      /system package update install\
    \n    "
/system script add dont-require-permissions=no name=bcp214-reboot owner=ansible policy=ftp,reboot,read,write,test,password source="\
    \n      :log warning \"BCP214: reboot\";\
    \n      /system reboot\
    \n    "
/system script add dont-require-permissions=no name=on-startup owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
    \n:log warning \"STARTUP: waiting 60s for BGP to initialize...\"\r\
    \n:delay 60s\r\
    \n:if ([:len [/routing filter rule find where comment=\"BCP214\"]] > 0) do={\r\
    \n    :log warning \"STARTUP: removing leftover BCP214 filter rules\"\r\
    \n    /routing filter rule remove [find comment=\"BCP214\"]\r\
    \n}\r\
    \n/ip firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=yes\r\
    \n/ipv6 firewall raw set [find comment~\"BGP-MAINTENANCE-MODE\"] disabled=yes\r\
    \n:delay 30s\r\
    \n:local established 0\r\
    \n:local total 0\r\
    \n:foreach sess in=[/routing/bgp/session find] do={\r\
    \n    :set total (\$total + 1)\r\
    \n    :if ([/routing/bgp/session get \$sess established]) do={ :set established (\$established + 1) }\r\
    \n}\r\
    \n:if (\$established > 0) do={\r\
    \n    :log warning \"STARTUP: BGP restored - \$established/\$total sessions established\"\r\
    \n} else={\r\
    \n    :log error \"STARTUP: WARNING - no BGP sessions established!\"\r\
    \n}\r\
    \n"
/system script add dont-require-permissions=no name=bcp214-maintenance owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
    \n:local now [/system clock get time]\r\
    \n:local nowSec ([:pick \$now 0 2] * 3600 + [:pick \$now 3 5] * 60 + [:pick \$now 6 8])\r\
    \n\r\
    \n# T+0: start graceful shutdown\r\
    \n:log warning \"BCP214-MAINT: starting graceful shutdown sequence\"\r\
    \n/system script run bcp214-start\r\
    \n\r\
    \n# calculate times for T+2min and T+3min\r\
    \n:local blockSec (\$nowSec + 120)\r\
    \n:local rebootSec (\$nowSec + 180)\r\
    \n\r\
    \n# handle day wrap\r\
    \n:if (\$blockSec >= 86400) do={ :set blockSec (\$blockSec - 86400) }\r\
    \n:if (\$rebootSec >= 86400) do={ :set rebootSec (\$rebootSec - 86400) }\r\
    \n\r\
    \n:local blockH (\$blockSec / 3600)\r\
    \n:local blockM ((\$blockSec % 3600) / 60)\r\
    \n:local blockS (\$blockSec % 60)\r\
    \n:local rebootH (\$rebootSec / 3600)\r\
    \n:local rebootM ((\$rebootSec % 3600) / 60)\r\
    \n:local rebootS (\$rebootSec % 60)\r\
    \n\r\
    \n:local blockTime \"\$[:pick (100 + \$blockH) 1 3]:\$[:pick (100 + \$blockM) 1 3]:\$[:pick (100 + \$blockS) 1 3]\"\r\
    \n:local rebootTime \"\$[:pick (100 + \$rebootH) 1 3]:\$[:pick (100 + \$rebootM) 1 3]:\$[:pick (100 + \$rebootS) 1 3]\"\r\
    \n\r\
    \n:local today [/system clock get date]\r\
    \n\r\
    \n# remove old schedulers if exist\r\
    \n/system scheduler remove [find name~\"bcp214-sched-\"]\r\
    \n\r\
    \n# schedule block at T+2min\r\
    \n/system scheduler add name=bcp214-sched-block start-date=\$today start-time=\$blockTime interval=0 \\\r\
    \n    on-event=\"/system script run bcp214-block; :log warning \\\"BCP214-MAINT: BGP blocked, reboot in 60s\\\"\" \\\r\
    \n    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon\r\
    \n\r\
    \n# schedule reboot at T+3min\r\
    \n/system scheduler add name=bcp214-sched-reboot start-date=\$today start-time=\$rebootTime interval=0 \\\r\
    \n    on-event=\"/system scheduler remove [find name~\\\"bcp214-sched-\\\"]; /system reboot\" \\\r\
    \n    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon\r\
    \n\r\
    \n:log warning \"BCP214-MAINT: block scheduled at \$blockTime, reboot at \$rebootTime\"\r\
    \n"
/system script add dont-require-permissions=no name=bcp214-abort owner=pj policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="\r\
    \n:log warning \"BCP214-ABORT: canceling maintenance\"\r\
    \n/system scheduler remove [find name~\"bcp214-sched-\"]\r\
    \n/system script run bcp214-restore\r\
    \n:log warning \"BCP214-ABORT: maintenance canceled, service restored\"\r\
    \n"
/system script add dont-require-permissions=no name=bcp214-status owner=pj policy=read source="\r\
    \n:local hasBcp214 ([:len [/routing filter rule find where comment=\"BCP214\"]] > 0)\r\
    \n:local hasMaintFw ([:len [/ip firewall raw find where comment~\"BGP-MAINTENANCE-MODE\" and disabled=no]] > 0)\r\
    \n:local pendingSched [:len [/system scheduler find where name~\"bcp214-sched-\"]]\r\
    \n\r\
    \n:put \"=== BCP214 Status ===\"\r\
    \n:if (\$hasBcp214) do={ :put \"GSHUT rules: ACTIVE\" } else={ :put \"GSHUT rules: inactive\" }\r\
    \n:if (\$hasMaintFw) do={ :put \"BGP blocked: YES\" } else={ :put \"BGP blocked: no\" }\r\
    \n:put \"Pending schedulers: \$pendingSched\"\r\
    \n\r\
    \n:local established 0\r\
    \n:local total 0\r\
    \n:foreach sess in=[/routing/bgp/session find] do={\r\
    \n    :set total (\$total + 1)\r\
    \n    :if ([/routing/bgp/session get \$sess established]) do={ :set established (\$established + 1) }\r\
    \n}\r\
    \n:put \"BGP sessions: \$established/\$total established\"\r\
    \n"
/system watchdog set watchdog-timer=no
/tool traffic-monitor add disabled=yes interface=BKNIX-LAG name=bknix
/tool traffic-monitor add disabled=yes interface=EU-AMS-IX-vlan3995 name=amsix
