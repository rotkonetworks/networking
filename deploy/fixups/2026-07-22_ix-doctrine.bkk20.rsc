# bkk20 (RR 10.155.255.2 / edge 160.22.181.178) — 2026-07-22
#
# Companion to 2026-07-22_ix-doctrine.bkk00.rsc — apply BOTH, bkk00 first.
# AMS-IX HK to transit tier (180 -> 150); reflected iBGP views of HK + EU
# to 150; AMS-IX Bangkok (AMSIX-BAN-IN, 200) and transit TE bands untouched.
#
# DEFERRED to the per-IX refactor (task #8): AMSIX-HE-HK shares chain
# AMSIX-HK-IN, so Hurricane-HK lands at 150 with the rest of the HK fabric
# for now instead of 120. Only matters when HE-BKK is down; splitting HE-HK
# into its own 120 chain is the follow-up.
#
# APPLY WHILE WATCHING. Rollback at bottom.

# --- 1. AMS-IX HK fabric to transit tier (180 -> 150) --------------------------
/routing filter rule set [find where chain="AMSIX-HK-IN-v4" and rule~"bgp-local-pref 180"] \
  rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"
/routing filter rule set [find where chain="AMSIX-HK-IN-v6" and rule~"bgp-local-pref 180"] \
  rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 150; accept"

# --- 2. reflected iBGP views (HK 180 -> 150, EU 200 -> 150) --------------------
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-hk-communities"] \
  rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-hk-communities"] \
  rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"

# --- 3. BOUNCE the HK-fabric sessions so the new prefs take effect -------------
/routing bgp connection set [find where name~"AMSIX-RS1-HK|AMSIX-RS2-HK|AMSIX-CLOUDFLARE-HK|AMSIX-HE-HK"] disabled=yes
:delay 10s
/routing bgp connection set [find where name~"AMSIX-RS1-HK|AMSIX-RS2-HK|AMSIX-CLOUDFLARE-HK|AMSIX-HE-HK"] disabled=no

# --- verify --------------------------------------------------------------------
# /routing filter rule print where chain~"AMSIX-HK-IN"   ;# 150
# /routing filter rule print where chain~"IBGP-IN" and rule~"amsix"  ;# ban 200, hk 150, eu 150
# /routing bgp session print where name~"HE-TH"          ;# BKK HE up, untouched

# --- ROLLBACK ------------------------------------------------------------------
# /routing filter rule set [find where chain="AMSIX-HK-IN-v4" and rule~"bgp-local-pref 150"] \
#   rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 180; accept"
# /routing filter rule set [find where chain="AMSIX-HK-IN-v6" and rule~"bgp-local-pref 150"] \
#   rule="set bgp-large-communities amsix-hk-communities; set bgp-local-pref 180; accept"
# (IBGP rules back to 180/200 similarly; re-bounce sessions after rollback.)
