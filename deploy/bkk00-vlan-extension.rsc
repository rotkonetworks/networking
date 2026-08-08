# bkk00 VLAN extension for Option B migration
# extends BKNIX and HGC VLANs to reach bkk06/07/08 via Q-in-Q
#
# CURRENT TOPOLOGY:
#   sfp28-4 (BKNIX native) -> BKNIX-LAG -> IP 203.159.68.168
#   BKK30-LAG -> bridge_vlan -> vlan400-bgp -> qnq-400-10x -> servers
#
# TARGET TOPOLOGY:
#   sfp28-4 -> bridge -> vlan translation -> qnq-400-200 -> BKK30-LAG -> servers
#   servers receive BKNIX traffic on vlan 200 inside vlan 400 (Q-in-Q)
#
# IMPORTANT: This script is for DOCUMENTATION and PLANNING only.
# DO NOT run these commands without explicit approval.
# These changes affect production connectivity.
#
# ============================================================================
# PHASE 1: PREPARATION (can be done during maintenance window)
# ============================================================================

# create Q-in-Q inner VLAN interfaces for peering LANs
# these ride inside vlan400-bgp which is already configured

# VLAN 200 = BKNIX peering LAN (203.159.68.0/23)
/interface vlan add interface=vlan400-bgp name=qnq-400-200 vlan-id=200 comment="BKNIX peering LAN Q-in-Q to servers"

# VLAN 201 = HGC-HK peering LAN (118.143.211.184/29)
/interface vlan add interface=vlan400-bgp name=qnq-400-201 vlan-id=201 comment="HGC-HK peering LAN Q-in-Q to servers"

# VLAN 202 = HGC-SG peering LAN (118.143.211.248/29)
/interface vlan add interface=vlan400-bgp name=qnq-400-202 vlan-id=202 comment="HGC-SG peering LAN Q-in-Q to servers"

# ============================================================================
# PHASE 2: BRIDGE CONFIGURATION
# ============================================================================

# the challenge: BKNIX traffic is NATIVE (untagged) on sfp28-4
# we need to translate native -> VLAN 200 for Q-in-Q encapsulation
#
# RouterOS approach: use bridge with VLAN translation
# 1. add sfp28-4 to bridge as untagged member of VLAN 200
# 2. qnq-400-200 is tagged member of VLAN 200
# 3. bridge translates: sfp28-4 untagged <-> qnq-400-200 tagged

# WARNING: adding sfp28-4 to bridge will briefly interrupt BKNIX!
# current BKNIX-LAG interface will stop working
# we need to move IP from BKNIX-LAG to qnq-400-200 on bkk00

# step 2a: create translation bridge
/interface bridge add name=bridge_bknix vlan-filtering=no comment="BKNIX VLAN translation bridge"

# step 2b: add interfaces to bridge
# sfp28-4 will receive untagged BKNIX traffic
/interface bridge port add bridge=bridge_bknix interface=sfp28-4 pvid=200

# qnq-400-200 will carry tagged VLAN 200 traffic to servers
/interface bridge port add bridge=bridge_bknix interface=qnq-400-200 frame-types=admit-only-vlan-tagged

# step 2c: configure VLAN table
/interface bridge vlan add bridge=bridge_bknix untagged=sfp28-4 tagged=qnq-400-200 vlan-ids=200

# step 2d: enable VLAN filtering (do this LAST)
/interface bridge set bridge_bknix vlan-filtering=yes

# ============================================================================
# PHASE 3: IP MIGRATION ON BKK00
# ============================================================================

# bkk00 needs to keep its BKNIX IP for the transition period
# option A: add IP to bridge_bknix (will work since bridge is also VLAN 200)
# option B: create vlan200 on bridge and add IP there

# option B is cleaner:
/interface vlan add interface=bridge_bknix name=bknix-local vlan-id=200 comment="bkk00 local BKNIX access"
/ip address add address=203.159.68.168/23 interface=bknix-local comment="BKNIX-V4 migrated"
/ipv6 address add address=2001:df5:b881::168 interface=bknix-local comment="BKNIX-V6 migrated"

# remove old IP from BKNIX-LAG (after adding to bknix-local)
/ip address remove [find where address="203.159.68.168/23" interface=BKNIX-LAG]
/ipv6 address remove [find where address~"2001:df5:b881::168" interface=BKNIX-LAG]

# remove sfp28-4 from BKNIX-LAG
/interface bonding set BKNIX-LAG slaves=""

# ============================================================================
# PHASE 4: SERVER CONFIGURATION
# ============================================================================

# on bkk06/07/08, create VLAN interface for BKNIX:
#
# Linux side (example for bkk06):
#   # eth0.400 already exists for BGP RR network (10.155.254.x)
#   # create VLAN 200 on top of VLAN 400 for BKNIX
#   ip link add link eth0.400 name eth0.400.200 type vlan id 200
#   ip link set eth0.400.200 up
#   ip addr add 203.159.68.169/23 dev eth0.400.200  # need IP from BKNIX
#   ip addr add 2001:df5:b881::169/64 dev eth0.400.200
#
# or using netplan/systemd-networkd:
#   [NetDev]
#   Name=eth0.400.200
#   Kind=vlan
#
#   [VLAN]
#   Id=200
#
#   [Match]
#   Name=eth0.400
#
# CRITICAL: we need 2 more IPs from BKNIX (requested in maintenance email)
# current: 203.159.68.168 (bkk00)
# requested: 203.159.68.169, 203.159.68.170 (for bkk06, bkk07)
# bkk08 will take over 203.159.68.168 eventually

# ============================================================================
# PHASE 5: HGC VLAN EXTENSION (similar process)
# ============================================================================

# HGC-HK is on VLAN 2519 from AMSIX-LAG
# we need to bridge VLAN 2519 to qnq-400-201

/interface bridge add name=bridge_hgc_hk vlan-filtering=no comment="HGC-HK VLAN translation bridge"
/interface bridge port add bridge=bridge_hgc_hk interface=HK-HGC-IPTx-vlan2519 pvid=201
/interface bridge port add bridge=bridge_hgc_hk interface=qnq-400-201 frame-types=admit-only-vlan-tagged
/interface bridge vlan add bridge=bridge_hgc_hk untagged=HK-HGC-IPTx-vlan2519 tagged=qnq-400-201 vlan-ids=201
/interface bridge set bridge_hgc_hk vlan-filtering=yes

# HGC-SG is on VLAN 2518 from AMSIX-LAG
/interface bridge add name=bridge_hgc_sg vlan-filtering=no comment="HGC-SG VLAN translation bridge"
/interface bridge port add bridge=bridge_hgc_sg interface=SG-HGC-IPTx-backup-vlan2518 pvid=202
/interface bridge port add bridge=bridge_hgc_sg interface=qnq-400-202 frame-types=admit-only-vlan-tagged
/interface bridge vlan add bridge=bridge_hgc_sg untagged=SG-HGC-IPTx-backup-vlan2518 tagged=qnq-400-202 vlan-ids=202
/interface bridge set bridge_hgc_sg vlan-filtering=yes

# ============================================================================
# ROLLBACK PLAN
# ============================================================================

# if something goes wrong:
#
# 1. disable the translation bridges
#    /interface bridge set bridge_bknix vlan-filtering=no
#    /interface bridge set bridge_hgc_hk vlan-filtering=no
#    /interface bridge set bridge_hgc_sg vlan-filtering=no
#
# 2. remove bridge ports
#    /interface bridge port remove [find bridge=bridge_bknix]
#    /interface bridge port remove [find bridge=bridge_hgc_hk]
#    /interface bridge port remove [find bridge=bridge_hgc_sg]
#
# 3. restore sfp28-4 to BKNIX-LAG
#    /interface bonding set BKNIX-LAG slaves=sfp28-4
#
# 4. restore IPs to BKNIX-LAG
#    /ip address add address=203.159.68.168/23 interface=BKNIX-LAG
#    /ipv6 address add address=2001:df5:b881::168 interface=BKNIX-LAG

# ============================================================================
# CHECKLIST BEFORE EXECUTION
# ============================================================================
#
# [ ] BKNIX freeze ended (after Jan 5)
# [ ] Additional IPs received from BKNIX
# [ ] Maintenance window scheduled with BKNIX
# [ ] BCP 214 maintenance mode enabled
# [ ] All team members notified
# [ ] Console access available (in case SSH dies)
# [ ] Rollback plan tested
# [ ] Server VLAN interfaces pre-configured (but not brought up)
