# 2025-02-19 19:07:01 by RouterOS 7.16.2
# software id = 74Z8-YX0B
#
# model = CCR2216-1G-12XS-2XQ
# serial number = HGQ09NWHXX7
/interface bridge add admin-mac=D4:01:C3:F6:9E:62 auto-mac=no comment="bridge for local network" name=bridge_local vlan-filtering=yes
/interface ethernet set [ find default-name=qsfp28-1-1 ] advertise=25G-baseCR
/interface ethernet set [ find default-name=qsfp28-1-3 ] advertise=10G-baseCR,25G-baseCR
/interface ethernet set [ find default-name=sfp28-2 ] advertise=10G-baseSR-LR arp-timeout=4h comment=HGC/core3,4/MMR-3A
/interface ethernet set [ find default-name=sfp28-4 ] advertise=10G-baseSR-LR
/interface ethernet set [ find default-name=sfp28-5 ] advertise=10G-baseCR comment=bkk10sfp3
/interface ethernet set [ find default-name=sfp28-10 ] advertise=10G-baseT,10G-baseCR
/interface ethernet set [ find default-name=sfp28-11 ] advertise=10G-baseCR comment=BKK50sfp2
/interface wireguard add listen-port=51820 mtu=1420 name=wg_rotko
/interface bonding add arp-timeout=4h lacp-rate=1sec mode=802.3ad name=AMSIX-LAG slaves=sfp28-2 transmit-hash-policy=layer-3-and-4
/interface bonding add comment=bkk10-sfp3 lacp-rate=1sec mode=802.3ad name=BKK10-LAG slaves=sfp28-5 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=bkk50-sfp2 lacp-rate=1sec mode=802.3ad name=BKK50-LAG slaves=sfp28-11 transmit-hash-policy=layer-2-and-3
/interface bonding add name=QSFP1 slaves=qsfp28-1-1,qsfp28-1-2,qsfp28-1-3,qsfp28-1-4
/interface bonding add mode=802.3ad name=QSFP2 slaves=qsfp28-2-1,qsfp28-2-2,qsfp28-2-3,qsfp28-2-4
/interface vlan add interface=AMSIX-LAG name=BKK-AMS-IX-vlan911 vlan-id=911
/interface vlan add interface=AMSIX-LAG name=HK-AMS-IX-vlan3994 vlan-id=3994
/interface vlan add interface=AMSIX-LAG name=HK-HGC-IPTx-backup-vlan2517 vlan-id=2517
/interface vlan add interface=AMSIX-LAG name=SG-HGC-IPTx-vlan2520 vlan-id=2520
/interface bonding add lacp-rate=1sec mode=active-backup name=HGC-IPTX-SG-HK-BKK20-LAG primary=SG-HGC-IPTx-vlan2520 slaves=HK-HGC-IPTx-backup-vlan2517,SG-HGC-IPTx-vlan2520 transmit-hash-policy=layer-3-and-4
/interface list add name=local
/interface list add name=WAN
/port set 0 name=serial0
/routing bgp template set default address-families=ip as=142108 input.filter=iBGP-IN multihop=yes nexthop-choice=force-self output.filter-chain=iBGP-OUT .network=ipv4-apnic-rotko router-id=10.155.255.2 use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 input.filter=iBGP-IN multihop=yes name=default_v6 nexthop-choice=force-self output.filter-chain=iBGP-OUT .network=ipv6-apnic-rotko .redistribute=connected router-id=10.155.255.1 use-bfd=no
/routing id add id=10.155.255.2 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add comment="OSPF instance for Router2" disabled=no name=ospf-instance-v2 originate-default=always router-id=10.155.255.2
/routing ospf instance add comment="OSPFv3 instance for Router2" disabled=no name=ospf-instance-v3 originate-default=always router-id=10.155.255.2 version=3
/routing ospf area add disabled=no instance=ospf-instance-v2 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/routing table add fib name=rt_latency
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=AMSIX-BAN-IN-v4 name=AMSIX-BAN-v4 output.as-override=no .filter-chain=AMSIX-BAN-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=AMSIX-BAN-IN-v6 name=AMSIX-BAN-v6 output.as-override=no .filter-chain=AMSIX-BAN-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-SG-IN-v4 name=HGC-SG-v4 output.as-override=no .filter-chain=HGC-SG-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-SG-IN-v6 name=HGC-SG-v6 output.as-override=no .filter-chain=HGC-SG-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=AMSIX-EU-IN-v4 name=AMSIX-EU-v4 output.as-override=no .filter-chain=AMSIX-EU-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=AMSIX-EU-IN-v6 name=AMSIX-EU-v6 output.as-override=no .filter-chain=AMSIX-EU-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=HGC-HK-IN-v4 name=HGC-HK-BACKUP-v4 output.as-override=no .filter-chain=HGC-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=HGC-HK-IN-v6 name=HGC-HK-BACKUP-v6 output.as-override=no .filter-chain=HGC-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ip as=142108 disabled=no input.filter=AMSIX-HK-IN-v4 name=AMSIX-HK-v4 output.as-override=no .filter-chain=AMSIX-HK-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/routing bgp template add address-families=ipv6 as=142108 disabled=no input.filter=AMSIX-HK-IN-v6 name=AMSIX-HK-v6 output.as-override=no .filter-chain=AMSIX-HK-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes router-id=10.155.255.2 routing-table=main use-bfd=no
/interface bridge filter add action=accept chain=forward mac-protocol=ip out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=arp out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward mac-protocol=vlan out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface-list=WAN
/interface bridge filter add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface-list=WAN
/interface bridge filter add action=drop chain=forward out-interface-list=WAN
/interface bridge port add bridge=bridge_local interface=sfp28-12
/interface bridge port add bridge=bridge_local interface=sfp28-10
/interface bridge port add bridge=bridge_local interface=sfp28-8
/interface bridge port add bridge=bridge_local interface=sfp28-6
/ip firewall connection tracking set enabled=no loose-tcp-tracking=no udp-timeout=10s
/ip neighbor discovery-settings set discover-interval=1m
/ip settings set secure-redirects=no send-redirects=no tcp-syncookies=yes
/ipv6 settings set accept-redirects=no accept-router-advertisements=no
/interface ethernet switch set 0 l3-hw-offloading=yes
/interface list member add interface=AMSIX-LAG list=WAN
/interface list member add interface=SG-HGC-IPTx-vlan2520 list=WAN
/interface list member add interface=BKK-AMS-IX-vlan911 list=WAN
/interface list member add interface=ether1 list=local
/interface list member add interface=lo list=local
/interface list member add interface=bridge_local list=local
/interface list member add interface=HK-AMS-IX-vlan3994 list=WAN
/interface list member add interface=qsfp28-1-1 list=local
/interface list member add interface=qsfp28-1-2 list=local
/interface list member add interface=qsfp28-1-3 list=local
/interface list member add interface=qsfp28-1-4 list=local
/interface list member add interface=qsfp28-2-4 list=local
/interface list member add interface=qsfp28-2-3 list=local
/interface list member add interface=qsfp28-2-2 list=local
/interface list member add interface=qsfp28-2-1 list=local
/interface list member add interface=sfp28-1 list=local
/interface list member add interface=sfp28-3 list=local
/interface list member add interface=sfp28-4 list=local
/interface list member add interface=sfp28-5 list=local
/interface list member add interface=sfp28-6 list=local
/interface list member add interface=sfp28-7 list=local
/interface list member add interface=sfp28-8 list=local
/interface list member add interface=sfp28-9 list=local
/interface list member add interface=sfp28-10 list=local
/interface list member add interface=sfp28-11 list=local
/interface list member add interface=sfp28-12 list=local
/interface list member add interface=sfp28-2 list=WAN
/interface list member add interface=BKK10-LAG list=local
/interface list member add interface=BKK50-LAG list=local
/interface list member add interface=wg_rotko list=local
/interface list member add interface=HK-HGC-IPTx-backup-vlan2517 list=WAN
/interface wireguard peers add allowed-address=172.31.0.1/32 interface=wg_rotko name=laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.10/32 interface=wg_rotko name=bkk10 public-key="nahvhOxYg+859oPKgnXopw2fqvcpJFaC92SqdMckI0I="
/interface wireguard peers add allowed-address=172.31.0.2/32 interface=wg_rotko name=gatus public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.31.0.3/32 interface=wg_rotko name=amdnuc public-key="IlZR7z5LVE6BKwkApq+VTvXRGaOp0hvmKSSrgi1R/V4="
/interface wireguard peers add allowed-address=172.31.0.50/32 interface=wg_rotko name=bkk50 public-key="HSEVRjXj7x7jSVy8A9YQducW6BNme/a19/o5CA/KrUI="
/ip address add address=10.20.0.1/8 interface=bridge_local network=10.0.0.0
/ip address add address=118.143.234.74/29 interface=SG-HGC-IPTx-vlan2520 network=118.143.234.72
/ip address add address=172.31.0.20/16 interface=wg_rotko network=172.31.0.0
/ip address add address=10.155.255.2 interface=lo network=10.155.255.2
/ip address add address=103.100.140.31/24 interface=BKK-AMS-IX-vlan911 network=103.100.140.0
/ip address add address=192.168.69.2/16 interface=bridge_local network=192.168.0.0
/ip address add address=103.247.139.76/25 interface=HK-AMS-IX-vlan3994 network=103.247.139.0
/ip address add address=172.16.0.2/30 comment=from_bkk10 interface=BKK10-LAG network=172.16.0.0
/ip address add address=172.16.20.1/30 comment=to_bkk50 interface=BKK50-LAG network=172.16.20.0
/ip address add address=160.22.181.178 comment=pub_ip interface=lo network=160.22.181.178
/ip address add address=103.168.174.178/30 interface=HK-HGC-IPTx-backup-vlan2517 network=103.168.174.176
/ip dhcp-client add comment=defconf disabled=yes interface=bridge_local
/ip dns set servers=1.0.0.1,1.1.1.1
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
/ip firewall address-list add address=10.0.0.0/8 list=internal-ipv4
/ip firewall address-list add address=192.168.88.0/24 list=mgmt-ipv4
/ip firewall address-list add address=160.22.180.0/24 list=ibp-anycast-ipv4
/ip firewall address-list add address=160.22.181.0/24 list=rotko-unicast-ipv4
/ip firewall address-list add address=203.159.68.0/23 list=bknix-ipv4
/ip firewall address-list add address=10.0.0.0/8 list=mgmt-ipv4
/ip firewall address-list add address=118.143.211.184/29 list=HK-HGC-vlan2519
/ip firewall address-list add address=118.143.234.72/29 list=HK-SG-vlan2520
/ip firewall address-list add address=0.0.0.0/8 comment=RFC6890 list=not_in_internet
/ip firewall address-list add address=172.16.0.0/12 comment=RFC6890 list=not_in_internet
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
/ip firewall address-list add address=10.0.0.0/8 list=lan_subnets
/ip firewall address-list add address=192.168.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.31.0.0/16 list=lan_subnets
/ip firewall address-list add address=172.16.0.0/16 list=lan_subnets
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
/ip firewall raw add action=accept chain=prerouting comment="Enable this rule for transparent mode"
/ip firewall raw add action=accept chain=prerouting dst-address=160.22.181.181 dst-port=8728 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="Allow traffic for our networks" dst-address-list=our-networks src-address-list=our-networks
/ip firewall raw add action=accept chain=prerouting comment=wg_rotko src-address=172.31.0.0/16
/ip firewall raw add action=drop chain=prerouting comment="defconf: Drop DHCP discover on LAN" dst-address=255.255.255.255 dst-port=67 in-interface-list=local protocol=udp src-address=0.0.0.0 src-port=68
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop bad src IPs" src-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop bad dst IPs" dst-address-list=bad_ipv4
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop bad src IPs" src-address-list=bad_src_ipv4
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop bad dst IPs" dst-address-list=bad_dst_ipv4
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop non global from WAN" in-interface-list=WAN src-address-list=not_in_internet
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop local if not from default IP range" in-interface-list=local src-address-list=!lan_subnets
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop bad UDP" port=0 protocol=udp
/ip firewall raw add action=jump chain=prerouting comment="defconf: jump to ICMP chain" jump-target=icmp protocol=icmp
/ip firewall raw add action=jump chain=prerouting comment="defconf: jump to TCP chain" jump-target=bad_tcp protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="defconf: accept everything else from LAN" in-interface-list=local
/ip firewall raw add action=accept chain=prerouting comment="defconf: accept everything else from WAN" in-interface-list=WAN
/ip firewall raw add action=drop chain=prerouting comment="defconf: drop the rest"
/ip firewall raw add action=accept chain=icmp comment="defconf: echo reply" icmp-options=0:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: net unreachable" icmp-options=3:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: host unreachable" icmp-options=3:1 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: protocol unreachable" icmp-options=3:2 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: port unreachable" icmp-options=3:3 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: host unreachable fragmentation required" icmp-options=3:4 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: echo request" icmp-options=8:0 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: time exceeded " icmp-options=11:0-255 protocol=icmp
/ip firewall raw add action=accept chain=icmp comment="defconf: allow parameter bad" icmp-options=12:0 protocol=icmp
/ip firewall raw add action=drop chain=icmp comment="defconf: drop other icmp" protocol=icmp
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=fin,syn
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=fin,rst
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=fin,!ack
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=fin,urg
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=syn,rst
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP flag filter" protocol=tcp tcp-flags=rst,urg
/ip firewall raw add action=drop chain=bad_tcp comment="defconf: TCP port 0 drop" port=0 protocol=tcp
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add blackhole distance=240 dst-address=160.22.180.0/23
/ip route add distance=220 gateway=172.16.0.1
/ip route add dst-address=203.159.70.26/32 gateway=118.143.234.73 routing-table=*401
/ipv6 route add blackhole distance=2 dst-address=2401:a860::/32
/ipv6 route add distance=1 dst-address=2401:a860::/32 gateway=2001:df5:b881::1
/ip service set telnet address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set ftp address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set www address=10.0.0.0/8,192.168.0.0/16,172.31.0.0/16
/ip service set ssh address=95.217.216.149/32,2a01:4f9:c012:fbcd::/64,119.76.35.40/32,160.22.181.181/32,125.164.0.0/16,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,172.104.169.64/32,171.101.163.225/32
/ip service set www-ssl address=10.0.0.0/8,192.168.88.0/24
/ip service set api address=160.22.181.181/32
/ip service set winbox address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ip service set api-ssl address=10.0.0.0/8,192.168.88.0/24 disabled=yes
/ipv6 address add address=2401:a860:181::20/128 advertise=no comment=bkk20-singapore interface=lo
/ipv6 address add address=2403:5000:165:15::2 interface=SG-HGC-IPTx-vlan2520
/ipv6 address add address=fc00::20 advertise=no comment=bridge_local_address interface=bridge_local
/ipv6 address add address=2401:a860:cafe::20 interface=lo
/ipv6 address add address=2402:b740:15:388:a500:14:2108:1 advertise=no interface=BKK-AMS-IX-vlan911
/ipv6 address add address=2001:df0:296:0:a500:14:2108:1 advertise=no interface=HK-AMS-IX-vlan3994
/ipv6 address add address=fd00:dead:beef::20/128 advertise=no interface=lo
/ipv6 address add address=2401:a860:181::20/32 advertise=no interface=AMSIX-LAG
/ipv6 address add address=fd00:dead:beef:20::1/126 advertise=no interface=BKK50-LAG
/ipv6 address add address=2407:9540:111:7::2/126 advertise=no interface=HK-HGC-IPTx-backup-vlan2517
/ipv6 address add address=2407:9540:111:7::2/128 advertise=no interface=lo
/ipv6 address add address=fd00:dead:beef::2/126 advertise=no interface=BKK10-LAG
/ipv6 address add address=2401:a860:181::1 interface=BKK10-LAG
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
/ipv6 firewall raw add action=notrack chain=prerouting
/ipv6 firewall raw add action=notrack chain=postrouting
/ipv6 firewall raw add action=accept chain=prerouting comment="Enable for transparent mode"
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow from our networks" src-address-list=our-networks-v6
/ipv6 firewall raw add action=accept chain=prerouting comment="Rate limit ICMPv6" limit=50/5s,5 protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop excess ICMPv6" protocol=icmpv6
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow essential protocols" dst-port=53,179 protocol=tcp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow essential protocols" dst-port=53,123,3784,4784 protocol=udp
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow OSPFv3" protocol=ospf
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop invalid TCP flags" protocol=tcp tcp-flags=!fin,!syn,!rst,!ack
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop bogon/spoofed IPv6" src-address-list=bogons-v6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop spoofed packets" in-interface-list=WAN src-address-list=our-networks-v6
/ipv6 firewall raw add action=accept chain=prerouting comment="Allow remaining IPv6 traffic"
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop Router Advertisements on AMSIX" icmp-options=134:0 in-interface=AMSIX-LAG protocol=icmpv6
/ipv6 firewall raw add action=drop chain=prerouting comment="Drop multicast on AMSIX" dst-address=ff00::/8 in-interface=AMSIX-LAG
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=500000 local.role=ebgp name=HGC-SG-v6 remote.address=2403:5000:165:15::1 .as=9304 templates=HGC-SG-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=1500000 local.role=ebgp name=HGC-SG-v4 remote.address=118.143.234.73 .as=9304 templates=HGC-SG-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=2000000 local.address=10.155.255.2 .role=ibgp name=ROTKO-BKK20-TO-BKK10-v4 output.keep-sent-attributes=yes .redistribute=connected,bgp remote.address=10.155.255.1 .as=142108 templates=default
/routing bgp connection add address-families=ipv6 as=142108 disabled=no input.filter=iBGP-IN .limit-process-routes-ipv6=2000000 local.address=fd00:dead:beef::2 .role=ibgp name=ROTKO-BKK20-TO-BKK10-v6 output.filter-chain=iBGP-OUT .keep-sent-attributes=yes .redistribute=connected,bgp remote.address=fd00:dead:beef::1 .as=142108 router-id=10.155.255.2 routing-table=main templates=default_v6 use-bfd=no
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp name=HE-AMSIX-BAN-v4 remote.address=103.100.140.44 .as=6939 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=HE-AMSIX-BAN-v6 remote.address=2402:b740:15:388:0:a500:6939:1 .as=6939 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp name=RS1-AMSIX-BAN-v4 remote.address=103.100.140.251 .as=150388 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp name=RS2-AMSIX-BAN-v4 remote.address=103.100.140.252 .as=150388 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=RS1-AMSIX-BAN-v6 remote.address=2402:b740:15:388:a500:15:388:251 .as=150388 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=RS2-AMSIX-BAN-v6 remote.address=2402:b740:15:388:a500:15:388:252 .as=150388 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=230000 local.address=103.100.140.31 .role=ebgp name=HE-AMSIX-HK-v4 remote.address=103.247.139.6 .as=6939 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=HE-AMSIX-HK-v6 remote.address=2001:df0:296::a500:6939:1 .as=6939 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=500000 local.address=2407:9540:111:7::2 .role=ebgp name=HGC-HK-BACKUP-v6 remote.address=2407:9540:111:7::1 .as=142435 templates=HGC-HK-BACKUP-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=1500000 local.role=ebgp name=HGC-HK-BACKUP-v4 remote.address=103.168.174.177 .as=142435 templates=HGC-HK-BACKUP-v4
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=250000 local.address=103.247.139.76 .role=ebgp name=AMSIX-HK-RS1-v4 remote.address=103.247.139.125 .as=58560 templates=AMSIX-HK-v4 use-bfd=yes
/routing bgp connection add address-families=ip input.limit-process-routes-ipv4=250000 local.address=103.247.139.76 .role=ebgp name=AMSIX-HK-RS2-v4 remote.address=103.247.139.126 .as=58560 templates=AMSIX-HK-v4 use-bfd=yes
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp name=AMSIX-HK-RS1-v6 remote.address=2001:df0:296::a505:8560:1 .as=58560 templates=AMSIX-HK-v6 use-bfd=yes
/routing bgp connection add address-families=ipv6 input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp name=AMSIX-HK-RS2-v6 remote.address=2001:df0:296::a505:8560:2 .as=58560 templates=AMSIX-HK-v6 use-bfd=yes
/routing bgp connection add disabled=no input.limit-process-routes-ipv4=250000 local.role=ebgp name=Cloudflare-AMSIX-HK-v4 remote.address=103.247.139.50 .as=13335 templates=AMSIX-HK-v4
/routing bgp connection add disabled=no input.limit-process-routes-ipv6=250000 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp name=Cloudflare-AMSIX-HK-v6 remote.address=2001:df0:296::a501:3335:2 .as=13335 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Oriental_Power_Holdings_Ltd-HK-v4 remote.address=103.247.139.14 .as=139341 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Oriental_Power_Holdings_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:13:9341:1 .as=139341 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Nathosts_Limited-HK-v4 remote.address=103.247.139.59 .as=141677 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Nathosts_Limited-HK-v6 remote.address=2001:df0:296:0:a500:14:1677:1 .as=141677 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Hong_Kong_Broadband_Network_Limited__-HK-v4 remote.address=103.247.139.9 .as=9269 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Riot_Games-HK-v4 remote.address=103.247.139.18 .as=6507 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Riot_Games-HK-v6 remote.address=2001:df0:296::a500:6507:1 .as=6507 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DATALINE_LLC-HK-v4 remote.address=103.247.139.34 .as=35297 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=DATALINE_LLC-HK-v6 remote.address=2001:df0:296::a503:5297:1 .as=35297 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amarutu_Technology_Ltd-HK-v4 remote.address=103.247.139.72 .as=206264 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Amarutu_Technology_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:20:6264:1 .as=206264 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.address=103.247.139.76 .role=ebgp name=Deutsche_Telekom_AG-HK-v4 remote.address=103.247.138.197 .as=20936 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=SG.GS_Pte_Ltd-HK-v4 remote.address=103.247.139.45 .as=24482 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=SG.GS_Pte_Ltd-HK-v6 remote.address=2001:df0:296::a502:4482:1 .as=24482 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Earth_Network_TechnologyHong_KongCo.Limited-HK-v4 remote.address=103.247.139.26 .as=136493 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Earth_Network_TechnologyHong_KongCo.Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:6493:1 .as=136493 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Flag_Telecom_Asia_Limited-HK-v4 remote.address=103.247.139.42 .as=15412 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Flag_Telecom_Asia_Limited-HK-v6 remote.address=2001:df0:296::a501:5412:1 .as=15412 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.address=103.247.139.76 .role=ebgp name=TATA_Communications-HK-v4 remote.address=103.247.138.196 .as=4755 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v4 remote.address=103.247.139.67 .as=140627 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:14:627:1 .as=140627 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v4 remote.address=103.247.139.67 .as=140627 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:14:627:2 .as=140627 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v4 remote.address=103.247.139.61 .as=140627 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:14:627:1 .as=140627 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v4 remote.address=103.247.139.61 .as=140627 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=OneQode_Assets_Pty_Ltd-HK-v6 remote.address=2001:df0:296:0:a500:14:627:2 .as=140627 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=eBay,_Inc.-HK-v4 remote.address=103.247.139.40 .as=62955 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=eBay,_Inc.-HK-v6 remote.address=2001:df0:296::a506:2955:1 .as=62955 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Packet_Clearing_House-HK-v4 remote.address=103.247.139.19 .as=42 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Packet_Clearing_House-HK-v6 remote.address=2001:df0:296::a500:42:1 .as=42 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DingFeng_XinHuiHongKong_Technology_Limited-HK-v4 remote.address=103.247.139.35 .as=134548 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=DingFeng_XinHuiHongKong_Technology_Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:4548:1 .as=134548 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.15 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:1 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.15 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:3 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.15 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:2 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.12 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:1 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.12 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:3 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.12 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:2 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.57 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:1 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.57 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:3 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Google_Inc-HK-v4 remote.address=103.247.139.57 .as=15169 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Google_Inc-HK-v6 remote.address=2001:df0:296::a501:5169:2 .as=15169 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Tao_Bao_Hong_Kong_Limited-HK-v4 remote.address=103.247.139.20 .as=24429 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Tao_Bao_Hong_Kong_Limited-HK-v6 remote.address=2001:df0:296::a502:4429:1 .as=24429 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=i3D_BV-HK-v4 remote.address=103.247.139.38 .as=49544 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=i3D_BV-HK-v6 remote.address=2001:df0:296::a504:9544:1 .as=49544 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v4 remote.address=103.247.139.41 .as=136907 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:6907:2 .as=136907 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v4 remote.address=103.247.139.41 .as=136907 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:6907:1 .as=136907 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v4 remote.address=103.247.139.11 .as=136907 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:6907:2 .as=136907 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v4 remote.address=103.247.139.11 .as=136907 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Sparkoo_Technologies_Hong_Kong_Co._Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:6907:1 .as=136907 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Epsilon_Telecommunications_Limited-HK-v4 remote.address=103.247.139.4 .as=44356 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Epsilon_Telecommunications_Limited-HK-v6 remote.address=2001:df0:296::a504:4356:1 .as=44356 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Acquire_BPO-HK-v4 remote.address=103.247.139.55 .as=58907 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=ByteArk_Company_Limited-HK-v4 remote.address=103.247.139.77 .as=59238 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=ByteArk_Company_Limited-HK-v6 remote.address=2001:df0:296::a505:9238:1 .as=59238 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon-HK-v4 remote.address=103.247.139.10 .as=16509 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Amazon-HK-v6 remote.address=2001:df0:296::a501:6509:2 .as=16509 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon-HK-v4 remote.address=103.247.139.74 .as=16509 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Amazon-HK-v6 remote.address=2001:df0:296::a501:6509:2 .as=16509 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Viettel_Business_Solutions_Corporation-HK-v4 remote.address=103.247.139.31 .as=7552 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Viettel_Business_Solutions_Corporation-HK-v6 remote.address=2001:df0:296::a500:7552:2 .as=7552 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CMC_Telecom_Infrastructure_Corporation-HK-v4 remote.address=103.247.139.36 .as=45903 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=CMC_Telecom_Infrastructure_Corporation-HK-v6 remote.address=2001:df0:296::a504:5903:2 .as=45903 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v4 remote.address=103.247.139.30 .as=4775 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v6 remote.address=2001:df0:296::a500:4775:2 .as=4775 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v4 remote.address=103.247.139.30 .as=4775 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v6 remote.address=2001:df0:296::a500:4775:1 .as=4775 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v4 remote.address=103.247.139.44 .as=4775 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v6 remote.address=2001:df0:296::a500:4775:2 .as=4775 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v4 remote.address=103.247.139.44 .as=4775 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Innove_Communications,_Inc.-HK-v6 remote.address=2001:df0:296::a500:4775:1 .as=4775 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v4 remote.address=103.247.139.97 .as=32934 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v6 remote.address=2001:df0:296::a503:2934:1 .as=32934 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v4 remote.address=103.247.139.97 .as=32934 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v6 remote.address=2001:df0:296::a503:2934:2 .as=32934 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v4 remote.address=103.247.139.81 .as=32934 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v6 remote.address=2001:df0:296::a503:2934:1 .as=32934 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v4 remote.address=103.247.139.81 .as=32934 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-HK-v6 remote.address=2001:df0:296::a503:2934:2 .as=32934 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Belgacom_International_Carrier_Services_SA-HK-v4 remote.address=103.247.139.56 .as=6774 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.address=103.247.139.76 .role=ebgp name=Belgacom_International_Carrier_Services_SA-HK-v4 remote.address=103.247.138.195 .as=6774 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Converge_ICT_Solution_INC-HK-v4 remote.address=103.247.139.7 .as=17639 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Converge_ICT_Solution_INC-HK-v6 remote.address=2001:df0:296::a501:7639:1 .as=17639 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=RISE-HK-v4 remote.address=103.247.139.25 .as=63927 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=RISE-HK-v6 remote.address=2001:df0:296::a506:3927:1 .as=63927 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Clear_path_Networks,_Inc.-HK-v4 remote.address=103.247.139.37 .as=45754 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Clear_path_Networks,_Inc.-HK-v6 remote.address=2001:df0:296::a504:5754:1 .as=45754 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=CityLink_Co.,_LTD-HK-v4 remote.address=103.247.139.80 .as=24441 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=CityLink_Co.,_LTD-HK-v6 remote.address=2001:df0:296::a502:4441:1 .as=24441 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-HK-v4 remote.address=103.247.139.17 .as=20940 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Akamai-HK-v6 remote.address=2001:df0:296::a502:940:1 .as=20940 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-HK-v4 remote.address=103.247.139.17 .as=20940 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Akamai-HK-v6 remote.address=2001:df0:296::a502:940:2 .as=20940 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-HK-v4 remote.address=103.247.139.73 .as=20940 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Akamai-HK-v6 remote.address=2001:df0:296::a502:940:1 .as=20940 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai-HK-v4 remote.address=103.247.139.73 .as=20940 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Akamai-HK-v6 remote.address=2001:df0:296::a502:940:2 .as=20940 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Hurricane_Electric-HK-v4 remote.address=103.247.139.6 .as=6939 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Hurricane_Electric-HK-v6 remote.address=2001:df0:296::a500:6939:1 .as=6939 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Yahoo_Inc.-HK-v4 remote.address=103.247.139.58 .as=10310 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Yahoo_Inc.-HK-v6 remote.address=2001:df0:296::a501:310:1 .as=10310 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Telcotech_Limited-HK-v4 remote.address=103.247.139.29 .as=55329 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Telcotech_Limited-HK-v6 remote.address=2001:df0:296::a505:5329:1 .as=55329 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Vocus_Pty_Ltd-HK-v4 remote.address=103.247.139.27 .as=4826 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Vocus_Pty_Ltd-HK-v6 remote.address=2001:df0:296::a500:4826:1 .as=4826 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Cloudflare-HK-v4 remote.address=103.247.139.50 .as=13335 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Cloudflare-HK-v6 remote.address=2001:df0:296::a501:3335:2 .as=13335 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Pacswitch_Globe_Telecom_Limited-HK-v4 remote.address=103.247.139.33 .as=55536 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Pacswitch_Globe_Telecom_Limited-HK-v6 remote.address=2001:df0:296::a505:5536:1 .as=55536 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Limelight_Networks-HK-v4 remote.address=103.247.139.49 .as=22822 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Limelight_Networks-HK-v6 remote.address=2001:df0:296::a502:2822:1 .as=22822 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Verizon_Digital_Media_Services_Inc-HK-v4 remote.address=103.247.139.52 .as=15133 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Verizon_Digital_Media_Services_Inc-HK-v6 remote.address=2001:df0:296::a501:5133:1 .as=15133 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Twitter-HK-v4 remote.address=103.247.139.53 .as=13414 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Twitter-HK-v6 remote.address=2001:df0:296::a501:3414:1 .as=13414 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Computerline-HK-v4 remote.address=103.247.139.8 .as=41913 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Computerline-HK-v6 remote.address=2001:df0:296::a504:1913:1 .as=41913 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AWN-HK-v4 remote.address=103.247.139.48 .as=45430 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AWN-HK-v6 remote.address=2001:df0:296::a504:5430:1 .as=45430 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Chief_Telecom_Inc.-HK-v4 remote.address=103.247.139.65 .as=17408 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Chief_Telecom_Inc.-HK-v6 remote.address=2001:df0:296::a501:7408:1 .as=17408 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Telecommunication_Service_and_Network_Provider-HK-v4 remote.address=103.247.139.54 .as=7713 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Telecommunication_Service_and_Network_Provider-HK-v6 remote.address=2001:df0:296::a500:7713:1 .as=7713 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=G-Core_Labs_S.A.-HK-v4 remote.address=103.247.139.62 .as=199524 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=G-Core_Labs_S.A.-HK-v6 remote.address=2001:df0:296:0:a500:19:9524:1 .as=199524 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Philippine_Long_Distance_Telephone_Company-HK-v4 remote.address=103.247.139.43 .as=9299 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=DSV_AS-HK-v4 remote.address=103.247.139.82 .as=49362 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=MTel_Telecommunication_Company_Limited-HK-v4 remote.address=103.247.139.3 .as=133613 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=MTel_Telecommunication_Company_Limited-HK-v6 remote.address=2001:df0:296:0:a500:13:3613:1 .as=133613 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.address=103.247.139.76 .role=ebgp name=Vodafone_Enterprise_Netherlands_B.V.-HK-v4 remote.address=103.247.138.194 .as=4445 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Packet_Clearing_House-HK-v4 remote.address=103.247.139.75 .as=3856 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Packet_Clearing_House-HK-v6 remote.address=2001:df0:296::a500:3856:1 .as=3856 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AMS-IX_Hong_Kong_Route_Servers-HK-v4 remote.address=103.247.139.126 .as=58560 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AMS-IX_Hong_Kong_Route_Servers-HK-v6 remote.address=2001:df0:296::a505:8560:2 .as=58560 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AMS-IX_Hong_Kong_Route_Servers-HK-v4 remote.address=103.247.139.125 .as=58560 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AMS-IX_Hong_Kong_Route_Servers-HK-v6 remote.address=2001:df0:296::a505:8560:1 .as=58560 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AMS-IX_Hong_Kong_Native_Router-HK-v4 remote.address=103.247.139.1 .as=58516 templates=AMSIX-HK-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AMS-IX_Hong_Kong_Native_Router-HK-v6 remote.address=2001:df0:296::a505:8516:1 .as=58516 templates=AMSIX-HK-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Dot_Enterprise_Company_Ltd-BAN-v4 remote.address=103.100.140.205 .as=63989 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Dot_Enterprise_Company_Ltd-BAN-v6 remote.address=2402:b740:15:388:0:a506:3989:1 .as=63989 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Akamai_Technologies-BAN-v4 remote.address=103.100.140.173 .as=20940 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Akamai_Technologies-BAN-v6 remote.address=2402:b740:15:388:0:a502:940:1 .as=20940 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=KIRZ_Company_Limited-BAN-v4 remote.address=103.100.140.117 .as=133540 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=KIRZ_Company_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a502:4187:1 .as=133540 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=COLODEE_DIGITAL_NETWORK_CO.,_LTD.-BAN-v4 remote.address=103.100.140.73 .as=136523 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=COLODEE_DIGITAL_NETWORK_CO.,_LTD.-BAN-v6 remote.address=2402:b740:15:388:a500:13:6523:1 .as=136523 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=International_Gateway_Company_Limited-BAN-v4 remote.address=103.100.140.37 .as=137557 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=yes input.limit-process-routes-ipv6=100000 local.role=ebgp name=International_Gateway_Company_Limited-BAN-v6 remote.address=2402:b740:15:388:a500:13:7557:1 .as=137557 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Hurricane_Electric-BAN-v4 remote.address=103.100.140.44 .as=6939 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Hurricane_Electric-BAN-v6 remote.address=2402:b740:15:388:0:a500:6939:1 .as=6939 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=SUPERNAP_Thailand_Co.,Ltd.-BAN-v4 remote.address=103.100.140.58 .as=137566 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=SUPERNAP_Thailand_Co.,Ltd.-BAN-v6 remote.address=2402:b740:15:388:a500:13:7566:1 .as=137566 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Cable_Connect_Company-BAN-v4 remote.address=103.100.140.235 .as=135419 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Cable_Connect_Company-BAN-v6 remote.address=2402:b740:15:388:a500:13:5419:1 .as=135419 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon_Web_Services,_Inc-BAN-v4 remote.address=103.100.140.201 .as=16509 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Amazon_Web_Services,_Inc-BAN-v6 remote.address=2402:b740:15:388:0:a501:6509:1 .as=16509 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Amazon_Web_Services,_Inc-BAN-v6 remote.address=2402:b740:15:388:0:a501:6509:2 .as=16509 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Amazon_Web_Services,_Inc-BAN-v4 remote.address=103.100.140.204 .as=16509 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=National_Telecom_Public_Company_Limited-BAN-v4 remote.address=103.100.140.195 .as=38040 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=National_Telecom_Public_Company_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a503:8040:1 .as=38040 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Tencent-BAN-v4 remote.address=103.100.140.175 .as=139341 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=Tencent-BAN-v6 remote.address=2402:b740:15:388:a500:13:9341:1 .as=139341 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=JasTel_Network_Co.,_Ltd.-BAN-v4 remote.address=103.100.140.225 .as=45629 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=JasTel_Network_Co.,_Ltd.-BAN-v6 remote.address=2402:b740:15:388:0:a504:5629:1 .as=45629 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=Alibaba_Cloud_Thailand-BAN-v4 remote.address=103.100.140.120 .as=45102 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ip disabled=yes input.limit-process-routes-ipv4=200000 local.role=ebgp name=International_Gateway_Company_Limited-BAN-v4 remote.address=103.100.140.38 .as=140867 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=yes input.limit-process-routes-ipv6=100000 local.role=ebgp name=International_Gateway_Company_Limited-BAN-v6 remote.address=2402:b740:15:388:a500:14:867:1 .as=140867 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v4 remote.address=103.100.140.192 .as=32934 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a503:2934:2 .as=32934 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v4 remote.address=103.100.140.192 .as=32934 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a503:2934:1 .as=32934 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v4 remote.address=103.100.140.199 .as=32934 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a503:2934:2 .as=32934 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v4 remote.address=103.100.140.199 .as=32934 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=_Edge_Network_Services_Limited-BAN-v6 remote.address=2402:b740:15:388:0:a503:2934:1 .as=32934 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AMS-IX_AMS-IX_Bangkok_Route_Servers-BAN-v4 remote.address=103.100.140.251 .as=150388 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AMS-IX_AMS-IX_Bangkok_Route_Servers-BAN-v6 remote.address=2402:b740:15:388:a500:15:388:251 .as=150388 templates=AMSIX-BAN-v6
/routing bgp connection add address-families=ip disabled=no input.limit-process-routes-ipv4=200000 local.role=ebgp name=AMS-IX_AMS-IX_Bangkok_Route_Servers-BAN-v4-2 remote.address=103.100.140.252 .as=150388 templates=AMSIX-BAN-v4
/routing bgp connection add address-families=ipv6 disabled=no input.limit-process-routes-ipv6=100000 local.role=ebgp name=AMS-IX_AMS-IX_Bangkok_Route_Servers-BAN-v6-2 remote.address=2402:b740:15:388:a500:15:388:252 .as=150388 templates=AMSIX-BAN-v6
/routing bgp connection add as=9304 local.address=103.247.139.76 .role=ebgp name=HGC_Global_Communications_Limited-HK-v4 remote.address=103.247.139.39 templates=AMSIX-HK-v4
/routing bgp connection add as=9304 local.address=2001:df0:296:0:a500:14:2108:1 .role=ebgp name=HGC_Global_Communications_Limited-HK-v6 remote.address=2001:df0:296::a500:9304:1 templates=AMSIX-HK-v6
/routing bgp connection add as=9304 local.address=103.100.140.31 .role=ebgp name=HGC_Global_Communications-BAN-v4 remote.address=103.100.140.47 templates=AMSIX-BAN-v4
/routing bgp connection add as=9304 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=HGC_Global_Communications-BAN-v6 remote.address=2402:b740:15:388:0:a500:9304:1 templates=AMSIX-BAN-v6
/routing bgp connection add as=142435 local.address=103.100.140.31 .role=ebgp name=HGC_Global_Communications_Thailand-BAN-v4 remote.address=103.100.140.98 templates=AMSIX-BAN-v4
/routing bgp connection add as=142435 local.address=2402:b740:15:388:a500:14:2108:1 .role=ebgp name=HGC_Global_Communications_Thailand-BAN-v6 remote.address=2402:b740:15:388:a500:14:2435:1 templates=AMSIX-BAN-v6
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
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list hgc-th-sg-communities) { set bgp-local-pref 170; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list hgc-hk-communities) { set bgp-local-pref 120; }"
/routing filter rule add chain=iBGP-IN rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 100; }"
/routing filter rule add chain=iBGP-IN rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=iBGP-OUT rule="set bgp-large-communities ibgp-communities; accept;"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v6 rule="set bgp-med 50; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-SG-OUT-v4 rule="set bgp-med 50; set bgp-path-prepend 2; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-BAN-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v4 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-BAN-OUT-v6 rule="set bgp-med 20; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 3; set bgp-large-communities location; accept"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=HGC-HK-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 3; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v4 rule="set bgp-med 100; set bgp-path-prepend 3; set bgp-large-communities location; accept"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing filter rule add chain=AMSIX-HK-OUT-v6 rule="set bgp-med 100; set bgp-path-prepend 3; set bgp-large-communities location; accept"
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
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="RPKI validation" rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Reject RPKI invalid routes" rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Discard default route" rule="if (dst == 0.0.0.0/0) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard IPv6 bogons" rule="if (dst in ipv6-bogons) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard overly specific IPv6 prefixes" rule="if (dst-len > 48) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="RPKI validation" rule="rpki-verify rpki.bknix.co.th"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Reject RPKI invalid routes" rule="if (rpki invalid) { reject; }"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Discard default route" rule="if (dst == ::/0) { reject; }"
/routing filter rule add chain=AMSIX-BAN-IN-v4 comment="Accept route v4" rule="set bgp-large-communities amsix-ban-communities; set bgp-local-pref 190; accept"
/routing filter rule add chain=HGC-SG-IN-v4 comment="Accept route v4" rule="set bgp-large-communities hgc-sg-communities; set bgp-local-pref 160; accept"
/routing filter rule add chain=AMSIX-HK-IN-v4 comment="Accept route v4" rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"
/routing filter rule add chain=HGC-HK-IN-v4 comment="Accept route v4" rule="set bgp-large-communities hgc-th-hk-communities; set bgp-local-pref 130; accept"
/routing filter rule add chain=AMSIX-BAN-IN-v6 comment="Accept route v6" rule="set bgp-large-communities amsix-ban-communities; set bgp-local-pref 190; accept"
/routing filter rule add chain=HGC-SG-IN-v6 comment="Accept route v6" rule="set bgp-large-communities hgc-sg-communities; set bgp-local-pref 160; accept"
/routing filter rule add chain=AMSIX-HK-IN-v6 comment="Accept route v6" rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"
/routing filter rule add chain=HGC-HK-IN-v6 comment="Accept route v6" rule="set bgp-large-communities hgc-th-hk-communities; set bgp-local-pref 130; accept"
/routing filter rule add chain=graceful-shutdown rule="set bgp-communities graceful-shutdown; set bgp-local-pref 0; accept"
/routing ospf interface-template add area=backbone comment=BKK20-LO disabled=no networks=10.155.255.2 use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=AMSIX-BAN-v6 disabled=no networks=2402:b740:15:388::/64 passive use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment=HGC-HK-IPTx-v6 disabled=no networks=2403:5000:165:15::/64 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=BKK10-BKK20 disabled=no networks=172.16.0.0/30 use-bfd=no
/routing ospf interface-template add area=backbone comment=BKK20-BKK50 disabled=no networks=172.16.20.0/30 use-bfd=no
/routing ospf interface-template add area=backbone comment=ROTKO-UNICAST disabled=no networks=160.22.181.0/24 use-bfd=no
/routing ospf interface-template add area=backbone comment=HGC-HK-IPTx disabled=no networks=118.143.234.72/29 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=AMSIX-BAN-v4 disabled=no networks=103.100.140.0/24 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=AMSIX-HK-v4 disabled=no networks=103.247.139.76/25 passive use-bfd=no
/routing ospf interface-template add area=backbone comment=HK-HGC-IPTx-backup-vlan2517 disabled=no networks=103.168.174.178/30 passive use-bfd=no
/routing ospf interface-template add area=backbone-v6 comment="ULA BKK50 Link" disabled=no networks=fd00:dead:beef:20::1/126
/routing ospf interface-template add area=backbone-v6 comment="ULA BKK10 Link" disabled=no networks=fd00:dead:beef::1/126
/routing ospf interface-template add area=backbone-v6 comment=ROTKO-UNICAST-v6 disabled=no networks=2401:a860::/32 use-bfd=no
/routing rpki add address=203.159.70.26 comment="Routinator IPv4 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=2001:deb:0:4070::26 comment="Routinator IPv6 Primary" group=rpki.bknix.co.th port=323
/routing rpki add address=203.159.70.36 comment="StayRTR IPv4 Secondary" group=rpki.bknix.net port=4323
/routing rpki add address=2001:deb:0:4070::36 comment="StayRTR IPv6 Secondary" group=rpki.bknix.net port=4323
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
/system note set show-at-login=no
/system ntp client set enabled=yes
/system ntp client servers add address=3.sg.pool.ntp.org
/system ntp client servers add address=2.sg.pool.ntp.org
/system routerboard settings set enter-setup-on=delete-key
/user group add name=mktxp_group policy=ssh,read,api,!local,!telnet,!ftp,!reboot,!write,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api
