# eBGP-to-host + edge simplification — design (2026-08-08)

Retire the iBGP route-reflector design in favour of eBGP-to-the-host, and collapse the
legacy filter sprawl. Cuts the failure surface behind the 2026-08 incidents: stale
HW-FIB on leaf /32s, RR-client `next-hop-self`/add-paths gymnastics, and ~180 filter
rules.

## Current state (observed this session)

- **Single AS142108**, numbered **iBGP**. Edges `bkk00`(RR1)+`bkk20`(RR2) = MikroTik
  **RouterOS 7.22**, dual-role: eBGP border to transit (HGC-SG/HK, AMS-IX) **and** iBGP
  route-reflectors.
- Hosts `bkk06/07/08` = bird, RR clients over the UNIFIED fabric
  `10.155.100.x / fd00:155:100::x` (`qnq-400-100`), with `next hop self`, add-paths,
  per-node source addresses.
- Services: nearly all on the **anycast VIP** (`2401:a860:1081::` under the RPKI-valid
  `/40`, `160.22.181.81`) terminated by haproxy on the hosts. **penumbra is the lone
  holdout on a raw leaf /32 (`160.22.181.252`)** — served by the container's own nginx,
  and the only thing that depends on the edge HW-FIB'ing a single /32 correctly (hence
  it's the only service that "flaps").
- Filters: ~180 rules, carrying dead **BKNIX**, mislabelled **AMSIX** (now Bangkok-only
  → should be AMSIXBAN), **ROUTEVIEWS**, **HE-AMSIX** leftovers.

## Reality check on "unnumbered"

True BGP unnumbered (Cumulus/FRR: `neighbor <iface> interface remote-as external`,
IPv6 link-local + RFC 5549 IPv4-over-v6-nexthop) is a **bird/FRR** feature.
**RouterOS 7.22 doesn't support it.** Therefore:

- Keep MikroTik edges → eBGP-to-host is **numbered** (reuse the existing fabric IPs;
  still eBGP, still no RRs). ~90% of the simplification, low risk.
- **True unnumbered requires moving the edges to FRR/bird on Linux** — which
  *independently* eliminates the RouterOS HW-offload FIB-staleness bug class (the actual
  recurring pain, incl. the penumbra flap). That is the real prize and the honest reason
  to go all the way.

## Target design

- Edges keep **AS142108** (public, transit-facing) — the only eBGP-to-outside nodes.
- Each host a **private ASN**: `bkk06=4200000006`, `bkk07=4200000007`, `bkk08=4200000008`, …
- host ↔ each edge = **eBGP** (numbered on today's fabric; unnumbered link-local once
  edges run FRR).
- Hosts **export only their anycast VIPs, health-gated** — announce while the local
  service is up, withdraw on failure (natural with eBGP + BFD/service check). Import
  default only.
- Edges **import from hosts**: accept only rotko space (anti-spoof); no reflection
  needed — eBGP re-advertises by default. **Export to transit**: aggregates only
  (`dst-len ≤ /40`), `remove-private-as` to strip host ASNs.
- **No route reflectors.** No `next-hop-self` / add-paths / RR-client chains.

## What it fixes / doesn't

Fixes: RR complexity, add-paths/next-hop-self, health-gated announcement (kills
dead-service-in-ECMP), filter sprawl, clean AS boundaries, drift-prone manual
origination. Doesn't fix until edges leave MikroTik: HW-FIB staleness on whatever the
edge still forwards — but Phase 0 shrinks that to a handful of aggregates, so the
blackhole surface nearly vanishes.

## Migration — incremental, reversible, per-node

- **Phase 0 — shrink what BGP carries (do now).** Move penumbra (and any remaining
  leaf-/32 service) onto the anycast VIP + haproxy; retire the `.252` svc-fib-watchdog
  band-aid. This is also today's penumbra fix, and it proves the pattern.
- **Phase 1 — pilot.** Pick the ASN scheme; add eBGP sessions **alongside** the existing
  iBGP on ONE host (`bkk08`, least critical). Verify it announces its VIP and receives
  default over eBGP. Dual-run.
- **Phase 2 — cut over the pilot.** Remove `bkk08`'s iBGP RR-client sessions; verify
  traffic rides eBGP; confirm the VIP still in DFZ. Rollback = re-enable the iBGP session.
- **Phase 3 — roll to `bkk07`, then `bkk06`,** one at a time, same dual-run→cut pattern.
- **Phase 4 — delete RR (reflector) config from the edges** once no clients remain, and
  collapse filters to the per-boundary set below.
- **Phase 5 (separate window) — replace MikroTik edges with FRR/bird.** True unnumbered
  + eliminates the HW-FIB bug class. Optional, but this is where "unnumbered" actually
  lands and where the flapping-forever risk finally dies.

## Filter collapse (bundle with Phase 4)

Replace the ~180-rule chains with per-boundary policies:

- **host→edge (import at edge):** `accept if dst in rotko-space and dst-len ≤ 40; else reject` (anti-spoof + no more-specifics leaking in).
- **edge→transit (export):** accept aggregates `2401:a860::/32`, `2401:a860:1000::/40` (+ v4 `/23`,`/24`); set MED/prepend per upstream; `remove-private-as`; else reject.
- **transit→edge (import):** bogons + RPKI-invalid drop + max-prefix (the existing IN logic, deduped).
- **Delete:** BKNIX, ROUTEVIEWS, HE-AMSIX, `graceful-shutdown-out` (unless you actively drain). **Rename** AMSIX → AMSIXBAN.

## Risks / guards

- Per-node dual-run; every step reversible by re-enabling the iBGP session.
- **Never** send graceful-shutdown community `65535:0` to AS6939 (HE) — permanent
  teardown; OUT chains are shared.
- Prefer **per-node private ASNs** over keeping single-AS-with-`allowas-in` — you get
  eBGP's clean loop protection for free and avoid re-advertisement hazards.
- Keep BFD on the fabric for fast failover (already present).
- Don't attempt Phase 5 (edge replacement) in the same window as a cutover, and not
  while an edge is actively blackholing.

## Related

- Penumbra leaf-/32 flap (Phase 0 trigger): [[project_monitor_rotko_migration]] context,
  `docs/2026-08-08_leaf-public-ip-asymmetric-return.md`,
  `docs/2026-08-05_overbroad-prefixes-and-arp-blackholes.md`.
- RPKI /40 origination (already fixed): `src/news/2026-08-08-ipv6-rpki-maxlength-anycast.mdx` (www repo).
