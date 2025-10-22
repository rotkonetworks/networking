# 2025-10-21 23:05:49 by RouterOS 7.20beta2
# software id = I1J4-ZIVY
#
# model = CCR2004-16G-2S+
# serial number = HEF08WE12HR
/interface bridge add name=bridge_local vlan-filtering=yes
/interface ethernet set [ find default-name=ether9 ] comment=bkk-sax-01-kvm
/interface ethernet set [ find default-name=ether10 ] comment=bkk-sax-01-9950x
/interface ethernet set [ find default-name=sfp-sfpplus1 ] advertise=10G-baseCR comment="atm to bkk00 hk" fec-mode=fec91
/interface ethernet set [ find default-name=sfp-sfpplus2 ] advertise=10G-baseCR comment="atm to bkk20 sg" fec-mode=fec91
/interface wireguard add listen-port=52281 mtu=1420 name=bkk_sax_wg
/interface wireguard add listen-port=52180 mtu=1420 name=wg_rotko
/interface vlan add interface=bridge_local name=vlan_cgnat vlan-id=100
/interface bonding add comment=bkk00-sfp11 lacp-rate=1sec mode=802.3ad name=BKK00-LAG slaves=sfp-sfpplus1 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=BKK20-sfp11 lacp-rate=1sec mode=802.3ad name=BKK20-LAG slaves=sfp-sfpplus2 transmit-hash-policy=layer-2-and-3
/interface bonding add comment=saxemberg-9950X-client name=SAX-BKK-01 slaves=ether9
/interface bonding add comment=saxemberg-9950X-asrock-ipmi-client name=SAX-BKK-01-KVM slaves=ether10
/interface list add name=WAN
/interface list add name=local
/interface list add name=WG
/ip pool add name=dhcp69 ranges=192.168.69.210-192.168.69.236
/ip pool add name=saxbkk ranges=10.69.169.2-10.69.169.254
/ip pool add name=cgnat_pool ranges=100.64.0.10-100.64.0.250
/ip dhcp-server add address-pool=dhcp69 interface=bridge_local name=dhcp1
/ip dhcp-server add address-pool=saxbkk interface=SAX-BKK-01-KVM name=saxemberg-kvm
/ip dhcp-server add address-pool=cgnat_pool interface=vlan_cgnat name=dhcp_cgnat
/port set 0 name=serial0
/routing bgp instance add as=142108 name=bgp-instance-1 router-id=10.155.255.3
/routing bgp template add add-path-out=all afi=ip as=142108 input.filter=iBGP-IN-v4 multihop=yes name=iBGP-v4 nexthop-choice=default output.filter-chain=iBGP-OUT-v4
/routing bgp template add afi=ipv6 as=142108 input.filter=iBGP-IN-v6 multihop=yes name=iBGP-v6 nexthop-choice=default output.filter-chain=iBGP-OUT-v6
/routing id add id=10.155.255.3 name=main select-dynamic-id=only-static select-from-vrf=main
/routing ospf instance add comment="OSPF instance for LocalGW" disabled=no name=ospf-instance-1 originate-default=never redistribute=static router-id=10.155.255.3
/routing ospf instance add comment="OSPFv3 instance for LocalGW" disabled=no name=ospf-instance-v3 originate-default=never router-id=10.155.255.3 version=3
/routing ospf area add disabled=no instance=ospf-instance-1 name=backbone
/routing ospf area add disabled=no instance=ospf-instance-v3 name=backbone-v6
/system logging action set 0 memory-lines=1
/system logging action set 3 remote=192.168.77.92 remote-log-format=syslog syslog-facility=local0
/user group add name=mktxp_group policy=ssh,read,api,!local,!telnet,!ftp,!reboot,!write,!policy,!test,!winbox,!password,!web,!sniff,!sensitive,!romon,!rest-api
/interface bridge port add bridge=bridge_local interface=ether1
/interface bridge port add bridge=bridge_local interface=ether2
/interface bridge port add bridge=bridge_local interface=ether3
/interface bridge port add bridge=bridge_local interface=ether4
/interface bridge port add bridge=bridge_local interface=ether5
/interface bridge port add bridge=bridge_local interface=ether6
/interface bridge port add bridge=bridge_local interface=ether7
/interface bridge port add bridge=bridge_local interface=ether8
/interface bridge port add bridge=bridge_local comment="SAX-BKK-01 Machine" disabled=yes interface=ether9
/interface bridge port add bridge=bridge_local comment="SAX-BKK-01 KVM" disabled=yes interface=ether10
/interface bridge port add bridge=bridge_local comment=bkk06mgmt interface=ether11
/interface bridge port add bridge=bridge_local comment=bkk06 interface=ether12
/interface bridge port add bridge=bridge_local comment=bkk07mgmt interface=ether13
/interface bridge port add bridge=bridge_local comment=bkk07 interface=ether14
/interface bridge port add bridge=bridge_local comment=bkk08mgmt interface=ether15
/interface bridge port add bridge=bridge_local comment=bkk08 interface=ether16
/ip firewall connection tracking set udp-timeout=10s
/ipv6 settings set accept-router-advertisements=no
/interface bridge vlan add bridge=bridge_local tagged=ether13,ether14 vlan-ids=100
/interface list member add interface=sfp-sfpplus1 list=WAN
/interface list member add interface=sfp-sfpplus2 list=WAN
/interface list member add interface=bridge_local list=local
/interface list member add interface=ether1 list=local
/interface list member add interface=ether2 list=local
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
/interface list member add interface=ether14 list=local
/interface list member add interface=ether15 list=local
/interface list member add interface=ether16 list=local
/interface list member add interface=lo list=local
/interface list member add interface=wg_rotko list=WG
/interface list member add interface=BKK00-LAG list=WAN
/interface list member add interface=BKK20-LAG list=WAN
/interface ovpn-server server add mac-address=FE:0A:3F:45:6B:F2 name=ovpn-server1
/interface wireguard peers add allowed-address=172.31.0.1/32 disabled=yes interface=wg_rotko name=tn_laptop public-key="udBx+UmZ60dJCyF6QxxNmEPnBT+nIkv6ZdCZKTAVdSA="
/interface wireguard peers add allowed-address=172.31.0.20/32 disabled=yes interface=wg_rotko name=peer8 public-key="/09ofEbIM1qjlq7xM/R0KfJMQ8R/UR9aHaph70FTp30="
/interface wireguard peers add allowed-address=172.31.0.2/32 disabled=yes interface=wg_rotko name=peer9 public-key="k9UnZ8ssv9SccGUMwQ8PHIwXeT4j5P0jDDoWhi3abCI="
/interface wireguard peers add allowed-address=172.30.50.2/32 comment=tommi@pc01 interface=wg_rotko name=peer10 public-key="IlZR7z5LVE6BKwkApq+VTvXRGaOp0hvmKSSrgi1R/V4="
/interface wireguard peers add allowed-address=172.31.0.10/32 comment=bkk10 disabled=yes interface=wg_rotko name=peer3 public-key="nahvhOxYg+859oPKgnXopw2fqvcpJFaC92SqdMckI0I="
/interface wireguard peers add allowed-address=172.30.50.4/32 comment=bkk04 interface=wg_rotko name=peer7 public-key="SRPXYavqbiZpuLFMhNRT/mieCy6hsYaOODb3zNtzriw="
/interface wireguard peers add allowed-address=172.30.50.6/32 comment=alarchlinux interface=wg_rotko name=peer11 public-key="fpjwiYxizNATSZMwrK7wKf2IqSfm/ZKcSOur9BMT5Bg="
/interface wireguard peers add allowed-address=172.29.169.11/32 comment=al interface=bkk_sax_wg name=peer12 public-key="fpjwiYxizNATSZMwrK7wKf2IqSfm/ZKcSOur9BMT5Bg="
/ip address add address=192.168.88.50/24 comment=defconf interface=bridge_local network=192.168.88.0
/ip address add address=192.168.69.1/16 interface=bridge_local network=192.168.0.0
/ip address add address=10.155.255.3 interface=lo network=10.155.255.3
/ip address add address=172.16.10.2/30 interface=BKK00-LAG network=172.16.10.0
/ip address add address=172.16.20.2/30 interface=BKK20-LAG network=172.16.20.0
/ip address add address=160.22.181.181 interface=lo network=160.22.181.181
/ip address add address=10.50.0.1 interface=lo network=10.50.0.1
/ip address add address=192.168.69.1 interface=lo network=192.168.69.1
/ip address add address=172.30.50.1/24 interface=wg_rotko network=172.30.50.0
/ip address add address=172.29.169.1/24 interface=bkk_sax_wg network=172.29.169.0
/ip address add address=160.22.181.181/28 interface=bridge_local network=160.22.181.176
/ip address add address=160.22.181.169/29 interface=SAX-BKK-01 network=160.22.181.168
/ip address add address=160.22.181.169 interface=lo network=160.22.181.169
/ip address add address=10.69.169.1/24 interface=SAX-BKK-01-KVM network=10.69.169.0
/ip address add address=160.22.181.20 interface=lo network=160.22.181.20
/ip address add address=172.16.50.1/31 interface=BKK00-LAG network=172.16.50.0
/ip address add address=100.64.0.1/24 interface=bridge_local network=100.64.0.0
/ip dhcp-server lease add address=192.168.69.232 client-id=1:48:da:35:6f:6b:66 comment="bkk09nanokvm, port 80 for kvm" mac-address=48:DA:35:6F:6B:66 server=dhcp1
/ip dhcp-server lease add address=192.168.69.231 client-id=1:e4:5f:1:de:47:96 comment="blikvm nixos" mac-address=E4:5F:01:DE:47:96 server=dhcp1
/ip dhcp-server lease add address=192.168.69.230 comment=bkk09 mac-address=58:47:CA:78:CD:48 server=dhcp1
/ip dhcp-server lease add address=192.168.69.221 client-id=1:9c:6b:0:1c:e3:a1 comment="bkk03 ipmi" mac-address=9C:6B:00:1C:E3:A1 server=dhcp1
/ip dhcp-server lease add address=10.69.169.2 client-id=1:9c:6b:0:6d:8b:21 comment=saxembergkvm mac-address=9C:6B:00:6D:8B:21 server=saxemberg-kvm
/ip dhcp-server lease add address=192.168.69.227 client-id=1:3c:ec:ef:e3:5c:bf comment="bkk07 ipmi" mac-address=3C:EC:EF:E3:5C:BF server=dhcp1
/ip dhcp-server lease add address=192.168.69.220 client-id=1:3c:ec:ef:73:30:8b comment="bkk08 ipmi" mac-address=3C:EC:EF:73:30:8B server=dhcp1
/ip dhcp-server lease add address=192.168.69.218 comment="bkk08 machine" mac-address=3C:EC:EF:73:2F:7B server=dhcp1
/ip dhcp-server lease add address=192.168.69.216 client-id=1:9c:6b:0:84:cf:63 comment="bkk13 ipmi" mac-address=9C:6B:00:84:CF:63 server=dhcp1
/ip dhcp-server lease add address=192.168.69.217 client-id=1:9c:6b:0:84:cf:85 comment="bkk11 ipmi" mac-address=9C:6B:00:84:CF:85 server=dhcp1
/ip dhcp-server lease add address=192.168.69.214 disabled=yes mac-address=9C:6B:00:84:CD:B4 server=dhcp1
/ip dhcp-server lease add address=192.168.69.212 client-id=ff:fc:e3:ea:9a:0:2:0:0:ab:11:83:cc:34:84:60:61:8d:22 mac-address=3E:80:02:B7:1E:5A server=dhcp1
/ip dhcp-server lease add address=192.168.69.210 comment=val-paseo-bkk13-01 mac-address=52:54:00:DD:41:AE server=dhcp1
/ip dhcp-server lease add address=192.168.69.219 client-id=ff:0:dd:1e:d8:0:1:0:1:2f:8f:7a:95:52:54:0:dd:1e:d8 comment=val-paseo-bkk13-02 mac-address=52:54:00:DD:1E:D8 server=dhcp1
/ip dhcp-server lease add address=192.168.69.222 client-id=ff:0:96:39:9c:0:1:0:1:2f:8f:96:fb:52:54:0:96:39:9c comment=val-kusama-bkk13-01 mac-address=52:54:00:96:39:9C server=dhcp1
/ip dhcp-server lease add address=192.168.69.215 client-id=1:9c:6b:0:9f:f5:57 comment="bkk12 ipmi" mac-address=9C:6B:00:9F:F5:57 server=dhcp1
/ip dhcp-server network add address=10.69.169.0/24 dns-server=9.9.9.9 gateway=10.69.169.1
/ip dhcp-server network add address=192.168.0.0/16 dns-server=9.9.9.9 gateway=192.168.69.1
/ip dns set cache-max-ttl=1d cache-size=4096KiB max-concurrent-queries=30 max-concurrent-tcp-sessions=10 max-udp-packet-size=512 servers=9.9.9.9,2620:fe::fe,1.0.0.1,8.8.4.4
/ip firewall address-list add address=100.64.0.0/10 comment="CGNAT subnets" list=cgnat_customers
/ip firewall address-list add list=ddos-attackers
/ip firewall address-list add list=ddos-targets
/ip firewall address-list add address=0.0.0.0/8 comment=RFC6890 list=not_in_internet
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
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA-assigned block" list=our-networks
/ip firewall address-list add address=203.159.68.0/23 comment="BKNIX network" list=our-networks
/ip firewall address-list add address=118.143.211.184/29 comment=HK-HGC-vlan2519 list=our-networks
/ip firewall address-list add address=118.143.234.72/29 comment=HK-SG-vlan2520 list=our-networks
/ip firewall address-list add address=172.31.0.0/16 comment=wg_rotko list=our-networks
/ip firewall address-list add address=172.16.0.0/16 comment=ospf list=our-networks
/ip firewall address-list add address=10.155.255.0/24 list=our-networks
/ip firewall address-list add address=10.0.0.0/8 list=our-networks
/ip firewall address-list add address=192.168.0.0/16 list=our-networks
/ip firewall address-list add address=172.16.20.1 list=ospf-neighbors
/ip firewall address-list add address=172.16.10.1 list=ospf-neighbors
/ip firewall address-list add address=172.16.20.2 list=our-ospf
/ip firewall address-list add address=172.16.10.2 list=our-ospf
/ip firewall address-list add address=10.155.255.1 list=ospf-neighbors
/ip firewall address-list add address=10.155.255.2 list=ospf-neighbors
/ip firewall address-list add address=10.155.255.3 list=ospf-neighbors
/ip firewall address-list add address=0.0.0.0/0 list=non-local-destinations
/ip firewall address-list add address=10.0.0.0/8 comment="RFC1918 Private Network" list=private-networks
/ip firewall address-list add address=172.16.0.0/12 comment="RFC1918 Private Network" list=private-networks
/ip firewall address-list add address=192.168.0.0/16 comment="RFC1918 Private Network" list=private-networks
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA-assigned block" list=public-networks
/ip firewall address-list add address=10.0.0.0/8 comment="RFC1918 Private Network" list=all-internal-networks
/ip firewall address-list add address=172.16.0.0/12 comment="RFC1918 Private Network" list=all-internal-networks
/ip firewall address-list add address=192.168.0.0/16 comment="RFC1918 Private Network" list=all-internal-networks
/ip firewall address-list add address=160.22.180.0/23 comment="Our IANA-assigned block" list=all-internal-networks
/ip firewall address-list add address=9.9.9.9 comment="Quad9 DNS" list=dns_servers
/ip firewall address-list add address=1.1.1.1 comment="Cloudflare DNS" list=dns_servers
/ip firewall address-list add address=8.8.8.8 comment="Google DNS" list=dns_servers
/ip firewall address-list add address=160.22.181.168/29 list=not_in_internet
/ip firewall filter add action=drop chain=input dst-port=161 in-interface-list=WAN protocol=udp
/ip firewall filter add action=fasttrack-connection chain=forward comment=Fasttrack connection-state=established,related,untracked hw-offload=yes
/ip firewall filter add action=accept chain=forward comment="Allow established/related" connection-state=established,related,untracked
/ip firewall filter add action=drop chain=forward comment="Drop invalid" connection-state=invalid
/ip firewall filter add action=accept chain=forward dst-port=25001 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=25002 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3513 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=13513 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34031 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3323 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=13323 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34032 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3147 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3341 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10971 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34071 protocol=tcp
/ip firewall filter add action=drop chain=input comment="Block VM to router 192.168" dst-address=192.168.0.0/16 src-address=160.22.181.254
/ip firewall filter add action=drop chain=input comment="Block VM to router 10.x" dst-address=10.0.0.0/8 src-address=160.22.181.254
/ip firewall filter add action=drop chain=input comment="Block VM to router 172.16-31" dst-address=172.16.0.0/12 src-address=160.22.181.254
/ip firewall filter add action=drop chain=forward comment="Block VM to 192.168" dst-address=192.168.0.0/16 src-address=160.22.181.254
/ip firewall filter add action=drop chain=forward comment="Block CGNAT to local 192.168" dst-address=192.168.0.0/16 src-address=100.64.0.0/24
/ip firewall filter add action=drop chain=forward comment="Block VM to 10.x" dst-address=10.0.0.0/8 src-address=160.22.181.254
/ip firewall filter add action=drop chain=forward comment="Block CGNAT to local 10.x" dst-address=10.0.0.0/8 src-address=100.64.0.0/24
/ip firewall filter add action=drop chain=forward comment="Block VM to 172.16-31" dst-address=172.16.0.0/12 src-address=160.22.181.254
/ip firewall filter add action=drop chain=forward comment="Block CGNAT to local 172.16-31" dst-address=172.16.0.0/12 src-address=100.64.0.0/24
/ip firewall filter add action=accept chain=forward comment="Allow VM to internet" src-address=160.22.181.254
/ip firewall filter add action=drop chain=forward comment="Block local to CGNAT" dst-address=100.64.0.0/24 src-address=192.168.0.0/16
/ip firewall filter add action=drop chain=forward comment="Block local to CGNAT" dst-address=100.64.0.0/24 src-address=10.0.0.0/8
/ip firewall filter add action=accept chain=forward comment="BYPASS RULE - DISABLE WHEN NOT NEEDED"
/ip firewall filter add action=accept chain=forward dst-port=3142 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10972 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34072 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3742 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10821 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31321 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3842 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10822 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3831 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10731 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31231 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3241 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3833 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10833 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31232 protocol=tcp
/ip firewall filter add action=accept chain=input comment="BYPASS RULE - DISABLE WHEN NOT NEEDED" disabled=yes
/ip firewall filter add action=accept chain=input comment="allow wg_rotko traffic -al" protocol=udp src-address=172.30.50.0/24
/ip firewall filter add action=accept chain=forward dst-port=2915 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10815 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3178 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=13178 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3197 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=13197 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2982 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10182 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3141 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31311 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31003 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2483 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=26683 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2142 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10142 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34005 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2918 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10178 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3242 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10302 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31302 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3231 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31211 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3232 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31212 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=26681 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2481 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2167 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10167 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3361 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10361 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3362 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10362 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31251 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3137 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31271 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3881 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3391 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10831 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3135 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10135 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31252 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31272 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3882 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3392 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10839 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3891 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10891 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31291 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3892 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10892 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31292 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3138 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31281 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3838 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10834 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31282 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2131 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10131 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31201 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2132 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10132 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31202 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2141 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10141 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34004 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3136 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10136 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31262 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3834 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31242 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32012 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32062 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2482 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=26682 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2958 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10958 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34011 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2341 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10341 protocol=tcp
/ip firewall filter add action=accept chain=forward port=53 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=34001 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2838 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10838 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31261 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2321 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10321 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32001 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2622 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10622 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2652 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10652 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2602 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32008 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10602 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2916 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10916 protocol=tcp
/ip firewall filter add action=accept chain=input dst-address=160.22.181.174 dst-port=54242 protocol=tcp
/ip firewall filter add action=accept chain=input comment=NAT-KVM-54242 dst-address=160.22.181.174 dst-port=54242 protocol=tcp
/ip firewall filter add action=accept chain=forward comment=NAT-KVM-54242-FWD dst-address=10.69.169.2 dst-port=54242 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33051 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2829 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10829 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32041 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2814 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10814 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33041 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2824 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10824 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32051 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=21006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=22006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=12006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=42006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=11006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31006 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=41006 protocol=tcp
/ip firewall filter add action=accept chain=input comment=sax-bkk-wg protocol=udp src-address=172.29.169.0/24
/ip firewall filter add action=accept chain=forward dst-port=2961 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10961 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2954 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10954 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2992 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10172 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31001 protocol=tcp
/ip firewall filter add action=accept chain=input comment="for mktxp" dst-port=8728 protocol=tcp src-address=192.168.0.0/16
/ip firewall filter add action=accept chain=forward dst-port=33001 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2917 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10177 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2991 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10991 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2996 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10314 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30434 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30434 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30434 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30434 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30434 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2935 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33052 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2869 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10869 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33042 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2828 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10828 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32052 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2830 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10830 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32042 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2631 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33011 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2634 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10634 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33012 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31011 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31012 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33021 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33022 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31031 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31032 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33031 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33032 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31052 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2623 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10623 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32011 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2651 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10651 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2601 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10601 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32061 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31022 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32022 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2715 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10715 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2725 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10725 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=31021 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=32021 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2845 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10845 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2311 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10311 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2331 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10331 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2611 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10611 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2612 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10612 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2641 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10641 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2642 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10642 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2661 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10661 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2662 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10662 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2671 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10671 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2672 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10672 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2691 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10691 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2692 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10692 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30334 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=30335 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2902 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2905 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2125 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10125 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33125 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34125 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2116 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10116 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33116 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34116 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2117 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10117 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33117 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34117 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2998 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2115 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10115 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33115 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34115 protocol=tcp
/ip firewall filter add action=accept chain=input comment="allow wg_rotko -al" dst-port=52180 protocol=udp
/ip firewall filter add action=accept chain=input comment=sax-bkk-wg dst-port=52281 protocol=udp
/ip firewall filter add action=accept chain=input disabled=yes dst-port=52180 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=2904 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2901 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=3866 protocol=tcp
/ip firewall filter add action=accept chain=input disabled=yes in-interface=wg_rotko
/ip firewall filter add action=accept chain=forward in-interface=wg_rotko out-interface-list=WAN
/ip firewall filter add action=accept chain=forward in-interface-list=WAN out-interface=wg_rotko
/ip firewall filter add action=accept chain=forward dst-port=2816 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10816 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33816 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34816 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35816 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35317 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35322 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2332 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10332 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33332 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34332 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35332 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2342 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10342 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33342 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34342 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35342 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35312 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2967 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10967 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33967 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34967 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35967 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2966 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10966 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33966 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34966 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35966 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2847 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10847 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33847 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34847 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35847 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2216 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35925 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10214 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33214 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34214 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35214 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2226 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10224 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33224 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34224 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35224 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2236 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10234 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33234 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34234 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35234 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2516 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10514 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33514 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34514 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35514 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2526 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10524 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33524 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34524 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35524 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2536 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10534 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33534 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34534 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35534 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2546 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10543 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33543 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34543 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35543 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2556 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10553 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33553 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34553 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35553 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2566 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10563 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33563 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34563 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35563 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2576 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10576 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33576 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34576 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35576 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2596 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10593 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33593 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34593 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35593 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2506 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10504 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33504 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34504 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35504 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2316 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10316 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33316 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34316 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2326 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10326 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33326 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34326 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2336 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10336 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33336 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34336 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2146 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10146 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33146 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34146 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2246 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10246 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33246 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34246 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35246 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2346 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10346 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33346 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34346 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2606 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10606 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33606 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34606 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2616 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10616 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33616 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34616 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35616 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2626 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10626 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33626 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34626 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35626 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2636 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10636 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33636 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34636 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35636 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2646 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10646 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33646 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34646 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35646 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2656 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10656 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33656 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34656 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35656 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2666 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10666 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33666 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34666 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35666 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2676 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10676 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33676 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34676 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35676 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2696 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10696 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33696 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34696 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35696 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2836 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10836 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33836 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34836 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35836 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2736 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10736 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33736 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34736 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35736 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2936 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10936 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33936 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34936 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35936 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2766 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10766 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33766 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34766 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35766 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2866 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10866 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33866 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34866 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35866 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2946 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10946 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33946 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34946 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35946 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2956 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10956 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33956 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34956 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35956 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2726 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10726 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33726 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34726 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35726 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2826 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10826 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33826 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34826 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35826 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2756 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10756 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33756 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34756 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35756 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2856 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10856 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33856 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34856 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35856 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2846 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10846 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33846 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34846 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35846 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2625 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10925 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33925 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34925 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35837 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2107 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10107 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33107 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=8888 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34107 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2827 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10827 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33827 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34827 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35827 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2857 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10857 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33857 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34857 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35857 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2937 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10937 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33937 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34937 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35937 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2867 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10867 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33867 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34867 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35867 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2897 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10897 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33897 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34897 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35897 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2957 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10957 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33957 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34957 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35957 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2617 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10617 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33617 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34617 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=35617 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2123 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10123 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33123 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33123 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=34123 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34123 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=34103 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2113 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10113 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33113 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33113 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=34113 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34113 protocol=udp
/ip firewall filter add action=accept chain=forward dst-port=2997 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34313 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34333 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2613 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10613 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33613 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34613 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2633 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10633 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33633 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34633 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2643 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10643 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33643 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34643 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2663 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10663 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33663 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34663 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2673 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10673 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33673 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34673 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2693 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10693 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33693 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=34693 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=2103 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=10103 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=33103 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=28006 protocol=tcp
/ip firewall filter add action=accept chain=input dst-port=20780 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=20780-20820 protocol=tcp
/ip firewall filter add action=accept chain=input comment="Allow SSH" dst-port=22 protocol=tcp
/ip firewall filter add action=accept chain=input comment="Allow established/related" connection-state=established,related
/ip firewall filter add action=drop chain=input comment="Drop invalid" connection-state=invalid
/ip firewall filter add action=accept chain=input comment="Allow ICMP" protocol=icmp
/ip firewall filter add action=accept chain=input comment="Allow SNMP" dst-port=161 protocol=udp
/ip firewall filter add action=accept chain=input comment="Allow Winbox" dst-port=8291 protocol=tcp
/ip firewall filter add action=accept chain=input comment="Allow DNS" dst-port=53 protocol=udp
/ip firewall filter add action=accept chain=input comment="Allow NTP" dst-port=123 protocol=udp
/ip firewall filter add action=accept chain=input comment="Allow OSPF" protocol=ospf
/ip firewall filter add action=drop chain=input comment="Drop all other input"
/ip firewall filter add action=accept chain=forward dst-address-list=WAN
/ip firewall filter add action=accept chain=forward out-interface-list=WAN
/ip firewall filter add action=accept chain=forward comment="testing routing to haproxy -al" dst-port=30435 protocol=tcp
/ip firewall filter add action=accept chain=forward dst-port=8188 protocol=tcp
/ip firewall filter add action=accept chain=forward comment="Allow our networks to Internet" src-address-list=our-networks
/ip firewall filter add action=accept chain=forward comment="Allow CGNAT customers to Internet" src-address-list=cgnat_customers
/ip firewall filter add action=drop chain=forward comment="Drop traffic from not_in_internet list" src-address-list=not_in_internet
/ip firewall filter add action=drop chain=forward dst-address-list=not_in_internet
/ip firewall filter add action=accept chain=forward dst-port=30433 protocol=tcp
/ip firewall filter add action=drop chain=forward comment="Drop all other forward"
/ip firewall nat add action=dst-nat chain=dstnat comment="bkk04 ipmi https - disabled" dst-address=160.22.181.181 dst-port=17845 protocol=tcp to-addresses=192.168.69.204 to-ports=443
/ip firewall nat add action=masquerade chain=srcnat out-interface-list=WAN src-address=100.64.0.0/24
/ip firewall nat add action=dst-nat chain=dstnat comment="bkk04 ipmi http - disabled" dst-address=160.22.181.181 dst-port=17846 protocol=tcp to-addresses=192.168.69.204 to-ports=80
/ip firewall nat add action=masquerade chain=srcnat out-interface-list=WAN src-address=172.31.0.0/24
/ip firewall nat add action=src-nat chain=srcnat out-interface-list=WAN src-address=192.168.0.0/16 to-addresses=160.22.181.181
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=80 protocol=tcp to-addresses=192.168.69.103 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=443 protocol=tcp to-addresses=192.168.69.103 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk07 dst-address=160.22.181.181 dst-port=80 protocol=tcp to-addresses=192.168.77.91 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk07 dst-address=160.22.181.181 dst-port=443 protocol=tcp to-addresses=192.168.77.91 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk06 dst-address=160.22.181.181 dst-port=80 protocol=tcp to-addresses=192.168.76.91 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk06 dst-address=160.22.181.181 dst-port=443 protocol=tcp to-addresses=192.168.76.91 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk08 dst-address=160.22.181.181 dst-port=80 protocol=tcp to-addresses=192.168.78.91 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk08 dst-address=160.22.181.181 dst-port=443 protocol=tcp to-addresses=192.168.78.91 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20781 protocol=tcp to-addresses=192.168.69.101 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32006 protocol=tcp to-addresses=192.168.223.10 to-ports=32006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31006 protocol=tcp to-addresses=192.168.213.10 to-ports=31006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20791 protocol=tcp to-addresses=192.168.69.201 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20782 protocol=tcp to-addresses=192.168.69.102 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20792 protocol=tcp to-addresses=192.168.69.202 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20783 protocol=tcp to-addresses=192.168.69.103 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20793 protocol=tcp to-addresses=192.168.69.203 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20784 protocol=tcp to-addresses=192.168.69.104 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20794 protocol=tcp to-addresses=192.168.69.204 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20785 protocol=tcp to-addresses=192.168.69.105 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20795 protocol=tcp to-addresses=192.168.69.205 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20786 protocol=tcp to-addresses=192.168.76.1 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20796 protocol=tcp to-addresses=192.168.69.206 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20787 protocol=tcp to-addresses=192.168.77.1 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20797 protocol=tcp to-addresses=192.168.69.207 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20788 protocol=tcp to-addresses=192.168.69.108 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20798 protocol=tcp to-addresses=192.168.69.208 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20789 protocol=tcp to-addresses=192.168.69.109 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20799 protocol=tcp to-addresses=192.168.69.209 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22781 protocol=tcp to-addresses=192.168.69.101 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22791 protocol=tcp to-addresses=192.168.69.201 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22782 protocol=tcp to-addresses=192.168.69.102 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22792 protocol=tcp to-addresses=192.168.69.202 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22783 protocol=tcp to-addresses=192.168.69.103 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22793 protocol=tcp to-addresses=192.168.69.203 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22784 protocol=tcp to-addresses=192.168.69.104 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22794 protocol=tcp to-addresses=192.168.69.204 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22785 protocol=tcp to-addresses=192.168.69.105 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22795 protocol=tcp to-addresses=192.168.69.205 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22786 protocol=tcp to-addresses=192.168.76.1 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22796 protocol=tcp to-addresses=192.168.69.206 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22787 protocol=tcp to-addresses=192.168.77.1 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22797 protocol=tcp to-addresses=192.168.69.207 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=22788 protocol=tcp to-addresses=192.168.69.108 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22788 protocol=tcp to-addresses=192.168.69.218 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22798 protocol=tcp to-addresses=192.168.69.208 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=22789 protocol=tcp to-addresses=192.168.69.109 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22789 protocol=tcp to-addresses=192.168.69.230 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22801 protocol=tcp to-addresses=192.168.69.201 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22802 protocol=tcp to-addresses=192.168.69.202 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22803 protocol=tcp to-addresses=192.168.69.212 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22682 protocol=tcp to-addresses=192.168.72.1 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=60601 protocol=tcp to-addresses=192.168.69.2 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22799 protocol=tcp to-addresses=192.168.69.209 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20801 protocol=tcp to-addresses=192.168.69.101 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.174 dst-port=54242 protocol=tcp to-addresses=10.69.169.2 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20802 protocol=tcp to-addresses=192.168.69.102 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20803 protocol=tcp to-addresses=192.168.69.103 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20804 protocol=tcp to-addresses=192.168.69.104 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20805 protocol=tcp to-addresses=192.168.69.105 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20806 protocol=tcp to-addresses=192.168.69.106 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20807 protocol=tcp to-addresses=192.168.69.107 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20808 protocol=tcp to-addresses=192.168.69.108 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=20809 protocol=tcp to-addresses=192.168.69.109 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2123 protocol=tcp to-addresses=192.168.69.123 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10123 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33123 protocol=tcp to-addresses=192.168.69.123 to-ports=33123
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33123 protocol=udp to-addresses=192.168.69.123 to-ports=33123
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34123 protocol=tcp to-addresses=192.168.69.123 to-ports=34123
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34123 protocol=udp to-addresses=192.168.69.123 to-ports=34123
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2113 protocol=tcp to-addresses=192.168.69.113 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10113 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33113 protocol=tcp to-addresses=192.168.69.113 to-ports=33113
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33113 protocol=udp to-addresses=192.168.69.113 to-ports=33113
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34113 protocol=tcp to-addresses=192.168.69.113 to-ports=34113
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34113 protocol=udp to-addresses=192.168.69.113 to-ports=34113
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2997 protocol=tcp to-addresses=192.168.69.97 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10313 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2313 protocol=tcp to-addresses=192.168.69.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10313 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33313 protocol=tcp to-addresses=192.168.69.13 to-ports=33313
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34313 protocol=tcp to-addresses=192.168.69.13 to-ports=34313
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2333 protocol=tcp to-addresses=192.168.69.33 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10333 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33333 protocol=tcp to-addresses=192.168.69.33 to-ports=33333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34333 protocol=tcp to-addresses=192.168.69.33 to-ports=34333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2613 protocol=tcp to-addresses=192.168.69.41 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10613 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33613 protocol=tcp to-addresses=192.168.69.41 to-ports=33613
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34613 protocol=tcp to-addresses=192.168.69.41 to-ports=34613
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2633 protocol=tcp to-addresses=192.168.69.43 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10633 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33633 protocol=tcp to-addresses=192.168.69.43 to-ports=33633
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34633 protocol=tcp to-addresses=192.168.69.43 to-ports=34633
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2643 protocol=tcp to-addresses=192.168.69.44 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10643 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33643 protocol=tcp to-addresses=192.168.69.44 to-ports=33643
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34643 protocol=tcp to-addresses=192.168.69.44 to-ports=34643
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2663 protocol=tcp to-addresses=192.168.69.46 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10663 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33663 protocol=tcp to-addresses=192.168.69.46 to-ports=33663
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34663 protocol=tcp to-addresses=192.168.69.46 to-ports=34663
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2673 protocol=tcp to-addresses=192.168.69.47 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10673 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33673 protocol=tcp to-addresses=192.168.69.47 to-ports=33673
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34673 protocol=tcp to-addresses=192.168.69.47 to-ports=34673
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2693 protocol=tcp to-addresses=192.168.69.49 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10693 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33693 protocol=tcp to-addresses=192.168.69.49 to-ports=33693
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34693 protocol=tcp to-addresses=192.168.69.49 to-ports=34693
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2103 protocol=tcp to-addresses=192.168.73.103 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=10103 protocol=tcp to-addresses=192.168.69.98 to-ports=10050
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33103 protocol=tcp to-addresses=192.168.73.103 to-ports=33103
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34103 protocol=tcp to-addresses=192.168.73.103 to-ports=34103
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2837 protocol=tcp to-addresses=192.168.77.83 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33837 protocol=tcp to-addresses=192.168.77.83 to-ports=33837
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34837 protocol=tcp to-addresses=192.168.77.83 to-ports=34837
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35837 protocol=tcp to-addresses=192.168.77.83 to-ports=35837
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2107 protocol=tcp to-addresses=192.168.77.107 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33107 protocol=tcp to-addresses=192.168.77.107 to-ports=33107
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34107 protocol=tcp to-addresses=192.168.77.107 to-ports=34107
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33827 protocol=tcp to-addresses=192.168.122.15 to-ports=33827
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34827 protocol=tcp to-addresses=192.168.122.15 to-ports=34827
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35827 protocol=tcp to-addresses=192.168.122.15 to-ports=35827
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33857 protocol=tcp to-addresses=192.168.122.14 to-ports=33857
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34857 protocol=tcp to-addresses=192.168.122.14 to-ports=34857
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35857 protocol=tcp to-addresses=192.168.122.14 to-ports=35857
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33937 protocol=tcp to-addresses=192.168.132.15 to-ports=33937
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34937 protocol=tcp to-addresses=192.168.132.15 to-ports=34937
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35937 protocol=tcp to-addresses=192.168.132.15 to-ports=35937
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33867 protocol=tcp to-addresses=192.168.132.14 to-ports=33867
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34867 protocol=tcp to-addresses=192.168.132.14 to-ports=34867
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35867 protocol=tcp to-addresses=192.168.132.14 to-ports=35867
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2897 protocol=tcp to-addresses=192.168.77.39 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33897 protocol=tcp to-addresses=192.168.77.39 to-ports=33897
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34897 protocol=tcp to-addresses=192.168.77.39 to-ports=34897
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35897 protocol=tcp to-addresses=192.168.77.39 to-ports=35897
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2957 protocol=tcp to-addresses=192.168.77.50 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33957 protocol=tcp to-addresses=192.168.77.50 to-ports=33957
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34957 protocol=tcp to-addresses=192.168.77.50 to-ports=34957
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35957 protocol=tcp to-addresses=192.168.77.50 to-ports=35957
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33617 protocol=tcp to-addresses=192.168.112.11 to-ports=33617
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34617 protocol=tcp to-addresses=192.168.112.11 to-ports=34617
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35617 protocol=tcp to-addresses=192.168.112.11 to-ports=35617
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2216 protocol=tcp to-addresses=192.168.76.216 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33214 protocol=tcp to-addresses=192.168.76.216 to-ports=33214
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34214 protocol=tcp to-addresses=192.168.76.216 to-ports=34214
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35214 protocol=tcp to-addresses=192.168.76.216 to-ports=35214
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2226 protocol=tcp to-addresses=192.168.76.226 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33224 protocol=tcp to-addresses=192.168.76.226 to-ports=33224
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34224 protocol=tcp to-addresses=192.168.76.226 to-ports=34224
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35224 protocol=tcp to-addresses=192.168.76.226 to-ports=35224
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2236 protocol=tcp to-addresses=192.168.76.236 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33234 protocol=tcp to-addresses=192.168.76.236 to-ports=33234
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34234 protocol=tcp to-addresses=192.168.76.236 to-ports=34234
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35234 protocol=tcp to-addresses=192.168.76.236 to-ports=35234
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2516 protocol=tcp to-addresses=192.168.76.241 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33514 protocol=tcp to-addresses=192.168.76.241 to-ports=33514
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34514 protocol=tcp to-addresses=192.168.76.241 to-ports=34514
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35514 protocol=tcp to-addresses=192.168.76.241 to-ports=35514
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2526 protocol=tcp to-addresses=192.168.76.242 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33524 protocol=tcp to-addresses=192.168.76.242 to-ports=33524
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34524 protocol=tcp to-addresses=192.168.76.242 to-ports=34524
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35524 protocol=tcp to-addresses=192.168.76.242 to-ports=35524
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2536 protocol=tcp to-addresses=192.168.76.243 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33534 protocol=tcp to-addresses=192.168.76.243 to-ports=33534
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34534 protocol=tcp to-addresses=192.168.76.243 to-ports=34534
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35534 protocol=tcp to-addresses=192.168.76.243 to-ports=35534
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2546 protocol=tcp to-addresses=192.168.76.244 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33543 protocol=tcp to-addresses=192.168.76.244 to-ports=33543
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34543 protocol=tcp to-addresses=192.168.76.244 to-ports=34543
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35543 protocol=tcp to-addresses=192.168.76.244 to-ports=35543
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2556 protocol=tcp to-addresses=192.168.76.245 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33553 protocol=tcp to-addresses=192.168.76.245 to-ports=33553
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34553 protocol=tcp to-addresses=192.168.76.245 to-ports=34553
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35553 protocol=tcp to-addresses=192.168.76.245 to-ports=35553
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2566 protocol=tcp to-addresses=192.168.76.248 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33563 protocol=tcp to-addresses=192.168.76.248 to-ports=33563
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34563 protocol=tcp to-addresses=192.168.76.248 to-ports=34563
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35563 protocol=tcp to-addresses=192.168.76.248 to-ports=35563
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2576 protocol=tcp to-addresses=192.168.76.247 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33576 protocol=tcp to-addresses=192.168.76.247 to-ports=33576
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34576 protocol=tcp to-addresses=192.168.76.247 to-ports=34576
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35576 protocol=tcp to-addresses=192.168.76.247 to-ports=35576
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2596 protocol=tcp to-addresses=192.168.76.249 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33593 protocol=tcp to-addresses=192.168.76.249 to-ports=33593
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34593 protocol=tcp to-addresses=192.168.76.249 to-ports=34593
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35593 protocol=tcp to-addresses=192.168.76.249 to-ports=35593
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2506 protocol=tcp to-addresses=192.168.76.240 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33504 protocol=tcp to-addresses=192.168.76.240 to-ports=33504
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34504 protocol=tcp to-addresses=192.168.76.240 to-ports=34504
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35504 protocol=tcp to-addresses=192.168.76.240 to-ports=35504
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2316 protocol=tcp to-addresses=192.168.76.16 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33316 protocol=tcp to-addresses=192.168.76.16 to-ports=33316
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34316 protocol=tcp to-addresses=192.168.76.16 to-ports=34316
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2326 protocol=tcp to-addresses=192.168.76.26 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33326 protocol=tcp to-addresses=192.168.76.26 to-ports=33326
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34326 protocol=tcp to-addresses=192.168.76.26 to-ports=34326
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35326 protocol=tcp to-addresses=192.168.76.26 to-ports=35326
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2336 protocol=tcp to-addresses=192.168.76.36 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33336 protocol=tcp to-addresses=192.168.76.36 to-ports=33336
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34336 protocol=tcp to-addresses=192.168.76.36 to-ports=34336
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2146 protocol=tcp to-addresses=192.168.76.146 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33146 protocol=tcp to-addresses=192.168.76.146 to-ports=33146
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34146 protocol=tcp to-addresses=192.168.76.146 to-ports=34146
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2246 protocol=tcp to-addresses=192.168.76.246 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33246 protocol=tcp to-addresses=192.168.76.246 to-ports=33246
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34246 protocol=tcp to-addresses=192.168.76.246 to-ports=34246
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35246 protocol=tcp to-addresses=192.168.76.246 to-ports=35246
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2346 protocol=tcp to-addresses=192.168.76.46 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33346 protocol=tcp to-addresses=192.168.76.46 to-ports=33346
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34346 protocol=tcp to-addresses=192.168.76.46 to-ports=34346
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2606 protocol=tcp to-addresses=192.168.76.40 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33606 protocol=tcp to-addresses=192.168.76.40 to-ports=33606
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34606 protocol=tcp to-addresses=192.168.76.40 to-ports=34606
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2616 protocol=tcp to-addresses=192.168.76.41 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33616 protocol=tcp to-addresses=192.168.76.41 to-ports=33616
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34616 protocol=tcp to-addresses=192.168.76.41 to-ports=34616
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35616 protocol=tcp to-addresses=192.168.76.41 to-ports=35616
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2626 protocol=tcp to-addresses=192.168.76.42 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33626 protocol=tcp to-addresses=192.168.76.42 to-ports=33626
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34626 protocol=tcp to-addresses=192.168.76.42 to-ports=34626
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35626 protocol=tcp to-addresses=192.168.76.42 to-ports=35626
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2636 protocol=tcp to-addresses=192.168.76.43 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33636 protocol=tcp to-addresses=192.168.76.43 to-ports=33636
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34636 protocol=tcp to-addresses=192.168.76.43 to-ports=34636
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35636 protocol=tcp to-addresses=192.168.76.43 to-ports=35636
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2646 protocol=tcp to-addresses=192.168.76.44 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33646 protocol=tcp to-addresses=192.168.76.44 to-ports=33646
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34646 protocol=tcp to-addresses=192.168.76.44 to-ports=34646
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35646 protocol=tcp to-addresses=192.168.76.44 to-ports=35646
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2656 protocol=tcp to-addresses=192.168.76.45 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33656 protocol=tcp to-addresses=192.168.76.45 to-ports=33656
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34656 protocol=tcp to-addresses=192.168.76.45 to-ports=34656
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35656 protocol=tcp to-addresses=192.168.76.45 to-ports=35656
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2666 protocol=tcp to-addresses=192.168.76.48 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33666 protocol=tcp to-addresses=192.168.76.48 to-ports=33666
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34666 protocol=tcp to-addresses=192.168.76.48 to-ports=34666
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35666 protocol=tcp to-addresses=192.168.76.48 to-ports=35666
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2676 protocol=tcp to-addresses=192.168.76.47 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33676 protocol=tcp to-addresses=192.168.76.47 to-ports=33676
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34676 protocol=tcp to-addresses=192.168.76.47 to-ports=34676
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35676 protocol=tcp to-addresses=192.168.76.47 to-ports=35676
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2696 protocol=tcp to-addresses=192.168.76.49 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33696 protocol=tcp to-addresses=192.168.76.49 to-ports=33696
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34696 protocol=tcp to-addresses=192.168.76.49 to-ports=34696
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35696 protocol=tcp to-addresses=192.168.76.49 to-ports=35696
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2836 protocol=tcp to-addresses=192.168.76.83 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33836 protocol=tcp to-addresses=192.168.76.83 to-ports=33836
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34836 protocol=tcp to-addresses=192.168.76.83 to-ports=34836
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35836 protocol=tcp to-addresses=192.168.76.83 to-ports=35836
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2736 protocol=tcp to-addresses=192.168.76.237 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33736 protocol=tcp to-addresses=192.168.76.237 to-ports=33736
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34736 protocol=tcp to-addresses=192.168.76.237 to-ports=34736
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35736 protocol=tcp to-addresses=192.168.76.237 to-ports=35736
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2936 protocol=tcp to-addresses=192.168.76.37 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33936 protocol=tcp to-addresses=192.168.76.37 to-ports=33936
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34936 protocol=tcp to-addresses=192.168.76.37 to-ports=34936
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35936 protocol=tcp to-addresses=192.168.76.37 to-ports=35936
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2766 protocol=tcp to-addresses=192.168.76.238 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33766 protocol=tcp to-addresses=192.168.76.238 to-ports=33766
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34766 protocol=tcp to-addresses=192.168.76.238 to-ports=34766
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35766 protocol=tcp to-addresses=192.168.76.238 to-ports=35766
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2866 protocol=tcp to-addresses=192.168.76.38 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33866 protocol=tcp to-addresses=192.168.76.38 to-ports=33866
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34866 protocol=tcp to-addresses=192.168.76.38 to-ports=34866
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35866 protocol=tcp to-addresses=192.168.76.38 to-ports=35866
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2946 protocol=tcp to-addresses=192.168.76.250 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33946 protocol=tcp to-addresses=192.168.76.50 to-ports=33946
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35946 protocol=tcp to-addresses=192.168.76.50 to-ports=35946
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=2956 protocol=tcp to-addresses=192.168.76.50 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33956 protocol=tcp to-addresses=192.168.76.50 to-ports=33936
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34956 protocol=tcp to-addresses=192.168.76.50 to-ports=34936
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35956 protocol=tcp to-addresses=192.168.76.50 to-ports=35936
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2726 protocol=tcp to-addresses=192.168.76.227 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33726 protocol=tcp to-addresses=192.168.76.227 to-ports=33726
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34726 protocol=tcp to-addresses=192.168.76.227 to-ports=34726
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35726 protocol=tcp to-addresses=192.168.76.227 to-ports=35726
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2826 protocol=tcp to-addresses=192.168.76.27 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33826 protocol=tcp to-addresses=192.168.76.27 to-ports=33826
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34826 protocol=tcp to-addresses=192.168.76.27 to-ports=34826
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35826 protocol=tcp to-addresses=192.168.76.27 to-ports=35826
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2756 protocol=tcp to-addresses=192.168.76.228 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=33756 protocol=tcp to-addresses=192.168.76.228 to-ports=33756
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34756 protocol=tcp to-addresses=192.168.76.228 to-ports=34756
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35756 protocol=tcp to-addresses=192.168.76.228 to-ports=35756
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2856 protocol=tcp to-addresses=192.168.76.28 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33856 protocol=tcp to-addresses=192.168.76.28 to-ports=33856
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34856 protocol=tcp to-addresses=192.168.76.28 to-ports=34856
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35856 protocol=tcp to-addresses=192.168.76.28 to-ports=35856
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2625 protocol=tcp to-addresses=192.168.76.66 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33925 protocol=tcp to-addresses=192.168.76.66 to-ports=33925
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34925 protocol=tcp to-addresses=192.168.76.66 to-ports=34925
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35925 protocol=tcp to-addresses=192.168.76.66 to-ports=35925
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=8000 protocol=tcp to-addresses=192.168.69.103 to-ports=8000
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=28006 protocol=tcp to-addresses=192.168.76.1 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2847 protocol=tcp to-addresses=192.168.77.18 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33847 protocol=tcp to-addresses=192.168.77.18 to-ports=33847
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34847 protocol=tcp to-addresses=192.168.77.18 to-ports=34847
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35847 protocol=tcp to-addresses=192.168.77.18 to-ports=35847
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2966 protocol=tcp to-addresses=192.168.76.60 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34021 protocol=tcp to-addresses=192.168.76.60 to-ports=34021
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34966 protocol=tcp to-addresses=192.168.76.60 to-ports=34966
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=35966 protocol=tcp to-addresses=192.168.76.60 to-ports=35966
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2967 protocol=tcp to-addresses=192.168.77.60 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33967 protocol=tcp to-addresses=192.168.77.60 to-ports=33967
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34967 protocol=tcp to-addresses=192.168.77.60 to-ports=34967
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35967 protocol=tcp to-addresses=192.168.77.60 to-ports=35967
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2312 protocol=tcp to-addresses=192.168.77.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33312 protocol=tcp to-addresses=192.168.77.12 to-ports=33312
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34312 protocol=tcp to-addresses=192.168.77.12 to-ports=34312
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35312 protocol=tcp to-addresses=192.168.77.12 to-ports=35312
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2317 protocol=tcp to-addresses=192.168.77.17 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33317 protocol=tcp to-addresses=192.168.77.17 to-ports=33317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34317 protocol=tcp to-addresses=192.168.77.17 to-ports=34317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35317 protocol=tcp to-addresses=192.168.77.17 to-ports=35317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2317 protocol=tcp to-addresses=192.168.77.17 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33317 protocol=tcp to-addresses=192.168.77.17 to-ports=33317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34317 protocol=tcp to-addresses=192.168.77.17 to-ports=34317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35317 protocol=tcp to-addresses=192.168.77.17 to-ports=35317
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2322 protocol=tcp to-addresses=192.168.77.22 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33322 protocol=tcp to-addresses=192.168.77.22 to-ports=33322
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34322 protocol=tcp to-addresses=192.168.77.22 to-ports=34322
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35322 protocol=tcp to-addresses=192.168.77.22 to-ports=35322
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2332 protocol=tcp to-addresses=192.168.77.32 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33332 protocol=tcp to-addresses=192.168.77.32 to-ports=33332
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34332 protocol=tcp to-addresses=192.168.77.32 to-ports=34332
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35332 protocol=tcp to-addresses=192.168.77.32 to-ports=35332
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2342 protocol=tcp to-addresses=192.168.77.42 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33342 protocol=tcp to-addresses=192.168.77.42 to-ports=33342
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34342 protocol=tcp to-addresses=192.168.77.42 to-ports=34342
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35342 protocol=tcp to-addresses=192.168.77.42 to-ports=35342
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=34011 protocol=tcp to-addresses=192.168.76.50 to-ports=34011
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33816 protocol=tcp to-addresses=192.168.76.16 to-ports=33816
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34816 protocol=tcp to-addresses=192.168.76.16 to-ports=34816
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35816 protocol=tcp to-addresses=192.168.76.16 to-ports=35816
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2846 protocol=tcp to-addresses=192.168.76.18 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31041 protocol=tcp to-addresses=192.168.76.18 to-ports=31041
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34846 protocol=tcp to-addresses=192.168.76.18 to-ports=34846
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35846 protocol=tcp to-addresses=192.168.76.18 to-ports=35846
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2816 protocol=tcp to-addresses=192.168.176.16 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31051 protocol=tcp to-addresses=192.168.176.16 to-ports=31051
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34816 protocol=tcp to-addresses=192.168.176.16 to-ports=34816
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35816 protocol=tcp to-addresses=192.168.176.16 to-ports=35816
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=2901 protocol=tcp to-addresses=192.168.46.60 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3866 protocol=tcp to-addresses=192.168.86.86 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2901 protocol=tcp to-addresses=192.168.46.90 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34051 protocol=tcp to-addresses=192.168.46.90 to-ports=34051
/ip firewall nat add action=dst-nat chain=dstnat comment="testing 30435 to bkk03 haproxy -al" disabled=yes dst-address=160.22.181.181 dst-port=30435 protocol=tcp to-addresses=192.168.69.103 to-ports=30435
/ip firewall nat add action=dst-nat chain=dstnat comment="routing wss 30335 to haproxy" disabled=yes dst-address=160.22.181.181 dst-port=30335 protocol=tcp to-addresses=192.168.69.103 to-ports=30335
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk07 dst-address=160.22.181.181 dst-port=30435 protocol=tcp to-addresses=192.168.77.91 to-ports=30435
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk07 dst-address=160.22.181.181 dst-port=30335 protocol=tcp to-addresses=192.168.77.91 to-ports=30335
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk06 dst-address=160.22.181.181 dst-port=30335 protocol=tcp to-addresses=192.168.76.91 to-ports=30335
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk06 dst-address=160.22.181.181 dst-port=30435 protocol=tcp to-addresses=192.168.76.91 to-ports=30435
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk08 dst-address=160.22.181.181 dst-port=30335 protocol=tcp to-addresses=192.168.78.91 to-ports=30335
/ip firewall nat add action=dst-nat chain=dstnat comment=haproxy-bkk08 dst-address=160.22.181.181 dst-port=30435 protocol=tcp to-addresses=192.168.78.91 to-ports=30435
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=2725 protocol=tcp to-addresses=192.168.77.125 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.125 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=2715 protocol=tcp to-addresses=192.168.77.115 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.115 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2904 protocol=tcp to-addresses=192.168.46.94 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.46.94 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.46.94 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat comment="asrockrack bkk04 -al" dst-address=172.30.50.1 dst-port=4443 protocol=tcp to-addresses=192.168.69.204 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.22 dst-port=22 protocol=tcp to-addresses=192.168.69.231 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat comment="pi kvm" dst-address=172.30.50.22 dst-port=8881 protocol=tcp to-addresses=192.168.69.231 to-ports=8188
/ip firewall nat add action=dst-nat chain=dstnat comment="proxmox bkk04 -al" dst-address=172.30.50.1 dst-port=48006 protocol=tcp to-addresses=192.168.69.104 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat comment="supermicro bkk06" dst-address=172.30.50.16 dst-port=4443 protocol=tcp to-addresses=10.58.0.1 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment="proxmox bkk06" dst-address=172.30.50.16 dst-port=48006 protocol=tcp to-addresses=192.168.76.1 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat comment="supermicro bkk07" dst-address=172.30.50.17 dst-port=4443 protocol=tcp to-addresses=192.168.69.227 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat comment="proxmox bkk07" dst-address=172.30.50.17 dst-port=48006 protocol=tcp to-addresses=192.168.77.1 to-ports=8006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2998 protocol=tcp to-addresses=192.168.69.98 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2115 protocol=tcp to-addresses=192.168.69.115 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33115 protocol=tcp to-addresses=192.168.69.115 to-ports=33115
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34115 protocol=tcp to-addresses=192.168.69.115 to-ports=34115
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35115 protocol=tcp to-addresses=192.168.69.115 to-ports=35115
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2125 protocol=tcp to-addresses=192.168.69.104 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33125 protocol=tcp to-addresses=192.168.69.104 to-ports=33125
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34125 protocol=tcp to-addresses=192.168.69.104 to-ports=34125
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2902 protocol=tcp to-addresses=192.168.47.90 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34052 protocol=tcp to-addresses=192.168.47.90 to-ports=34052
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2905 protocol=tcp to-addresses=192.168.47.94 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34042 protocol=tcp to-addresses=192.168.47.94 to-ports=34042
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.11 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.11 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.31 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.31 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.44 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.44 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2642 protocol=tcp to-addresses=192.168.112.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.46 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.46 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2662 protocol=tcp to-addresses=192.168.132.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.48 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.48 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2672 protocol=tcp to-addresses=192.168.112.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.51 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.51 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2692 protocol=tcp to-addresses=192.168.132.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2845 protocol=tcp to-addresses=192.168.77.16 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30333 protocol=tcp to-addresses=192.168.77.16 to-ports=30333
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.77.16 to-ports=30334
/ip firewall nat add action=src-nat chain=srcnat disabled=yes protocol=tcp to-addresses=172.30.50.22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34041 protocol=tcp to-addresses=192.168.46.94 to-ports=34041
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2715 protocol=tcp to-addresses=192.168.217.115 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31022 protocol=tcp to-addresses=192.168.217.115 to-ports=31022
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.217.115 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2725 protocol=tcp to-addresses=192.168.227.125 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32022 protocol=tcp to-addresses=192.168.227.125 to-ports=32022
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30334 protocol=tcp to-addresses=192.168.227.125 to-ports=30334
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.103 dst-port=4443 protocol=tcp to-addresses=192.168.69.233 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.39 dst-port=80 protocol=tcp to-addresses=192.168.69.230 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.39 protocol=tcp to-addresses=192.168.69.230
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.72 dst-port=22 protocol=tcp to-addresses=192.168.72.1 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2651 protocol=tcp to-addresses=192.168.122.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32022 protocol=tcp to-addresses=192.168.122.12 to-ports=32022
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2601 protocol=tcp to-addresses=192.168.122.16 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32062 protocol=tcp to-addresses=192.168.122.16 to-ports=32062
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31022 protocol=tcp to-addresses=192.168.112.12 to-ports=31022
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33022 protocol=tcp to-addresses=192.168.132.12 to-ports=33022
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31032 protocol=tcp to-addresses=192.168.112.13 to-ports=31032
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33032 protocol=tcp to-addresses=192.168.132.13 to-ports=33032
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31052 protocol=tcp to-addresses=192.168.77.16 to-ports=31052
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2623 protocol=tcp to-addresses=192.168.122.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32012 protocol=tcp to-addresses=192.168.122.11 to-ports=32012
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2612 protocol=tcp to-addresses=192.168.112.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31012 protocol=tcp to-addresses=192.168.112.11 to-ports=31012
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2634 protocol=tcp to-addresses=192.168.132.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33012 protocol=tcp to-addresses=192.168.132.11 to-ports=33012
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2611 protocol=tcp to-addresses=192.168.111.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31011 protocol=tcp to-addresses=192.168.111.11 to-ports=31011
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2641 protocol=tcp to-addresses=192.168.111.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31021 protocol=tcp to-addresses=192.168.111.12 to-ports=31021
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2661 protocol=tcp to-addresses=192.168.131.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33021 protocol=tcp to-addresses=192.168.131.12 to-ports=33021
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2671 protocol=tcp to-addresses=192.168.111.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31031 protocol=tcp to-addresses=192.168.111.13 to-ports=31031
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2691 protocol=tcp to-addresses=192.168.131.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33031 protocol=tcp to-addresses=192.168.131.13 to-ports=33031
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2631 protocol=tcp to-addresses=192.168.131.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33011 protocol=tcp to-addresses=192.168.131.11 to-ports=33011
/ip firewall nat add action=dst-nat chain=dstnat comment="Transition bootnode" dst-address=160.22.181.181 dst-port=33514 protocol=tcp to-addresses=192.168.111.11 to-ports=33514
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34514 protocol=tcp to-addresses=192.168.111.11 to-ports=34514
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35514 protocol=tcp to-addresses=192.168.111.11 to-ports=35514
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=33543 protocol=tcp to-addresses=192.168.111.12 to-ports=33543
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34543 protocol=tcp to-addresses=192.168.111.12 to-ports=34543
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35543 protocol=tcp to-addresses=192.168.111.12 to-ports=35543
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=33576 protocol=tcp to-addresses=192.168.111.13 to-ports=33576
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34576 protocol=tcp to-addresses=192.168.111.13 to-ports=34576
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35576 protocol=tcp to-addresses=192.168.111.13 to-ports=35576
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=33534 protocol=tcp to-addresses=192.168.131.11 to-ports=33534
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34534 protocol=tcp to-addresses=192.168.131.11 to-ports=34534
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35534 protocol=tcp to-addresses=192.168.131.11 to-ports=35534
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=33563 protocol=tcp to-addresses=192.168.131.12 to-ports=33563
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34563 protocol=tcp to-addresses=192.168.131.12 to-ports=34563
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35563 protocol=tcp to-addresses=192.168.131.12 to-ports=35563
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=33593 protocol=tcp to-addresses=192.168.131.13 to-ports=33593
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=34593 protocol=tcp to-addresses=192.168.131.13 to-ports=34593
/ip firewall nat add action=dst-nat chain=dstnat comment="transition bootnode" dst-address=160.22.181.181 dst-port=35593 protocol=tcp to-addresses=192.168.131.13 to-ports=35593
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.17 protocol=tcp to-addresses=192.168.77.1
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.17 dst-port=8080 protocol=tcp to-addresses=192.168.77.1 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2935 protocol=tcp to-addresses=192.168.132.15 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33052 protocol=tcp to-addresses=192.168.132.15 to-ports=33052
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2869 protocol=tcp to-addresses=192.168.132.14 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33042 protocol=tcp to-addresses=192.168.132.14 to-ports=33042
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2828 protocol=tcp to-addresses=192.168.122.15 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32052 protocol=tcp to-addresses=192.168.122.15 to-ports=32052
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2830 protocol=tcp to-addresses=192.168.122.14 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32042 protocol=tcp to-addresses=192.168.122.14 to-ports=32042
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2996 protocol=tcp to-addresses=192.168.77.97 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.96 dst-port=9090 protocol=tcp to-addresses=192.168.77.97 to-ports=9090
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.96 dst-port=80 protocol=tcp to-addresses=192.168.77.97 to-ports=80
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2991 protocol=tcp to-addresses=192.168.77.91 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2917 protocol=tcp to-addresses=192.168.77.177 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2311 protocol=tcp to-addresses=192.168.111.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31001 protocol=tcp to-addresses=192.168.111.10 to-ports=31001
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33214 protocol=tcp to-addresses=192.168.111.10 to-ports=33214
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34214 protocol=tcp to-addresses=192.168.111.10 to-ports=34214
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2331 protocol=tcp to-addresses=192.168.131.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35214 protocol=tcp to-addresses=192.168.111.10 to-ports=35214
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33001 protocol=tcp to-addresses=192.168.131.10 to-ports=33001
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33234 protocol=tcp to-addresses=192.168.131.10 to-ports=33234
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34234 protocol=tcp to-addresses=192.168.131.10 to-ports=34234
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35234 protocol=tcp to-addresses=192.168.131.10 to-ports=35234
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2992 protocol=tcp to-addresses=192.168.77.92 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39111 protocol=tcp to-addresses=192.168.69.230 to-ports=39111
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39112 protocol=tcp to-addresses=192.168.69.230 to-ports=39112
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39113 protocol=tcp to-addresses=192.168.69.230 to-ports=39113
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39121 protocol=tcp to-addresses=192.168.69.230 to-ports=39121
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39122 protocol=tcp to-addresses=192.168.69.230 to-ports=39122
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=39123 protocol=tcp to-addresses=192.168.69.230 to-ports=39123
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30434 protocol=tcp to-addresses=192.168.112.11 to-ports=30434
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30434 protocol=tcp to-addresses=192.168.112.12 to-ports=30434
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30434 protocol=tcp to-addresses=192.168.132.12 to-ports=30434
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30434 protocol=tcp to-addresses=192.168.112.13 to-ports=30434
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30434 protocol=tcp to-addresses=192.168.132.13 to-ports=30434
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2954 protocol=tcp to-addresses=192.168.69.254 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2961 protocol=tcp to-addresses=192.168.76.91 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat comment="bkk-sax-wg to IPMI sax-bkk-01" dst-address=172.29.169.101 dst-port=443 protocol=tcp to-addresses=10.169.0.1 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=21006 protocol=tcp to-addresses=192.168.213.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=41006 protocol=tcp to-addresses=192.168.213.10 to-ports=41006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22006 protocol=tcp to-addresses=192.168.223.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=42006 protocol=tcp to-addresses=192.168.223.10 to-ports=42006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2824 protocol=tcp to-addresses=192.168.121.15 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32051 protocol=tcp to-addresses=192.168.121.15 to-ports=32051
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33726 protocol=tcp to-addresses=192.168.121.15 to-ports=33726
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34726 protocol=tcp to-addresses=192.168.121.15 to-ports=34726
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35726 protocol=tcp to-addresses=192.168.121.15 to-ports=35726
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2916 protocol=tcp to-addresses=192.168.131.15 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33051 protocol=tcp to-addresses=192.168.131.15 to-ports=33051
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33736 protocol=tcp to-addresses=192.168.131.15 to-ports=33736
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34736 protocol=tcp to-addresses=192.168.131.15 to-ports=34736
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35736 protocol=tcp to-addresses=192.168.131.15 to-ports=35736
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2829 protocol=tcp to-addresses=192.168.121.14 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32041 protocol=tcp to-addresses=192.168.121.14 to-ports=32041
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33756 protocol=tcp to-addresses=192.168.121.14 to-ports=33756
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34756 protocol=tcp to-addresses=192.168.121.14 to-ports=34756
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35756 protocol=tcp to-addresses=192.168.121.14 to-ports=35756
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2814 protocol=tcp to-addresses=192.168.131.14 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33041 protocol=tcp to-addresses=192.168.131.14 to-ports=33041
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33766 protocol=tcp to-addresses=192.168.131.14 to-ports=33766
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34766 protocol=tcp to-addresses=192.168.131.14 to-ports=34766
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35766 protocol=tcp to-addresses=192.168.131.14 to-ports=35766
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2321 protocol=tcp to-addresses=192.168.121.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32001 protocol=tcp to-addresses=192.168.121.10 to-ports=32001
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33224 protocol=tcp to-addresses=192.168.121.10 to-ports=33224
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34224 protocol=tcp to-addresses=192.168.121.10 to-ports=34224
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35224 protocol=tcp to-addresses=192.168.121.10 to-ports=35224
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2622 protocol=tcp to-addresses=192.168.121.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32011 protocol=tcp to-addresses=192.168.121.11 to-ports=32011
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33524 protocol=tcp to-addresses=192.168.121.11 to-ports=33524
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34524 protocol=tcp to-addresses=192.168.121.11 to-ports=34524
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35524 protocol=tcp to-addresses=192.168.121.11 to-ports=35524
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2652 protocol=tcp to-addresses=192.168.121.12 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32021 protocol=tcp to-addresses=192.168.121.12 to-ports=32021
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33553 protocol=tcp to-addresses=192.168.121.12 to-ports=33553
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34553 protocol=tcp to-addresses=192.168.121.12 to-ports=34553
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35553 protocol=tcp to-addresses=192.168.121.12 to-ports=35553
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2602 protocol=tcp to-addresses=192.168.121.16 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32061 protocol=tcp to-addresses=192.168.121.16 to-ports=32061
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33504 protocol=tcp to-addresses=192.168.121.16 to-ports=33504
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34504 protocol=tcp to-addresses=192.168.121.16 to-ports=34504
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35504 protocol=tcp to-addresses=192.168.121.16 to-ports=35504
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=172.29.169.150 dst-port=4443 protocol=tcp to-addresses=192.168.69.225 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat disabled=yes dst-address=160.22.181.174 dst-port=53102 protocol=tcp to-addresses=192.168.69.225 to-ports=443
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2341 protocol=tcp to-addresses=192.168.141.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34001 protocol=tcp to-addresses=192.168.141.10 to-ports=34001
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33246 protocol=tcp to-addresses=192.168.141.10 to-ports=33246
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34246 protocol=tcp to-addresses=192.168.141.10 to-ports=34246
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35246 protocol=tcp to-addresses=192.168.141.10 to-ports=35246
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2838 protocol=tcp to-addresses=192.168.111.35 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2958 protocol=tcp to-addresses=192.168.141.11 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34011 protocol=tcp to-addresses=192.168.141.11 to-ports=34011
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=33946 protocol=tcp to-addresses=192.168.141.11 to-ports=33946
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34946 protocol=tcp to-addresses=192.168.141.11 to-ports=34946
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=35946 protocol=tcp to-addresses=192.168.141.11 to-ports=35946
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2482 protocol=tcp to-addresses=192.168.77.82 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=26682 protocol=tcp to-addresses=192.168.77.82 to-ports=26682
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31241 protocol=tcp to-addresses=192.168.86.86 to-ports=31241
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3834 protocol=tcp to-addresses=192.168.112.34 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31242 protocol=tcp to-addresses=192.168.112.34 to-ports=31242
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3135 protocol=tcp to-addresses=192.168.112.35 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31252 protocol=tcp to-addresses=192.168.112.35 to-ports=31252
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31026 protocol=tcp to-addresses=192.168.72.1 to-ports=31026
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=30326 protocol=tcp to-addresses=192.168.72.1 to-ports=30326
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2141 protocol=tcp to-addresses=192.168.241.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34004 protocol=tcp to-addresses=192.168.241.10 to-ports=34004
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2132 protocol=tcp to-addresses=192.168.112.30 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31202 protocol=tcp to-addresses=192.168.112.30 to-ports=31202
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2131 protocol=tcp to-addresses=192.168.111.30 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31201 protocol=tcp to-addresses=192.168.111.30 to-ports=31201
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3837 protocol=tcp to-addresses=192.168.112.37 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31272 protocol=tcp to-addresses=192.168.112.37 to-ports=31272
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3137 protocol=tcp to-addresses=192.168.111.37 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31271 protocol=tcp to-addresses=192.168.111.37 to-ports=31271
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3882 protocol=tcp to-addresses=192.168.112.38 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31282 protocol=tcp to-addresses=192.168.112.38 to-ports=31282
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3881 protocol=tcp to-addresses=192.168.111.38 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31281 protocol=tcp to-addresses=192.168.111.38 to-ports=31281
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3392 protocol=tcp to-addresses=192.168.112.39 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31292 protocol=tcp to-addresses=192.168.112.39 to-ports=31292
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31251 protocol=tcp to-addresses=192.168.111.35 to-ports=31251
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3391 protocol=tcp to-addresses=192.168.111.39 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31291 protocol=tcp to-addresses=192.168.111.39 to-ports=31291
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3362 protocol=tcp to-addresses=192.168.112.36 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31262 protocol=tcp to-addresses=192.168.112.36 to-ports=31262
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3361 protocol=tcp to-addresses=192.168.111.36 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31261 protocol=tcp to-addresses=192.168.111.36 to-ports=31261
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2167 protocol=tcp to-addresses=192.168.77.167 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2481 protocol=tcp to-addresses=192.168.77.81 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=26681 protocol=tcp to-addresses=192.168.77.81 to-ports=26681
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.88 protocol=tcp to-addresses=192.168.69.220
/ip firewall nat add action=dst-nat chain=dstnat dst-address=172.30.50.89 protocol=tcp to-addresses=192.168.69.227
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3232 protocol=tcp to-addresses=192.168.112.31 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31212 protocol=tcp to-addresses=192.168.112.31 to-ports=31212
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3231 protocol=tcp to-addresses=192.168.111.31 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31211 protocol=tcp to-addresses=192.168.111.31 to-ports=31211
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3242 protocol=tcp to-addresses=192.168.112.40 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31302 protocol=tcp to-addresses=192.168.112.40 to-ports=31302
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32121 protocol=tcp to-addresses=192.168.72.1 to-ports=32121
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32122 protocol=tcp to-addresses=192.168.72.1 to-ports=32122
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=41121 protocol=tcp to-addresses=192.168.69.214 to-ports=41121
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=41122 protocol=tcp to-addresses=192.168.69.214 to-ports=41122
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=41111 protocol=tcp to-addresses=192.168.69.214 to-ports=41111
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=41112 protocol=tcp to-addresses=192.168.69.214 to-ports=41112
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=43121 protocol=tcp to-addresses=192.168.69.212 to-ports=43121
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=43122 protocol=tcp to-addresses=192.168.69.212 to-ports=43122
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=43111 protocol=tcp to-addresses=192.168.69.212 to-ports=43111
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=43112 protocol=tcp to-addresses=192.168.69.212 to-ports=43112
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2918 protocol=tcp to-addresses=192.168.78.178 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2142 protocol=tcp to-addresses=192.168.242.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34005 protocol=tcp to-addresses=192.168.242.10 to-ports=34005
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2483 protocol=tcp to-addresses=192.168.78.83 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=26683 protocol=tcp to-addresses=192.168.78.83 to-ports=26683
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34006 protocol=tcp to-addresses=192.168.69.210 to-ports=34006
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2143 protocol=tcp to-addresses=192.168.69.210 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2144 protocol=tcp to-addresses=192.168.69.219 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34007 protocol=tcp to-addresses=192.168.69.219 to-ports=34007
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3313 protocol=tcp to-addresses=192.168.113.10 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31003 protocol=tcp to-addresses=192.168.113.10 to-ports=31003
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=22413 protocol=tcp to-addresses=192.168.69.222 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2982 protocol=tcp to-addresses=192.168.78.92 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3141 protocol=tcp to-addresses=192.168.111.41 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31311 protocol=tcp to-addresses=192.168.111.41 to-ports=31311
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3197 protocol=tcp to-addresses=192.168.78.97 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3178 protocol=tcp to-addresses=192.168.78.91 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=2915 protocol=tcp to-addresses=192.168.78.15 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32008 protocol=tcp to-addresses=192.168.69.222 to-ports=32008
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=42008 protocol=tcp to-addresses=192.168.69.222 to-ports=42008
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3833 protocol=tcp to-addresses=192.168.112.33 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31232 protocol=tcp to-addresses=192.168.112.33 to-ports=31232
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3831 protocol=tcp to-addresses=192.168.111.33 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31231 protocol=tcp to-addresses=192.168.111.33 to-ports=31231
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3241 protocol=tcp to-addresses=192.168.112.41 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31312 protocol=tcp to-addresses=192.168.112.41 to-ports=31312
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3842 protocol=tcp to-addresses=192.168.112.42 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31322 protocol=tcp to-addresses=192.168.112.42 to-ports=31322
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3742 protocol=tcp to-addresses=192.168.111.42 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31321 protocol=tcp to-addresses=192.168.111.42 to-ports=31321
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34072 protocol=tcp to-addresses=192.168.142.17 to-ports=34072
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3142 protocol=tcp to-addresses=192.168.142.17 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3147 protocol=tcp to-addresses=192.168.141.17 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34071 protocol=tcp to-addresses=192.168.141.17 to-ports=34071
/ip firewall nat add action=masquerade chain=srcnat comment="Hairpin NAT - masquerade internal traffic accessing public services to enable loopback" out-interface=bridge_local src-address=192.168.0.0/16
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34008 protocol=tcp to-addresses=192.168.69.201 to-ports=34008
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34009 protocol=tcp to-addresses=192.168.69.201 to-ports=34009
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32506 protocol=tcp to-addresses=192.168.69.202 to-ports=32506
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3323 protocol=tcp to-addresses=192.168.142.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34032 protocol=tcp to-addresses=192.168.142.13 to-ports=34032
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=3513 protocol=tcp to-addresses=192.168.141.13 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=34031 protocol=tcp to-addresses=192.168.141.13 to-ports=34031
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32302 protocol=tcp to-addresses=192.168.69.201 to-ports=32302
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=32301 protocol=tcp to-addresses=192.168.69.202 to-ports=32301
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=31101 protocol=tcp to-addresses=192.168.67.101 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=25001 protocol=tcp to-addresses=10.7.0.100 to-ports=22
/ip firewall nat add action=dst-nat chain=dstnat dst-address=160.22.181.181 dst-port=25002 protocol=tcp to-addresses=100.64.0.2 to-ports=22
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass" dst-port=53 protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass" dst-port=53 protocol=tcp
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass" protocol=udp src-port=53
/ip firewall raw add action=accept chain=prerouting comment="DNS bypass" protocol=tcp src-port=53
/ip firewall raw add action=notrack chain=prerouting protocol=ospf
/ip firewall raw add action=notrack chain=output protocol=ospf
/ip firewall raw add action=accept chain=prerouting comment=wg_rotko dst-address=172.31.0.0/16
/ip firewall raw add action=accept chain=prerouting comment=wg_rotko src-address=172.31.0.0/16
/ip firewall raw add action=notrack chain=prerouting in-interface=wg_rotko protocol=udp
/ip firewall raw add action=notrack chain=output out-interface=wg_rotko protocol=udp
/ip firewall raw add action=notrack chain=output dst-address=172.31.0.0/16 out-interface-list=WAN protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="Allow DNS queries from LAN to router (UDP)" dst-port=53 protocol=udp src-address-list=not_in_internet
/ip firewall raw add action=accept chain=prerouting comment="Allow DNS queries from LAN to router (TCP)" dst-port=53 protocol=tcp src-address-list=not_in_internet
/ip firewall raw add action=accept chain=prerouting comment="Allow DNS queries from LAN to external DNS (UDP)" dst-port=53 protocol=udp src-address-list=not_in_internet
/ip firewall raw add action=accept chain=prerouting comment="Allow DNS queries from LAN to external DNS (TCP)" dst-port=53 protocol=tcp src-address-list=not_in_internet
/ip firewall raw add action=accept chain=prerouting comment="Rate limit DNS queries from LAN (UDP)" disabled=yes dst-port=53 limit=20,10:packet protocol=udp
/ip firewall raw add action=accept chain=prerouting comment="Rate limit DNS queries from LAN (TCP)" disabled=yes dst-port=53 limit=20,10:packet protocol=tcp
/ip firewall raw add action=drop chain=prerouting comment="Drop external DNS queries to router (UDP)" disabled=yes dst-port=53 protocol=udp src-address-list=!not_in_internet
/ip firewall raw add action=drop chain=prerouting comment="Drop external DNS queries to router (TCP)" disabled=yes dst-port=53 protocol=tcp src-address-list=!not_in_internet
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add distance=220 gateway=BKK20-LAG
/ip route add distance=220 gateway=BKK00-LAG
/ip route add blackhole distance=220 dst-address=160.22.181.169/29
/ip route add blackhole distance=220 dst-address=160.22.181.181/29
/ip route add disabled=no dst-address=160.22.181.254/32 gateway=100.64.0.2
/ipv6 route add blackhole disabled=yes distance=254 dst-address=2401:a860::/32
/ip service set ftp disabled=yes
/ip service set ssh address=119.76.35.40/32,110.169.129.201/32,184.82.210.82/32,171.97.101.232/32,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.104.169.64/32,158.140.0.0/16,95.217.134.129/32
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
/ip service set api address=192.168.0.0/16
/ip service set api-ssl disabled=yes
/ip ssh set always-allow-password-login=yes
/ipv6 address add address=fd00:dead:beef::50/128 advertise=no interface=lo
/ipv6 address add address=2401:a860:169::50 comment=SAXv6 interface=SAX-BKK-01
/ipv6 address add address=2401:a860:1181::/128 advertise=no comment="bkk50 ipv6 public address" interface=lo
/ipv6 address add address=2401:a860:1181::50 comment=ROTKO-GW interface=bridge_local
/ipv6 address add address=fd00:dead:beef:50::1/127 advertise=no comment="ULA P2P to BKK00" interface=BKK00-LAG
/ipv6 address add address=fd00:dead:beef:2050::1/127 advertise=no comment="ULA P2P to BKK20" interface=BKK20-LAG
/ipv6 address add address=2401:a860:1181:50::1/127 advertise=no comment="Global P2P to BKK00" interface=BKK00-LAG
/ipv6 address add address=2401:a860:1181:2050::1/127 advertise=no comment="Global P2P to BKK20" interface=BKK20-LAG
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
/ipv6 firewall address-list add address=fd00:dead:beef::/48 list=our-networks-v6
/ipv6 firewall raw add action=accept chain=prerouting
/ipv6 nd add interface=bridge_local ra-lifetime=10m
/ipv6 nd add interface=SAX-BKK-01 ra-lifetime=10m
/ipv6 nd add interface=SAX-BKK-01-KVM ra-lifetime=10m
/routing bgp connection add disabled=no instance=bgp-instance-1 local.address=10.155.255.3 .role=ibgp multihop=yes name=ibgp-bkk00-v4 output.redistribute=connected remote.address=10.155.255.4 .as=142108 templates=iBGP-v4
/routing bgp connection add disabled=no instance=bgp-instance-1 local.address=10.155.255.3 .role=ibgp multihop=yes name=ibgp-bkk20-v4 output.redistribute=connected remote.address=10.155.255.2 .as=142108 templates=iBGP-v4
/routing bgp connection add disabled=no instance=bgp-instance-1 local.address=fd00:dead:beef::50 .role=ibgp name=ibgp-bkk00-v6 output.redistribute=connected remote.address=fd00:dead:beef::100 .as=142108 templates=iBGP-v6
/routing bgp connection add disabled=no instance=bgp-instance-1 local.address=fd00:dead:beef::50 .role=ibgp name=ibgp-bkk20-v6 output.redistribute=connected remote.address=fd00:dead:beef::20 .as=142108 templates=iBGP-v6
/routing filter rule add chain=iBGP-IN-v4 comment="Set BGP distance to 100" rule="set distance 100"
/routing filter rule add chain=iBGP-IN-v4 comment="Accept all from iBGP" rule=accept
/routing filter rule add chain=iBGP-IN-v6 comment="Accept all from iBGP" rule=accept
/routing filter rule add chain=iBGP-IN-v6 comment="Set BGP distance to 100" rule="set distance 100"
/routing filter rule add chain=iBGP-OUT-v4 comment="Local IBP network" rule="if (dst in 160.22.181.176/28 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v4 comment="SAX network" rule="if (dst in 160.22.181.169/29 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v4 comment="Public loopback" rule="if (dst in 160.22.181.181/32 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v4 comment="Another loopback" rule="if (dst in 160.22.181.20/32 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v4 comment="Advertise our prefix" rule="if (dst in 160.22.180.0/23) { accept }"
/routing filter rule add chain=iBGP-OUT-v4 comment="Don't readvertise BGP learned routes" rule="if (protocol bgp) { reject }"
/routing filter rule add chain=iBGP-OUT-v4 comment="Default reject" rule=reject
/routing filter rule add chain=iBGP-OUT-v6 comment="SAX IPv6" rule="if (dst in 2401:a860:169::/64 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v6 comment="IBP IPv6" rule="if (dst in 2401:a860:1181::/48 && protocol connected) { accept }"
/routing filter rule add chain=iBGP-OUT-v6 comment="Advertise our prefix" rule="if (dst in 2401:a860::/32) { accept }"
/routing filter rule add chain=iBGP-OUT-v6 comment="Don't readvertise BGP learned routes" rule="if (protocol bgp) { reject }"
/routing filter rule add chain=iBGP-OUT-v6 comment="Default reject" rule=reject
/routing ospf interface-template add area=backbone comment=loopback-v4 disabled=no networks=10.155.255.3/32 passive
/routing ospf interface-template add area=backbone-v6 comment=loopback-v6 disabled=no networks=fd00:dead:beef::50/128 passive
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk00-v6-ula disabled=no networks=fd00:dead:beef:50::1/127
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk20-v6-ula disabled=no networks=fd00:dead:beef:2050::1/127
/routing ospf interface-template add area=backbone comment=p2p-bkk00-v4 disabled=no networks=172.16.10.2/30
/routing ospf interface-template add area=backbone comment=p2p-bkk20-v4 disabled=no networks=172.16.20.2/30
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk00-v6-gua disabled=no networks=2401:a860:1181:50::1/127
/routing ospf interface-template add area=backbone-v6 comment=p2p-bkk20-v6-gua disabled=no networks=2401:a860:1181:2050::1/127
/routing ospf interface-template add area=backbone comment=ibp-v4 disabled=no networks=160.22.181.176/28 passive
/routing ospf interface-template add area=backbone comment=sax-v4 disabled=no networks=160.22.181.169/29 passive
/routing ospf interface-template add area=backbone comment=ibp-v4 disabled=no networks=160.22.181.176/28 passive
/routing ospf interface-template add area=backbone comment=sax-v4 disabled=no networks=160.22.181.169/29 passive
/routing ospf interface-template add area=backbone comment=rotko-infra-v4 disabled=no networks=160.22.181.0/26 passive
/routing ospf interface-template add area=backbone-v6 comment=anycast-v6 disabled=no networks=2401:a860::/48 passive
/routing ospf interface-template add area=backbone-v6 comment=ibp-unicast-v6 disabled=no networks=2401:a860:1181::/48 passive
/routing ospf interface-template add area=backbone comment=ibp-runner-001 disabled=no networks=160.22.181.254/32 passive
/snmp set enabled=yes trap-version=3
/system clock set time-zone-autodetect=no time-zone-name=Asia/Bangkok
/system identity set name=bkk50
/system logging set 0 prefix=:Info
/system logging set 1 prefix=:Error
/system logging set 2 prefix=:Warning
/system logging set 3 prefix=:Critical
/system logging add action=remote prefix=:Firewall topics=firewall
/system logging add action=remote prefix=:Account topics=account
/system logging add action=remote prefix=:Caps topics=caps
/system logging add action=remote prefix=:Wireles topics=wireless
/system ntp client set enabled=yes
/system ntp client servers add address=0.th.pool.ntp.org
/system ntp client servers add address=0.asia.pool.ntp.org
/system ntp client servers add address=1.asia.pool.ntp.org
/system package update set channel=testing
/system routerboard settings set enter-setup-on=delete-key
/tool netwatch add down-script="/ip firewall nat disable [find comment=\"haproxy-bkk08\"]" host=192.168.78.91 http-codes=200 interval=10s port=6404 timeout=5s type=http-get up-script="/ip firewall nat enable [find comment=\"haproxy-bkk08\"]"
/tool netwatch add down-script="/ip firewall nat disable [find comment=\"haproxy-bkk07\"]" host=192.168.77.91 http-codes=200 interval=10s port=6404 timeout=5s type=http-get up-script="/ip firewall nat enable [find comment=\"haproxy-bkk07\"]"
/tool netwatch add down-script="/ip firewall nat disable [find comment=\"haproxy-bkk06\"]" host=192.168.76.91 http-codes=200 interval=10s port=6404 timeout=5s type=http-get up-script="/ip firewall nat enable [find comment=\"haproxy-bkk06\"]"
/tool traffic-generator packet-template add name=blast-template
