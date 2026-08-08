# bkk00 (RR 10.155.255.4 / edge 160.22.181.180) — 2026-07-16
#
# WHY: BKNIX port terminated 2026-07-14 (STT SOF 6005100409). That killed
# HE-BKNIX (AS6939) v4+v6 and all BKNIX peering. Meanwhile the AMS-IX
# Amsterdam sessions ride an EoMPLS pseudowire (vAMSIX-EU, vlan 3995) that is
# far narrower than the 800M HGC transit, yet HE-AMSIX sits at local-pref 200
# and the AMS-IX Amsterdam RS at 170 — both ABOVE HGC transit (140-155). So
# the entire HE cone + AMS-IX peers pull bulk traffic onto the narrow EU
# pseudowire while 800M of HGC transit sits idle -> saturation, near-zero
# speeds. IPv6 that was pinned to the dead HE-BKNIX path went dark.
#
# FIX (this file):
#   1. Disable the dead BKNIX / RouteViews / HE-BKNIX sessions (no-op: down
#      since 2026-07-14; disable, do NOT delete).
#   2. Drop AMS-IX Amsterdam (HE + RS) local-pref 200/170 -> 130, i.e. BELOW
#      HGC transit (140). Bulk now prefers the 800M transit and local peering;
#      the EU pseudowire becomes last-resort.
#   3. Fix the reflected iBGP mapping (amsix-communities 200 -> 130) so bkk20
#      agrees and stops hairpinning EU traffic back to this pseudowire.
#
# Hurricane Electric at AMS-IX Bangkok (bkk20, AMSIX-BAN-IN, local-pref 200)
# is untouched and BECOMES the preferred HE path — local, low latency. That is
# the "priority with Bangkok" intent. HGC transit carries anything HE-BKK
# lacks, so nothing can black-hole (worst case falls to transit).
#
# APPLY WHILE WATCHING: ssh pjbkk00, paste, then verify with the checks at the
# bottom. Rollback: 2026-07-16_amsix-eu-deprio_bknix-disable.bkk00.ROLLBACK.rsc

# --- 1. disable dead BKNIX-fabric sessions ------------------------------------
/routing bgp connection set [find name="BKNIX-RS0-v4"] disabled=yes
/routing bgp connection set [find name="BKNIX-RS1-v4"] disabled=yes
/routing bgp connection set [find name="BKNIX-RS0-v6"] disabled=yes
/routing bgp connection set [find name="BKNIX-RS1-v6"] disabled=yes
/routing bgp connection set [find name="HE-BKNIX-v4"] disabled=yes
/routing bgp connection set [find name="HE-BKNIX-v6"] disabled=yes
/routing bgp connection set [find name="RouteViews-BKNIX-v4"] disabled=yes
/routing bgp connection set [find name="RouteViews-BKNIX-v6"] disabled=yes

# --- 2. AMS-IX Amsterdam below HGC transit (200/170 -> 130) --------------------
/routing filter rule set [find where chain="HE-AMSIX-IN-v4" and comment="HE free transit priority"] \
  rule="set bgp-local-pref 130; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="HE-AMSIX-IN-v6" and comment="HE free transit priority"] \
  rule="set bgp-local-pref 130; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"set bgp-local-pref 170"] \
  rule="set bgp-local-pref 130; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"set bgp-local-pref 170"] \
  rule="set bgp-local-pref 130; set bgp-large-communities amsix-communities; accept"

# --- 3. reflected iBGP view of Amsterdam routes (200 -> 130) -------------------
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 130; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 130; }"

# --- verify -------------------------------------------------------------------
# /routing bgp connection print where name~"BKNIX"          ;# all disabled=yes
# /routing filter rule print where chain~"AMSIX-IN|HE-AMSIX";# local-pref 130
# /ip route print count-only where gateway-status~"HGC"     ;# transit now bulk
# /routing bgp session print where remote.as=6939           ;# HE-BKK up, others as expected
