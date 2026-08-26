# bkk60 (CRS354) — L2 demarcation for the Telehouse XC.
#
# Role: the HGC cross-connect from the MMR lands HERE, not on the router.
# bkk60 hands the provider VLANs up to bkk10 over the LAG. One XC on a switch
# means it can later fan out to a second router, and router swaps don't disturb
# the cross-connect (design doc section 1).
#
# HARD PREREQUISITE — do this before anything else:
#   bkk60 must be manageable. As of the design doc it rejected the ansible SSH
#   key and its console (bkk06/ttyUSB0) was held by another session. The cause
#   was found to be an /ip/service address allowlist, NOT a bad key — check
#   `/ip/service/print detail` and confirm your source IP is permitted, before
#   this box becomes the demarc for paid transit.

# --------------------------------------------------------------- 1. identity
/system/identity/set name=bkk60

# ------------------------------------------------- 2. verify before changing
# Confirm which physical port the XC actually landed on. Do NOT assume.
#   /interface/print where running=yes
#   /interface/ethernet/monitor [find name=<xc-port>] once
# Expect: 10G, single-mode, LC/UPC (10GBASE-LR class). If the crate shipped
# DACs or SR multimode optics the link will not come up — verify the optic
# BEFORE leaving Bangkok.

# ------------------------------------------------------------ 3. VLAN trunk
# Provider VLANs must be trunked THROUGH bkk60 to bkk10: XC port tagged with
# the provider VLANs, handoff port tagged with the same set.
#
#   <<<XC_PORT>>>        physical port the HGC cross-connect landed on
#   <<<BKK10_LAG>>>      the bond/port facing bkk10 (LACP must match bkk10's BKK60-LAG)
#   <<<HGC_VLAN>>>       same value as in 01-bkk10-edge.rsc — from HGC
#
# /interface/bridge/vlan/add bridge=<bridge> tagged=<<<XC_PORT>>>,<<<BKK10_LAG>>> vlan-ids=<<<HGC_VLAN>>>
#
# Port budget note: 4x SFP+ total on bkk60, minus 1 for the HGC XC, minus 1-2
# for the bkk10 handoff, leaves 1-2 spare. A second XC (e.g. AMS-IX Bangkok
# delivered separately rather than as a VLAN on the HGC XC) consumes another.

# ------------------------------------------------------- 4. LACP must match
# bkk10's BKK60-LAG is 802.3ad, lacp-rate=1sec, transmit-hash-policy
# layer-2-and-3. The bkk60 side must match or the bond stays down — this is
# exactly what stranded bkk10 on 2026-08-21.
