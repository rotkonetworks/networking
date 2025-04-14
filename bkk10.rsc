# 2025-04-14 20:15:38 by RouterOS 7.18.2
# software id = SF1Q-LGYJ
#
# model = CCR2116-12G-4S+
# serial number = HF609CW8B20
/interface bridge add comment="bridge for local network" name=bridge_local vlan-filtering=yes
/interface ethernet set [ find default-name=ether11 ] comment=bkk60-switch
/interface ethernet set [ find default-name=sfp-sfpplus1 ] advertise=10G-baseCR comment=bkk50-router
/interface ethernet set [ find default-name=sfp-sfpplus2 ] auto-negotiation=no comment=HGC-HK-UPLINK
/interface ethernet set [ find default-name=sfp-sfpplus3 ] advertise=10G-baseCR comment=bkk20-edge
/interface ethernet set [ find default-name=sfp-sfpplus4 ] comment=BKNIX-TH-UPLINK
/interface wireguard add listen-port=51820 mtu=1420 name=wg_rotko
/interface bonding add mode=802.3ad mtu=1514 name=AMSIX-LAG slaves=sfp-sfpplus2 transmit-hash-policy=layer-3-and-4
/interface bonding add comment=bkk20-sfp5 lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus3 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=bkk50-sfp1 lacp-rate=1sec mode=802.3ad name=BKK50-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
/interface bonding add mode=802.3ad name=BKNIX-LAG slaves=sfp-sfpplus4 transmit-hash-policy=layer-3-and-4
/interface vlan add interface=AMSIX-LAG name=EU-AMS-IX-vlan3995 vlan-id=3995
/interface vlan add interface=AMSIX-LAG name=HK-HGC-IPTx-vlan2519 vlan-id=2519
/interface vlan add interface=AMSIX-LAG name=SG-HGC-IPTx-backup-vlan2518 vlan-id=2518
/interface bonding add comment="to be removed and just use slave directly without bond" mode=active-backup name=UPLINK-HGC-IPTX-HK-LAG primary=HK-HGC-IPTx-vlan2519 slaves=HK-HGC-IPTx-vlan2519 transmit-hash-policy=layer-3-and-4
/interface ethernet switch port set 1 limit-unknown-multicasts=yes limit-unknown-unicasts=yes
/interface ethernet switch port set 3 limit-unknown-multicasts=yes limit-unknown-unicasts=yes
/interface list add name=local
/interface list add name=WAN
/interface list add name=WG
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/ip pool add name=dhcp_pool ranges=192.168.69.50-192.168.69.70
/ip smb users set [ find default=yes ] disabled=yes
/port set 0 name=serial0
/routing bgp template add address-families=ipv6 as=142108 input.filter=iBGP-IN multihop=yes name=IBGP-v6 nexthop-choice=default output.filter-chain=iBGP-OUT .network=ipv6-apnic-rotko router-id=10.155.255.1
/routing bgp template add address-families=ip as=142108 input.filter=iBGP-IN multihop=yes name=IBGP-v4 nexthop-choice=default output.filter-chain=iBGP-OUT .network=ipv4-apnic-rotko router-id=10.155.255.1
/routing id add id=10.155.255.1 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add comment="originate-default=always configured since we receive full BGP tables not default routes from transit/IXPs" disabled=no name=ospf-instance-v2 originate-default=always router-id=10.155.255.1
/routing ospf instance add comment="originate-default=always configured since we receive full BGP tables not default routes from transit/IXPs" disabled=no name=ospf-instance-v3 originate-default=always router-id=10.155.255.1 version=3
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/routing table add fib name=rt_latency
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=BKNIX-IN-v4 name=BKNIX-v4 output.as-override=no .filter-chain=BKNIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=BKNIX-IN-v6 name=BKNIX-v6 output.as-override=no .filter-chain=BKNIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-HK-IN-v4 multihop=yes name=IPTX-HGC-HK-v4 output.as-override=no .filter-chain=HGC-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-HK-IN-v6 multihop=yes name=IPTX-HGC-HK-v6 output.as-override=no .filter-chain=HGC-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=AMSIX-IN-v4 name=AMSIX-v4 output.as-override=no .filter-chain=AMSIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=AMSIX-IN-v6 name=AMSIX-v6 output.as-override=no .filter-chain=AMSIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-SG-IN-v6 name=HGC-TH-SG-v6 output.as-override=no .filter-chain=HGC-SG-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-SG-IN-v4 name=HGC-TH-SG-v4 output.as-override=no .filter-chain=HGC-SG-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.255.255.1 routing-table=main
/user group add name=mktxp_group policy=ssh,read,api,!local,!telnet,!ftp,!reboot,!write,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=vlan out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface-list=WAN
/interface bridge filter add action=drop chain=forward out-interface-list=WAN
/interface bridge port add bridge=bridge_local interface=ether1 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether2 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether3 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether4 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether5 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether6 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether7 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether8 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether9 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether10 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether11 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether12 internal-path-cost=10 path-cost=10
/interface bridge port add bridge=bridge_local interface=ether13 internal-path-cost=10 path-cost=10
/interface ethernet switch l3hw-settings set autorestart=yes ipv6-hw=yes
/ip firewall connection tracking set enabled=no loose-tcp-tracking=no udp-timeout=10s
/ip neighbor discovery-settings set discover-interval=1m mode=rx-only
/ip settings set secure-redirects=no send-redirects=no tcp-syncookies=yes
/ipv6 settings set accept-redirects=no accept-router-advertisements=no max-neighbor-entries=8192 soft-max-neighbor-entries=8191
/interface ethernet switch set 0 l3-hw-offloading=yes qos-hw-offloading=yes
/interface list member add interface=bridge_local list=local
/interface list member add interface=ether1 list=local
/interface list member add interface=ether2 list=local
/interface list member add interface=lo list=local
/interface list member add interface=sfp-sfpplus1 list=local
/interface list member add interface=sfp-sfpplus3 list=local
/interface list member add interface=ether3 list=local
/interface list member add interface=ether4 list=local
/interface list member add interface=ether5 list=local
/interface list member add interface=ether6 list=local
/interface list member add interface=ether7 list=local
/interface list member add interface=ether8 list=local
/interface list member add interface=ether9 list=local
/interface list member add interface=ether10 list=local
/interface list member add interface=ether11 list=local
/interface list member add interface=ether12 list=local
/interface list member add interface=ether13 list=local
/interface list member add interface=AMSIX-LAG list=WAN
/interface list member add interface=BKNIX-LAG list=WAN
/interface list member add interface=HK-HGC-IPTx-vlan2519 list=WAN
/interface list member add interface=sfp-sfpplus2 list=WAN
/interface list member add interface=sfp-sfpplus4 list=WAN
/interface list member add interface=EU-AMS-IX-vlan3995 list=WAN
/interface list member add interface=BKK20-LAG list=local
/interface list member add interface=BKK50-LAG list=local
/interface list member add interface=SG-HGC-IPTx-backup-vlan2518 list=WAN
/interface ovpn-server server add mac-address=FE:67:97:3A:AC:2F name=ovpn-server1
/interface wireguard peers add allowed-address=172.31.0.1/32 interface=wg_rotko name=laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.20/32 interface=wg_rotko name=bkk20 public-key="/09ofEbIM1qjlq7xM/R0KfJMQ8R/UR9aHaph70FTp30="
/interface wireguard peers add allowed-address=172.31.0.2/32 interface=wg_rotko name=gatus public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.31.0.3/32 interface=wg_rotko name=amdnuc public-key="IlZR7z5LVE6BKwkApq+VTvXRGaOp0hvmKSSrgi1R/V4="
/interface wireguard peers add allowed-address=172.31.0.50/32 endpoint-address=172.16.10.2 endpoint-port=51820 interface=wg_rotko name=bkk50 public-key="HSEVRjXj7x7jSVy8A9YQducW6BNme/a19/o5CA/KrUI="
/ip address add address=192.168.88.10/24 comment=bkk10-mgmt interface=bridge_local network=192.168.88.0
/ip address add address=203.159.68.168/23 comment=BKNIX-V4 interface=BKNIX-LAG network=203.159.68.0
/ip address add address=118.143.211.186/29 interface=HK-HGC-IPTx-vlan2519 network=118.143.211.184
/ip address add address=172.31.0.10/16 interface=wg_rotko network=172.31.0.0
/ip address add address=10.25.1.126/24 interface=EU-AMS-IX-vlan3995 network=10.25.1.0
/ip address add address=172.16.0.1/30 interface=BKK20-LAG network=172.16.0.0
/ip address add address=172.16.10.1/30 interface=BKK50-LAG network=172.16.10.0
/ip address add address=10.155.255.1 interface=lo network=10.155.255.1
/ip address add address=160.22.181.177 interface=lo network=160.22.181.177
/ip address add address=80.249.212.139/21 interface=EU-AMS-IX-vlan3995 network=80.249.208.0
/ip address add address=103.168.174.182/30 interface=SG-HGC-IPTx-backup-vlan2518 network=103.168.174.180
/ip arp add address=192.168.69.201 interface=bridge_local mac-address=E4:5F:01:EA:75:3E
/ip dns set cache-max-ttl=1d cache-size=4096KiB max-concurrent-queries=50 max-concurrent-tcp-sessions=10 max-udp-packet-size=512 servers=9.9.9.9,1.1.1.1
/ip firewall address-list add address=10.0.0.0/8 list=internal-ipv4
/ip firewall address-list add address=192.168.88.0/24 list=mgmt-ipv4
/ip firewall address-list add address=160.22.180.0/24 list=ibp-anycast-ipv4
/ip firewall address-list add address=160.22.181.0/24 list=rotko-unicast-ipv4
/ip firewall address-list add address=203.159.68.0/23 list=bknix-ipv4
/ip firewall address-list add address=203.159.68.168 list=bknix-rotko-address
/ip firewall address-list add address=160.22.180.0/23 list=ipv4-apnic-rotko
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
/ip firewall address-list add address=10.155.255.1 list=bgp-loopback-ips
/ip firewall address-list add address=80.249.208.0/21 comment="AMS-IX IXP Range" list=bgp-peers
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX IXP Range" list=bgp-peers
/ip firewall address-list add address=118.143.211.184/29 comment="HGC IXP Range" list=bgp-peers
/ip firewall address-list add address=10.25.1.0/24 comment="EU-AMS-IX IXP Range" list=bgp-peers
/ip firewall address-list add address=172.16.0.0/30 comment="BKK20 IXP Range" list=bgp-peers
/ip firewall address-list add address=172.16.10.0/30 comment="BKK50 IXP Range" list=bgp-peers
/ip firewall address-list add address=10.155.255.0/24 list=ROTKO-LOCAL-v4
/ip firewall address-list add address=0.0.0.0/0 list=all-addresses
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA block" list=our-networks
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX network" list=our-networks
/ip firewall address-list add address=118.143.211.184/29 comment="HK-HGC IPv4" list=our-networks
/ip firewall address-list add address=118.143.234.72/29 comment="SG-HGC IPv4" list=our-networks
/ip firewall address-list add address=103.168.174.176/29 comment="HK Backup Range" list=our-networks
/ip firewall address-list add address=103.168.174.180/30 comment="SG Backup Range" list=our-networks
/ip firewall address-list add address=103.100.140.0/24 comment="BKK AMS-IX" list=our-networks
/ip firewall address-list add address=103.247.139.0/24 comment="HK AMS-IX" list=our-networks
/ip firewall address-list add address=80.249.208.0/21 comment="EU AMS-IX" list=our-networks
/ip firewall address-list add address=172.16.0.0/16 comment="Internal Router Links" list=our-networks
/ip firewall address-list add address=172.31.0.0/16 comment="WG Network" list=our-networks
/ip firewall address-list add address=10.155.255.0/24 comment="Loopback Network" list=our-networks
/ip firewall address-list add address=203.159.70.0/23 comment="RPKI Network" list=our-networks
/ip firewall raw add action=accept chain=prerouting comment=wg_rotko src-address=172.31.0.0/16
/ip firewall raw add action=accept chain=prerouting comment="mikrotik monitoring" dst-address=160.22.181.181 dst-port=8728 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="Enable for transparent mode"
/ip firewall raw add action=drop chain=prerouting comment="Drop bad src IPs" src-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad dst IPs" dst-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad src IPs" src-address-list=bad_src_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop bad dst IPs" dst-address-list=bad_dst_ipv4
/ip firewall raw add action=drop chain=prerouting comment="Drop non-global from WAN" in-interface-list=WAN src-address-list=not_in_internet
/ip firewall raw add action=drop chain=prerouting comment="Drop local if not from LAN" disabled=yes in-interface-list=local src-address-list=!lan_subnets
/ip firewall raw add action=drop chain=prerouting comment="Drop bad UDP" port=0 protocol=udp
/ip firewall raw add action=drop chain=prerouting comment="Drop DHCP discover on LAN" dst-address=255.255.255.255 dst-port=67 in-interface-list=local protocol=udp src-address=0.0.0.0 src-port=68
/ip firewall raw add action=jump chain=prerouting comment="ICMP processing" jump-target=icmp protocol=icmp
/ip firewall raw add action=jump chain=prerouting comment="TCP flag filtering" jump-target=bad_tcp protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="Accept from LAN" in-interface-list=local
/ip firewall raw add action=accept chain=prerouting comment="Allow BGP from IX peers" dst-address-list=bgp-loopback-ips dst-port=179 protocol=tcp src-address-list=bgp-peers
/ip firewall raw add action=drop chain=prerouting comment="Drop all other access to the loopback IPs" dst-address-list=bgp-loopback-ips
/ip firewall raw add action=accept chain=prerouting comment="Accept from WAN" in-interface-list=WAN
/ip firewall raw add action=drop chain=prerouting comment="Drop all other traffic"
/ip firewall raw add action=accept chain=icmp comment="Echo reply" icmp-options=0:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Net unreachable" icmp-options=3:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Host unreachable" icmp-options=3:1 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Protocol unreachable" icmp-options=3:2 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Port unreachable" icmp-options=3:3 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Fragmentation needed" icmp-options=3:4 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Echo request" icmp-options=8:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Time exceeded" icmp-options=11:0-255 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="Parameter problem" icmp-options=12:0 protocol=icmp
/ip firewall raw add action=drop chain=icmp comment="Drop other ICMP" protocol=icmp
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (fin+syn)" protocol=tcp tcp-flags=fin,syn
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (fin+rst)" protocol=tcp tcp-flags=fin,rst
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (fin,!ack)" protocol=tcp tcp-flags=fin,!ack
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (fin+urg)" protocol=tcp tcp-flags=fin,urg
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (syn+rst)" protocol=tcp tcp-flags=syn,rst
/ip firewall raw add action=drop chain=bad_tcp comment="Drop invalid TCP flags (rst+urg)" protocol=tcp tcp-flags=rst,urg
/ip firewall raw add action=drop chain=bad_tcp comment="Drop TCP port 0" port=0 protocol=tcp
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add blackhole distance=240 dst-address=160.22.181.0/23
/ip route add distance=220 gateway=172.16.0.2
/ipv6 route add blackhole dst-address=2401:a860::/32
/ipv6 route add distance=2 dst-address=2401:a860::/32 gateway=2001:df5:b881::1
/ipv6 route add dst-address=::/0
/ip service set telnet address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip service set ftp address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16 disabled=yes
/ip service set www address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16
/ip service set ssh address=95.217.216.149/32,2a01:4f9:c012:fbcd::/64,160.22.181.181/32,110.169.129.201/32,172.104.169.64/32,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12,171.101.163.225/32,158.140.0.0/16,95.217.134.129/32
/ip service set www-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16
/ip service set api address=160.22.181.181/32
/ip service set winbox address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16 disabled=yes
/ip service set api-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip smb shares set [ find default=yes ] directory=/pub
/ipv6 address add address=2001:df5:b881::168 comment=BKNIX-V6 interface=BKNIX-LAG
/ipv6 address add address=2401:a860:181::10/128 advertise=no interface=lo
/ipv6 address add address=2403:5000:171:138::2 comment="HK IPv6" interface=HK-HGC-IPTx-vlan2519
/ipv6 address add address=2401:a860:181::10 interface=AMSIX-LAG
/ipv6 address add address=fd00:dead:beef::1/126 advertise=no interface=BKK20-LAG
/ipv6 address add address=fd00:dead:beef:10::1/126 advertise=no interface=BKK50-LAG
/ipv6 address add address=2001:7f8:1:0:a500:14:2108:1 advertise=no interface=EU-AMS-IX-vlan3995
/ipv6 address add address=2407:9540:111:8::2/126 advertise=no interface=SG-HGC-IPTx-backup-vlan2518
/ipv6 address add address=fd00:dead:beef::10/128 advertise=no interface=lo
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
/ipv6 firewall address-list add address=fd00:dead:beef::/126 comment="BKK20 iBGP" list=bgp-peers
/ipv6 firewall address-list add address=fd00:dead:beef:10::/126 comment="BKK50 iBGP" list=bgp-peers
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
/ipv6 firewall raw add action=accept chain=prerouting comment="Enable for transparent mode"
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow from our networks" in-interface-list=WAN src-address-list=our-networks-v6
/ipv6 firewall raw add action=accept chain=prerouting comment="Rate limit ICMPv6" in-interface-list=WAN limit=50/5s,5 protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop excess ICMPv6" in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow essential protocols" dst-port=53,179 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow essential protocols" dst-port=53,123,3784,4784 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow OSPFv3" protocol=ospf
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop invalid TCP flags" in-interface-list=WAN protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop bogon/spoofed IPv6" in-interface-list=WAN src-address-list=bogons-v6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop spoofed packets" in-interface-list=WAN src-address-list=our-networks-v6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop Router Advertisements" icmp-options=134:0 in-interface-list=WAN protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop multicast" dst-address=ff00::/8 in-interface-list=WAN
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow remaining IPv6 traffic"
/ipv6 nd add disabled=yes interface=AMSIX-LAG
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=BKNIX-RS0-v4 remote.address=203.159.68.68 .as=63529 templates=BKNIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=BKNIX-RS1-v4 remote.address=203.159.68.69 .as=63529 templates=BKNIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS0-v6 remote.address=2001:df5:b881::68 .as=63529 templates=BKNIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS1-v6 remote.address=2001:df5:b881::69 .as=63529 templates=BKNIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=RouteViews-BKNIX-v4 remote.address=203.159.68.20 .as=6447 templates=BKNIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.role=ebgp name=RouteViews-BKNIX-v6 remote.address=2001:df5:b881::20 .as=6447 templates=BKNIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=210000 local.role=ebgp name=HE-BKNIX-v4 remote.address=203.159.68.135 .as=6939 templates=BKNIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=237000 local.role=ebgp name=HE-BKNIX-v6 remote.address=2001:df5:b881::135 .as=6939 templates=BKNIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=500000 local.address=2403:5000:171:138::2 .role=ebgp name=HGC-HK-IPTX-v6 remote.address=2403:5000:171:138::1 .as=9304 templates=IPTX-HGC-HK-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1500000 local.address=118.143.211.186 .role=ebgp name=HGC-HK-IPTX-v4 remote.address=118.143.211.185 .as=9304 templates=IPTX-HGC-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no hold-time=4m input.limit-process-routes-ipv6=2000000 keepalive-time=1m local.address=fd00:dead:beef::10 .role=ibgp multihop=yes name=IBGP-ROTKO-BKK20-v6 nexthop-choice=default output.filter-chain=iBGP-OUT .keep-sent-attributes=yes .redistribute=connected,bgp remote.address=fd00:dead:beef::20 .as=142108 templates=IBGP-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=2000000 local.address=10.155.255.1 .role=ibgp name=IBGP-ROTKO-BKK20-v4 nexthop-choice=default output.keep-sent-attributes=yes .redistribute=connected,bgp remote.address=10.155.255.2 .as=142108 templates=IBGP-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=AMSIX-RS1-v4 remote.address=80.249.208.255 .as=6777 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=AMSIX-RS2-v4 remote.address=80.249.209.0 .as=6777 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS1-v6 remote.address=2001:7f8:1::a500:6777:1 .as=6777 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS2-v6 remote.address=2001:7f8:1::a500:6777:2 .as=6777 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=AMSIX-MON1-v4 remote.address=80.249.208.1 .as=1200 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=AMSIX-MON2-v4 remote.address=80.249.209.1 .as=1200 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.address=80.249.212.139 .role=ebgp name=AMSIX-MON3-v4 remote.address=193.105.101.1 .as=1200 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON1-v6 remote.address=2001:7f8:1::a500:1200:1 .as=1200 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON2-v6 remote.address=2001:7f8:1::a500:1200:2 .as=1200 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON3-v6 remote.address=2001:7f8:86:1:0:a500:1200:1 .as=1200 templates=AMSIX-v6
/routing bgp connection add disabled=no local.role=ebgp name=AXERA-AMSIX-v4 remote.address=80.249.211.255 .as=34758 templates=AMSIX-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=500000 local.address=2407:9540:111:8::2 .role=ebgp name=HGC-SG-IPTX-BACKUP-v6 remote.address=2407:9540:111:8::1 .as=142435 templates=HGC-TH-SG-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=1500000 local.role=ebgp name=HGC-SG-IPTX-BACKUP-v4 remote.address=103.168.174.181 .as=142435 templates=HGC-TH-SG-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=Cloudflare-AMSIX-v4-1 remote.address=80.249.211.140 .as=13335 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=Cloudflare-AMSIX-v4-2 remote.address=80.249.210.118 .as=13335 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-1 remote.address=2001:7f8:1::a501:3335:1 .as=13335 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-2 remote.address=2001:7f8:1::a501:3335:2 .as=13335 templates=AMSIX-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=210000 local.address=80.249.212.139 .role=ebgp name=HE-AMSIX-v4 remote.address=80.249.209.150 .as=6939 templates=AMSIX-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=237000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=HE-AMSIX-v6 remote.address=2001:7f8:1::a500:6939:1 .as=6939 templates=AMSIX-v6
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-BKNIX-v4 remote.address=203.159.68.40 .as=20940 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Akamai-BKNIX-v6 remote.address=2001:df5:b881::40 .as=20940 templates=BKNIX-v6
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=PCH-3856-BKNIX-v4 remote.address=203.159.68.15 .as=3856 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=PCH-3856-BKNIX-v6 remote.address=2001:df5:b881::15 .as=3856 templates=BKNIX-v6
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=PCH-42-BKNIX-v4 remote.address=203.159.68.14 .as=42 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=PCH-42-BKNIX-v6 remote.address=2001:df5:b881::14 .as=42 templates=BKNIX-v6
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=ThaiNS-BKNIX-v4-1 remote.address=203.159.68.26 .as=141362 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=ThaiNS-BKNIX-v4-2 remote.address=203.159.68.25 .as=141362 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=TRUE-BKNIX-v4 remote.address=203.159.68.111 .as=7470 templates=BKNIX-v4
/routing bgp connection add disabled=yes input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TRUE-BKNIX-v6 remote.address=2001:df5:b881::111 .as=7470 templates=BKNIX-v6
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
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list bknix-communities) { set bgp-local-pref 200; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list amsix-ban-communities) { set bgp-local-pref 190; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list hgc-th-sg-communities) { set bgp-local-pref 160; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list hgc-sg-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list hgc-th-hk-communities) { set bgp-local-pref 140; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 100; }"
/routing filter rule add chain=iBGP-IN rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=iBGP-OUT rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=BKNIX-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=BKNIX-OUT-v6 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=BKNIX-OUT-v4 disabled=no rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=BKNIX-OUT-v4 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v4 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=AMSIX-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-OUT-v6 rule="set bgp-large-communities location; accept;"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
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
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len > 24) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
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
/routing filter rule add chain=BKNIX-IN-v4 comment="Accept route" rule="set bgp-local-pref 200; set bgp-large-communities bknix-communities; accept"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-th-sg-communities; accept"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept"
/routing filter rule add chain=AMSIX-IN-v4 comment="Accept route" rule="set bgp-local-pref 100; set bgp-large-communities amsix-communities; accept"
/routing filter rule add chain=BKNIX-IN-v6 comment="Accept route" rule="set bgp-local-pref 200; set bgp-large-communities bknix-communities; accept"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-th-sg-communities; accept"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Accept route" rule="set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept"
/routing filter rule add chain=AMSIX-IN-v6 comment="Accept route" rule="set bgp-local-pref 100; set bgp-large-communities amsix-communities; accept"
/routing filter rule add chain=graceful-shutdown rule="set bgp-communities graceful-shutdown; set bgp-local-pref 0; accept"
/routing ospf interface-template add area=backbone comment=BKK10-lo disabled=no networks=10.155.255.1 passive
/routing ospf interface-template add area=backbone comment=BKK20-v4 disabled=no networks=172.16.0.0/30
/routing ospf interface-template add area=backbone comment=BKK50-v4 disabled=no networks=172.16.10.0/30
/routing ospf interface-template add area=backbone comment=ROTKO-UNICAST-v4 disabled=no networks=160.22.181.0/24 passive
/routing ospf interface-template add area=backbone-v6 comment=BKNIX-v6 disabled=no networks=2001:df5:b881::168/128 passive
/routing ospf interface-template add area=backbone-v6 comment=HK-HGC-IPTx-v6-lo disabled=no networks=2403:5000:171:138::2/128 passive
/routing ospf interface-template add area=backbone comment=HK-HGC-IPTx-v4-lo disabled=no networks=118.143.211.186/32 passive
/routing ospf interface-template add area=backbone comment=BKNIX-v4-lo disabled=no networks=203.159.68.168/32 passive
/routing ospf interface-template add area=backbone comment=EU-AMS-IX-v4-lo disabled=no networks=80.249.212.139/32 passive
/routing ospf interface-template add area=backbone-v6 comment="ULA Loopback" disabled=no networks=fd00:dead:beef::10/128 passive
/routing ospf interface-template add area=backbone-v6 comment="ULA BKK20 Link" disabled=no networks=fd00:dead:beef::/126
/routing ospf interface-template add area=backbone-v6 comment="ULA BKK50 Link" disabled=no networks=fd00:dead:beef:10::1/126
/routing ospf interface-template add area=backbone-v6 comment="Global Loopback" disabled=no networks=2401:a860:181::10/128 passive
/routing ospf interface-template add area=backbone-v6 comment=ROTKO-UNICAST-v6 disabled=no networks=2401:a860::/32 passive
/routing ospf interface-template add area=backbone-v6 comment="Global Loopback" disabled=no networks=2401:a860:181::10/128 passive
/routing ospf interface-template add area=backbone-v6 comment="ULA Loopback" disabled=no networks=fd00:dead:beef::20/128 passive
/routing rpki add address=203.159.70.26 comment="Routinator IPv4 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=2001:deb:0:4070::26 comment="Routinator IPv6 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=203.159.70.36 comment="StayRTR IPv4 Secondary" group=rpki.bknix.net port=4323
/routing rpki add address=2001:deb:0:4070::36 comment="StayRTR IPv6 Secondary" group=rpki.bknix.net port=4323
/system clock set time-zone-autodetect=no time-zone-name=Asia/Bangkok
/system identity set name=bkk10
/system logging add action=disk topics=bgp,!debug
/system logging add topics=interface,warning
/system logging add action=disk topics=firewall,warning
/system logging add action=disk topics=firewall,error
/system logging add topics=account,critical
/system logging add topics=error,!debug
/system logging add topics=firewall,info,!debug
/system logging add topics=firewall,!debug
/system note set show-at-login=no
/system ntp client set enabled=yes
/system ntp server set enabled=yes
/system ntp client servers add address=0.th.pool.ntp.org
/system ntp client servers add address=0.asia.pool.ntp.org
/system ntp client servers add address=1.asia.pool.ntp.org
/system routerboard settings set enter-setup-on=delete-key
/system scheduler add name=restore-on-boot on-event="/system script run on-startup" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-time=startup
/system watchdog set watch-address=127.0.0.1 watchdog-timer=no
