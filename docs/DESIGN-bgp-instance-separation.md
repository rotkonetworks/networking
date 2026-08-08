# DESIGN: split BGP into transit + fabric instances (enables scoped anycast ECMP)

Status: **proposal for review — nothing applied to live routers**
Scope: bkk00 and bkk20 (the route reflectors / edge routers). Validator-adjacent.

## Problem

Everything on bkk00/bkk20 runs in a single `bgp-instance-1`:

- eBGP transit/IX (full DFZ, ~1.29M routes): BKNIX, RouteViews, HE, HGC-HK,
  HGC-SG, AMS-IX, Cloudflare
- internal iBGP fabric: RR-client sessions (bkk06/07/08/12), RR↔RR peer
  (IBGP-ROTKO-BKK20), bkk50

RouterOS 7's `multipath` and best-path policy are **per-instance**. One
instance = one global policy. We cannot enable BGP ECMP for the haproxy
anycast `/32`s without also applying it to the entire DFZ (incl. the
validator's transit egress). That is why the only safe lever today is a
scoped static route (which bypasses BGP health).

## Key enabling fact

RR-client sessions advertise **`ipv4-apnic-rotko` only** to clients (verified:
`rr-client-bkk06-unified-v4 output.network = ipv4-apnic-rotko`), *not* the
DFZ. Therefore a dedicated fabric instance would only ever carry
rotko/anycast prefixes — never the 1.29M DFZ. `multipath` on that instance
is isolated from transit **by construction**, not by filter.

## Current session inventory (bkk00)

**FABRIC (move to `instance-fabric`)** — 14 sessions, all AS142108:
- `IBGP-ROTKO-BKK20-v4`, `-v6`            (RR↔RR peer)
- `ibgp-bkk50-v4`, `-v6`                  (internal)
- `rr-client-bkk06-unified-v4`, `-v6`     (ibgp-rr)
- `rr-client-bkk07-unified-v4`, `-v6`     (ibgp-rr)
- `rr-client-bkk08-unified-v4`, `-v6`     (ibgp-rr)
- `rr-client-bkk12-v4`, `-v6`             (ibgp-rr)

**TRANSIT (stays in `bgp-instance-1`)** — ~26 eBGP sessions:
- BKNIX-RS0/RS1 v4/v6 (AS63529), RouteViews (AS6447), HE-BKNIX/HE-AMSIX
  (AS6939), HGC-HK (AS9304), HGC-SG (AS142435), AMSIX-RS1/RS2 (AS6777),
  Cloudflare-AMSIX ×4 (AS13335)

bkk20 mirrors this (own router-id 10.155.255.2); same split applies.

## Target design

```
bgp-instance-1   (rename intent: "transit")     vrf=main  router-id=10.155.255.4
   └── all eBGP transit/IX sessions  ── carries DFZ ── NO multipath

instance-fabric                                  vrf=main  router-id=<NEW /32>
   └── rr-client-* , IBGP-ROTKO-* , ibgp-bkk50-*  ── rotko/anycast only
       multipath=8   ← scoped here; only ever sees rotko prefixes
```

Both instances share `vrf=main` → one FIB. Mechanics:
- Fabric learns anycast `/32` from rr-clients → installs into main table,
  ECMP across bkk06/07/08(/12) because `multipath=8` on fabric instance.
- Transit instance still advertises the anycast to the world via its
  existing `output.network=ipv4-apnic-rotko` (the prefix is in main table;
  network-statement origination doesn't care which instance learned it).
- DFZ best-path stays entirely in the transit instance — `multipath`
  there remains unset → zero change to validator egress.

Net: anycast gets BGP-health-aware ECMP (follows withdrawals); transit /
validator path selection byte-for-byte unchanged.

## Open items to decide before execution

1. **Fabric router-id**: needs a unique /32 (cannot reuse 10.155.255.4).
   Candidates: a new loopback e.g. `10.155.254.4` (bkk00) / `10.155.254.2`
   (bkk20). Must be reachable for iBGP if used as update-source — confirm.
2. **Maintenance window**: moving a session between instances bounces
   *that session only*. Transit sessions are never touched. Fabric peers
   (rr-clients, RR↔RR) bounce briefly as they migrate.
3. Apply to bkk00 first, validate, then bkk20 — or both in one window.
4. Whether to also fix the bkk20 reflected-path / originator-id rewrite
   at the same time (related but separable — see below).

## Migration order (per router; transit never touched)

For each step: change → verify → (rollback = reverse the one step).

1. **Baseline capture** (read-only): full `/routing/route` for anycast
   `/32`s + validator `.201` + FDC + a transit sample; session count;
   active-route count. Save.
2. Create `instance-fabric` (new router-id, same AS 142108, vrf=main).
   No sessions yet → inert.
3. Move **one rr-client** (e.g. `rr-client-bkk12-*` — least critical, not
   a haproxy node) to `instance-fabric`. Session bounces (~seconds).
   Verify: anycast still learned + still announced to transit/world; that
   client's prefixes intact; transit untouched.
4. Move remaining rr-clients **one at a time** (bkk08, bkk07, bkk06),
   verifying anycast stays announced after each (others keep it alive →
   no world-facing gap).
5. Move `IBGP-ROTKO-BKK20-*` and `ibgp-bkk50-*` to `instance-fabric`.
6. `set instance-fabric multipath=8`.
7. Verify: anycast `/32` now `+ECMP` with N nexthops, active; validator
   `.201`/FDC/`.206`/hydration unchanged; transit DFZ best-paths
   unchanged; session count back to baseline; active-route count sane.
8. Repeat on bkk20.

Rollback at any step: move the session(s) back to `bgp-instance-1` /
remove `instance-fabric`. Each step is independently reversible; transit
is never in the change set so the validator's internet path cannot break
from this work.

## Risk assessment

| Risk | Mitigation |
|---|---|
| Anycast world-facing gap while migrating rr-clients | move one at a time; others keep the /32 alive in main table |
| Transit/validator egress disruption | transit sessions are *not* in the change set at all |
| Fabric router-id collision / unreachable update-source | pre-allocate + verify reachability before step 2 |
| Session bounce on move | only fabric peers, brief, internal; expected |
| bkk20 reflected-path quirk persists | separable; see below |

## Related: bkk20 reflected-path / originator-id

bkk20 currently prefers the anycast path *reflected from bkk00*
(`originator-id=10.155.255.4`, lower than bkk06/07/08 → wins tiebreak)
over its own direct rr-client paths. Instance separation alone may not
fix this — the originator-id rewrite happens in bkk00's
RR-CLIENT-IN/IBGP-OUT filters. Recommend addressing as a **separate,
sequenced change** after instance separation is stable, with its own
baseline/rollback. Do not bundle.

## Decision

This doc is for review only. No live changes until the open items
(esp. fabric router-id allocation + maintenance window) are decided and
the per-step commands are written out and reviewed, same discipline as
the (reverted) multipath probe and the (parked) arb-bot bird change.
