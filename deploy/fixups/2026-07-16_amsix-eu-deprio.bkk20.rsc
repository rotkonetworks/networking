# bkk20 (RR 10.155.255.2 / edge 160.22.181.178) — 2026-07-16
#
# WHY: bkk20 learns AMS-IX Amsterdam routes reflected from bkk00 tagged
# amsix-communities and currently bumps them to local-pref 200. If left at 200
# while bkk00 drops Amsterdam to 130, bkk20 would keep preferring Amsterdam and
# hairpin its EU traffic across the internal link back onto the narrow EU
# pseudowire — defeating the fix. Set the reflected Amsterdam view to 130 to
# match bkk00.
#
# NOT TOUCHED here (correct as-is):
#   AMSIX-BAN-IN (HE-TH + AMS-IX Bangkok RS) local-pref 200  -> local HE, keep
#   AMSIX-HK-IN  (HE-HK + RS + Cloudflare)   local-pref 180  -> regional, keep
#   HGC-SG-PRIMARY transit                    local-pref 150  -> 800M pipe, keep
#
# APPLY WHILE WATCHING: ssh pjbkk20, paste. Rollback below.

/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 130; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 130; }"

# --- verify -------------------------------------------------------------------
# /routing filter rule print where chain~"IBGP-IN" and rule~"amsix-communities" ;# 130
# /routing bgp session print where remote.as=6939   ;# AMSIX-HE-TH up (local HE)
# /ip route print count-only where gateway-status~"HGC-SG" ;# transit now bulk

# --- ROLLBACK (130 -> 200) ----------------------------------------------------
# /routing filter rule set [find where chain="IBGP-IN-v4" and rule~"amsix-communities"] \
#   rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 200; }"
# /routing filter rule set [find where chain="IBGP-IN-v6" and rule~"amsix-communities"] \
#   rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 200; }"
