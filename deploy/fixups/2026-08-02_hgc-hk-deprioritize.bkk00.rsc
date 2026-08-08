# bkk00 (RR 10.155.255.4 / edge 160.22.181.180) — 2026-08-02
# DE-PRIORITIZE HGC HONG KONG (staged step toward dropping the HK circuit).
#
# Rationale: HGC backhauls even Singapore-destined traffic through Hong Kong
# internally (traced 2026-08-02: SG dests egress HGC-SG ingress ~29ms then
# hairpin via 218.189.5.x HGC-HK to ~52-55ms, blowing the 50ms RPC SLA). HK
# circuit is being dropped. This shifts our OUTBOUND transit onto HGC-SG now,
# leaving HK as a warm backup, so the eventual HK removal is a no-op for egress.
#
# Mechanism: the ONLY thing that makes HGC-HK preferred is bkk00's HGC-HK-IN
# half-space rule (dst in 0.0.0.0/1 -> local-pref 155). Everywhere else HK is
# already 140. Collapse that 155 to 140 so:
#   AMS-IX-BKK 200 > HGC-SG 150 = AMS-IX-HK/EU 150 > HGC-HK 140 > HE-AMS 120
# Result: SG (150) wins all transit egress; HK (140) used only if SG lacks a
# route (never — full table) => warm standby. Bonus: HK stops beating AMS-IX-HK
# (was 155 > 150), so IX-reachable dests now prefer the local IX over HK transit.
#
# bkk20 needs NO egress change (its HGC-HK-IN is already 140).
# INBOUND (announcement prepends) is deliberately NOT touched here — bkk00/bkk20
# use a crossed prepend design (bkk00: HK-OUT prepend 10 / SG-OUT 3-4; bkk20:
# SG-OUT 10 / HK-OUT 3-4). Inbound re-converges to SG automatically when the HK
# session is withdrawn at drop time, so egress-first is the safe staging order.
# If you want inbound off HK before the physical drop, do it as a separate,
# reviewed fixup (raise bkk20 HGC-HK-OUT prepend to 10) — not folded in here.
#
# IMPACT: bouncing the HGC-HK session re-learns its full table (~1M v4 routes,
# ~1-2 min, CPU bump). SG carries everything meanwhile — zero traffic loss, HK
# only becomes LESS preferred. Safe to run anytime; a quiet window is nicer.
# APPLY WHILE WATCHING. Rollback at bottom. Reversible in seconds.
#
# ============================ APPLIED LIVE 2026-08-02 =========================
# Rules 1-2 applied on bkk00. RouterOS v7 RE-EVALUATED ON THE FILTER EDIT — the
# session bounce in step 3 was NOT needed (verified: HGC-HK routes flipped to
# lp=140 inactive, SG/IX 150 active, immediately). Then, per operator decision
# (new contract = HGC-SG + AMS-IX Bangkok only, HK dropped entirely):
#   bkk00:  /routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=yes
#   bkk20:  /routing bgp connection set [find where name~"HGC-HK-BACKUP"]  disabled=yes
# Verified post-removal from bkk03 CT: global reachability intact; SG carries
# full 1.06M table; traffic now egresses HGC-SG (~27ms) -> NTT AS2914 (was
# HK -> Cogent). dot01 validator healthy (75 peers). REVERSIBLE: disabled=no.
# TODO housekeeping: the HGC-HK-IN/OUT filter chains + templates are now dead
# config; remove in a cleanup pass once the HK circuit is physically gone.
# =============================================================================

# --- 1. HGC-HK-IN v4: kill the 155 half-preference (155 -> 140) ----------------
/routing filter rule set [find where chain="HGC-HK-IN-v4" and rule~"bgp-local-pref 155"] \
  rule="if (dst in 0.0.0.0/1) { set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept; }"

# --- 2. HGC-HK-IN v6: same (155 -> 140) ---------------------------------------
/routing filter rule set [find where chain="HGC-HK-IN-v6" and rule~"bgp-local-pref 155"] \
  rule="if (dst in ::/1) { set bgp-local-pref 140; set bgp-large-communities hgc-hk-communities; accept; }"

# --- 3. BOUNCE the HGC-HK sessions so routes re-enter through the new filter ----
#        (RouterOS applies input filters only when routes are (re)received.)
#        SG holds the full table throughout — this only de-prefers HK.
/routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=yes
:delay 10s
/routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=no

# --- verify --------------------------------------------------------------------
# /routing filter rule print where chain~"HGC-HK-IN" and rule~"local-pref"   ;# all 140
# :put [/routing/route/print count-only where dst-address=8.8.8.0/24 and active]  ;# active nexthop should be HGC-SG (150), not HK
# /routing/route/print detail where dst-address~"8.8.8" ;# active = local-pref 150 via HGC-SG / bkk20; HK candidate at 140
# trace from a CT to a SG dest (139.162.16.5): should now hand to HGC-SG, still
#   subject to HGC's internal HK backhaul until the circuit is physically dropped.

# --- ROLLBACK (restore the 155 half-split) -------------------------------------
# /routing filter rule set [find where chain="HGC-HK-IN-v4" and rule~"bgp-local-pref 140" and rule~"0.0.0.0/1"] \
#   rule="if (dst in 0.0.0.0/1) { set bgp-local-pref 155; set bgp-large-communities hgc-hk-communities; accept; }"
# /routing filter rule set [find where chain="HGC-HK-IN-v6" and rule~"bgp-local-pref 140" and rule~"::/1"] \
#   rule="if (dst in ::/1) { set bgp-local-pref 155; set bgp-large-communities hgc-hk-communities; accept; }"
# /routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=yes
# :delay 10s
# /routing bgp connection set [find where name~"HGC-HK-PRIMARY"] disabled=no
