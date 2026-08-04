# IPAM — 160.22.181.0/24 (portable production block)

Auto-generated occupancy audit, 2026-08-04 (DNS via Cloudflare API + deploy/config/*.json).
This is the block that stays with / roams to the migrated services. 180/24 is being vacated.

## Occupied

| Addr | Role | Names / notes |
|------|------|----------------|
| .1 | |  |
| .6 | | bkk06,xeye |
| .7 | | bkk07 |
| .8 | | bkk08 |
| .12 | | bkk12 |
| .41 | |  |
| .42 | |  |
| .81 | | asset-hub-kusama,asset-hub-polkadot asset-hub-westend,bridge-hub-kusama bridge-hub-polkadot,bridge-hub-westend bulletin-polkadot,collectives-polkadot collectives-westend,coretime-kusama coretime-polkadot… (+12 more) |
| .110 | | polkadot.boot |
| .111 | | asset-hub-polkadot.boot |
| .112 | | bridge-hub-polkadot.boot |
| .113 | | collectives-polkadot.boot |
| .114 | | people-polkadot.boot |
| .115 | | coretime-polkadot.boot |
| .116 | |  |
| .120 | | kusama.boot |
| .121 | | asset-hub-kusama.boot |
| .122 | | bridge-hub-kusama.boot |
| .124 | | people-kusama.boot |
| .125 | | coretime-kusama.boot |
| .126 | | encointer-kusama.boot |
| .140 | |  |
| .141 | |  |
| .142 | |  |
| .143 | |  |
| .144 | |  |
| .145 | |  |
| .146 | |  |
| .150 | | *.clab,clab |
| .151 | | hydration.boot |
| .178 | |  |
| .180 | |  |
| .181 | | alerts,ansible astrolabe,bkk01 bkk02,bkk03 bkk04,bkk05 bkk09,bkk10 bkk20… (+48 more) |
| .188 | | people-paseo.boot |
| .201 | | val-flare-01 |
| .202 | | eth-fdc-01 |
| .203 | | btc-fdc-01 |
| .204 | | doge-fdc-01 |
| .205 | | xrp-fdc-01 |
| .206 | |  |
| .207 | |  |
| .209 | |  |
| .210 | |  |
| .211 | |  |
| .241 | |  |
| .250 | | ibp-geodns-01 |
| .251 | |  |
| .252 | | api.explorer,dex explorer,ibc-relay ibc,penumbra pindexer,testnet |
| .253 | |  |

### Fixed infrastructure (do not reallocate)
- .6/.7/.8/.12 — host primaries bkk06/07/08/12 (also carry 180-alt TE IPs — those alts are being dropped)
- .81 — SITE anycast VIP (all IBP public RPCs; HAProxy). Now the sole home after the 180.180 retirement.
- .178/.180/.181 — router loopbacks / origins (bkk20 / bkk00 / bkk50-NAT). .181 is a large multi-service anycast.
- .41/.42 — bgpctl TE probe sources; .1 — quicnet

## Free ranges (still available)

- .0–.0  (1 free)
- .2–.5  (4 free)
- .9–.11  (3 free)
- .13–.40  (28 free)
- .43–.80  (38 free)
- .82–.109  (28 free)
- .117–.119  (3 free)
- .123–.123  (1 free)
- .127–.139  (13 free)
- .147–.149  (3 free)
- .152–.177  (26 free)
- .179–.179  (1 free)
- .182–.187  (6 free)
- .189–.200  (12 free)
- .208–.208  (1 free)
- .212–.240  (29 free)
- .242–.249  (8 free)
- .254–.255  (2 free)

## CIDR-aligned free blocks
- Free /28s (16): .16/28, .48/28, .160/28, .224/28
- Free /27s (32): NONE (every /27 boundary has ≥1 occupant)
- Free /26s (64): NONE — block is fragmented

## NAT44 customer pool (moving off 180.64/26)
Pool is EMPTY (no customers assigned). Cannot fit a clean /26 in 181 without a defrag.
Options: (a) start as .48/28 now, grow later; (b) defrag a /26; (c) birth it at the new DC on the clean 180/24.

---

# TARGET SCHEME — CIDR-aligned /24 (design 2026-08-04)

Functional blocks, fully CIDR-aligned, edge-router block `.176/29` fixed (untouchable).
This is the **template for the production /24** — instantiate it natively at the new DC so
services are born in the right slot (no wasteful in-place defrag of the old block).

| CIDR | Size | Purpose | Current addrs that already fit |
|------|------|---------|-------------------------------|
| `.0/26`   | 64 | **NAT customer pool** (clean /26) | — (needs .1/.6/.7/.8/.12/.41/.42 vacated) |
| `.64/27`  | 32 | **Core infra**: host primaries, anycast VIPs, mgmt, TE probes | `.81` anycast ✓ |
| `.96/27`  | 32 | **Bootnodes** | `.110–.126` ✓ (all fit) |
| `.128/27` | 32 | **Guest RPC/app VMs — A** | `.140–.151` ✓ |
| `.160/28` | 16 | **Guest RPC/app VMs — B** | `.160–.175` free |
| `.176/29` | 8  | **EDGE ROUTERS / loopbacks — FIXED** | `.178/.180/.181` ✓ (untouchable) |
| `.184/29` | 8  | Reserved (router-adjacent) | `.188` boot → move to guest block |
| `.192/27` | 32 | **Validators + FDC + arb** | `.201–.211` ✓ (all fit) |
| `.224/27` | 32 | **App guests** (penumbra/explorer/geodns) | `.241–.253` ✓ |

Total = 64+32+32+32+16+8+8+32+32 = **256** (clean, no waste).

## Migration cost under this scheme (low)
Already in the right block, **no move**: anycast `.81`, bootnodes `.110–.126`, validators/FDC
`.201–.211`, app guests `.241–.253`, routers `.176/29`. That's the bulk of production.

**Only moves** (to free `.0/26` for the pool): host primaries `.6/.7/.8/.12` → `.64/27`,
plus `.1` (quicnet), `.41/.42` (TE probes) → `.64/27`. ~7 addresses.

## How to apply (no double-churn)
Instantiate this map on the **new DC's clean /24** in `deploy/config/network.json`
(`sites.<newdc>`), so every service that migrates lands on its aligned target address.
The old fragmented block is simply vacated as services leave — never re-defragged in place.
NAT pool is born at `.0/26` of the new block (empty, so zero customer impact).

---

# LEAST-DESTRUCTIVE DEFRAG PLAN (in-place, 181/24)

Goal: reach the target scheme by clearing **only `.0/26`** (for the NAT pool). Everything else
is already in its target block — no move. Total: **8 address moves**, all additive (add-new →
cut-over → remove-old = zero downtime), ordered low-risk first.

Infra landing block `.64/27` (`.81` anycast already lives here and does NOT move):
```
.65/.66  TE probes      (was .41/.42)
.67      quicnet        (was .1)
.70/.71/.72  bkk06/07/08 primaries  (was .6/.7/.8)
.76      bkk12 primary  (was .12)
.81      site anycast   (STAYS — untouched)
```

| # | Move | From→To | Risk | Touch points |
|---|------|---------|------|--------------|
| 1 | TE probes | .41/.42 → .65/.66 | **low** | bgpctl config + restart |
| 2 | paseo boot | .188 → .147 (guest blk) | **low** | VM IP + DNS + chain bootnode arg |
| 3 | quicnet | .1 → .67 | low-med | VM IP + DNS + BIRD origination |
| 4 | bkk06 primary | .6 → .70 | **med** | host BIRD `PUBLIC_NET4` + iface + DNS `bkk06` |
| 5 | bkk07 primary | .7 → .71 | med | same, one host at a time |
| 6 | bkk08 primary | .8 → .72 | med | same (bkk08 also runs FSP/monitoring — do last / carefully) |
| 7 | bkk12 primary | .12 → .76 | med | same |
| 8 | verify `.0/26` empty | — | — | then define NAT pool `.0/26` |

Host-primary moves (4–7): additive — add the new /32 to the host's BIRD + interface, confirm
reachability + BGP, move DNS, then withdraw the old /32. Never drop the old before the new is up.
Do them one host at a time so the anycast/RR fabric always has quorum.

## Even-less-destructive alternative: defrag by attrition (zero in-place moves)
Because every service renumbers as it migrates to the new DC anyway, the cheapest defrag is to
**instantiate the target scheme on the new site's /24 and let each service land aligned on arrival.**
The old 181 block is never touched — it just empties. Pick this if the DC migration is imminent;
pick the 8-move plan above if you want 181 clean *before* the migration.
