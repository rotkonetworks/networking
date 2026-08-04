# DC migration — master runbook (Bangkok → new BKK DC)

Working doc, started 2026-08-04. Ties together `dc-migration-network-design.md` +
`IPAM-160.22.181.md`. Goal: relocate the whole cluster (~45 TB) to a new same-city DC,
both sites live during roll-over, **no lost Flare reward epoch, no double-run of keys**,
old DC decommissioned at the end.

## Decisions locked (this session)
- New DC is **same city** (Bangkok) → metro L2 / dark-fibre inter-site link is realistic.
- **BYOIP confirmed** — new DC accepts AS142108 eBGP; our PI space announces from there.
- **New hardware, parallel build** (do NOT relocate bkk00/bkk20 or bkk06/07/08 until cutover).
- **Both DCs live** during roll-over; **unicast** (no anycast); LB cuts over via **DNS flip**.
- End state = **single site** (new DC); old DC decommissioned after ≥1–2 clean reward epochs.
- Addressing: target **CIDR-aligned /24** scheme (see IPAM doc); **defrag by attrition** — services
  are born aligned at the new site, old fragmented block just empties.
- Edge routers block `.176/29` fixed. `180.180` idle, dropped at end (no edge surgery).

## Phase 0 — inputs to lock BEFORE build (blocking)
- [ ] **New-site IPv4 /24** — which block (the "new /24 ready"? or reuse 180/24?). Sets `sites.<newdc>`.
- [ ] **New-site IPv6 /48** — pick from the free `2401:a860:20xx::/48` band.
- [ ] **Transit / peering at new DC** — provider(s) + ASN(s), does it reach BKNIX/AMS-IX-BKK too?
- [ ] **Edge router HW** — 2× RouterOS (new CCRs) — model/procurement.
- [ ] **Inter-site link** — metro L2 / dark fibre / wavelength; bandwidth (drives the 45 TB sync window).
- [ ] **Rack/power/hands** at new DC; **compute HW** spec (mirror bkk06/07/08 core+NVMe).
- [ ] **Target date / maintenance windows**, and which reward epochs to avoid for the Flare cutover.

## Phase 1 — new-site network standup
1. Rack 2 edge routers; mgmt + loopbacks in `10.155.255.0/24` (new IDs).
2. Bring up transit/IX eBGP; announce the new-site /24 + participate in `2401:a860::/32`.
   Mirror IX doctrine (`deploy/fixups/2026-07-22_ix-doctrine.*`).
3. Inter-site: extend the drafted private-AS eBGP (`docs/ebgp-edge-migration-plan.md`) to
   inter-SITE eBGP between the two edge pairs; carry iBGP + the sync path. Start with the
   existing `172.31/16` WireGuard overlay if the metro link slips.
4. Add `sites.<newdc>` to `deploy/config/network.json` (aligned IPAM), run `deploy/bird/gencfg.sh`.

## Phase 2 — compute build + fabric
1. Install Proxmox hosts at new DC (dedicated NVMe ext4 for collators/validators — see
   `project_zfs_raidz1_random_write_ceiling`).
2. Join them to the BGP fabric as BIRD RR-clients (same pattern as bkk06/07/08).
3. Stand up **monitoring first** (a Prometheus/Alertmanager at the new site, or extend bkk08's)
   so the migration is watched from minute one.

## Phase 3 — data pre-sync (THE long pole — start ASAP once link is up)
Method by class: ZFS send/recv for subvol datasets where possible; else rsync + final delta;
chains that resync faster than they copy → bootstrap fresh at new DC. Order by size/lead-time:

| Class | Approx data | Method | Lead time |
|---|---|---|---|
| Polkadot / Kusama relay+system (`31001` 4 TB, `32001` 4.4 TB, asset-hubs 1 TB…) | ~15 TB | ZFS send, then delta | days |
| Penumbra ×4 + artifacts (`3.14 TB` + subvols) | ~7 TB | ZFS send | days |
| FDC verifiers/indexers (eth reth 0.9 TB, btc 0.84 TB, doge, xrp, sgb) | ~4 TB | resync or send | days |
| Flare validators (C+P chain, 4×~0.67 TB) | ~2.7 TB | pre-sync w/ temp id, final delta at cutover | hours |
| Hydration, zcash, hyperliquid, others | ~5 TB | per-chain | days |

## Phase 4 — service migration waves (rehearse → reward-critical → bulk)
1. **Rehearsal wave (low stakes):** migrate 1–2 non-critical RPC nodes end-to-end to prove the
   build→sync→cutover→verify loop and the rollback. (e.g. a westend/paseo RPC.)
2. **Flare reward stack** — Phase 5 below (the careful one).
3. **Bulk waves:** Polkadot/Kusama IBP fleet (mind IBP SLA), then Cosmos/other. Each service:
   build aligned at new DC → sync → cut over (DNS / NodeID-IP update) → verify → retire old.

## Phase 5 — Flare reward-stack cutover (reward-critical, no double-run)
Preconditions: new-site local validator RPC + indexer + value-provider all healthy; dashboard
green at new site. Time it **mid-epoch with margin**; 0 pass buffer + 1 strike = no room to miss.
- **Validators (4 NodeIDs):** one at a time. Pre-sync C+P DB at new host (temp identity), then in a
  short window: stop old node → copy staker/BLS keys → start new node → verify validating → move its
  DNS/advertised IP. Keep ≥3 of 4 up throughout. **Never run the same NodeID at both sites.**
- **FSP client:** stop old fsp-client → start new (same 7 wallets + BLS sortition) pointed at the new
  local RPC+indexer+value-provider. Gap must be < a few voting rounds. Watch `flared.rotko.net` live.
  fsp-client-02 (bkk07) is the warm standby — use it as the fallback if the new one misbehaves.
- **Arb bots:** move with their validator (mev-subscribe to local node); lower priority.

## Phase 6 — cutover LB + decommission
1. LB DNS flip (one edit if we do the `lb.rotko.net` CNAME collapse) → new-site LB when proven.
2. Withdraw old-site /24 announcement; new site now authoritative for production.
3. Run ≥1–2 full reward epochs clean, then decommission old DC. `180/24` freed / handed off last.

## Rollback (holds throughout)
Both DCs live + old instances retained until each service is proven → rollback = re-point DNS /
re-announce from old site / restart old instance. Nothing is destroyed until the end.
