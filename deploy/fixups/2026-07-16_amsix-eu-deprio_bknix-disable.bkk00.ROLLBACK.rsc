# ROLLBACK for bkk00 — restores pre-2026-07-16 state.
# ssh pjbkk00, paste.

# 1. re-enable BKNIX-fabric sessions (they will stay down until the port is
#    restored; re-enabling is only to return config to prior state)
/routing bgp connection set [find name="BKNIX-RS0-v4"] disabled=no
/routing bgp connection set [find name="BKNIX-RS1-v4"] disabled=no
/routing bgp connection set [find name="BKNIX-RS0-v6"] disabled=no
/routing bgp connection set [find name="BKNIX-RS1-v6"] disabled=no
/routing bgp connection set [find name="HE-BKNIX-v4"] disabled=no
/routing bgp connection set [find name="HE-BKNIX-v6"] disabled=no
/routing bgp connection set [find name="RouteViews-BKNIX-v4"] disabled=no
/routing bgp connection set [find name="RouteViews-BKNIX-v6"] disabled=no

# 2. restore AMS-IX Amsterdam local-pref (130 -> 200 / 170)
/routing filter rule set [find where chain="HE-AMSIX-IN-v4" and comment="HE free transit priority"] \
  rule="set bgp-local-pref 200; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="HE-AMSIX-IN-v6" and comment="HE free transit priority"] \
  rule="set bgp-local-pref 200; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"set bgp-local-pref 130"] \
  rule="set bgp-local-pref 170; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"set bgp-local-pref 130"] \
  rule="set bgp-local-pref 170; set bgp-large-communities amsix-communities; accept"

# 3. restore reflected iBGP mapping (130 -> 200)
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 200; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 200; }"
