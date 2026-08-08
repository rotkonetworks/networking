# ============================================================================
# NEW-DC EDGE — initial config for the relocated CCR2216 (ex-bkk00)
# RouterOS 7.23.x  ·  AS142108  ·  single edge: HGC transit up + unnumbered fabric
# Apply once on a freshly-reset + firmware-updated box:  /import file=edge-newdc.rsc
# ============================================================================
# >>> FILL THESE FROM HGC's NEW-DC HANDOFF (email/LOA) BEFORE APPLYING <<<
#   :global HGCPORT   -> physical SFP port the HGC fiber lands on   (default sfp28-1)
#   :global HGCVLAN   -> HGC transit VLAN id                        (SG today = 2520)
#   :global V4LOCAL   -> your /29 or /31 local v4 on the transit VLAN (SG = 118.143.234.74/29)
#   :global V4REMOTE  -> HGC's v4 peer                              (SG = 118.143.234.73)
#   :global V6LOCAL   -> your v6 local                              (SG = 2403:5000:165:15::2)
#   :global V6REMOTE  -> HGC's v6 peer                              (SG = 2403:5000:165:15::1)
#   :global RID       -> router-id                                  (e.g. 10.155.255.21)
# If HGC MOVES the SG circuit here, the SG values above are reused verbatim.
# ============================================================================

/system identity set name=edge-newdc
/system note set show-at-login=no

# ---- physical: HGC delivery is a tagged 10G fiber (bond -> transit VLAN) ----
/interface ethernet set [find default-name=sfp28-1] comment="HGC-NEWDC handoff" advertise=10G-baseSR-LR
/interface bonding add name=HGC-LAG mode=802.3ad transmit-hash-policy=layer-3-and-4 slaves=sfp28-1 comment="HGC new-DC fiber"
/interface vlan add name=vHGC-TRANSIT interface=HGC-LAG vlan-id=2520
/interface list add name=WAN
/interface list member add interface=HGC-LAG list=WAN

# ---- transit handoff addressing (SG defaults — confirm with HGC) ----
/ip address   add address=118.143.234.74/29        interface=vHGC-TRANSIT comment="HGC transit v4 (FILL)"
/ipv6 address add address=2403:5000:165:15::2/126   interface=vHGC-TRANSIT advertise=no comment="HGC transit v6 (FILL)"

# ---- our announced space (pull-up so BGP always originates) ----
/ip firewall address-list   add list=ipv4-apnic-rotko address=160.22.180.0/23
/ipv6 firewall address-list add list=ipv6-apnic-rotko address=2401:a860::/32
/ip route   add dst-address=160.22.180.0/23 blackhole comment="aggregate pull-up"
/ipv6 route add dst-address=2401:a860::/32  blackhole comment="aggregate pull-up"

# ---- inbound safety (MANRS-lite; port the full TE chains from bkk20 later) ----
/routing filter rule add chain=HGC-IN-v4 rule="if (dst-len > 24) { reject }"
/routing filter rule add chain=HGC-IN-v4 rule="if (dst in 0.0.0.0/8 || dst in 10.0.0.0/8 || dst in 100.64.0.0/10 || dst in 127.0.0.0/8 || dst in 169.254.0.0/16 || dst in 172.16.0.0/12 || dst in 192.0.2.0/24 || dst in 192.168.0.0/16 || dst in 198.18.0.0/15 || dst in 203.0.113.0/24 || dst in 224.0.0.0/3) { reject }"
/routing filter rule add chain=HGC-IN-v4 rule="accept"
/routing filter rule add chain=HGC-IN-v6 rule="if (dst-len > 48) { reject }"
/routing filter rule add chain=HGC-IN-v6 rule="if (dst in fc00::/7 || dst in fe80::/10 || dst in 2001:db8::/32 || dst in ::/8) { reject }"
/routing filter rule add chain=HGC-IN-v6 rule="accept"
# outbound: announce ONLY our own aggregate
/routing filter rule add chain=HGC-OUT-v4 rule="if (dst in 160.22.180.0/23 && dst-len==23) { accept }"
/routing filter rule add chain=HGC-OUT-v4 rule="reject"
/routing filter rule add chain=HGC-OUT-v6 rule="if (dst in 2401:a860::/32 && dst-len==32) { accept }"
/routing filter rule add chain=HGC-OUT-v6 rule="reject"

# ---- BGP: our instance ----
/routing bgp instance add name=inst1 as=142108 router-id=10.155.255.21 vrf=main

# ---- HGC transit eBGP (numbered, RFC9234 customer, GTSM) ----
/routing bgp connection add name=HGC-v4 instance=inst1 afi=ip local.role=ebgp \
    remote.address=118.143.234.73 .as=9304 hold-time=3m keepalive-time=1m \
    input.filter=HGC-IN-v4 output.filter-chain=HGC-OUT-v4 .network=ipv4-apnic-rotko
/routing bgp connection add name=HGC-v6 instance=inst1 afi=ipv6 local.role=ebgp \
    local.address=2403:5000:165:15::2 remote.address=2403:5000:165:15::1 .as=9304 hold-time=3m keepalive-time=1m \
    input.filter=HGC-IN-v6 output.filter-chain=HGC-OUT-v6 .network=ipv6-apnic-rotko

# ---- unnumbered eBGP DOWN to the new-DC switch (VALIDATED on 7.23) ----
/ipv6 nd add interface=sfp28-3 ra-interval=3s-5s
/ipv6 nd prefix add prefix=none interface=sfp28-3
/routing bgp connection add name=fabric-sw1 instance=inst1 afi=ip local.role=ebgp \
    local.address=sfp28-3 remote.as=65100
# (add sfp28-4 the same way for a 2nd switch / edge2 iBGP later — additive)

# ---- management + hardening ----
/ip service disable telnet,ftp,www,api
/ip service set ssh address=<YOUR-REMOTE-SRC>/32,192.168.0.0/16 comment="lock to your sources"
/ip service set winbox address=192.168.0.0/16
/ipv6 settings set forward=yes accept-router-advertisements=no
# TODO before prod: port bkk20's full HGC TE filter chains + RPKI (Routinator) + fail2ban-equiv
