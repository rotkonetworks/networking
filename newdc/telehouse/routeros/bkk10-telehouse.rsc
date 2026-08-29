# bkk10 @ Telehouse - CCR2116-12G-4S+ : the AS142108 edge router.
#
# Ports (lab mapping; real hw = sfp-sfpplus*, all 10G - this board has NO 25G):
#   ether1  mgmt (out of band)
#   ether2  handoff from bkk60, tagged 2519 (HGC) + 3995 (AMS-IX)
#   ether3  downstream to leaf h1, unnumbered eBGP (RFC5549)
#
# VLAN ids and the HGC p2p addressing are PLACEHOLDERS from the bkk00 circuit.
# The Telehouse cross-connect is issued its own values - replace before use.
#
# Policy mirrors bkk20 production: remove-private-as, as-override=no,
# origination from the ipv4/ipv6-apnic-rotko address lists, bogon + default +
# too-specific rejection inbound, and only our own prefixes outbound.

/system/identity/set name=bkk10

# ---------------------------------------------------------------- L2 / L3 ---
/interface/bridge/add name=br-edge protocol-mode=none vlan-filtering=no \
    comment="provider VLANs from bkk60"

/interface/bridge/port/add bridge=br-edge interface=ether2 comment="handoff from bkk60"

# The bridge itself must be tagged for a VLAN whose traffic we terminate in L3.
/interface/bridge/vlan/add bridge=br-edge vlan-ids=2519 tagged=ether2,br-edge
/interface/bridge/vlan/add bridge=br-edge vlan-ids=3995 tagged=ether2,br-edge

/interface/vlan/add name=vlan-hgc   interface=br-edge vlan-id=2519 comment="HGC transit"
/interface/vlan/add name=vlan-amsix interface=br-edge vlan-id=3995 comment="AMS-IX Bangkok"

/ip/address/add address=103.99.0.2/29        interface=vlan-hgc   comment="HGC p2p PLACEHOLDER"
/ip/address/add address=103.100.140.31/24    interface=vlan-amsix comment="AMS-IX BKK peering LAN"
/ipv6/address/add address=2403:5000:ff::2/126 interface=vlan-hgc   advertise=no
/ipv6/address/add address=2402:b740:15:388:a500:14:2108:1/64 interface=vlan-amsix advertise=no

# Loopback / router-id. New-site block, mirroring the fixed /29 edge convention
# (.178 bkk20, .179 bkk10, .180 bkk00, .181 bkk50).
/ip/address/add address=160.22.180.179/32 interface=lo comment="public loopback"
/ipv6/address/add address=2401:a860:2000::10/128 interface=lo advertise=no

# vlan-filtering LAST - before the vlan table exists it blackholes the ports.
/interface/bridge/set [find name=br-edge] vlan-filtering=yes

# ------------------------------------------------------- origination lists ---
/ip/firewall/address-list/add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ip/firewall/address-list/add address=160.22.180.0/24 list=ipv4-apnic-rotko
/ipv6/firewall/address-list/add address=2401:a860::/32 list=ipv6-apnic-rotko

/routing/filter/num-list/add list=ipv4-apnic-rotko range=142108
/routing/filter/num-list/add list=ipv6-apnic-rotko range=142108

# Origination requires the prefix to EXIST in the routing table -- output.network
# only announces what is present. A /32 on lo does not create the /24. Production
# (bkk20) uses blackhole statics at distance 240 for exactly this.
/ip/route/add blackhole distance=240 dst-address=160.22.180.0/23 comment=global_ipv4_resources
/ip/route/add blackhole distance=240 dst-address=160.22.180.0/24 comment=global_unicast_v4
/ipv6/route/add blackhole distance=240 dst-address=2401:a860::/32 comment=global_ipv6_resources
# site carve: /36 per site (decision 2026-08-29, see bkk10-newsite-edge-design.md par.6.3).
# ROA is /32 maxLength 40 and route6 objects exist, so this validates + passes IRR filters.
/ipv6/route/add blackhole distance=240 dst-address=2401:a860:2000::/36 comment=site_v6_36
/ipv6/firewall/address-list/add address=2401:a860:2000::/36 list=ipv6-apnic-rotko

# ------------------------------------------------------------------ bogons ---
/ip/firewall/address-list/add address=0.0.0.0/8       comment="RFC1122 this host"      list=ipv4-bogons
/ip/firewall/address-list/add address=10.0.0.0/8      comment="RFC1918"                list=ipv4-bogons
/ip/firewall/address-list/add address=100.64.0.0/10   comment="RFC6598 CGNAT"          list=ipv4-bogons
/ip/firewall/address-list/add address=127.0.0.0/8     comment="loopback"               list=ipv4-bogons
/ip/firewall/address-list/add address=169.254.0.0/16  comment="link local"             list=ipv4-bogons
/ip/firewall/address-list/add address=172.16.0.0/12   comment="RFC1918"                list=ipv4-bogons
/ip/firewall/address-list/add address=192.0.2.0/24    comment="TEST-NET-1"             list=ipv4-bogons
/ip/firewall/address-list/add address=192.168.0.0/16  comment="RFC1918"                list=ipv4-bogons
/ip/firewall/address-list/add address=224.0.0.0/4     comment="multicast"              list=ipv4-bogons
/ip/firewall/address-list/add address=240.0.0.0/4     comment="reserved"               list=ipv4-bogons
/ipv6/firewall/address-list/add address=::/128        comment="unspecified"            list=ipv6-bogons
/ipv6/firewall/address-list/add address=::1/128       comment="loopback"               list=ipv6-bogons
/ipv6/firewall/address-list/add address=fc00::/7      comment="ULA"                    list=ipv6-bogons
/ipv6/firewall/address-list/add address=fe80::/10     comment="link local"             list=ipv6-bogons
/ipv6/firewall/address-list/add address=2001:db8::/32 comment="documentation"          list=ipv6-bogons

# ------------------------------------------------------------ filter chains ---
# INBOUND from transit (HGC): full table wanted, but never our own space,
# never a bogon, never absurdly specific.
/routing/filter/rule/add chain=HGC-IN-v4 comment="reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v4 comment="bogons"                  rule="if (dst in ipv4-bogons) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v4 comment="too specific"            rule="if (dst-len > 24) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v4 comment="accept rest"             rule="accept"

/routing/filter/rule/add chain=HGC-IN-v6 comment="reject our own prefixes" rule="if (dst in ipv6-apnic-rotko) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v6 comment="bogons"                  rule="if (dst in ipv6-bogons) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v6 comment="too specific"            rule="if (dst-len > 48) { reject; }"
/routing/filter/rule/add chain=HGC-IN-v6 comment="accept rest"             rule="accept"

# INBOUND from the IX: same, plus an IX must NEVER hand us a default route.
/routing/filter/rule/add chain=AMSIX-BAN-IN-v4 comment="reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v4 comment="bogons"                  rule="if (dst in ipv4-bogons) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v4 comment="no default from an IX"   rule="if (dst == 0.0.0.0/0) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v4 comment="too specific"            rule="if (dst-len > 24) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v4 comment="accept rest"             rule="accept"

/routing/filter/rule/add chain=AMSIX-BAN-IN-v6 comment="reject our own prefixes" rule="if (dst in ipv6-apnic-rotko) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v6 comment="bogons"                  rule="if (dst in ipv6-bogons) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v6 comment="no default from an IX"   rule="if (dst == ::/0) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v6 comment="too specific"            rule="if (dst-len > 48) { reject; }"
/routing/filter/rule/add chain=AMSIX-BAN-IN-v6 comment="accept rest"             rule="accept"

# OUTBOUND - the rule that stops us becoming everyone's transit.
# Announce ONLY our own space. Anything else is rejected, explicitly.
/routing/filter/rule/add chain=HGC-OUT-v4 comment="only our own space" rule="if (dst in ipv4-apnic-rotko) { accept; } reject;"
/routing/filter/rule/add chain=HGC-OUT-v6 comment="only our own space" rule="if (dst in ipv6-apnic-rotko) { accept; } reject;"
/routing/filter/rule/add chain=AMSIX-BAN-OUT-v4 comment="only our own space" rule="if (dst in ipv4-apnic-rotko) { accept; } reject;"
/routing/filter/rule/add chain=AMSIX-BAN-OUT-v6 comment="only our own space" rule="if (dst in ipv6-apnic-rotko) { accept; } reject;"

# Downstream leaf: accept only what it is allowed to originate.
/routing/filter/rule/add chain=LEAF-IN-v4 rule="if (dst in 160.22.180.0/23 && dst-len <= 32) { accept; } reject;"
/routing/filter/rule/add chain=LEAF-IN-v6 rule="if (dst in ipv6-apnic-rotko) { accept; } reject;"
/routing/filter/rule/add chain=LEAF-OUT-v4 rule="accept"
/routing/filter/rule/add chain=LEAF-OUT-v6 rule="accept"

# ---------------------------------------------------------------------- BGP ---
/routing/bgp/instance/add as=142108 name=bgp-instance-1 router-id=160.22.180.179 vrf=main

/routing/bgp/template/add name=HGC-v4 afi=ip input.filter=HGC-IN-v4 \
    output.filter-chain=HGC-OUT-v4 .network=ipv4-apnic-rotko .as-override=no \
    .keep-sent-attributes=yes .remove-private-as=yes routing-table=main
/routing/bgp/template/add name=HGC-v6 afi=ipv6 input.filter=HGC-IN-v6 \
    output.filter-chain=HGC-OUT-v6 .network=ipv6-apnic-rotko .as-override=no \
    .keep-sent-attributes=yes .remove-private-as=yes routing-table=main
/routing/bgp/template/add name=AMSIX-BAN-v4 afi=ip input.filter=AMSIX-BAN-IN-v4 \
    output.filter-chain=AMSIX-BAN-OUT-v4 .network=ipv4-apnic-rotko .as-override=no \
    .keep-sent-attributes=yes .remove-private-as=yes routing-table=main
/routing/bgp/template/add name=AMSIX-BAN-v6 afi=ipv6 input.filter=AMSIX-BAN-IN-v6 \
    output.filter-chain=AMSIX-BAN-OUT-v6 .network=ipv6-apnic-rotko .as-override=no \
    .keep-sent-attributes=yes .remove-private-as=yes routing-table=main

/routing/bgp/connection/add name=HGC-TRANSIT-v4 instance=bgp-instance-1 templates=HGC-v4 \
    afi=ip local.role=ebgp local.address=103.99.0.2 remote.address=103.99.0.1 .as=9304 \
    input.limit-process-routes-ipv4=3000000 routing-table=main disabled=no
/routing/bgp/connection/add name=HGC-TRANSIT-v6 instance=bgp-instance-1 templates=HGC-v6 \
    afi=ipv6 local.role=ebgp local.address=2403:5000:ff::2 remote.address=2403:5000:ff::1 .as=9304 \
    input.limit-process-routes-ipv6=3000000 routing-table=main disabled=no

/routing/bgp/connection/add name=AMSIX-BAN-RS1-v4 instance=bgp-instance-1 templates=AMSIX-BAN-v4 \
    afi=ip local.role=ebgp local.address=103.100.140.31 remote.address=103.100.140.251 .as=150388 \
    input.limit-process-routes-ipv4=5000000 routing-table=main disabled=no
/routing/bgp/connection/add name=AMSIX-BAN-RS1-v6 instance=bgp-instance-1 templates=AMSIX-BAN-v6 \
    afi=ipv6 local.role=ebgp local.address=2402:b740:15:388:a500:14:2108:1 \
    remote.address=2402:b740:15:388:a500:15:388:251 .as=150388 \
    input.limit-process-routes-ipv6=5000000 routing-table=main disabled=no

# Downstream leaf, unnumbered (RFC5549): empty remote.address + local.address=<iface>
/routing/bgp/connection/add name=LEAF-h1 instance=bgp-instance-1 \
    local.role=ebgp local.address=ether3 remote.as=65110 \
    input.filter=LEAF-IN-v4 output.filter-chain=LEAF-OUT-v4 \
    .redistribute=connected,static,bgp routing-table=main disabled=no

# ------------------------------------------------- IX / carrier hygiene ------
# AMS-IX quarantine checks: no LLDP/CDP/MNDP, no IPv6 RA, only IPv4/ARP/IPv6
# ethertypes, one MAC per port. The architecture already gives one MAC (bkk60
# has no L3); the rest must be explicit because RouterOS defaults violate it.

# 1) MNDP/LLDP: transmitted on ALL interfaces by default. rx-only (as on
#    production bkk00/bkk20) silences tx everywhere.
/ip/neighbor/discovery-settings/set mode=rx-only

# 2) IPv6 RA: sent on every v6-enabled interface by default. Kill the default
#    entry, then re-enable ND ONLY where it is required - the unnumbered leaf
#    eBGP on ether3 discovers its peer via RA/link-local, so that one stays.
#    (Production bkk20 only sets ra-lifetime=none, which still EMITS RA frames
#    on the IX LAN - this is the stricter, actually-compliant form.)
/ipv6/nd/set [ find default=yes ] disabled=yes
/ipv6/nd/add interface=ether3 comment="RA required for unnumbered leaf eBGP"

# 3) Ethertype whitelist toward the provider trunk - ported from production
#    bkk20 bridge filters. Accepts IPv4/ARP/IPv6 (+ the legitimate multicast
#    and broadcast forms), drops everything else egressing ether2.
#    CAVEAT: with br-edge's single port, chain=forward matches nothing today -
#    router-originated frames take the bridge output path. These rules become
#    live protection the day another port joins the bridge (the contemplated
#    "extend HGC VLANs to servers"), which is exactly when stray-frame risk
#    appears. Tagged frames also match mac-protocol=vlan (as in production),
#    so the hard compliance guarantees are rules 1+2 above.
/interface/bridge/filter/add action=accept chain=forward mac-protocol=ip   out-interface=ether2
/interface/bridge/filter/add action=accept chain=forward mac-protocol=arp  out-interface=ether2
/interface/bridge/filter/add action=accept chain=forward mac-protocol=ipv6 out-interface=ether2
/interface/bridge/filter/add action=accept chain=forward mac-protocol=vlan out-interface=ether2
/interface/bridge/filter/add action=accept chain=forward dst-mac-address=33:33:00:00:00:00/FF:FF:00:00:00:00 mac-protocol=ipv6 out-interface=ether2
/interface/bridge/filter/add action=accept chain=forward dst-mac-address=FF:FF:FF:FF:FF:FF/FF:FF:FF:FF:FF:FF out-interface=ether2
/interface/bridge/filter/add action=drop   chain=forward out-interface=ether2 comment="ethertype whitelist: drop the rest"

# NOTE: RPKI is deliberately NOT enabled here - the lab has no validator.
# Production adds, per IN chain:
#   rule="rpki-verify rpki.bknix.co.th"
#   rule="if (rpki invalid) { reject; }"
# 2026-08: BKNIX membership has lapsed; their validators are still publicly
# reachable but the new site should run its own Routinator instead.
