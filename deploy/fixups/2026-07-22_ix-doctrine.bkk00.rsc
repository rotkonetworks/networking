# bkk00 (RR 10.155.255.4 / edge 160.22.181.180) — 2026-07-22
#
# IX doctrine (Tommi, 2026-07-22 night): AMS-IX Bangkok highest of all;
# HGC transit keeps the existing 50/50 half-space TE (HK 155/140 split,
# SG 150); AMS-IX HK + EU at transit tier (150); Hurricane ONLY at Bangkok,
# HE elsewhere BELOW transit (120) so HE-BKK's fallback is the 2x400M
# transit, never a thin pseudowire. BKNIX port terminated + unpaid: disable.
#
# NOTE: the 2026-07-16 fixup was written but NEVER APPLIED (verified live
# 2026-07-22: HE-AMSIX-IN still 200, AMSIX-IN still 170, IBGP amsix 200).
# This file supersedes it AND includes the session bounce the old file
# lacked — RouterOS applies input filters only when routes are (re)received.
#
# APPLY WHILE WATCHING. Rollback at bottom.

# --- 1. Hurricane Amsterdam below transit (200 -> 120) -------------------------
/routing filter rule set [find where chain="HE-AMSIX-IN-v4" and rule~"bgp-local-pref 200"] \
  rule="set bgp-local-pref 120; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="HE-AMSIX-IN-v6" and rule~"bgp-local-pref 200"] \
  rule="set bgp-local-pref 120; set bgp-large-communities amsix-communities; accept"

# --- 2. AMS-IX Amsterdam RS + direct peers to transit tier (170 -> 150) --------
/routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"bgp-local-pref 170"] \
  rule="set bgp-local-pref 150; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"bgp-local-pref 170"] \
  rule="set bgp-local-pref 150; set bgp-large-communities amsix-communities; accept"

# --- 3. reflected iBGP views ---------------------------------------------------
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-hk-communities"] \
  rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-hk-communities"] \
  rule="if (bgp-large-communities includes-list amsix-hk-communities) { set bgp-local-pref 150; }"

# --- 4. BKNIX: port terminated 2026-07-14, contract ended — keep disabled ------
/routing bgp connection set [find where name~"BKNIX"] disabled=yes

# --- 5. BOUNCE the EU-fabric sessions so routes re-enter through the new
#        filters (THE STEP THE 07-16 FILE MISSED) ------------------------------
/routing bgp connection set [find where name~"^AMSIX-RS|^Cloudflare-AMSIX|^HE-AMSIX"] disabled=yes
:delay 10s
/routing bgp connection set [find where name~"^AMSIX-RS|^Cloudflare-AMSIX|^HE-AMSIX"] disabled=no

# --- verify --------------------------------------------------------------------
# /routing filter rule print where chain~"HE-AMSIX-IN"   ;# 120
# /routing filter rule print where chain~"^AMSIX-IN"     ;# 150
# /routing route print detail where dst-address=2606:4700:4700::/48
#   ;# active = iBGP HE-BKK (pref 200); vAMSIX-EU candidates at 150; HE-AMS 120
# traceroute from bkk12: v6 to 2606:4700:4700::1111 via he.net regional ~25ms

# --- ROLLBACK ------------------------------------------------------------------
# /routing filter rule set [find where chain="HE-AMSIX-IN-v4" and rule~"bgp-local-pref 120"] \
#   rule="set bgp-local-pref 200; set bgp-large-communities amsix-communities; accept"
# /routing filter rule set [find where chain="HE-AMSIX-IN-v6" and rule~"bgp-local-pref 120"] \
#   rule="set bgp-local-pref 200; set bgp-large-communities amsix-communities; accept"
# /routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"bgp-local-pref 150"] \
#   rule="set bgp-local-pref 170; set bgp-large-communities amsix-communities; accept"
# /routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"bgp-local-pref 150"] \
#   rule="set bgp-local-pref 170; set bgp-large-communities amsix-communities; accept"
# (IBGP rules back to 200/180 similarly; re-bounce sessions after any rollback.)
