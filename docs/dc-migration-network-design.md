# DC migration — network design (AS142108, two-site)

Status: DRAFT for review. Author working doc, 2026-08.
Goal: migrate the whole Rotko cluster (~45 TB, Flare reward stack + Polkadot/Kusama IBP + Cosmos)
from the current Bangkok site to a new datacenter **this month**, with **both sites live during
the roll-over** and **no lost Flare reward epoch**. This doc covers the NETWORK layer only
(addressing + routers + BGP); compute/data/Flare-cutover are separate docs.

## 0. The one enabling fact
We own **AS142108** and PI space (`160.22.180.0/23` = `160.22.180.0/24` + `160.22.181.0/24`) and
IPv6 `2401:a860::/32` (announced), currently multi-site-anycast from one physical site. Because we
own the space + ASN, a new DC that gives us a BGP session (BYOIP — confirmed available) lets us
announce our prefixes there. The migration is a **BGP + renumber exercise, not a renumber-into-
someone-else's-space exercise.**

## 1. Hard constraint that sets the model
The public internet filters IPv4 announcements longer than **/24**. So we **cannot roam individual
/32s** between sites over transit. Migration granularity for IP-identical moves is a whole /24.
→ We use the **renumber-per-service** model: each site owns a /24, services move by renumbering.

## 2. Target addressing plan

| Block | Role | Announced from |
|---|---|---|
| `160.22.181.0/24` | **Existing production** (all current VMs already live here). Stays the OLD-site block; shrinks as services migrate off it. | Old site (BKK) until decommission |
| `160.22.180.0/24` | **New-DC native block.** Freed by Phase A, then re-homed to the new site for all migrated + new services. | New DC |
| `160.22.180.0/23` | Aggregate (covering both /24s) — keep announcing for resilience; each site also announces its own /24 more-specific so traffic lands at the right site. | Both (aggregate) + per-/24 per site |
| `2401:a860::/32` | Whole v6 alloc, announced globally (unchanged). | Both |
| `2401:a860:20xx::/48` (NEW, TBD exact) | **New-site IPv6 /48**, carved from the free `:20xx::` band (the `/36` is almost entirely free; `:10xx::` = per-host BKK today). Per-host `:20yy::/48`s under it. | New DC |
| `2401:a860:1081::/48` | Bangkok site anycast — stays with old site; new site gets its own `2401:a860:208x::/48` site-anycast. | per site |

Global service anycast (`160.22.180.180`, `2401:a860::`) becomes **true geo-anycast**: announced
from BOTH sites once both are up — closer-routing bonus, and it's the natural home for HAProxy/IBP.

## 3. Phase A — evacuate 180/24 at the OLD site (prereq, no new-DC dependency)
Everything currently on 180/24 must move onto 181/24 so 180/24 is free to re-home to the new site.
Inventory to relocate (source: `deploy/config/network.json`, `generated/bkk08-bird.conf`, `bkk00.rsc`):

| 180.x today | What | Action |
|---|---|---|
| `160.22.180.180/32` | GLOBAL anycast VIP (IBP/HAProxy) | Re-origin the VIP on a **181.x** (or keep as pure anycast and just re-home the /24 later — see note) |
| `160.22.180.64/26` | bkk08 NAT44 customer pool (→ `10.8.20.x`) | Renumber pool into a 181/24 sub-range (`hermes-nat44` + `deploy/ipv4-pool/`) OR move wholesale to the new site's 180 pool at cutover |
| `160.22.180.6/.7/.8/.12` | host-alt TE IPs | Fold into 181 host addressing; rework the per-IX TE filter chains that key on the `180/24` address-lists (`bkk00.rsc:800-806`) |

Edge work this touches (NOT just host BIRD): `ibp-anycast-ipv4` address-list semantics, the ECMP
statics for `.180` (`bkk00.rsc:546-551`), and the per-IX `*-OUT` TE filters keyed on `160.22.180.0/24`.
Do Phase A as its own change-set (dated fixup script w/ APPLY+ROLLBACK, like `deploy/fixups/`).

NOTE: if we'd rather NOT disturb the global anycast, an alternative is to leave `.180` as anycast and
simply add the new site as a third anycast origin — then 180/24 isn't "freed" but "shared." Decide in §7.

## 4. Phase B — stand up the new-DC network
1. **Transit/peering:** establish eBGP at the new DC (BYOIP confirmed). Announce `160.22.180.0/24`
   + participate in `/23` aggregate + `2401:a860::/32`. Mirror the existing IX doctrine
   (`deploy/fixups/2026-07-22_ix-doctrine.*`): transit + whatever IXPs the new metro offers.
2. **Edge routers:** 2× RouterOS edges at the new DC (dual RR, mirrors bkk00/bkk20). New hardware
   (parallel build) — do NOT relocate bkk00/bkk20 (that would drop the old site). Candidate names
   per the existing scheme; assign new router-ids in `10.155.255.0/24`.
3. **Inter-site link:** the two sites must share iBGP + a data path for the ~45 TB sync and for
   internal fabric during overlap. Options (decision in §7): (a) dedicated transport/wavelength,
   (b) L2 VPN from a carrier, (c) WireGuard over transit (extends the existing `172.31.0.0/16`
   `wg_rotko` overlay — simplest, already in use). iBGP between the two edge pairs = extend the
   drafted **eBGP-between-edges private-AS** plan (`docs/ebgp-edge-migration-plan.md`) to inter-SITE
   eBGP: old edges keep AS142108, new site uses a private sub-AS stripped on egress, or full
   confederation. Recommend: **inter-site eBGP with private AS on the new site, `remove-private-as`
   on external** (consistent with current `remove-private-as=yes` everywhere).
4. **Config generation:** add a `sites.<newdc>` block to `deploy/config/network.json` (router_id,
   public_v4 on 180, public_v6 on the new /48, bgp_rr_v4/v6, internal nets, anycast_*), add its VMs
   to `services.json`, run `deploy/bird/gencfg.sh <newdc>` + the nftables/haproxy generators. This is
   the same toolchain that builds bkk06/07/08 — a new site is a new entry, not a new tool.

## 5. Phase C — per-service migration (renumber 181→180)
For each service, in waves (Flare reward stack first, then Polkadot IBP, then Cosmos):
1. Build the LXC/VM at the new DC on a **180.x** IP (+ new-/48 v6), from ansible/config.
2. Pre-sync its chain data (rsync/snapshot) — the schedule long-pole; start weeks ahead for the big
   ones (polkadot 4 TB, kusama 4.4 TB, eth-FDC reth ~0.9 TB, penumbra 3 TB).
3. Cut over: DNS to the new 180.x; for **validators** update the NodeID advertised IP (signed P-chain
   tx) — NodeID/keys unchanged; for **FSP** just point the client at the new local validator RPC +
   indexer (submission is wallet-based, IP-independent); for anycast services add the new origin.
4. Verify, then retire the old 181.x instance. Rollback = keep old instance until proven (both live).

Result: 181/24 empties, 180/24 fills at the new DC. (Optionally re-consolidate onto one /24 later.)

## 6. Flare-specific network notes (reward-critical)
- **No double-run** of any validator NodeID or the FSP signing keys across sites — clean stop-old/
  start-new per node. Detail lives in the Flare-cutover doc; network-wise each val's IP just moves
  180.x-at-new (or keeps 181.x if we do IP-identical for Flare only — see §7).
- Time the FSP cutover **mid-epoch with margin**, watched live on `flared.rotko.net` (0 pass buffer +
  1 strike = no room for a missed epoch).
- The 4 validators span bkk07 (val-02/03) + bkk08 (val-01/04) today; sequence so the entity always
  keeps ≥3 NodeIDs up during moves.

## 7. Open decisions (block the detailed build)
1. **New DC location / metro** — sets transit + IX options, inter-site latency, and the exact v6 /48.
2. **Inter-site transport** — dedicated wave / carrier L2VPN / WireGuard-over-transit (recommend WG to
   start; upgrade if the 45 TB sync or fabric needs it).
3. **Edge router hardware** at new DC — new CCRs (recommended) vs relocate a spare (bkk10/30/40 are
   L2-only today; could be repurposed as the new edge if freed).
4. **Global anycast `.180`** — evacuate to 181 (Phase A frees 180 cleanly) vs keep as shared anycast
   origin (less disruptive, but 180/24 not fully "freed").
5. **Flare IP policy** — renumber validators onto 180 like everything else (simplest, consistent), or
   keep Flare on 181 and do an IP-identical /24-flip just for the Flare block at final cutover.
6. **Timeline vs data volume** — 45 TB pre-sync is the real long-pole; confirm the inter-site
   bandwidth so waves can be scheduled against realistic sync times.
