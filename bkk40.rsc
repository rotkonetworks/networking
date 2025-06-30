# 2025-06-25 19:23:32 by RouterOS 7.20beta4
# software id = S02Y-Y1T7
#
# model = CRS504-4XQ
# serial number = HGF09ZKA5QK
/interface bridge add forward-delay=6s max-message-age=10s name=ceph vlan-filtering=yes
/interface ethernet set [ find default-name=ether1 ] l2mtu=2028
/interface ethernet set [ find default-name=qsfp28-1-1 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-1-2 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-1-3 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-1-4 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet set [ find default-name=qsfp28-2-1 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-2-2 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-2-3 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-2-4 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet set [ find default-name=qsfp28-3-1 ] advertise=100G-baseCR4 comment=bkk08 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-3-2 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-3-3 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-3-4 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet set [ find default-name=qsfp28-4-1 ] advertise=100G-baseCR4 comment=bkk30 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-4-2 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-4-3 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface ethernet
# unsupported speed
set [ find default-name=qsfp28-4-4 ] advertise=100G-baseCR4 fec-mode=off l2mtu=9100 mtu=9000
/interface wireguard add listen-port=54483 mtu=1420 name=wg_rotko
/interface vlan add interface=ceph name=ceph_private vlan-id=200
/interface vlan add interface=ceph name=ceph_public vlan-id=100
/interface vlan add interface=ceph name=ceph_untagged vlan-id=1
/port set 0 name=serial0
/routing bgp template set default as=65530
/interface bridge port add bridge=ceph interface=qsfp28-2-1
/interface bridge port add bridge=ceph interface=qsfp28-3-1
/interface bridge port add bridge=ceph interface=qsfp28-4-1
/interface bridge port add bridge=ceph ingress-filtering=no interface=qsfp28-1-1
/interface bridge port add bridge=ceph ingress-filtering=no interface=qsfp28-1-2
/interface bridge port add bridge=ceph ingress-filtering=no interface=qsfp28-1-3
/interface bridge port add bridge=ceph ingress-filtering=no interface=qsfp28-1-4
/interface ethernet switch l3hw-settings set autorestart=yes ipv6-hw=yes
/ip neighbor discovery-settings set discover-interval=1m
/interface bridge vlan add bridge=ceph comment=public tagged=qsfp28-1-1,qsfp28-1-2,qsfp28-1-3,qsfp28-1-4,qsfp28-2-1,qsfp28-3-1,qsfp28-4-1 vlan-ids=100
/interface bridge vlan add bridge=ceph comment=private tagged=qsfp28-1-1,qsfp28-1-2,qsfp28-1-3,qsfp28-1-4,qsfp28-2-1,qsfp28-3-1,qsfp28-4-1 vlan-ids=200
/interface bridge vlan add bridge=ceph comment=untagged untagged=qsfp28-1-1,qsfp28-1-2,qsfp28-1-3,qsfp28-1-4,qsfp28-3-1,qsfp28-4-1,qsfp28-2-1 vlan-ids=1
/interface ovpn-server server add mac-address=FE:F4:B8:5E:41:C0 name=ovpn-server1
/ip address add address=192.168.88.40/24 interface=ether1 network=192.168.88.0
/ip address add address=10.255.40.1 interface=lo network=10.255.40.1
/ip address add address=10.255.255.40/24 disabled=yes interface=ceph_untagged network=10.255.255.0
/ip address add address=10.255.200.40/24 disabled=yes interface=ceph_private network=10.255.200.0
/ip address add address=10.255.100.40/24 disabled=yes interface=ceph_public network=10.255.100.0
/ip dns set servers=2620:fe::fe
/ip route add disabled=yes distance=110 gateway=ceph
/ip route add disabled=no dst-address=172.31.0.0/16 gateway=wg_rotko
/ip route add dst-address=0.0.0.0/0 gateway=192.168.88.1
/ipv6 route add dst-address=::/0 gateway=fe80::f61e:57ff:fe33:4c7e%ether1
/ip service set ftp address=10.40.0.0/24,192.168.88.0/24 disabled=yes
/ip service set ssh address=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,160.22.181.181/32,2401:a860:1181::/64,2400:8901::f03c:94ff:fe03:c318/128
/ip service set telnet address=10.40.0.0/24,192.168.88.0/24 disabled=yes
/ip service set www address=10.40.0.0/24,192.168.88.0/24 disabled=yes
/ip service set www-ssl address=10.40.0.0/24,192.168.88.0/24
/ip service set winbox address=10.40.0.0/24,192.168.88.0/24
/ip service set api address=10.40.0.0/24,192.168.88.0/24 disabled=yes
/ip service set api-ssl address=10.40.0.0/24,192.168.88.0/24 disabled=yes
/ipv6 address add address=fd12:3456:abcd:255::40 advertise=no interface=ceph_untagged
/ipv6 address add address=2401:a860:1181::40 advertise=no interface=ether1
/system clock set time-zone-name=America/Chicago
/system identity set name=bkk40
/system note set show-at-login=no
/system ntp client set enabled=yes
/system ntp client servers add address=10.10.0.1
/system ntp client servers add address=10.20.0.1
/system package update set channel=testing
/system routerboard reset-button set enabled=yes
/system routerboard settings set enter-setup-on=delete-key
