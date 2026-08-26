# bkk10 (CCR2116) — Telehouse edge. Paste at the SERIAL CONSOLE.
#
# Run 00-recover-mgmt.rsc FIRST if the box has been reset.
#
# PLACEHOLDERS marked <<<...>>> are provider-delivered and CANNOT be guessed.
# Do not paste sections 6/7 until HGC confirms them — see 90-PREFLIGHT.md.
#
# Sourced from docs/bkk10-newsite-edge-design.md and mirrored off the live
# bkk20 config (backup/mikrotik/bkk20.rsc) so policy matches the other edge.

# ---------------------------------------------------------------- 1. identity
/system/identity/set name=bkk10
/system/note/set show-at-login=no note="bkk10 Telehouse Rama9 DH122 K-03L - edge/BGP - AS142108"

# ------------------------------------------------------------ 2. loopback/ids
# Public edge loopback follows the /29 offset convention: old site
# 160.22.181.176/29 .179=bkk10 -> new site 160.22.180.176/29 .179=bkk10.
/interface/bridge/add name=lo0 protocol-mode=none comment="loopback"
/ip/address/add address=160.22.180.179/32 interface=lo0 comment="bkk10 public loopback"
/ip/address/add address=10.155.255.10/32 interface=lo0 comment="router-id / iBGP source"

# --------------------------------------------------------- 3. edge bridge (L2)
# One pattern throughout: bridge + vlan-filtering, provider VLANs tagged on the
# bkk60 handoff, L3 on VLAN interfaces over the bridge. Deliberately NOT
# per-port VLAN sub-interfaces (see design doc section 2).
/interface/bridge/add name=BR-EDGE vlan-filtering=no protocol-mode=none comment="edge bridge - enable vlan-filtering LAST"

# BKK60-LAG already exists from 00-recover-mgmt.rsc (sfp-sfpplus2 + sfp-sfpplus4).
/interface/bridge/port/add bridge=BR-EDGE interface=BKK60-LAG comment="handoff to bkk60 - provider VLANs tagged"

# ------------------------------------------------------- 4. address lists/RPKI
/ip/firewall/address-list/add address=160.22.180.0/23 list=ipv4-apnic-rotko
/ipv6/firewall/address-list/add address=2401:a860::/32 list=ipv6-apnic-rotko
/routing/filter/num-list/add list=ipv4-apnic-rotko range=142108
/routing/filter/num-list/add list=ipv6-apnic-rotko range=142108

# ------------------------------------------------------------ 5. filter chains
# Mirrors bkk20. v4 max /24, v6 max /40 (RPKI maxLength - a /48 from our /32
# would be RPKI-invalid, /40 is the minimum that validates at APNIC).
/routing/filter/rule/add chain=HGC-TH-IN-v4 comment="Reject our own prefixes" rule="if (dst in 160.22.180.0/23) { reject; }"
/routing/filter/rule/add chain=HGC-TH-IN-v4 comment="Discard overly specific IPv4 /25-/32" rule="if (dst-len > 24) { reject; }"
/routing/filter/rule/add chain=HGC-TH-IN-v4 comment="Discard IPv4 bogons" rule="if (dst in ipv4-bogons) { reject; }"
/routing/filter/rule/add chain=HGC-TH-IN-v4 rule="accept"
/routing/filter/rule/add chain=HGC-TH-IN-v6 comment="Reject our own prefixes" rule="if (dst in 2401:a860::/32) { reject; }"
/routing/filter/rule/add chain=HGC-TH-IN-v6 rule="if (dst-len > 48) { reject; }"
/routing/filter/rule/add chain=HGC-TH-IN-v6 rule="accept"

/routing/filter/rule/add chain=HGC-TH-OUT-v4 rule="if (dst-len > 24) { reject; }"
/routing/filter/rule/add chain=HGC-TH-OUT-v4 rule="if (not bgp-network) { reject; }"
/routing/filter/rule/add chain=HGC-TH-OUT-v4 rule="set bgp-med 100; set bgp-large-communities location; accept"
/routing/filter/rule/add chain=HGC-TH-OUT-v6 rule="if (dst-len > 40) { reject; }"
/routing/filter/rule/add chain=HGC-TH-OUT-v6 rule="if (dst in ipv6-apnic-rotko) { accept; }"
/routing/filter/rule/add chain=HGC-TH-OUT-v6 rule="if (not bgp-network) { reject; }"
/routing/filter/rule/add chain=HGC-TH-OUT-v6 rule="set bgp-med 100; set bgp-large-communities location; accept"

# ------------------------------------------------------------- 6. BGP instance
/routing/bgp/instance/set default as=142108 router-id=10.155.255.10 disabled=no

/routing/bgp/template/add name=HGC-TH-v4 afi=ip disabled=no input.filter=HGC-TH-IN-v4 output.as-override=no .filter-chain=HGC-TH-OUT-v4 .keep-sent-attributes=yes .network=ipv4-apnic-rotko .remove-private-as=yes routing-table=main
/routing/bgp/template/add name=HGC-TH-v6 afi=ipv6 disabled=no input.filter=HGC-TH-IN-v6 output.as-override=no .filter-chain=HGC-TH-OUT-v6 .keep-sent-attributes=yes .network=ipv6-apnic-rotko .remove-private-as=yes routing-table=main

# ============================ PROVIDER VALUES — DO NOT GUESS ================
# HGC has NOT confirmed these. design doc section 6 blocking unknown #1.
# NOTE 2026-08-26: HGC says "VLAN assignment for each circuit will keep the
# same", which CONTRADICTS the design doc's "NEW circuit, nothing carries
# over". Resolve before pasting this block.
#
#   <<<HGC_VLAN>>>           VLAN id on the XC          (bkk00 uses 2519 HK / 2518 SG - do NOT assume)
#   <<<HGC_LOCAL_V4>>>       our p2p v4 address/mask
#   <<<HGC_PEER_V4>>>        their p2p v4 address
#   <<<HGC_LOCAL_V6>>>       our p2p v6 address/mask
#   <<<HGC_PEER_V6>>>        their p2p v6 address
#   <<<HGC_ASN>>>            9304 (HK) or 142435 (SG)
#
# /interface/vlan/add name=VL-HGC-TH interface=BR-EDGE vlan-id=<<<HGC_VLAN>>> comment="HGC transit PP9094730"
# /interface/bridge/vlan/add bridge=BR-EDGE tagged=BR-EDGE,BKK60-LAG vlan-ids=<<<HGC_VLAN>>>
# /ip/address/add address=<<<HGC_LOCAL_V4>>> interface=VL-HGC-TH comment="HGC p2p v4"
# /ipv6/address/add address=<<<HGC_LOCAL_V6>>> interface=VL-HGC-TH advertise=no comment="HGC p2p v6"
# /routing/bgp/connection/add name=HGC-TH-PRIMARY-v4 afi=ip disabled=no instance=default local.role=ebgp multihop=no remote.address=<<<HGC_PEER_V4>>> .as=<<<HGC_ASN>>> input.limit-process-routes-ipv4=3000000 routing-table=main templates=HGC-TH-v4
# /routing/bgp/connection/add name=HGC-TH-PRIMARY-v6 afi=ipv6 disabled=no instance=default local.role=ebgp multihop=no remote.address=<<<HGC_PEER_V6>>> .as=<<<HGC_ASN>>> input.limit-process-routes-ipv6=3000000 output.redistribute=connected,static,bgp routing-table=main templates=HGC-TH-v6
# ===========================================================================

# ------------------------------------------------- 7. SHAPE the sub-rate port
# 10G physical, 400M committed / 500M burstable to 800M. A 10G interface bursts
# at line rate into HGC's policer and TCP collapses (retransmits, throughput far
# under contract). Queue on OUR egress just under contract so packets queue
# rather than get policed away. Design doc section 1, consequence 1.
# Enable only once VL-HGC-TH exists.
# /queue/simple/add name=HGC-TH-SHAPE target=VL-HGC-TH max-limit=480M/480M comment="shape under 500M contract - do not let HGC police"

# ------------------------------------------------------- 8. enable L2 last
# Do this from the CONSOLE. Enabling vlan-filtering re-evaluates every frame on
# BKK60-LAG; if the mgmt path rides that bond untagged it can cut you off.
# On 2026-08-21 BKK60-LAG failed to come up after a reset and the console was
# the only way back in.
# /interface/bridge/set BR-EDGE vlan-filtering=yes
