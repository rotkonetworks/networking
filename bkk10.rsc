# 2024-12-06 15:24:18 by RouterOS 7.16.2
# software id = SF1Q-LGYJ
#
# model = CCR2116-12G-4S+
# serial number = HF609CW8B20
/interface bridge add comment="bridge for local network" disabled=yes name=bridge_local vlan-filtering=yes
/interface bridge add name=loopback
/interface ethernet set [ find default-name=sfp-sfpplus1 ] advertise=10G-baseCR comment=bkk30-leaf-switch
/interface ethernet set [ find default-name=sfp-sfpplus2 ] auto-negotiation=no comment=AMSIX-MMRB-12
/interface ethernet set [ find default-name=sfp-sfpplus3 ] advertise=10G-baseCR comment=bkk40-leaf-switch
/interface ethernet set [ find default-name=sfp-sfpplus4 ] comment=BKNIX-MMRB-78
/interface wireguard add listen-port=51820 mtu=1420 name=wg_rotko
/interface bonding add mode=802.3ad name=AMSIX-LAG slaves=sfp-sfpplus2 transmit-hash-policy=layer-3-and-4
/interface bonding add comment=bkk20-sfp5 lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus3 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=bkk50-sfp1 lacp-rate=1sec mode=802.3ad name=BKK50-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
/interface bonding add mode=802.3ad name=BKNIX-LAG slaves=sfp-sfpplus4 transmit-hash-policy=layer-3-and-4
/interface vlan add interface=AMSIX-LAG name=EU-AMS-IX-vlan3995 vlan-id=3995
/interface vlan add interface=AMSIX-LAG name=HK-HGC-IPTx-vlan2519 vlan-id=2519
/interface vlan add interface=AMSIX-LAG name=SG-HGC-IPTx-backup-vlan2518 vlan-id=2518
/interface bonding add disabled=yes mode=active-backup name=HGC-IPTX-SG-HK-BKK10-LAG primary=HK-HGC-IPTx-vlan2519 slaves=HK-HGC-IPTx-vlan2519,SG-HGC-IPTx-backup-vlan2518 transmit-hash-policy=layer-3-and-4
/interface ethernet switch port set 1 limit-unknown-multicasts=yes limit-unknown-unicasts=yes
/interface ethernet switch port set 3 limit-unknown-multicasts=yes limit-unknown-unicasts=yes
/interface list add name=local
/interface list add name=WAN
/interface list add name=WG
/interface wireless security-profiles set [ find default=yes ] supplicant-identity=MikroTik
/ip pool add name=dhcp_pool ranges=192.168.69.50-192.168.69.70
/ip smb users set [ find default=yes ] disabled=yes
/port set 0 name=serial0
/routing bgp template set default use-bfd=no
/routing bgp template add address-families=ip as=142108 input.filter=iBGP-IN name=default_v6 output.filter-chain=iBGP-OUT .network=ROTKO-LOCAL-v6 router-id=10.155.255.1 use-bfd=no
/routing bgp template add address-families=ip as=142108 input.filter=iBGP-IN name=default output.filter-chain=iBGP-OUT .network=our-networks router-id=10.155.255.1 use-bfd=no
/routing ospf instance add comment="OSPF instance for Router1" disabled=no name=ospf-instance-v2 originate-default=always router-id=10.155.255.1
/routing ospf instance add comment="OSPFv3 instance for Router2" disabled=no name=ospf-instance-v3 originate-default=always router-id=10.155.255.1 version=3
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/routing rip instance add disabled=yes name=rip_network
/routing rip instance add disabled=yes name=rip_network
/routing table add fib name=rt_latency
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=BKNIX-IN-v4 name=BKNIX-RS-v4 output.as-override=no .filter-chain=BKNIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=203.159.68.168 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=BKNIX-IN-v6 name=BKNIX-RS-v6 output.as-override=no .filter-chain=BKNIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=203.159.68.168 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-HK-IN-v4 name=HGC-HK-v4 output.as-override=no .filter-chain=HGC-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=118.143.211.186 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-HK-IN-v6 name=HGC-HK-v6 output.as-override=no .filter-chain=HGC-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=118.143.211.186 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=AMSIX-IN-v4 name=AMSIX-RS-v4 output.as-override=no .filter-chain=AMSIX-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=80.249.212.139 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=AMSIX-IN-v6 name=AMSIX-RS-v6 output.as-override=no .filter-chain=AMSIX-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=80.249.212.139 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-SG-IN-v6 name=HGC-SG-BACKUP-v6 output.as-override=no .filter-chain=HGC-SG-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=103.168.174.182 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-SG-IN-v4 name=HGC-SG-BACKUP-v4 output.as-override=no .filter-chain=HGC-SG-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=103.168.174.182 routing-table=main use-bfd=no
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
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
/ip firewall connection tracking set udp-timeout=10s
/ip neighbor discovery-settings set discover-interface-list=local discover-interval=1m
/ip settings set rp-filter=loose secure-redirects=no send-redirects=no tcp-syncookies=yes
/ipv6 settings set accept-redirects=no accept-router-advertisements=no max-neighbor-entries=8192
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
/interface wireguard peers add allowed-address=172.31.0.1/32 interface=wg_rotko name=laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.20/32 interface=wg_rotko name=bkk20 public-key="/09ofEbIM1qjlq7xM/R0KfJMQ8R/UR9aHaph70FTp30="
/interface wireguard peers add allowed-address=172.31.0.2/32 interface=wg_rotko name=gatus public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.31.0.3/32 interface=wg_rotko name=amdnuc public-key="IlZR7z5LVE6BKwkApq+VTvXRGaOp0hvmKSSrgi1R/V4="
/interface wireguard peers add allowed-address=172.31.0.50/32 endpoint-address=172.16.10.2 endpoint-port=51820 interface=wg_rotko name=bkk50 public-key="HSEVRjXj7x7jSVy8A9YQducW6BNme/a19/o5CA/KrUI="
/ip address add address=192.168.88.10/24 comment=bkk10-mgmt interface=bridge_local network=192.168.88.0
/ip address add address=203.159.68.168/23 comment=BKNIX-V4 interface=BKNIX-LAG network=203.159.68.0
/ip address add address=118.143.211.186/29 interface=HK-HGC-IPTx-vlan2519 network=118.143.211.184
/ip address add address=172.31.0.10/16 interface=wg_rotko network=172.31.0.0
/ip address add address=10.155.255.1 interface=loopback network=10.155.255.1
/ip address add address=192.168.69.1/16 interface=bridge_local network=192.168.0.0
/ip address add address=203.159.68.168 interface=lo network=203.159.68.168
/ip address add address=10.25.1.126/24 interface=EU-AMS-IX-vlan3995 network=10.25.1.0
/ip address add address=10.10.0.1 interface=lo network=10.0.0.0
/ip address add address=172.16.0.1/30 interface=BKK20-LAG network=172.16.0.0
/ip address add address=172.16.10.1/30 interface=BKK50-LAG network=172.16.10.0
/ip address add address=10.155.255.1 interface=lo network=10.155.255.1
/ip address add address=118.143.211.186 interface=lo network=118.143.211.186
/ip address add address=160.22.181.177 interface=lo network=160.22.181.177
/ip address add address=80.249.212.139/21 interface=EU-AMS-IX-vlan3995 network=80.249.208.0
/ip address add address=80.249.212.139 interface=lo network=80.249.212.139
/ip address add address=103.168.174.182/30 interface=SG-HGC-IPTx-backup-vlan2518 network=103.168.174.180
/ip address add address=103.168.174.182 interface=lo network=103.168.174.182
/ip address add address=160.22.181.177/29 disabled=yes interface=BKK50-LAG network=160.22.181.176
/ip arp add address=192.168.69.201 interface=bridge_local mac-address=E4:5F:01:EA:75:3E
/ip dns set cache-max-ttl=1d cache-size=4096KiB max-concurrent-queries=50 max-concurrent-tcp-sessions=10 max-udp-packet-size=512 servers=9.9.9.9,1.1.1.1,8.8.8.8
/ip firewall address-list add address=10.0.0.0/8 list=internal-ipv4
/ip firewall address-list add address=192.168.88.0/24 list=mgmt-ipv4
/ip firewall address-list add address=160.22.180.0/24 list=ibp-anycast-ipv4
/ip firewall address-list add address=160.22.181.0/24 list=rotko-unicast-ipv4
/ip firewall address-list add address=203.159.68.0/23 list=bknix-ipv4
/ip firewall address-list add address=203.159.68.168 list=bknix-rotko-address
/ip firewall address-list add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ip firewall address-list add address=118.143.211.184/29 list=HK-HGC-vlan2519
/ip firewall address-list add address=118.143.234.72/29 list=HK-SG-vlan2520
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA-assigned block" list=our-networks
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX network" list=our-networks
/ip firewall address-list add address=118.143.211.184/29 comment=HK-HGC-vlan2519 list=our-networks
/ip firewall address-list add address=118.143.234.72/29 comment=HK-SG-vlan2520 list=our-networks
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
/ip firewall address-list add address=172.31.0.0/16 comment=wg_rotko list=our-networks
/ip firewall address-list add address=10.155.255.0/24 comment="Loopback network" list=our-networks
/ip firewall address-list add address=172.16.0.0/16 comment="Internal network for router links" list=our-networks
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
/ip firewall address-list add address=203.159.70.0/23 comment="BKNIX RPKI Server" list=our-networks
/ip firewall address-list add address=160.22.181.177 list=our-networks
/ip firewall address-list add address=160.22.181.176/29 list=our-networks
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
/ip route add disabled=no distance=220 dst-address=160.22.180.0/23 gateway=lo
/ip route add distance=110 dst-address=10.155.255.2/32 gateway=172.16.0.2
/ipv6 route add blackhole dst-address=2401:a860::/32
/ipv6 route add distance=2 dst-address=2401:a860::/32 gateway=2001:df5:b881::1
/ipv6 route add dst-address=::/0
/ip service set telnet address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip service set ftp address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16 disabled=yes
/ip service set www address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16
/ip service set ssh address=171.96.38.163/32,172.104.169.64/32,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12,171.101.163.225/32,125.164.0.0/16
/ip service set www-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16
/ip service set api address=160.22.181.181/32
/ip service set winbox address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16,172.16.0.0/16 disabled=yes
/ip service set api-ssl address=172.31.0.0/16,10.0.0.0/8,192.168.0.0/16 disabled=yes
/ip smb shares set [ find default=yes ] directory=/pub
/ipv6 address add address=2001:df5:b881::168 comment=BKNIX-V6 interface=BKNIX-LAG
/ipv6 address add address=2401:a860:181::10/128 advertise=no interface=lo
/ipv6 address add address=2403:5000:171:138::2 comment="HK IPv6" interface=HK-HGC-IPTx-vlan2519
/ipv6 address add address=2401:a860:181::10 interface=AMSIX-LAG
/ipv6 address add address=2403:5000:171:138::2/128 advertise=no interface=lo
/ipv6 address add address=2001:df5:b881::168/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::10/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::1/126 advertise=no interface=BKK20-LAG
/ipv6 address add address=fd00:dead:beef:10::1/126 advertise=no interface=BKK50-LAG
/ipv6 address add address=2001:7f8:1:0:a500:14:2108:1 advertise=no interface=EU-AMS-IX-vlan3995
/ipv6 address add address=2407:9540:111:8::2/126 advertise=no interface=SG-HGC-IPTx-backup-vlan2518
/ipv6 address add address=2407:9540:111:8::2/128 advertise=no interface=lo
/ipv6 address add address=2001:db8:0:1::1/126 advertise=no interface=BKK20-LAG
/ipv6 firewall address-list add address=2001:df5:b881::/64 list=bknix-ipv6
/ipv6 firewall address-list add address=2001:df5:b881::168/128 list=bknix-rotko-address
/ipv6 firewall address-list add address=2401:a860::/32 list=ipv6-apnic-rotko
/ipv6 firewall address-list add address=2402:b740:15::/48 list=amsix-ipv6
/ipv6 firewall address-list add address=2401:a860::/32 comment="Our IPv6 block" list=our-networks-v6
/ipv6 firewall address-list add address=2001:df5:b881::/48 comment="BKNIX network" list=our-networks-v6
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HK IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=2402:b740:15::/48 comment="AMSIX IPv6" list=our-networks-v6
/ipv6 firewall address-list add address=::/128 comment="Unspecified address" list=bogons-v6
/ipv6 firewall address-list add address=::1/128 comment="Loopback address" list=bogons-v6
/ipv6 firewall address-list add address=::ffff:0.0.0.0/96 comment="IPv4-mapped addresses" list=bogons-v6
/ipv6 firewall address-list add address=::/96 comment="IPv4-compatible addresses" list=bogons-v6
/ipv6 firewall address-list add address=100::/64 comment="Discard-only address block" list=bogons-v6
/ipv6 firewall address-list add address=2001::/23 comment="IETF Protocol Assignments" list=bogons-v6
/ipv6 firewall address-list add address=2001::/32 comment=TEREDO list=bogons-v6
/ipv6 firewall address-list add address=2001:2::/48 comment=Benchmarking list=bogons-v6
/ipv6 firewall address-list add address=2001:db8::/32 comment=Documentation list=bogons-v6
/ipv6 firewall address-list add address=2001:10::/28 comment=ORCHID list=bogons-v6
/ipv6 firewall address-list add address=fc00::/7 comment=Unique-Local list=bogons-v6
/ipv6 firewall address-list add address=fe80::/10 comment=Link-Local list=bogons-v6
/ipv6 firewall address-list add address=fec0::/10 comment="Site-Local (deprecated)" list=bogons-v6
/ipv6 firewall address-list add address=ff00::/8 comment=Multicast list=bogons-v6
/ipv6 firewall address-list add address=fd00:dead:beef::/48 comment=internal-range list=our-networks-v6
/ipv6 firewall address-list add address=2401:a860:181::10/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2403:5000:171:138::2/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:df5:b881::168/128 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:7f8:1:0:a500:14:2108:1/128 comment=AMS-IX-BAN-ROTKO-IPV6 list=bgp-loopback-ips
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment=EU-AMS-IX-vlan3995 list=our-networks-v6
/ipv6 firewall address-list add address=2407:9540:111:8::/64 comment=SG-HGC-IPTx-backup-vlan2518 list=our-networks-v6
/ipv6 firewall address-list add address=2001:7f8:1::/64 comment="AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:df5:b881::/64 comment="BKNIX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2403:5000:171:138::/64 comment="HGC IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2401:a860:181::10/128 comment="EU-AMS-IX IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:db8:0:1::/126 comment="BKK20 IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:db8:0:2::/126 comment="BKK50 IPv6 Range" list=bgp-peers
/ipv6 firewall address-list add address=2001:db8:0:1::/64 comment="iBGP Infrastructure" list=our-networks-v6
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
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=BKNIX-RS0-v4 remote.address=203.159.68.68 .as=63529 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=BKNIX-RS1-v4 remote.address=203.159.68.69 .as=63529 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS0-v6 remote.address=2001:df5:b881::68 .as=63529 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=BKNIX-RS1-v6 remote.address=2001:df5:b881::69 .as=63529 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=RouteViews-BKNIX-v4 remote.address=203.159.68.20 .as=6447 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.role=ebgp name=RouteViews-BKNIX-v6 remote.address=2001:df5:b881::20 .as=6447 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=210000 local.role=ebgp name=HE-BKNIX-v4 remote.address=203.159.68.135 .as=6939 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=237000 local.role=ebgp name=HE-BKNIX-v6 remote.address=2001:df5:b881::135 .as=6939 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=500000 local.role=ebgp name=HGC-HK-IPTX-v6 remote.address=2403:5000:171:138::1 .as=9304 templates=HGC-HK-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1500000 local.role=ebgp name=HGC-HK-IPTX-v4 remote.address=118.143.211.185 .as=9304 templates=HGC-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=2000000 local.address=2001:db8:0:1::1 .role=ibgp name=ROTKO-BKK10-TO-BKK20-v6 output.filter-chain=iBGP-OUT .keep-sent-attributes=yes .redistribute=bgp remote.address=2001:db8:0:1::2 .as=142108 templates=default_v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=2000000 local.address=10.155.255.1 .role=ibgp name=ROTKO-BKK10-TO-BKK20-v4 output.keep-sent-attributes=yes .redistribute=bgp remote.address=10.155.255.2 .as=142108 templates=default
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=AMSIX-RS1-v4 remote.address=80.249.208.255 .as=6777 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=AMSIX-RS2-v4 remote.address=80.249.209.0 .as=6777 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS1-v6 remote.address=2001:7f8:1::a500:6777:1 .as=6777 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-RS2-v6 remote.address=2001:7f8:1::a500:6777:2 .as=6777 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=AMSIX-MON1-v4 remote.address=80.249.208.1 .as=1200 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.role=ebgp name=AMSIX-MON2-v4 remote.address=80.249.209.1 .as=1200 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=10 local.address=80.249.212.139 .role=ebgp name=AMSIX-MON3-v4 remote.address=193.105.101.1 .as=1200 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON1-v6 remote.address=2001:7f8:1::a500:1200:1 .as=1200 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON2-v6 remote.address=2001:7f8:1::a500:1200:2 .as=1200 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=10 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=AMSIX-MON3-v6 remote.address=2001:7f8:86:1:0:a500:1200:1 .as=1200 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no local.role=ebgp name=AXERA-AMSIX-v4 remote.address=80.249.211.255 .as=34758 templates=AMSIX-RS-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=500000 local.address=2407:9540:111:8::2 .role=ebgp name=HGC-SG-IPTX-BACKUP-v6 remote.address=2407:9540:111:8::1 .as=142435 templates=HGC-SG-BACKUP-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=1500000 local.role=ebgp name=HGC-SG-IPTX-BACKUP-v4 remote.address=103.168.174.181 .as=142435 templates=HGC-SG-BACKUP-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=Cloudflare-AMSIX-v4-1 remote.address=80.249.211.140 .as=13335 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=1000000 local.role=ebgp name=Cloudflare-AMSIX-v4-2 remote.address=80.249.210.118 .as=13335 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-1 remote.address=2001:7f8:1::a501:3335:1 .as=13335 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=1000000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-v6-2 remote.address=2001:7f8:1::a501:3335:2 .as=13335 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=210000 local.address=80.249.212.139 .role=ebgp name=HE-AMSIX-v4 remote.address=80.249.209.150 .as=6939 templates=AMSIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=237000 local.address=2001:7f8:1:0:a500:14:2108:1 .role=ebgp name=HE-AMSIX-v6 remote.address=2001:7f8:1::a500:6939:1 .as=6939 templates=AMSIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-BKNIX-v4 remote.address=203.159.68.40 .as=20940 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Akamai-BKNIX-v6 remote.address=2001:df5:b881::40 .as=20940 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AmazonIVS-BKNIX-v4-1 remote.address=203.159.68.134 .as=46489 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=AmazonIVS-BKNIX-v6-1 remote.address=2001:df5:b881::134 .as=46489 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AmazonIVS-BKNIX-v4-2 remote.address=203.159.68.132 .as=46489 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=AmazonIVS-BKNIX-v6-2 remote.address=2001:df5:b881::132 .as=46489 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon-BKNIX-v4-1 remote.address=203.159.68.130 .as=16509 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Amazon-BKNIX-v6-1 remote.address=2001:df5:b881::130 .as=16509 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon-BKNIX-v4-2 remote.address=203.159.68.131 .as=16509 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Amazon-BKNIX-v6-2 remote.address=2001:df5:b881::131 .as=16509 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Anexia-BKNIX-v4 remote.address=203.159.68.128 .as=42473 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Anexia-BKNIX-v6 remote.address=2001:df5:b881::128 .as=42473 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AscendMoney-BKNIX-v4-1 remote.address=203.159.68.109 .as=142029 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=AscendMoney-BKNIX-v6-1 remote.address=2001:df5:b881::109 .as=142029 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AscendMoney-BKNIX-v4-2 remote.address=203.159.68.113 .as=142029 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=AscendMoney-BKNIX-v6-2 remote.address=2001:df5:b881::113 .as=142029 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AIT-BKNIX-v4 remote.address=203.159.68.13 .as=4767 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=AIT-BKNIX-v6 remote.address=2001:df5:b881::13 .as=4767 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ATOM-BKNIX-v4 remote.address=203.159.68.160 .as=133385 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ATOM-BKNIX-v6 remote.address=2001:df5:b881::160 .as=133385 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ByteDance-BKNIX-v4-1 remote.address=203.159.68.165 .as=396986 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ByteDance-BKNIX-v6-1 remote.address=2001:df5:b881::165 .as=396986 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ByteDance-BKNIX-v4-2 remote.address=203.159.68.166 .as=396986 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ByteDance-BKNIX-v6-2 remote.address=2001:df5:b881::166 .as=396986 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Cableconnect-BKNIX-v4 remote.address=203.159.68.107 .as=135419 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Cableconnect-BKNIX-v6 remote.address=2001:df5:b881::107 .as=135419 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CatoNetworks-BKNIX-v4 remote.address=203.159.68.157 .as=13150 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ChannelG-BKNIX-v4 remote.address=203.159.68.81 .as=150787 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ChannelG-BKNIX-v6 remote.address=2001:df5:b881::81 .as=150787 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CMI-BKNIX-v4 remote.address=203.159.68.161 .as=141419 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CMI-BKNIX-v6 remote.address=2001:df5:b881::161 .as=141419 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CMKL-BKNIX-v4-1 remote.address=203.159.68.140 .as=140918 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CMKL-BKNIX-v6-1 remote.address=2001:df5:b881::140 .as=140918 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CMKL-BKNIX-v4-2 remote.address=203.159.68.136 .as=140918 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CMKL-BKNIX-v6-2 remote.address=2001:df5:b881::136 .as=140918 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CommunityDNS-BKNIX-v4 remote.address=203.159.68.8 .as=42909 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CommunityDNS-BKNIX-v6 remote.address=2001:df5:b881::8 .as=42909 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CSLoxInfo-BKNIX-v4 remote.address=203.159.68.108 .as=45265 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CSLoxInfo-BKNIX-v6 remote.address=2001:df5:b881::108 .as=45265 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CTGNet-BKNIX-v4 remote.address=203.159.68.159 .as=23764 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=CTGNet-BKNIX-v6 remote.address=2001:df5:b881::159 .as=23764 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DNS-OARC-BKNIX-v4 remote.address=203.159.68.21 .as=112 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=DNS-OARC-BKNIX-v6 remote.address=2001:df5:b881::21 .as=112 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DotEnterprise-BKNIX-v4 remote.address=203.159.68.145 .as=63989 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=DotEnterprise-BKNIX-v6 remote.address=2001:df5:b881::145 .as=63989 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DTAC-BKNIX-v4-1 remote.address=203.159.68.101 .as=133543 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=DTAC-BKNIX-v6-1 remote.address=2001:df5:b881::101 .as=133543 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DTAC-BKNIX-v4-2 remote.address=203.159.68.104 .as=133543 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=DTAC-BKNIX-v6-2 remote.address=2001:df5:b881::104 .as=133543 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Fastly-BKNIX-v4-1 remote.address=203.159.68.151 .as=54113 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Fastly-BKNIX-v6-1 remote.address=2001:df5:b881::151 .as=54113 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Fastly-BKNIX-v4-2 remote.address=203.159.68.150 .as=54113 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Fastly-BKNIX-v6-2 remote.address=2001:df5:b881::150 .as=54113 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Frontiir-BKNIX-v4 remote.address=203.159.68.126 .as=58952 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Frontiir-BKNIX-v6 remote.address=2001:df5:b881::126 .as=58952 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=HuaweiCloud-BKNIX-v4-1 remote.address=203.159.68.137 .as=136907 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=HuaweiCloud-BKNIX-v6-1 remote.address=2001:df5:b881::137 .as=136907 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=HuaweiCloud-BKNIX-v4-2 remote.address=203.159.68.138 .as=136907 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=HuaweiCloud-BKNIX-v6-2 remote.address=2001:df5:b881::138 .as=136907 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=IGW-BKNIX-v4 remote.address=203.159.68.121 .as=140867 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=IGW-BKNIX-v6 remote.address=2001:df5:b881::121 .as=140867 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=INET-BKNIX-v4-1 remote.address=203.159.68.115 .as=4618 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=INET-BKNIX-v6-1 remote.address=2001:df5:b881::115 .as=4618 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=INET-BKNIX-v4-2 remote.address=203.159.68.103 .as=4618 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=INET-BKNIX-v6-2 remote.address=2001:df5:b881::103 .as=4618 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ITEL-BKNIX-v4 remote.address=203.159.68.133 .as=135529 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ITEL-BKNIX-v6 remote.address=2001:df5:b881::133 .as=135529 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=KSC-BKNIX-v4 remote.address=203.159.68.119 .as=7693 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=KSC-BKNIX-v6 remote.address=2001:df5:b881::119 .as=7693 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=MROOT-BKNIX-v4 remote.address=203.159.68.23 .as=7500 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=MROOT-BKNIX-v6 remote.address=2001:df5:b881::23 .as=7500 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=MWIT-BKNIX-v4-1 remote.address=203.159.68.156 .as=138685 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=MWIT-BKNIX-v6-1 remote.address=2001:df5:b881::156 .as=138685 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=MWIT-BKNIX-v4-2 remote.address=203.159.68.155 .as=138685 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=MWIT-BKNIX-v6-2 remote.address=2001:df5:b881::155 .as=138685 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Meta-BKNIX-v4-1 remote.address=203.159.68.162 .as=32934 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Meta-BKNIX-v6-1 remote.address=2001:df5:b881::162 .as=32934 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Meta-BKNIX-v4-2 remote.address=203.159.68.163 .as=32934 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Meta-BKNIX-v6-2 remote.address=2001:df5:b881::163 .as=32934 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=NEOCOM-BKNIX-v4 remote.address=203.159.68.169 .as=9902 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=NEOCOM-BKNIX-v6 remote.address=2001:df5:b881::169 .as=9902 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Netskope-BKNIX-v4 remote.address=203.159.68.146 .as=55256 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=Netskope-BKNIX-v6 remote.address=2001:df5:b881::146 .as=55256 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=NTT-BKNIX-v4 remote.address=203.159.68.110 .as=38566 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=NTT-BKNIX-v6 remote.address=2001:deb:0:68::110 .as=38566 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=PCH-3856-BKNIX-v4 remote.address=203.159.68.15 .as=3856 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=PCH-3856-BKNIX-v6 remote.address=2001:df5:b881::15 .as=3856 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=PCH-42-BKNIX-v4 remote.address=203.159.68.14 .as=42 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=PCH-42-BKNIX-v6 remote.address=2001:df5:b881::14 .as=42 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=POPIDC-BKNIX-v4 remote.address=203.159.68.143 .as=131447 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=POPIDC-BKNIX-v6 remote.address=2001:df5:b881::143 .as=131447 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=RackCorp-BKNIX-v4-1 remote.address=203.159.68.141 .as=56038 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=RackCorp-BKNIX-v6-1 remote.address=2001:deb:0:68::141 .as=56038 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=RackCorp-BKNIX-v4-2 remote.address=203.159.68.139 .as=56038 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=RackCorp-BKNIX-v6-2 remote.address=2001:deb:0:68::139 .as=56038 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=RiotGames-BKNIX-v4 remote.address=203.159.68.154 .as=6507 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=RiotGames-BKNIX-v6 remote.address=2001:df5:b881::154 .as=6507 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=SGGS-BKNIX-v4 remote.address=203.159.68.176 .as=24482 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=SGGS-BKNIX-v6 remote.address=2001:df5:b881::176 .as=24482 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=SUPERNAP-BKNIX-v4 remote.address=203.159.68.158 .as=137566 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=SUPERNAP-BKNIX-v6 remote.address=2001:df5:b881::158 .as=137566 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=SYMPHONY-BKNIX-v4 remote.address=203.159.68.122 .as=132280 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=SYMPHONY-BKNIX-v6 remote.address=2001:df5:b881::122 .as=132280 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TCC-BKNIX-v4-1 remote.address=203.159.68.106 .as=45667 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TCC-BKNIX-v6-1 remote.address=2001:df5:b881::106 .as=45667 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TCC-BKNIX-v4-2 remote.address=203.159.68.105 .as=45667 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TCC-BKNIX-v6-2 remote.address=2001:df5:b881::105 .as=45667 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ThaiNS-BKNIX-v4-1 remote.address=203.159.68.26 .as=141362 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ThaiNS-BKNIX-v6-1 remote.address=2001:df5:b881::26 .as=141362 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ThaiNS-BKNIX-v4-2 remote.address=203.159.68.25 .as=141362 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=ThaiNS-BKNIX-v6-2 remote.address=2001:df5:b881::25 .as=141362 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TripleT-BKNIX-v4-1 remote.address=203.159.68.114 .as=45758 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TripleT-BKNIX-v6-1 remote.address=2001:df5:b881::114 .as=45758 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TripleT-BKNIX-v4-2 remote.address=203.159.68.102 .as=45758 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TripleT-BKNIX-v6-2 remote.address=2001:df5:b881::102 .as=45758 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TRUE-BKNIX-v4 remote.address=203.159.68.111 .as=7470 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TRUE-BKNIX-v6 remote.address=2001:df5:b881::111 .as=7470 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TIDC-BKNIX-v4 remote.address=203.159.68.153 .as=9287 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TIDC-BKNIX-v6 remote.address=2001:df5:b881::153 .as=9287 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=TWGate-BKNIX-v4 remote.address=203.159.68.152 .as=9505 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=TWGate-BKNIX-v6 remote.address=2001:deb:0:68::152 .as=9505 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=UniNet-BKNIX-v4-1 remote.address=203.159.68.11 .as=4621 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=UniNet-BKNIX-v6-1 remote.address=2001:deb:0:68::11 .as=4621 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=UniNet-BKNIX-v4-2 remote.address=203.159.68.10 .as=4621 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=UniNet-BKNIX-v6-2 remote.address=2001:deb:0:68::10 .as=4621 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=UIH-IIG-BKNIX-v4 remote.address=203.159.68.100 .as=45796 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=UIH-IIG-BKNIX-v6 remote.address=2001:df5:b881::100 .as=45796 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=UIH-BKNIX-v4 remote.address=203.159.68.112 .as=38794 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=UIH-BKNIX-v6 remote.address=2001:df5:b881::112 .as=38794 templates=BKNIX-RS-v6
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=VeriSign-BKNIX-v4 remote.address=203.159.68.9 .as=26415 templates=BKNIX-RS-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=100000 local.address=2001:df5:b881::168 .role=ebgp name=VeriSign-BKNIX-v6 remote.address=2001:df5:b881::9 .as=26415 templates=BKNIX-RS-v6
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=BKNIX-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=BKNIX-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=BKNIX-OUT-v6 rule="reject;"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=BKNIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=BKNIX-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=BKNIX-OUT-v4 rule="if (dst == 203.159.68.0/23) { accept; }"
/routing filter rule add chain=BKNIX-OUT-v4 disabled=no rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=BKNIX-OUT-v4 rule="reject;"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="reject;"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="reject;"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="reject;"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-HK-OUT-v4 disabled=no rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="reject;"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="reject;"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-HK-OUT-v4 disabled=no rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="reject;"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.ams-ix.net"
/routing filter rule add chain=AMSIX-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-OUT-v4 rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=AMSIX-OUT-v4 rule="reject;"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.ams-ix.net"
/routing filter rule add chain=AMSIX-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=AMSIX-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=AMSIX-OUT-v6 rule="reject;"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (dst in 160.22.180.0/23 && dst-len >= 23 && dst-len <= 24) { accept; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="reject;"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (dst in 2401:A860::/32 && dst-len >= 32 && dst-len <= 48) { accept; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="reject;"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard overly specific IPv4 prefixes /25 to /32" disabled=no rule="if (dst-len >= 25 && dst-len <= 32) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard IPv4 bogons" disabled=no rule="if (dst in ipv4-bogons) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="RPKI validation for IPv4" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Reject RPKI invalid IPv4 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Discard default IPv4 route" disabled=no rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Accept remaining IPv4 routes" disabled=no rule="accept;"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard IPv6 bogons" disabled=no rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard overly specific IPv6 prefixes /49 to /128" disabled=no rule="if (dst-len >= 49 && dst-len <= 128) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="RPKI validation for IPv6" disabled=no rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Reject RPKI invalid IPv6 routes" disabled=no rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Discard default IPv6 route" disabled=no rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Accept remaining IPv6 routes" disabled=no rule="accept;"
/routing filter rule add chain=iBGP-IN rule="set bgp-local-pref 200; accept;"
/routing filter rule add chain=iBGP-OUT rule="accept;"
/routing ospf interface-template add area=backbone comment=BKK10-lo disabled=no networks=10.155.255.1 passive use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=BKK20-v6 disabled=no networks=2001:db8:0:1::/126 use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=BKK50-v6 disabled=no networks=2001:db8:0:2::/126 use-bfd=no
/routing ospf interface-template add area=backbone comment=BKK20-v4 disabled=no networks=172.16.0.0/30 use-bfd=no
/routing ospf interface-template add area=backbone comment=BKK50-v4 disabled=no networks=172.16.10.0/30 use-bfd=no
/routing ospf interface-template add area=backbone comment=ROTKO-UNICAST-v4 disabled=no networks=160.22.181.0/24 use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=BKNIX-v6 disabled=no networks=2001:df5:b881::168/128 passive use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=HK-HGC-IPTx-v6-lo disabled=no networks=2403:5000:171:138::2/128 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=HK-HGC-IPTx-v4-lo disabled=no networks=118.143.211.186/32 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=BKNIX-v4-lo disabled=no networks=203.159.68.168/32 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=EU-AMS-IX-v4-lo disabled=no networks=80.249.212.139/32 use-bfd=no
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
/system note set show-at-login=no
/system ntp client set enabled=yes
/system ntp server set enabled=yes
/system ntp client servers add address=203.159.70.33
/system ntp client servers add address=2001:deb:0:4070::33
/system ntp client servers add address=ntp1.bknix.co.th
/system routerboard settings set enter-setup-on=delete-key
/system watchdog set watch-address=127.0.0.1 watchdog-timer=no
/user group add name=mktxp_group policy=ssh,read,api,!local,!telnet,!ftp,!reboot,!write,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api
