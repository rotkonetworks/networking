# 2026-01-23 01:16:45 by RouterOS 7.20beta4
# software id = VILU-XVN6
#
# model = CRS354-48G-4S+2Q+
# serial number = HGZ0A43405J
/interface bridge add admin-mac=F4:1E:57:33:4C:7E auto-mac=no comment=defconf name=bridge protocol-mode=none vlan-filtering=yes
/interface ethernet set [ find default-name=ether1 ] comment=bkk01kvm
/interface ethernet set [ find default-name=ether2 ] comment=bkk01
/interface ethernet set [ find default-name=ether3 ] comment=bkk02kvm
/interface ethernet set [ find default-name=ether4 ] comment=bkk02
/interface ethernet set [ find default-name=ether5 ] comment=bkk03kvm
/interface ethernet set [ find default-name=ether6 ] comment=bkk03
/interface ethernet set [ find default-name=ether7 ] comment=bkk04kvm
/interface ethernet set [ find default-name=ether8 ] comment=bkk04
/interface ethernet set [ find default-name=ether9 ] comment=bkk05kvm
/interface ethernet set [ find default-name=ether10 ] comment=bkk05
/interface ethernet set [ find default-name=ether11 ] comment=bkk06kvm
/interface ethernet set [ find default-name=ether12 ] comment=bkk06
/interface ethernet set [ find default-name=ether13 ] comment=bkk07kvm
/interface ethernet set [ find default-name=ether14 ] comment=bkk07
/interface ethernet set [ find default-name=ether15 ] comment=bkk08kvm
/interface ethernet set [ find default-name=ether16 ] comment=bkk08
/interface ethernet set [ find default-name=ether17 ] comment=bkk09kvm
/interface ethernet set [ find default-name=ether18 ] comment=bkk09
/interface ethernet set [ find default-name=ether19 ] comment=bkk10kvm
/interface ethernet set [ find default-name=ether20 ] comment=bkk10
/interface ethernet set [ find default-name=ether21 ] comment=bkk11kvm
/interface ethernet set [ find default-name=ether22 ] comment=bkk11
/interface ethernet set [ find default-name=ether23 ] comment=bkk12kvm
/interface ethernet set [ find default-name=ether24 ] comment=bkk12
/interface ethernet set [ find default-name=ether25 ] comment=bkk13kvm
/interface ethernet set [ find default-name=ether26 ] comment=bkk13
/interface ethernet set [ find default-name=ether39 ] comment=bkk30
/interface ethernet set [ find default-name=ether40 ] comment=bkk40
/interface vlan add interface=bridge name=vlan400-bgp vlan-id=400
/interface bonding add mode=802.3ad name=BKK10-SFP24-LAG slaves=qsfpplus2-1,qsfpplus2-2
/interface bonding add mode=802.3ad name=BKK40-QSFP3-LAG slaves=qsfpplus1-1,qsfpplus1-2,qsfpplus1-3,qsfpplus1-4
/port set 0 name=serial0
/routing bgp template set default as=65530
/interface bridge port add bridge=bridge comment=defconf interface=ether1
/interface bridge port add bridge=bridge comment=defconf interface=ether2
/interface bridge port add bridge=bridge comment=defconf interface=ether3
/interface bridge port add bridge=bridge comment=defconf interface=ether4
/interface bridge port add bridge=bridge comment=defconf interface=ether5
/interface bridge port add bridge=bridge comment=defconf interface=ether6
/interface bridge port add bridge=bridge comment=defconf interface=ether7
/interface bridge port add bridge=bridge comment=defconf interface=ether8
/interface bridge port add bridge=bridge comment=defconf interface=ether9
/interface bridge port add bridge=bridge comment=defconf interface=ether10
/interface bridge port add bridge=bridge comment=defconf interface=ether11
/interface bridge port add bridge=bridge comment=defconf interface=ether12
/interface bridge port add bridge=bridge comment=defconf interface=ether13
/interface bridge port add bridge=bridge comment=defconf interface=ether14
/interface bridge port add bridge=bridge comment=defconf interface=ether15
/interface bridge port add bridge=bridge comment=defconf interface=ether16
/interface bridge port add bridge=bridge comment=defconf interface=ether17
/interface bridge port add bridge=bridge comment=defconf interface=ether18
/interface bridge port add bridge=bridge comment=defconf interface=ether19
/interface bridge port add bridge=bridge comment=defconf interface=ether20
/interface bridge port add bridge=bridge comment=defconf interface=ether21
/interface bridge port add bridge=bridge comment=defconf interface=ether22
/interface bridge port add bridge=bridge comment=defconf interface=ether23
/interface bridge port add bridge=bridge comment=defconf interface=ether24
/interface bridge port add bridge=bridge comment=defconf interface=ether25
/interface bridge port add bridge=bridge comment=defconf interface=ether26
/interface bridge port add bridge=bridge comment=defconf interface=ether27
/interface bridge port add bridge=bridge comment=defconf interface=ether28
/interface bridge port add bridge=bridge comment=defconf interface=ether29
/interface bridge port add bridge=bridge comment=defconf interface=ether30
/interface bridge port add bridge=bridge comment=defconf interface=ether31
/interface bridge port add bridge=bridge comment=defconf interface=ether32
/interface bridge port add bridge=bridge comment=defconf interface=ether33
/interface bridge port add bridge=bridge comment=defconf interface=ether34
/interface bridge port add bridge=bridge comment=defconf interface=ether35
/interface bridge port add bridge=bridge comment=defconf interface=ether36
/interface bridge port add bridge=bridge comment=defconf interface=ether37
/interface bridge port add bridge=bridge comment=defconf interface=ether38
/interface bridge port add bridge=bridge comment=defconf interface=ether39
/interface bridge port add bridge=bridge comment=defconf interface=ether40
/interface bridge port add bridge=bridge comment=defconf interface=ether41
/interface bridge port add bridge=bridge comment=defconf interface=ether42
/interface bridge port add bridge=bridge comment=defconf interface=ether43
/interface bridge port add bridge=bridge comment=defconf interface=ether44
/interface bridge port add bridge=bridge comment=defconf interface=ether45
/interface bridge port add bridge=bridge comment=defconf interface=ether46
/interface bridge port add bridge=bridge comment=defconf interface=ether47
/interface bridge port add bridge=bridge comment=defconf interface=ether48
/interface bridge port add bridge=bridge comment=defconf interface=ether49
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus1-1
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus1-2
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus1-3
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus1-4
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus2-1
/interface bridge port add bridge=bridge comment=defconf disabled=yes interface=qsfpplus2-2
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-3
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-4
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus1
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus2
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus3
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus4
/interface bridge port add bridge=bridge interface=BKK10-SFP24-LAG
/interface bridge port add bridge=bridge interface=BKK40-QSFP3-LAG
/interface bridge vlan add bridge=bridge tagged=BKK10-SFP24-LAG vlan-ids=400
/interface ovpn-server server add mac-address=FE:71:39:D1:05:64 name=ovpn-server1
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
/ip address add address=160.22.181.186 interface=lo network=160.22.181.186
/ip address add address=192.168.69.2/16 interface=bridge network=192.168.0.0
/ip address add address=160.22.181.186 interface=bridge network=160.22.181.186
/ip dhcp-relay add dhcp-server=192.168.69.1 interface=bridge local-address=192.168.69.2 name=relay-bkk50
/ip dns set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1
/ip hotspot profile set [ find default=yes ] html-directory=hotspot
/ip ipsec profile set [ find default=yes ] dpd-interval=2m dpd-maximum-failures=5
/ip route add dst-address=0.0.0.0/0 gateway=192.168.69.1
/ipv6 route add check-gateway=ping distance=1 dst-address=::/0 gateway=fe80::4aa9:8aff:fec0:8252%bridge
/ip service set ftp disabled=yes
/ip service set ssh address=172.104.169.64/32,158.140.0.0/16
/ip service set telnet disabled=yes
/ip service set www disabled=yes
/ip service set winbox disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ipv6 address add address=2401:a860:1181::60 disabled=yes interface=lo
/ipv6 address add address=2401:a860:1181::60 interface=bridge
/system clock set time-zone-name=America/Chicago
/system identity set name=bkk60
/system package update set channel=development
/system routerboard settings set enter-setup-on=delete-key
/tool sniffer set filter-direction=rx filter-interface=ether23
