# 2025-06-25 06:16:45 by RouterOS 7.15.2
# software id = VILU-XVN6
#
# model = CRS354-48G-4S+2Q+
# serial number = HGZ0A43405J
/interface bridge add admin-mac=F4:1E:57:33:4C:7E auto-mac=no comment=defconf name=bridge protocol-mode=none
/interface bridge add name=bridge-bkk50 protocol-mode=none
/port set 0 name=serial0
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
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus1-1
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus1-2
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus1-3
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus1-4
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-1
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-2
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-3
/interface bridge port add bridge=bridge comment=defconf interface=qsfpplus2-4
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus1
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus2
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus3
/interface bridge port add bridge=bridge comment=defconf interface=sfp-sfpplus4
/ip address add address=192.168.88.1/24 comment=defconf interface=bridge network=192.168.88.0
/ip address add address=160.22.181.186 interface=lo network=160.22.181.186
/ip address add address=192.168.69.2/16 interface=bridge network=192.168.0.0
/ip address add address=160.22.181.186 interface=bridge network=160.22.181.186
/ip dhcp-relay add dhcp-server=192.168.69.1 interface=bridge local-address=192.168.69.2 name=relay-bkk50
/ip dns set allow-remote-requests=yes servers=8.8.8.8,1.1.1.1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.69.1
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set ssh address=172.104.169.64/32,158.140.0.0/16
/ip service set api disabled=yes
/ip service set winbox disabled=yes
/ip service set api-ssl disabled=yes
/system clock set time-zone-name=America/Chicago
/system identity set name=bkk60
/system note set show-at-login=no
/system routerboard settings set boot-os=router-os enter-setup-on=delete-key
/tool sniffer set filter-direction=rx filter-interface=ether23
