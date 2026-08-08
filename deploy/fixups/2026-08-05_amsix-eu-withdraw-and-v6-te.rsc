# bkk00 (RR 10.155.255.4 / edge 160.22.181.180) + bkk20 (RR 10.155.255.2) — 2026-08-05
# WITHDRAW AMS-IX AMSTERDAM, FIX IPv6 TE ORDERING BUG, REPOINT bkk20 DEFAULT.
#
# ##############################################################################
# # !! DO NOT SEND BCP 214 / RFC 8326 GRACEFUL_SHUTDOWN (65535:0) TO AS6939 !!  #
# #                                                                            #
# # Hurricane Electric responds to the graceful-shutdown community by tearing   #
# # down the peering entirely, not by draining it. It is NOT recoverable by     #
# # simply removing the community.                                              #
# #                                                                            #
# # This is a live hazard because the OUT chains are SHARED:                    #
# #   AMSIX-HK-OUT-v4/v6  covers AMSIX-HE-HK  *and* the HK route servers        #
# #   AMSIX-OUT-v4/v6     covers HE-AMSIX     *and* the AMS RS + Cloudflare     #
# # So ANY fabric-wide OUT change also hits Hurricane. There is currently no    #
# # way to signal the route servers without also signalling HE.                 #
# #                                                                            #
# # Until task #8 (split HE into its own IN/OUT chains) is done: to remove a    #
# # path, DISABLE THE RS/CLOUDFLARE SESSIONS ONLY (see section 4) and leave the #
# # HE sessions untouched. Never add `set bgp-communities 65535:0` to a shared  #
# # chain.                                                                     #
# ##############################################################################
#
# WHY: vAMSIX-EU (AMS-IX Amsterdam) is VLAN 3995 on HGC-10G-HK-BKK00-LAG — a
# carrier EoMPLS pseudowire, Bangkok<->Amsterdam, measured 222-225ms RTT from
# bkk00 to the AMS-IX peering LAN. It is invisible to traceroute (no GRE/WG),
# which is why this hid for so long.
#
# Two independent defects, both fixed here:
#
#  1. EGRESS. 2026-07-22_ix-doctrine put AMS-IX EU at local-pref 150 — the SAME
#     tier as HGC-SG transit. Equal local-pref hands the decision to AS-path
#     length, and an IX peering path is ALWAYS shorter than a transit path, so
#     the 224ms pseudowire won every tie. 181,161 active v4 routes (~18% of the
#     IPv4 internet) were egressing via Amsterdam. NOTE: the superseded
#     2026-07-16 file had this right at 130 (below transit); the 07-22 rewrite
#     regressed it to 150. This file restores the original intent at 120.
#
#  2. INGRESS. The /23 was announced with `142108` x10 to BOTH HGC-SG (28ms)
#     and Amsterdam (225ms) — identically. AMS-IX members saw equal AS-path and
#     applied the universal "peering beats transit" rule, handing us traffic in
#     Amsterdam. vAMSIX-EU was ingesting 48-60 Mbps (54-60% of a 100M port,
#     climbing) vs 11.7 Mbps on the actual 10G transit.
#
#     !! PREPENDING DOES NOT FIX INGRESS HERE. Verified 2026-08-05: raising the
#     Amsterdam prepend to 15 changed nothing, because peers set local-pref by
#     relationship (customer > peer > transit) and local-pref is evaluated
#     BEFORE AS-path. Prepending only breaks ties WITHIN a tier. Only
#     withdrawing the announcement moved traffic. Confirmed with
#     `/tool/torch interface=vAMSIX-EU src-address=<test-ip>/32` — packets
#     visibly moved vAMSIX-EU -> vAMSIX-HK -> vHGC-SG-PRIMARY as each was
#     disabled, and external RTT fell 258 -> 96 -> 80ms.
#
#  3. IPv6 TE WAS ENTIRELY INOPERATIVE. Every *-OUT-v6 chain on both routers had
#     `if (dst in ipv6-apnic-rotko) { accept; }` ordered BEFORE the MED/prepend
#     rule, so our own /32 hit the early accept and exited the chain. Verified
#     live: every v6 advertisement of 2401:a860::/32 to all 12 eBGP peers was
#     bare `as-path=sequence 142108` — no MED, no prepend, no `location`
#     community. AMS-IX Amsterdam (224ms) was advertised exactly as attractively
#     as AMS-IX Bangkok (1.7ms). The v4 chains have no such early-accept, which
#     is why v4 TE worked and v6 did not. Fixed by folding the TE INTO the
#     early-accept rule (no reordering, no deletions).
#
# RESULTS (measured):
#   bkk20 -> 1.1.1.1            224ms -> 26ms
#   bkk20 -> AWN Bangkok        259ms -> 50ms
#   external Bangkok -> VIP     258ms -> 80-96ms
#   vAMSIX-EU rx/tx           48.6/53 Mbps -> ~0
#
# !! NOT FIXED / STILL OPEN — the RPC bounty probe (AWS ap-southeast-1,
#    3.1.233.179) did NOT improve. It was steady at 110-180ms rpc_connect until
#    03:08 UTC, stepped to ~300ms at 03:23 when Amsterdam+HK were withdrawn, and
#    did NOT recover when AMS-IX HK was restored at 05:12. Working the physics
#    back, its baseline ~35ms RTT means it was NEVER on the Amsterdam path. Root
#    cause unknown. Do not assume this file fixed the bounty numbers — it did
#    not. The likely real fix is peering with AS16509 at AMS-IX Bangkok, where
#    they are 0.74ms away (103.100.140.201 / .204) and we currently reach them
#    only via HGC transit at 51ms.
#
# APPLY WHILE WATCHING. Rollback at bottom.

# --- 1. bkk00: AMS-IX Amsterdam INBOUND below transit (150 -> 120) -------------
/routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"bgp-local-pref 150"] \
  rule="set bgp-local-pref 120; set bgp-large-communities amsix-communities; accept"
/routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"bgp-local-pref 150"] \
  rule="set bgp-local-pref 120; set bgp-large-communities amsix-communities; accept"

# --- 2. bkk20: reflected iBGP view of Amsterdam routes (150 -> 120) -----------
# The `includes-list amsix-communities` substring is ESSENTIAL — bare
# `amsix-communities` also matches amsix-ban-communities (HE Bangkok, lp 200)
# and amsix-hk-communities (lp 150).
/routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 120; }"
/routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-communities"] \
  rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 120; }"

# --- 3. IPv6 TE: fold TE into the early-accept (fixes the ordering bug) --------
# RouterOS `bgp-path-prepend N` = N total copies of the ASN, so 1 = clean.
# bkk20 — gradient: AMS-IX BKK (1.7ms) most attractive, HGC-SG next, HK, HGC-HK.
/routing filter rule set [find where chain="AMSIX-BAN-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 20; set bgp-path-prepend 1; set bgp-large-communities location; accept; }"
/routing filter rule set [find where chain="AMSIX-HK-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 75; set bgp-path-prepend 2; set bgp-large-communities location; accept; }"
/routing filter rule set [find where chain="HGC-SG-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 100; set bgp-path-prepend 3; set bgp-large-communities location; accept; }"
/routing filter rule set [find where chain="HGC-HK-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 100; set bgp-path-prepend 4; set bgp-large-communities location; accept; }"
# bkk00 — Amsterdam buried.
/routing filter rule set [find where chain="AMSIX-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 150; set bgp-path-prepend 8; set bgp-large-communities location; accept; }"
/routing filter rule set [find where chain="HGC-SG-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 100; set bgp-path-prepend 4; set bgp-large-communities location; accept; }"
/routing filter rule set [find where chain="HGC-HK-OUT-v6" and rule~"ipv6-apnic-rotko"] \
  rule="if (dst in ipv6-apnic-rotko) { set bgp-med 100; set bgp-path-prepend 10; set bgp-large-communities location; accept; }"
# MED matters specifically because HE sees us at TH, HK and AMS — lower wins.
# Verify: /routing/bgp/advertisements/print detail where dst=2401:a860::/32
#   expect AMSIX-HE-TH = 1 copy, HE-HK = 2, HGC-SG = 3, HE-AMSIX = 8

# --- 4. bkk00: WITHDRAW AMS-IX Amsterdam (RS + Cloudflare ONLY) ----------------
# HE-AMSIX is deliberately NOT disabled here — see the BCP 214 warning at top.
# Disabling the RS/Cloudflare sessions is what actually drains the pseudowire.
/routing bgp connection set [find where name~"^AMSIX-RS|^Cloudflare-AMSIX"] disabled=yes

# --- 5. bkk20: IPv4 ingress — un-bury the sole transit, sink Amsterdam ---------
# HGC-SG is the ONLY working IPv4 transit; prepending it 10x was vestigial (it
# was half a crossed HK/SG design, and HGC-HK has been disabled since 08-02).
/routing filter rule set [find where chain="HGC-SG-OUT-v4" and rule~"bgp-path-prepend 10"] \
  rule="set bgp-med 100; set bgp-path-prepend 1; set bgp-large-communities location; accept"
# bkk00 — Amsterdam least attractive.
/routing filter rule set [find where chain="AMSIX-OUT-v4" and rule~"bgp-path-prepend"] \
  rule="set bgp-med 150; set bgp-path-prepend 15; set bgp-large-communities location; accept"

# --- 6. bkk20: repoint the default route OFF bkk00 ----------------------------
# REQUIRED before bkk00 can be rebooted or decommissioned. bkk20's default was
# `0.0.0.0/0 gateway=172.16.30.1%BKK00-LAG` (static 220 + OSPF-learned 110).
# Distance 10 wins over both without deleting anything.
/ip route add dst-address=0.0.0.0/0 gateway=118.143.234.73 distance=10 \
  comment="default via HGC-SG (repointed off bkk00)"

# --- VERIFY -------------------------------------------------------------------
# /routing/route/print detail where dst-address=1.1.1.0/24 and afi=ip
#     ;# active gateway must be 118.143.234.73, NOT 10.155.255.4
# /ping 119.31.2.73 src-address=160.22.181.178 count=5      ;# ~50ms, not 260ms
# /ping 1.1.1.1 src-address=160.22.181.178 count=5          ;# ~26ms, not 224ms
# /interface/monitor-traffic vAMSIX-EU once                 ;# on bkk00, ~0
# /routing/bgp/advertisements/print detail where dst=160.22.180.0/23
# /routing/bgp/advertisements/print detail where dst=2401:a860::/32
# NOTE: RouterOS does NOT re-apply an input filter to already-received routes.
# After changing an IN chain, force re-learn:
#   /routing/bgp/session/refresh [find where name="<session>"] afi=ip
# (afi= is mandatory.) Output filters DO re-advertise automatically.

# --- ROLLBACK -----------------------------------------------------------------
# /routing filter rule set [find where chain="AMSIX-IN-v4" and rule~"bgp-local-pref 120"] \
#   rule="set bgp-local-pref 150; set bgp-large-communities amsix-communities; accept"
# /routing filter rule set [find where chain="AMSIX-IN-v6" and rule~"bgp-local-pref 120"] \
#   rule="set bgp-local-pref 150; set bgp-large-communities amsix-communities; accept"
# /routing filter rule set [find where chain="IBGP-IN-v4" and rule~"includes-list amsix-communities"] \
#   rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"
# /routing filter rule set [find where chain="IBGP-IN-v6" and rule~"includes-list amsix-communities"] \
#   rule="if (bgp-large-communities includes-list amsix-communities) { set bgp-local-pref 150; }"
# /routing bgp connection set [find where name~"^AMSIX-RS|^Cloudflare-AMSIX"] disabled=no
# /routing filter rule set [find where chain="HGC-SG-OUT-v4" and rule~"bgp-path-prepend 1;"] \
#   rule="set bgp-med 100; set bgp-path-prepend 10; set bgp-large-communities location; accept"
# /ip route remove [find where comment="default via HGC-SG (repointed off bkk00)"]
# Config backups taken 2026-08-05 on both routers:
#   /etc/haproxy-style: bkk00-filters-before.rsc / bkk20-filters-before.rsc (via /routing/filter/rule/export)
#
# --- SIDE EFFECTS TO KNOW -----------------------------------------------------
# * bkk20 HGC-SG-OUT-v4 rules 32/33/34 previously had per-/24 conditions
#   (160.22.180.0/24 and .181.0/24). The `set rule=` above replaces the whole
#   rule string, so all three are now identical catch-alls. This is harmless —
#   only 160.22.180.0/23 is ever advertised to eBGP (verified in
#   /routing/bgp/advertisements) — but the per-/24 TE is gone. The equivalent
#   dead rules still exist in HGC-HK-OUT-v4 on both routers (bkk20 113/114,
#   bkk00 33/34/39/40) and can be removed.
# * bkk00 was upgraded 7.22 -> 7.23 on 2026-08-05. bkk20 remains on 7.22 and
#   CANNOT be safely rebooted yet: bkk00 has no working IPv4 transit
#   (HGC-SG-BACKUP-v4 has never established, as=0; HGC-HK-PRIMARY disabled), so
#   a bkk20 reboot would drop IPv4 from ~1.06M routes to HE-AMSIX's 167k and put
#   everything on the 224ms/100M Amsterdam pseudowire. Fix HGC-SG-BACKUP-v4 or
#   temporarily re-enable HGC-HK-PRIMARY first.
# * rr-client-bkk12-v4/v6 on bkk20 point at 10.155.212.1, which bkk12 does not
#   answer (bkk12 responds on 10.155.112.1, its bkk00-facing address). bkk12
#   therefore has bkk00 as its ONLY route reflector. Repointing bkk20 at
#   10.155.112.1 would NOT help — that subnet is reachable only via bkk00.
#   bkk12's side of the 10.155.212.0/30 p2p needs configuring.
#   (2026-08-05: bkk12 is NOT in active service, so this is not a blocker for
#   bkk20 maintenance. Fix the p2p before bkk12 is brought back online.)
#
# --- 2026-08-05 LATER: HGC-HK-PRIMARY RE-ENABLED ON bkk00 ---------------------
# To make bkk20 reboot-safe (7.22 -> 7.23), HGC-HK-PRIMARY was re-enabled on
# bkk00 — it had been disabled since the 2026-07-16 fixup, and bkk00 otherwise
# had NO working IPv4 transit (HGC-SG-BACKUP-v4 has never established, as=0).
#   /routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=no
# Result: v4 1,063,180 prefixes, v6 250,349. Sits at local-pref 140 (warm
# standby, per the 08-02 doctrine) below HGC-SG at 150, so it changes nothing
# while bkk20 is up but takes over automatically if bkk20 goes away.
# HGC-HK peer RTT 43ms vs 26ms via SG — the known HGC HK hairpin.
# NOTE: this circuit is slated for cancellation. If it is dropped, bkk20 becomes
# a single point of failure again AND AMS-IX Amsterdam (vAMSIX-EU, vlan 3995)
# and vHGC-SG-BACKUP (vlan 2518) die with it — all three ride
# HGC-10G-HK-BKK00-LAG. Fix HGC-SG-BACKUP-v4 before that happens.
