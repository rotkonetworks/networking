# 2025-10-12 14:07:42 by RouterOS 7.19.4
# software id = 74Z8-YX0B
#
# model = CCR2216-1G-12XS-2XQ
# serial number = HGQ09NWHXX7
/interface bridge add name=bridge_vlan vlan-filtering=yes
/interface ethernet set [ find default-name=qsfp28-1-1 ] comment=bkk00-1
/interface ethernet set [ find default-name=qsfp28-2-1 ] comment=bkk00-2
/interface ethernet set [ find default-name=sfp28-2 ] advertise=10G-baseSR-LR arp-timeout=4h comment=HGC/core3,4/MMR-3A
/interface ethernet set [ find default-name=sfp28-4 ] advertise=10G-baseSR-LR comment="empty cable atm to mmr-b, not in use / dark"
/interface ethernet set [ find default-name=sfp28-5 ] advertise=10G-baseCR comment=bkk10sfp3
/interface ethernet set [ find default-name=sfp28-11 ] advertise=10G-baseCR comment=BKK50sfp2
/interface wireguard add listen-port=51820 mtu=1420 name=wg_rotko
/interface vlan add interface=bridge_vlan name=vlan-400 vlan-id=400
/interface bonding add arp-timeout=4h comment=WAN-LAG-sfp2 lacp-rate=1sec mode=802.3ad name=AMSIX-LAG slaves=sfp28-2 transmit-hash-policy=layer-3-and-4
/interface bonding add comment=bkk00-2x100Gqsfp-edge lacp-rate=1sec mode=802.3ad name=BKK00-LAG slaves=qsfp28-1-1 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=bkk10-sfp5-gw lacp-rate=1sec mode=802.3ad name=BKK10-LAG slaves=sfp28-5 transmit-hash-policy=layer-2-and-3
/interface bonding add mode=802.3ad name=BKK40-LAG slaves=qsfp28-2-1
/interface bonding add comment=bkk50-sfp11-gw lacp-rate=1sec mode=802.3ad name=BKK50-LAG slaves=sfp28-11 transmit-hash-policy=layer-2-and-3
/interface vlan add interface=AMSIX-LAG name=BKK-AMS-IX-vlan911 vlan-id=911
/interface vlan add interface=AMSIX-LAG name=HK-AMS-IX-vlan3994 vlan-id=3994
/interface vlan add interface=AMSIX-LAG name=HK-HGC-IPTx-backup-vlan2517 vlan-id=2517
/interface vlan add interface=AMSIX-LAG name=SG-HGC-IPTx-vlan2520 vlan-id=2520
/interface vlan add interface=vlan-400 name=qnq-400-100 vlan-id=100
/interface vlan add interface=vlan-400 name=qnq-400-200 vlan-id=200
/interface vlan add interface=vlan-400 name=qnq-400-206 vlan-id=206
/interface vlan add interface=vlan-400 name=qnq-400-207 vlan-id=207
/interface vlan add interface=vlan-400 name=qnq-400-208 vlan-id=208
/interface vlan add interface=vlan-400 name=qnq-400-216 vlan-id=216
/interface vlan add interface=vlan-400 name=qnq-400-217 vlan-id=217
/interface vlan add interface=vlan-400 name=qnq-400-218 vlan-id=218
/interface bonding add mode=active-backup name=BKK06-LAG primary=qnq-400-206 slaves=qnq-400-206,qnq-400-216 transmit-hash-policy=layer-3-and-4
/interface bonding add mode=active-backup name=BKK07-LAG primary=qnq-400-207 slaves=qnq-400-207,qnq-400-217 transmit-hash-policy=layer-3-and-4
/interface bonding add mode=active-backup name=BKK08-LAG primary=qnq-400-208 slaves=qnq-400-208,qnq-400-218 transmit-hash-policy=layer-3-and-4
/interface list add name=LAN
/interface list add name=WAN
/port set 0 name=serial0
/routing bgp template set default as=142108 router-id=10.155.255.2
/routing bgp template add afi=ipv6 as=142108 input.filter=iBGP-IN-v6 multihop=yes name=IBGP-ROTKO-v6 nexthop-choice=force-self output.filter-chain=iBGP-OUT-v6 .network=ipv6-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.2
/routing id add id=10.155.255.2 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add comment="originate-default=always configured since we receive full BGP tables not default routes from transit/IXPs" disabled=no name=ospf-instance-v2 originate-default=if-installed router-id=10.155.255.2
/routing ospf instance add comment="originate-default=always configured since we receive full BGP tables not default routes from transit/IXPs" disabled=no name=ospf-instance-v3 originate-default=if-installed router-id=10.155.255.2 version=3
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/routing table add fib name=rt_latency
/routing bgp template add afi=ip as=142108 disabled=no input.filter=AMSIX-BAN-IN-v4 name=AMSIX-BAN-v4 output.as-override=no .filter-chain=AMSIX-BAN-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=AMSIX-BAN-IN-v6 name=AMSIX-BAN-v6 output.as-override=no .filter-chain=AMSIX-BAN-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=HGC-SG-IN-v4 name=HGC-SG-v4 output.as-override=no .filter-chain=HGC-SG-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=HGC-SG-IN-v6 name=HGC-SG-v6 output.as-override=no .filter-chain=HGC-SG-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=AMSIX-EU-IN-v4 name=AMSIX-EU-v4 output.as-override=no .filter-chain=AMSIX-EU-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=AMSIX-EU-IN-v6 name=AMSIX-EU-v6 output.as-override=no .filter-chain=AMSIX-EU-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=HGC-HK-IN-v4 multihop=yes name=IPTX-HGC-TH-HK-v4 output.as-override=no .filter-chain=HGC-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=HGC-HK-IN-v6 multihop=yes name=IPTX-HGC-TH-HK-v6 output.as-override=no .filter-chain=HGC-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ip as=142108 disabled=no input.filter=AMSIX-HK-IN-v4 name=AMSIX-HK-v4 output.as-override=no .filter-chain=AMSIX-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 disabled=no input.filter=AMSIX-HK-IN-v6 name=AMSIX-HK-v6 output.as-override=no .filter-chain=AMSIX-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main
/routing bgp template add as=142108 input.filter=RR-CLIENT-IN-v4 name=RR-CLIENTS nexthop-choice=default output.filter-chain=RR-CLIENT-OUT-v4 .network=ipv4-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ipv6 as=142108 input.filter=RR-CLIENT-IN-v6 name=RR-CLIENTS-v6 nexthop-choice=default output.filter-chain=RR-CLIENT-OUT-v6 router-id=10.155.255.2 routing-table=main
/routing bgp template add afi=ip as=142108 input.filter=iBGP-IN multihop=yes name=IBGP-ROTKO-v4 nexthop-choice=force-self output.filter-chain=iBGP-OUT .network=ipv4-apnic-rotko .redistribute=connected,static,bgp router-id=10.155.255.2 routing-table=main
/tool traffic-generator port add interface=BKK00-LAG name=test-port
/user group add name=mktxp_group policy=ssh,read,write,api,!local,!telnet,!ftp,!reboot,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api
/certificate settings set builtin-trust-anchors=not-trusted
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=vlan out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface-list=WAN
/interface bridge filter add action=drop chain=forward comment="Block inbound RA/NS/NA multicasts from WAN" dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 in-interface-list=WAN mac-protocol=ipv6
/interface bridge filter add action=drop chain=forward out-interface-list=WAN
/interface bridge port add bridge=bridge_vlan frame-types=admit-only-vlan-tagged interface=BKK40-LAG
/interface bridge port add bridge=bridge_vlan interface=BKK10-LAG
/ip firewall connection tracking set enabled=no loose-tcp-tracking=no udp-timeout=10s
/ip neighbor discovery-settings set discover-interval=1m mode=rx-only
/ip settings set secure-redirects=no send-redirects=no tcp-syncookies=yes
/ipv6 settings set accept-redirects=no accept-router-advertisements=no
/interface bridge vlan add bridge=bridge_vlan tagged=BKK40-LAG,BKK10-LAG vlan-ids=400
/interface ethernet switch set 0 l3-hw-offloading=yes
/interface list member add interface=ether1 list=LAN
/interface list member add interface=lo list=LAN
/interface list member add interface=wg_rotko list=LAN
/interface list member add interface=BKK10-LAG list=LAN
/interface list member add interface=BKK50-LAG list=LAN
/interface list member add interface=AMSIX-LAG list=WAN
/interface list member add interface=BKK-AMS-IX-vlan911 list=WAN
/interface list member add interface=HK-AMS-IX-vlan3994 list=WAN
/interface list member add interface=SG-HGC-IPTx-vlan2520 list=WAN
/interface list member add interface=HK-HGC-IPTx-backup-vlan2517 list=WAN
/interface list member add interface=sfp28-2 list=WAN
/interface list member add interface=BKK00-LAG list=LAN
/interface list member add interface=qsfp28-1-1 list=LAN
/interface list member add interface=qsfp28-2-1 list=LAN
/interface list member add interface=qnq-400-206 list=LAN
/interface list member add interface=qnq-400-207 list=LAN
/interface list member add interface=qnq-400-208 list=LAN
/interface list member add interface=*6D list=LAN
/interface list member add interface=vlan-400 list=LAN
/interface wireguard peers add allowed-address=172.31.0.1/32 interface=wg_rotko name=laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.10/32 interface=wg_rotko name=bkk10 public-key="nahvhOxYg+859oPKgnXopw2fqvcpJFaC92SqdMckI0I="
/interface wireguard peers add allowed-address=172.31.0.2/32 interface=wg_rotko name=gatus public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.31.0.3/32 interface=wg_rotko name=amdnuc public-key="IlZR7z5LVE6BKwkApq+VTvXRGaOp0hvmKSSrgi1R/V4="
/interface wireguard peers add allowed-address=172.31.0.50/32 interface=wg_rotko name=bkk50 public-key="HSEVRjXj7x7jSVy8A9YQducW6BNme/a19/o5CA/KrUI="
/ip address add address=118.143.234.74/29 interface=SG-HGC-IPTx-vlan2520 network=118.143.234.72
/ip address add address=172.31.0.20/16 interface=wg_rotko network=172.31.0.0
/ip address add address=10.155.255.2 interface=lo network=10.155.255.2
/ip address add address=103.100.140.31/24 interface=BKK-AMS-IX-vlan911 network=103.100.140.0
/ip address add address=103.247.139.76/25 interface=HK-AMS-IX-vlan3994 network=103.247.139.0
/ip address add address=172.16.20.1/30 comment=to_bkk50 interface=BKK50-LAG network=172.16.20.0
/ip address add address=160.22.181.178 comment=pub_ip interface=lo network=160.22.181.178
/ip address add address=103.168.174.178/30 interface=HK-HGC-IPTx-backup-vlan2517 network=103.168.174.176
/ip address add address=172.16.30.2/30 interface=BKK00-LAG network=172.16.30.0
/ip address add address=192.168.88.20/24 comment=bkk20-mgmt disabled=yes interface=ether1 network=192.168.88.0
/ip address add address=160.22.181.178 comment="for rkpi to work" interface=BKK00-LAG network=160.22.181.178
/ip address add address=10.155.254.200/24 interface=vlan-400 network=10.155.254.0
/ip address add address=10.155.208.0/31 disabled=yes interface=BKK08-LAG network=10.155.208.0
/ip address add address=10.155.206.0/31 disabled=yes interface=BKK06-LAG network=10.155.206.0
/ip address add address=10.155.207.0/31 disabled=yes interface=BKK07-LAG network=10.155.207.0
/ip address add address=172.16.210.0/31 interface=BKK10-LAG network=172.16.210.0
/ip address add address=10.155.120.1/16 interface=qnq-400-100 network=10.155.0.0
/ip address add address=10.155.208.0/16 interface=qnq-400-100 network=10.155.0.0
/ip address add address=10.155.206.0/16 interface=qnq-400-100 network=10.155.0.0
/ip address add address=10.155.207.0/16 interface=qnq-400-100 network=10.155.0.0
/ip dhcp-client add comment=defconf disabled=yes interface=*17
/ip dns set servers=9.9.9.9,1.0.0.1
/ip dns static add address=159.148.147.251 disabled=yes name=download.mikrotik.com type=A
/ip dns static add address=159.148.147.251 disabled=yes name=upgrade.mikrotik.com type=A
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
/ip firewall address-list add address=203.159.68.168 list=bknix-rotko-address
/ip firewall address-list add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ip firewall address-list add address=160.22.180.0/24 list=ibp-anycast-ipv4
/ip firewall address-list add address=160.22.181.0/24 list=rotko-unicast-ipv4
/ip firewall address-list add address=203.159.68.0/23 list=bknix-ipv4
/ip firewall address-list add address=118.143.211.184/29 list=HK-HGC-vlan2519
/ip firewall address-list add address=118.143.234.72/29 list=HK-SG-vlan2520
/ip firewall address-list add address=10.0.0.0/8 list=lan_subnets
/ip firewall address-list add address=192.168.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.31.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.16.0.0/16 list=lan_subnets
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA block" list=our-networks
/ip firewall address-list add address=10.155.255.2 comment="BKK20 Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.100.140.31 comment="AMSIX BKK Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.247.139.76 comment="AMSIX HK Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=118.143.234.74 comment="HGC SG Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=103.168.174.178 comment="HGC HK Backup Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=160.22.181.178 comment="Public IP Loopback" list=bgp-loopback-ips
/ip firewall address-list add address=80.249.208.0/21 comment="AMS-IX IXP Range" list=bgp-peers
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX IXP Range" list=bgp-peers
/ip firewall address-list add address=118.143.234.72/29 comment="HGC SG Range" list=bgp-peers
/ip firewall address-list add address=103.100.140.0/24 comment="BKK AMS-IX Range" list=bgp-peers
/ip firewall address-list add address=103.247.139.0/24 comment="HK AMS-IX Range" list=bgp-peers
/ip firewall address-list add address=103.168.174.176/29 comment="HK Backup Range" list=bgp-peers
/ip firewall address-list add address=172.16.30.0/30 comment="BKK00 Link Range" list=bgp-peers
/ip firewall address-list add address=172.16.20.0/30 comment="BKK50 Link Range" list=bgp-peers
/ip firewall address-list add address=172.16.10.0/30 comment="BKK10 Link Range" list=bgp-peers
/ip firewall address-list add address=10.0.0.0/8 list=dns-clients
/ip firewall address-list add address=172.16.0.0/12 list=dns-clients
/ip firewall address-list add address=192.168.0.0/16 list=dns-clients
/ip firewall address-list add address=160.22.180.0/24 list=our-networks
/ip firewall address-list add address=160.22.181.0/24 list=our-networks
/ip firewall address-list add address=202.28.92.208 comment=0.th.pool.ntp.org list=ntp-clients
/ip firewall address-list add address=185.217.99.236 comment=0.asia.pool.ntp.org list=ntp-clients
/ip firewall address-list add address=103.186.118.214 comment=1.asia.pool.ntp.org list=ntp-clients
/ip firewall address-list add address=10.155.106.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=10.155.107.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=10.155.108.0/24 list=ibgp-block-gw-v4
/ip firewall address-list add address=160.22.181.176/28 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.168/29 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.181 list=bkk50-rotko-ranges
/ip firewall address-list add address=160.22.181.20 list=bkk50-rotko-ranges
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass all" port=53 protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass all" port=53 protocol=tcp
/ip firewall raw add action=drop chain=prerouting comment=SNMP-DANGER dst-port=161,162 in-interface-list=WAN protocol=udp
/ip firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-BAN disabled=yes dst-address=103.100.140.0/24 port=179 protocol=tcp src-address=103.100.140.0/24
/ip firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-HK disabled=yes dst-address=103.247.139.0/25 port=179 protocol=tcp src-address=103.247.139.0/25
/ip firewall raw add action=accept chain=prerouting comment="Enable this rule for transparent mode" disabled=yes
/ip firewall raw add action=drop chain=prerouting comment="drop our-space seen on WAN" in-interface-list=WAN log=yes log-prefix=SPOOFED-NET src-address-list=our-networks
/ip firewall raw add action=accept chain=prerouting comment="AF8 RPKI RTR" dst-address=203.159.70.0/23 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="AF8 RPKI inbound via P2P" protocol=tcp src-address=203.159.70.0/23
/ip firewall raw add action=accept chain=prerouting comment="AF5 fabric /16 links" src-address=172.16.0.0/16
/ip firewall raw add action=accept chain=prerouting comment="AF6 wg_rotko VPN" src-address=172.31.0.0/16
/ip firewall raw add action=accept chain=prerouting comment="AF1 intra-OSPF" in-interface-list=!WAN protocol=ospf
/ip firewall raw add action=accept chain=prerouting comment="AF2 eBGP in" dst-address-list=bgp-loopback-ips dst-port=179 protocol=tcp src-address-list=bgp-peers
/ip firewall raw add action=accept chain=prerouting comment="Allow NTP inbound" dst-port=123 in-interface-list=WAN protocol=udp src-address-list=ntp-clients
/ip firewall raw add action=accept chain=prerouting comment="AF-RPKI inbound v4" protocol=tcp src-address=203.159.70.0/24
/ip firewall raw add action=accept chain=prerouting comment="AF3 eBGP established" dst-address-list=bgp-loopback-ips protocol=tcp src-address-list=bgp-peers tcp-flags=ack
/ip firewall raw add action=accept chain=prerouting comment="AF4 iBGP / loopback" dst-address-list=bgp-loopback-ips src-address-list=bgp-loopback-ips
/ip firewall raw add action=accept chain=prerouting comment="AF7 east-west (own /23)" dst-address-list=our-networks src-address-list=our-networks
/ip firewall raw add action=accept chain=prerouting comment="AF9 Tik monitoring" dst-address=160.22.181.181 dst-port=8728 protocol=tcp
/ip firewall raw add action=drop chain=prerouting comment="RFC6890 src  WAN" in-interface-list=WAN log=yes log-prefix=RFC-INVALID-SRC src-address-list=ipv4-bogons
/ip firewall raw add action=drop chain=prerouting comment="RFC6890 dst  WAN" dst-address-list=ipv4-bogons in-interface-list=WAN
/ip firewall raw add action=drop chain=prerouting comment="lock UDP 53" disabled=yes dst-port=53 protocol=udp
/ip firewall raw add action=drop chain=prerouting comment="lock TCP 53" disabled=yes dst-port=53 protocol=tcp
/ip firewall raw add action=drop chain=prerouting comment="invalid TCP flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ip firewall raw add action=drop chain=prerouting comment="TCP Xmas" protocol=tcp tcp-flags=fin,syn,rst,psh,ack,urg
/ip firewall raw add action=drop chain=prerouting comment="TCP null" protocol=tcp tcp-flags=!fin,!syn,!rst,!psh,!ack,!urg
/ip firewall raw add action=drop chain=prerouting comment="TCP FIN scan" protocol=tcp tcp-flags=fin,!syn,!rst,!psh,!ack,!urg
/ip firewall raw add action=drop chain=prerouting comment="UDP 0" port=0 protocol=udp
/ip firewall raw add action=drop chain=prerouting comment="TCP 0" port=0 protocol=tcp
/ip firewall raw add action=jump chain=prerouting jump-target=icmp protocol=icmp
/ip firewall raw add action=accept chain=icmp icmp-options=0:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp icmp-options=3:0-4 protocol=icmp
/ip firewall raw add action=accept chain=icmp icmp-options=8:0 protocol=icmp
/ip firewall raw add action=drop chain=icmp
/ip firewall raw add action=accept chain=prerouting comment="accept LAN after RFC checks" in-interface-list=LAN
/ip firewall raw add action=add-src-to-address-list address-list=seen-junk address-list-timeout=1h chain=prerouting comment="DEFAULT-DROP (log + mark first packet)" disabled=yes in-interface-list=WAN log=yes log-prefix="DEFAULT-DROP " src-address-list=!seen-junk
/ip firewall raw add action=drop chain=prerouting comment="everything else dies" disabled=yes log=yes log-prefix=DEFAULT-DROP
/ip firewall raw add action=drop chain=prerouting comment="drop rest of junk" disabled=yes
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add blackhole distance=240 dst-address=160.22.180.0/23
/ip route add distance=220 gateway=172.16.30.1 pref-src=160.22.181.178
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=0.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=172.16.0.0/12
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=192.168.0.0/16
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=10.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=169.254.0.0/16
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=127.0.0.0/8
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=224.0.0.0/4
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=198.18.0.0/15
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=192.0.0.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=192.0.2.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=198.51.100.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=203.0.113.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=100.64.0.0/10
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" disabled=no dst-address=192.88.99.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (limited broadcast)" disabled=no dst-address=255.255.255.255/32
/ip route add comment="Force src-IP for BKNIX RPKI v4" dst-address=203.159.70.26/32 gateway=172.16.30.1 pref-src=160.22.181.178
/ip route add blackhole comment=global_unicast_v4 distance=240 dst-address=160.22.181.0/24
/ip route add blackhole comment=global_anycast_v4 distance=240 dst-address=160.22.180.0/24
/ip route add blackhole comment="Blackhole route for RFC6890 (aggregated)" dst-address=240.0.0.0/4
/ip route add disabled=yes distance=150 dst-address=160.22.181.81 gateway=10.155.208.1
/ipv6 route add blackhole comment=global_ipv6_resources distance=240 dst-address=2401:a860::/32
/ipv6 route add blackhole comment="Blackhole for IPv6 Rotko Networks" disabled=no distance=240 dst-address=fc00::/7
/ipv6 route add blackhole comment="Blackhole for IPv6 Site-Local (Deprecated)" disabled=no distance=240 dst-address=fec0::/10
/ipv6 route add blackhole comment="Blackhole for IPv6 Discard Prefix (RFC6666)" distance=240 dst-address=100::/64
/ipv6 route add blackhole comment=global_unicast_ipv6 distance=240 dst-address=2401:a860:1000::/36
/ipv6 route add blackhole comment=global_anycast_ipv6 distance=240 dst-address=2401:a860::/36
/ip service set ftp address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set ssh address=95.217.216.149/32,2a01:4f9:c012:fbcd::/64,119.76.35.40/32,160.22.181.181/32,158.140.0.0/16,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,172.104.169.64/32,171.101.163.225/32,95.217.134.129/32
/ip service set telnet address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set www address=10.0.0.0/8,192.168.0.0/16,172.31.0.0/16
/ip service set www-ssl address=10.0.0.0/8,192.168.88.0/24
/ip service set winbox address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set api address=160.22.181.181/32
/ip service set api-ssl address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ipv6 address add address=2403:5000:165:15::2 advertise=no interface=SG-HGC-IPTx-vlan2520
/ipv6 address add address=2402:b740:15:388:a500:14:2108:1 advertise=no interface=BKK-AMS-IX-vlan911
/ipv6 address add address=2001:df0:296:0:a500:14:2108:1 advertise=no interface=HK-AMS-IX-vlan3994
/ipv6 address add address=fd00:dead:beef::20/128 advertise=no interface=lo
/ipv6 address add address=2407:9540:111:7::2/126 advertise=no interface=HK-HGC-IPTx-backup-vlan2517
/ipv6 address add address=fd00:dead:beef:30::2/126 advertise=no interface=BKK00-LAG
/ipv6 address add address=2401:a860:1181::20/128 advertise=no comment=BKK20-GUA-SG-OUT interface=lo
/ipv6 address add address=fd00:dead:beef::1/127 advertise=no comment=EDGE-BKK00-LUA interface=BKK00-LAG
/ipv6 address add address=fd00:dead:beef:2010::/127 advertise=no comment="ULA P2P to BKK10" interface=BKK10-LAG
/ipv6 address add address=fd00:dead:beef:2050::/127 advertise=no comment="ULA P2P to BKK50" interface=BKK50-LAG
/ipv6 address add address=2401:a860:1181:2010::/127 advertise=no comment="Global P2P to BKK10" interface=BKK10-LAG
/ipv6 address add address=2401:a860:1181:2050::/127 advertise=no comment="Global P2P to BKK50" interface=BKK50-LAG
/ipv6 address add address=fd00:155:206::/127 advertise=no disabled=yes interface=BKK06-LAG
/ipv6 address add address=fd00:155:207::/127 advertise=no disabled=yes interface=BKK07-LAG
/ipv6 address add address=fd00:155:208::/127 advertise=no disabled=yes interface=BKK08-LAG
/ipv6 address add address=fd00:155:208::/32 advertise=no interface=qnq-400-100
/ipv6 address add address=fd00:155:207::/32 advertise=no interface=qnq-400-100
/ipv6 address add address=fd00:155:206::/32 advertise=no interface=qnq-400-100
/ipv6 address add address=fd00:155::20/32 advertise=no interface=qnq-400-100
/ipv6 firewall address-list add address=2001:df5:b881::/64 list=bknix-ipv6
/ipv6 firewall address-list add address=::/128 comment="RFC 4291: Unspecified address" list=ipv6-bogons
/ipv6 firewall address-list add address=::1/128 comment="RFC 4291: Loopback address" list=ipv6-bogons
/ipv6 firewall address-list add address=::ffff:0.0.0.0/96 comment="RFC 4291: IPv4-mapped IPv6 addresses" list=ipv6-bogons
/ipv6 firewall address-list add address=100::/64 comment="RFC 6666: Discard prefix" list=ipv6-bogons
/ipv6 firewall address-list add address=2001:10::/28 comment="RFC 4843: ORCHID" list=ipv6-bogons
/ipv6 firewall address-list add address=fc00::/7 comment="RFC 4193: Unique local address" list=ipv6-bogons
/ipv6 firewall address-list add address=fe80::/10 comment="RFC 4291: Link-local address" list=ipv6-bogons
/ipv6 firewall address-list add address=ff00::/8 comment="RFC 4291: Multicast" list=ipv6-bogons
/ipv6 firewall address-list add address=2001:df5:b881::168/128 list=bknix-rotko-address
/ipv6 firewall address-list add address=2401:a860::/32 list=ipv6-apnic-rotko
/ipv6 firewall address-list add address=2402:b740:15::/48 list=amsix-ipv6
/ipv6 firewall address-list add address=2401:a860::/32 comment="Our IPv6 block" list=valid-src-addresses-v6
/ipv6 firewall address-list add address=fc00::/7 comment="ULA addresses" list=valid-src-addresses-v6
/ipv6 firewall address-list add address=2001:df5:b881::/48 comment="BKNIX network" list=valid-src-addresses-v6
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HGC network" list=valid-src-addresses-v6
/ipv6 firewall address-list add address=2001:deb:0:4070::/64 comment="RPKI network" list=valid-src-addresses-v6
/ipv6 firewall address-list add address=2402:b740:15:388::/64 comment="AMS-IX Bangkok IPv6 range" list=valid-src-addresses-v6
/ipv6 firewall address-list add comment="Default route for iBGP" list=all-addresses-v6
/ipv6 firewall address-list add address=2001:df5:b881::/48 comment="BKNIX IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX EU IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2001:df0:296::/48 comment="AMS-IX HK IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2402:b740:15::/48 comment="AMS-IX BKK IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2401:a860::/32 comment="Our Main IPv6 block" list=our-networks-v6
/ipv6 firewall address-list add address=2403:5000:165:15::/64 comment="SG HGC IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HK HGC IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2407:9540:111:7::/64 comment="HK HGC Backup IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2407:9540:111:8::/64 comment="SG HGC Backup IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2401:a860:181::/48 comment="Global Loopback Range" list=our-networks-v6
/ipv6 firewall address-list add address=2401:a860:cafe::/64 comment="Management Range" list=our-networks-v6
/ipv6 firewall address-list add address=fd00:dead:beef::/48 comment="Internal ULA Infrastructure" list=our-networks-v6
/ipv6 firewall address-list add address=2001:df5:b881::168/128 comment="BKNIX Loopback" list=our-networks-v6
/ipv6 firewall address-list add address=2001:7f8:1:0:a500:14:2108:1/128 comment="AMS-IX Router ID" list=our-networks-v6
/ipv6 firewall address-list add address=2402:b740:15:388:a500:14:2108:1/128 comment="BKK AMS-IX Router ID" list=our-networks-v6
/ipv6 firewall address-list add address=2001:df0:296:0:a500:14:2108:1/128 comment="HK AMS-IX Router ID" list=our-networks-v6
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:df5:b881::/64 comment="BKNIX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HGC IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2401:a860:181::10/128 comment="EU-AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:30::/126 comment="BKK20 iBGP" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:40::/126 comment="BKK10 iBGP" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:50::/126 comment="BKK50 iBGP" list=bgp-peers
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
/ipv6 firewall address-list add address=2402:b740:15:388::/64 comment="AMS-IX Bangkok IPv6 range" list=our-networks-v6
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
/ipv6 firewall address-list add address=2001:7f8:1:0:a500:14:2108:1/128 comment="AMS-IX EU - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=2402:b740:15:388:a500:14:2108:1/128 comment="AMS-IX BKK - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=2001:df0:296:0:a500:14:2108:1/128 comment="AMS-IX HK - exchange only" list=exchange-only-loopbacks
/ipv6 firewall address-list add address=fd00:155:106::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=fd00:155:107::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=fd00:155:108::/64 list=ibgp-block-gw-v6
/ipv6 firewall address-list add address=2401:a860:1181::/48 list=bkk50-rotko-ranges-v6
/ipv6 firewall address-list add address=2401:a860:169::/64 list=bkk50-rotko-ranges-v6
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-BAN disabled=yes dst-address=2402:b740:15::/48 port=179 protocol=tcp src-address=2402:b740:15::/48
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-HK disabled=yes dst-address=2001:df0:296::/64 port=179 protocol=tcp src-address=2001:df0:296::/64
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-BKK disabled=yes dst-address=2402:b740:15:388::/64 port=179 protocol=tcp src-address=2402:b740:15:388::/64
/ipv6 firewall raw add action=drop chain=prerouting comment=BGP-MAINTENANCE-MODE-AMSIX-HK disabled=yes dst-address=2001:df0:296::/64 port=179 protocol=tcp src-address=2001:df0:296::/64
/ipv6 firewall raw add action=drop chain=prerouting comment="drop SNMP from WAN" dst-port=161,162 in-interface-list=WAN protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting comment="WArNiNGGGG DANGERZONEEEE - Enable for transparent mode" disabled=yes
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow RPKI validation" dst-port=323,4323 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow RPKI validators" dst-address-list=rpki-validators
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow RPKI validators" src-address-list=rpki-validators
/ipv6 firewall raw add action=drop chain=prerouting comment="Block spoofed exchange loopbacks from WAN" in-interface-list=WAN src-address-list=exchange-only-loopbacks
/ipv6 firewall raw add action=drop chain=prerouting comment="Block spoofed our ip ranges from WAN" in-interface-list=WAN src-address-list=ipv6-apnic-rotko
/ipv6 firewall raw add action=drop chain=prerouting comment="block inbound RAs" icmp-options=134:0 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=output comment="block outbound RAs" icmp-options=134:0 out-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=jump chain=prerouting comment="Check TCP flags" jump-target=bad_tcp protocol=tcp
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP port 0 drop" port=0 protocol=tcp
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: no flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+SYN" protocol=tcp tcp-flags=fin,syn
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+RST" protocol=tcp tcp-flags=fin,rst
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN without ACK" protocol=tcp tcp-flags=fin,!ack
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: FIN+URG" protocol=tcp tcp-flags=fin,urg
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: SYN+RST" protocol=tcp tcp-flags=syn,rst
/ipv6 firewall raw add action=drop chain=bad_tcp comment="TCP flag: RST+URG" protocol=tcp tcp-flags=rst,urg
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
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow internal ULA infrastructure" dst-address=fd00:dead:beef::/48
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow internal ULA infrastructure" src-address=fd00:dead:beef::/48
/ipv6 firewall raw add action=accept chain=prerouting comment="AF-RPKI inbound (v6)" protocol=tcp src-address=2001:deb::/48
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow IPv6 fragments" headers=frag
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow OSPFv3" protocol=ospf
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow BFD" dst-port=3784,4784 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow BGP to peers" dst-address-list=bgp-peers-v6 dst-port=179 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow BGP from peers" protocol=tcp src-address-list=bgp-peers-v6 src-port=179
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow DNS" dst-port=53 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow DNS" dst-port=53 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow SSH" dst-port=22 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow NTP" dst-port=123 protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop packets with extension header types 0, 43" headers=hop,route:contains
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop UDP port 0" port=0 protocol=udp
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop hop-limit=1 from WAN" hop-limit=equal:1 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=accept chain=prerouting comment="Accept all link-local ICMPv6" in-interface-list=WAN src-address=fe80::/10
/ipv6 firewall raw add action=jump chain=prerouting comment="Jump to bogon handler" in-interface-list=WAN jump-target=bogon-drop src-address-list=bogons-v6
/ipv6 firewall raw add action=drop chain=bogon-drop comment="Drop bogons"
/ipv6 firewall raw add action=accept chain=prerouting comment="FINAL ACCEPT"
/ipv6 firewall raw add action=log chain=bogon-drop disabled=yes limit=1,5:packet log-prefix=BOGON:
/ipv6 nd set [ find default=yes ] ra-lifetime=none
/ipv6 nd add disabled=yes interface=AMSIX-LAG
/routing bgp connection add afi=ipv6 disabled=no input.limit-process-routes-ipv6=3000000 local.role=ebgp multihop=no name=HGC-SG-PRIMARY-v6 output.redistribute=connected,static,bgp remote.address=2403:5000:165:15::1 .as=9304 routing-table=main templates=HGC-SG-v6
/routing bgp connection add afi=ip as=142108 disabled=no input.limit-process-routes-ipv4=3000000 local.role=ebgp multihop=no name=HGC-SG-PRIMARY-v4 remote.address=118.143.234.73 .as=9304 routing-table=main templates=HGC-SG-v4
/routing bgp connection add afi=ip as=142108 input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp multihop=yes name=AMSIX-HE-TH-v4 remote.address=103.100.140.44 .as=6939 routing-table=main templates=AMSIX-BAN-v4
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-HE-TH-v6 remote.address=2402:b740:15:388:0:a500:6939:1 .as=6939 routing-table=main templates=AMSIX-BAN-v6
/routing bgp connection add afi=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp multihop=yes name=AMSIX-RS1-TH-v4 remote.address=103.100.140.251 .as=150388 routing-table=main templates=AMSIX-BAN-v4
/routing bgp connection add afi=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp multihop=yes name=AMSIX-RS2-TH-v4 remote.address=103.100.140.252 .as=150388 routing-table=main templates=AMSIX-BAN-v4
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-RS1-TH-v6 remote.address=2402:b740:15:388:a500:15:388:251 .as=150388 routing-table=main templates=AMSIX-BAN-v6
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-RS2-TH-v6 output.redistribute=connected,static,bgp remote.address=2402:b740:15:388:a500:15:388:252 .as=150388 routing-table=main templates=AMSIX-BAN-v6
/routing bgp connection add afi=ip input.limit-process-routes-ipv4=230000 local.address=103.247.139.76 .role=ebgp multihop=no name=AMSIX-HE-HK-v4 remote.address=103.247.139.6 .as=6939 routing-table=main templates=AMSIX-HK-v4
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp multihop=no name=AMSIX-HE-HK-v6 remote.address=2001:df0:296::a500:6939:1 .as=6939 routing-table=main templates=AMSIX-HK-v6
/routing bgp connection add afi=ipv6 disabled=no input.limit-process-routes-ipv4=3000000 .limit-process-routes-ipv6=3000000 local.address=2407:9540:111:7::2 .role=ebgp name=HGC-HK-BACKUP-v6 remote.address=2407:9540:111:7::1 .as=142435 routing-table=main templates=IPTX-HGC-TH-HK-v6
/routing bgp connection add afi=ip disabled=no input.limit-process-routes-ipv4=3000000 .limit-process-routes-ipv6=3000000 local.role=ebgp name=HGC-HK-BACKUP-v4 remote.address=103.168.174.177 .as=142435 routing-table=main templates=IPTX-HGC-TH-HK-v4
/routing bgp connection add afi=ip input.limit-process-routes-ipv4=250000 local.address=103.247.139.76 .role=ebgp multihop=yes name=AMSIX-RS1-HK-v4 remote.address=103.247.139.125 .as=58560 routing-table=main templates=AMSIX-HK-v4
/routing bgp connection add afi=ip input.limit-process-routes-ipv4=250000 local.address=103.247.139.76 .role=ebgp multihop=yes name=AMSIX-RS2-HK-v4 remote.address=103.247.139.126 .as=58560 routing-table=main templates=AMSIX-HK-v4
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-RS1-HK-v6 remote.address=2001:df0:296::a505:8560:1 .as=58560 routing-table=main templates=AMSIX-HK-v6
/routing bgp connection add afi=ipv6 input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-RS2-HK-v6 remote.address=2001:df0:296::a505:8560:2 .as=58560 routing-table=main templates=AMSIX-HK-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=250000 local.address=103.247.139.76 .role=ebgp multihop=yes name=AMSIX-CLOUDFLARE-HK-v4 remote.address=103.247.139.50 .as=13335 routing-table=main templates=AMSIX-HK-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp multihop=yes name=AMSIX-CLOUDFLARE-HK-v6 remote.address=2001:df0:296::a501:3335:2 .as=13335 routing-table=main templates=AMSIX-HK-v6
/routing bgp connection add disabled=no input.filter=IBGP-IN-v4 .limit-process-routes-ipv4=2000000 local.address=10.155.255.2 .role=ibgp name=IBGP-ROTKO-BKK00-v4 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v4 .keep-sent-attributes=yes .redistribute=connected,static,bgp remote.address=10.155.255.4 .as=142108 routing-table=main templates=IBGP-ROTKO-v4
/routing bgp connection add afi=ipv6 disabled=no input.filter=IBGP-IN-v6 .limit-process-routes-ipv6=2000000 local.address=fd00:dead:beef::20 .role=ibgp name=IBGP-ROTKO-BKK00-v6 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v6 .keep-sent-attributes=yes .redistribute=connected,static,bgp remote.address=fd00:dead:beef::100 .as=142108 routing-table=main templates=IBGP-ROTKO-v6
/routing bgp connection add disabled=no local.address=10.155.206.0 .role=ibgp-rr name=rr-client-bkk06-v4 remote.address=10.155.206.1 .as=142108 templates=RR-CLIENTS
/routing bgp connection add disabled=no local.address=10.155.207.0 .role=ibgp-rr name=rr-client-bkk07-v4 remote.address=10.155.207.1 .as=142108 templates=RR-CLIENTS
/routing bgp connection add disabled=no local.address=10.155.208.0 .role=ibgp-rr name=rr-client-bkk08-v4 remote.address=10.155.208.1 .as=142108 templates=RR-CLIENTS
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:206:: .role=ibgp-rr name=rr-client-bkk06-v6 remote.address=fd00:155:206::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:207:: .role=ibgp-rr name=rr-client-bkk07-v6 remote.address=fd00:155:207::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ipv6 disabled=no local.address=fd00:155:208:: .role=ibgp-rr name=rr-client-bkk08-v6 remote.address=fd00:155:208::1 .as=142108 templates=RR-CLIENTS-v6
/routing bgp connection add afi=ip input.filter=IBGP-IN-v4 local.address=10.155.255.2 .role=ibgp multihop=yes name=ibgp-bkk50-v4 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v4 .redistribute=connected,static,bgp remote.address=10.155.255.3 .as=142108 templates=IBGP-ROTKO-v4
/routing bgp connection add afi=ipv6 input.filter=IBGP-IN-v6 local.address=fd00:dead:beef::20 .role=ibgp multihop=yes name=ibgp-bkk50-v6 nexthop-choice=force-self output.filter-chain=IBGP-OUT-v6 .redistribute=connected,static,bgp remote.address=fd00:dead:beef::50 .as=142108 templates=IBGP-ROTKO-v6
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
/routing filter rule add chain=IBGP-IN-v4 rule="if (dst in bkk50-rotko-ranges && gw == 10.155.255.3) { set distance 100; set bgp-local-pref 150; accept; }"
/routing filter rule add chain=IBGP-IN-v6 rule="if (dst in bkk50-rotko-ranges-v6 && gw == fd00:dead:beef::50) { set distance 100; set bgp-local-pref 150; accept; }"
/routing filter rule add chain=IBGP-OUT-v6 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=IBGP-OUT-v4 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-EU-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-EU-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (gw in ibgp-block-gw-v4) { reject; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list bknix-communities) { set bgp-local-pref 200; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-ban-communities) { set bgp-local-pref 190; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-th-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-th-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list hgc-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=IBGP-IN-v4 rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 100; }"
/routing filter rule add chain=IBGP-IN-v4 rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="set bgp-med 50; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="set bgp-med 50; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-BAN-OUT-v4 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="set bgp-med 75; set bgp-path-prepend 1; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="set bgp-med 75; set bgp-path-prepend 1; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="RPKI validation" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Reject RPKI invalid routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Discard default route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Discard overly specific prefixes" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="RPKI validation" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Reject RPKI invalid routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Discard default route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Discard overly specific prefixes" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard IPv4 bogons" rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="RPKI validation" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Reject RPKI invalid routes" rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard default route" rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard IPv6 bogons" rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard overly specific IPv6 prefixes" rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="RPKI validation" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Reject RPKI invalid routes" rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard default route" rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Accept route v4" rule="set bgp-large-communities amsix-ban-communities; set bgp-local-pref 190; accept"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Accept route v4" rule="set bgp-large-communities hgc-sg-communities; set bgp-local-pref 140; accept"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Accept route v4" rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Accept route v4" rule="set bgp-large-communities hgc-th-hk-communities; set bgp-local-pref 140; accept"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Accept route v6" rule="set bgp-large-communities amsix-ban-communities; set bgp-local-pref 190; accept"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Accept route v6" rule="set bgp-large-communities hgc-sg-communities; set bgp-local-pref 140; accept"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Accept route v6" rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Accept route v6" rule="set bgp-large-communities hgc-th-hk-communities; set bgp-local-pref 140; accept"
/routing filter rule add chain=graceful-shutdown rule="set bgp-communities graceful-shutdown; set bgp-local-pref 0; accept"
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
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=too-specific rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=bogons rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=default rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=RPKI-invalid rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v4 comment=accept-all disabled=yes rule=accept
/routing filter rule add chain=ROUTEVIEWS-IN-v4 comment=discard rule=reject
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=too-specific rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=bogons rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=default rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=RPKI-invalid rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=ROUTEVIEWS-OUT-v6 comment=accept-all rule="accept;"
/routing filter rule add chain=ROUTEVIEWS-IN-v6 comment=discard rule="reject;"
/routing filter rule add chain=graceful-shutdown-out rule="set bgp-communities 65535:65281; accept"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (dst in 10.155.0.0/17) { reject; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (dst in 10.155.128.0/17) { reject; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="if (bgp-network) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v4 rule="reject;"
/routing filter rule add chain=RR-CLIENT-IN-v4 disabled=yes rule="if (gw in ibgp-block-gw-v4) { reject; }"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="if (bgp-network) { accept; }"
/routing filter rule add chain=RR-CLIENT-IN-v6 disabled=yes rule="if (gw in ibgp-block-gw-v6) { reject; }"
/routing filter rule add chain=RR-CLIENT-OUT-v6 rule="reject;"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="if (dst in 10.155.0.0/17) { reject;} "
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="if (dst in ipv4-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-IN-v4 rule="reject;"
/routing filter rule add chain=RR-CLIENT-IN-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing filter rule add chain=RR-CLIENT-IN-v6 rule="reject;"
/routing ospf interface-template add area=backbone-v6 comment=BKK20-LO-v6 disabled=no networks=fd00:dead:beef::20
/routing ospf interface-template add area=backbone comment=BKK20-LO-v4 disabled=no networks=10.155.255.2
/routing ospf interface-template add area=backbone-v6 comment=GW-BKK50-LAG-v6 disabled=no networks=fd00:dead:beef:2050::/127
/routing ospf interface-template add area=backbone comment=GW-BKK50-LAG-v4 disabled=no networks=172.16.20.0/30
/routing ospf interface-template add area=backbone-v6 comment=EDGE-BKK00-LAG-v6 disabled=no networks=fd00:dead:beef:30::2/126
/routing ospf interface-template add area=backbone comment=EDGE-BKK00-LAG-v4 disabled=no networks=172.16.30.0/30
/routing ospf interface-template add area=backbone-v6 comment=GW-BKK10-LAG-v6 disabled=no networks=fd00:dead:beef:1020::1/127
/routing ospf interface-template add area=backbone comment=GW-BKK10-LAG-v4 disabled=no networks=172.16.210.0/31
/routing ospf interface-template add area=backbone-v6 comment=EDGE-BKK00-v6 disabled=no networks=fd00:dead:beef::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK10" disabled=no networks=2401:a860:1181:1020::1/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK50" disabled=no networks=2401:a860:1181:2050::/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK10" disabled=no networks=2401:a860:1181:1020::1/127
/routing ospf interface-template add area=backbone-v6 comment="Global P2P BKK50" disabled=no networks=2401:a860:1181:2050::/127
/routing ospf interface-template add area=backbone-v6 comment="ULA Loopback" disabled=no networks=fd00:dead:beef::20/128 passive
/routing rpki add address=203.159.70.26 comment="Routinator IPv4 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=2001:deb:0:4070::26 comment="Routinator IPv6 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=203.159.70.36 comment="StayRTR IPv4 Secondary" group=rpki.bknix.net port=4323
/routing rpki add address=2001:deb:0:4070::36 comment="StayRTR IPv6 Secondary" group=rpki.bknix.net port=4323
/snmp set enabled=yes trap-version=3
/system clock set time-zone-autodetect=no time-zone-name=Asia/Bangkok
/system identity set name=bkk20
/system logging add action=disk topics=bgp,!debug
/system logging add topics=interface,warning
/system logging add action=disk topics=firewall,warning
/system logging add action=disk topics=firewall,error
/system logging add topics=account,critical
/system logging add topics=error,!debug
/system logging add topics=firewall,info,!debug
/system logging add topics=firewall,!debug
/system logging add topics=route,bgp,debug
/system ntp client set enabled=yes
/system ntp client servers add address=0.th.pool.ntp.org
/system ntp client servers add address=0.asia.pool.ntp.org
/system ntp client servers add address=1.asia.pool.ntp.org
/system package update set channel=testing
/system routerboard settings set enter-setup-on=delete-key
/system scheduler add interval=1h name=sync-ntp-list on-event="/system script run \"update-ntp-clients\"" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-06-02 start-time=17:50:20
/system scheduler add name=bcp214-start on-event="/system script run bcp214-start" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=17:00:00
/system scheduler add name=bcp214-block on-event="/system script run bcp214-block" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=17:00:10
/system scheduler add disabled=yes name=bcp214-restore on-event="/system script run bcp214-restore" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=17:15:00
/system scheduler add name=bcp214-downgrade on-event="/system script run bcp214-downgrade" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=2025-08-15 start-time=17:01:00
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
/system watchdog set watchdog-timer=no
