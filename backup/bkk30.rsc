# 2025-07-04 05:15:59 by RouterOS 7.20beta4
# software id = VMHP-N1T8
#
# model = CRS504-4XQ
# serial number = HE308K785GX
/interface bridge
add name=bridge vlan-filtering=yes
add disabled=yes forward-delay=6s max-message-age=10s name=ceph vlan-filtering=yes
/interface ethernet
set [ find default-name=ether1 ] l2mtu=2028
set [ find default-name=qsfp28-1-1 ] advertise=100G-baseCR4 comment=BKK00-LAG fec-mode=off l2mtu=9100 mtu=9000
set [ find default-name=qsfp28-2-1 ] auto-negotiation=no l2mtu=9100 mtu=9000
set [ find default-name=qsfp28-3-1 ] advertise=100G-baseCR4 comment=bkk08 fec-mode=off l2mtu=9100 mtu=9000
set [ find default-name=qsfp28-4-1 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface vlan
add disabled=yes interface=ceph name=ceph_private vlan-id=200
add disabled=yes interface=ceph name=ceph_public vlan-id=100
add disabled=yes interface=ceph name=ceph_untagged vlan-id=1
add interface=bridge name=vlan400-bgp vlan-id=400
/port
set 0 name=serial0
/routing bgp template
set default as=65530
/interface bridge port
add bridge=bridge ingress-filtering=no interface=qsfp28-1-1
add bridge=bridge ingress-filtering=no interface=qsfp28-2-1
add bridge=bridge ingress-filtering=no interface=qsfp28-3-1
add bridge=bridge ingress-filtering=no interface=qsfp28-4-1
/ip neighbor discovery-settings
set discover-interval=1m
/interface bridge vlan
add bridge=ceph comment=public tagged=qsfp28-1-1,qsfp28-2-1,qsfp28-3-1,qsfp28-4-1,ceph vlan-ids=100
add bridge=ceph comment=private tagged=qsfp28-1-1,qsfp28-2-1,qsfp28-3-1,qsfp28-4-1,ceph vlan-ids=200
add bridge=ceph comment=untagged untagged=ceph,qsfp28-1-1,qsfp28-2-1,qsfp28-3-1,qsfp28-4-1 vlan-ids=1
add bridge=bridge tagged=qsfp28-2-1,qsfp28-3-1,qsfp28-4-1,qsfp28-1-1 vlan-ids=400
/interface ovpn-server server
add mac-address=FE:52:AD:0F:B5:98 name=ovpn-server1
/ip address
add address=192.168.88.30/24 comment=defconf interface=ether1 network=192.168.88.0
add address=10.255.30.1 interface=lo network=10.255.40.1
add address=10.255.255.30/24 interface=ceph_untagged network=10.255.255.0
add address=10.255.100.30/24 interface=ceph_public network=10.255.100.0
add address=10.255.200.30/24 interface=ceph_private network=10.255.200.0
add address=160.22.181.183 interface=ether1 network=160.22.181.183
add address=10.155.254.30/24 interface=vlan400-bgp network=10.155.254.0
/ip dns
set servers=2620:fe::fe
/ip route
add dst-address=0.0.0.0/0 gateway=192.168.88.1
/ipv6 route
add dst-address=::/0 gateway=fe80::f61e:57ff:fe33:4c7e%ether1
/ip service
set ftp disabled=yes
set ssh address=160.22.180.0/23,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8,2400:8901::f03c:94ff:fe03:c318/128
set telnet disabled=yes
set www disabled=yes
set winbox disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/ipv6 address
add address=fd12:3456:abcd:255::30 advertise=no interface=ceph_untagged
add address=2401:a860:1181::30 interface=ether1
/system clock
set time-zone-name=America/Chicago
/system identity
set name=bkk30  
/system package update
set channel=testing
/system routerboard settings
set auto-upgrade=yes enter-setup-on=delete-key
