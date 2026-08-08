# Current production network fabric — Rotko Networks (Bangkok) — topology reference

Purpose: complete, migration-planning reference of the CURRENT live fabric.
Gathered read-only 2026-08-06 (live device state, LLDP cross-referenced from both ends).
Companion containerlab model: `../current-infra.clab.yml`. Raw capture: `_raw-gather.txt`.

AS **142108**, iBGP fabric, PI space `160.22.180.0/23` + `2401:a860::/32`.

> Reachability note: bkk00, bkk50 gathered fully over the network key; bkk10 gathered over
> serial console (bkk03/ttyUSB1). **bkk20, bkk30, bkk40 reject the key and have no console
> mapping — captured via LLDP only** (model/version/loopback/role known, full config not).
> **bkk60 NOT gathered** — its console port (bkk06/ttyUSB0) was held by another user's `screen`
> session; captured via LLDP only. See §6.

---

## 1. Device inventory

### MikroTik routers / switches

| Device | Model | Role | ROS ver | cur-fw → upg-fw | Loopback (router-id) | Public loopback | Mgmt IP | Access |
|--------|-------|------|---------|-----------------|----------------------|-----------------|---------|--------|
| **bkk00** | CCR2216-1G-12XS-2XQ | **Edge (HK) + Route-Reflector** | 7.23 | 7.22 → **7.23** | 10.155.255.4 | 160.22.181.180 | 192.168.88.100 (ether1) | network ✓ |
| **bkk20** | CCR2216-1G-12XS-2XQ | **Edge (SG) + Route-Reflector** | 7.22¹ | — | 10.155.255.2 | 160.22.181.178 | — | key-rejected → LLDP only |
| **bkk10** | CCR2116-12G-4S+ | **Core L2 aggregation** (no BGP) | 7.22 | 7.22 → 7.22 | 10.155.255.1 + .10 | 160.22.181.179 | (ether13 mgmt, disabled) | console bkk03/USB1 ✓ |
| **bkk50** | CCR2004-16G-2S+ | **Core / CGNAT / cluster+mgmt switch** + iBGP | 7.22 | 7.22 → 7.22 | 10.155.255.3 | 160.22.181.181 | 192.168.88.50 / 192.168.69.1 | network ✓ |
| **bkk30** | CRS504-4XQ | **100G leaf / compute-pod ToR** | 7.22¹ | — | (10.155.255.30?)² | 2401:a860:1181::30 | 160.22.181.183 | key-rejected → LLDP only |
| **bkk40** | CRS504-4XQ | **100G leaf / compute-pod ToR** | 7.22¹ | — | (10.155.255.40?)² | 2401:a860:1181::40 | 160.22.181.184 | key-rejected → LLDP only |
| **bkk60** | CRS354-48G-4S+2Q+ | **Mgmt access switch** | 7.23.3¹ | — | (—)² | 2401:a860:1181::60 | 160.22.181.186 / 192.168.88.1 | console HELD → NOT gathered |

¹ version from LLDP neighbour advertisement. ² loopback/router-id not confirmed (device not reached);
public v6 `::30/::40/::60` seen in neighbour tables. bkk30/40/60 carry no BGP (L2 leaves on VLAN 400).

### Proxmox hosts (compute leaves)

| Host | OS | Role | Router-id lo | Public lo | Data-plane NICs | Mgmt |
|------|----|------|--------------|-----------|-----------------|------|
| **bkk03** | Debian 13 / PVE 9 | Mgmt/aux node + **console server** (bkk50, bkk10) | — (no BGP) | — | enp6s0 → **bkk50 ether6** (LLDP-confirmed) | vmbr0 192.168.69.103, gw bkk50 |
| **bkk06** | Proxmox | Compute + **console server** (bkk00, bkk60) | 10.155.255.6 | 160.22.181.6 / 160.22.180.6 | enp193s0f1np1 **100G** (BGP pri), eno1 1G (BGP bkup), eno2 1G (mgmt) | vmbr0 192.168.76.1, gw bkk50 |
| **bkk07** | Proxmox | Compute | 10.155.255.7 | 160.22.181.7 / 160.22.180.7 | enp1s0f1np1 100G-class (BGP pri), eno1 1G (bkup), eno2 1G (mgmt) | gw bkk50 |
| **bkk08** | Proxmox | Compute + **FSP / monitoring hub** | 10.155.255.8 | 160.22.181.8 / 160.22.180.8 | enp193s0f1np1 **100G** (BGP pri), eno1 1G (bkup), eno2 1G (mgmt) | vmbr0 192.168.69.218, gw bkk50 |
| **bkk12** | node | Compute leaf | (10.155.112.x) | 160.22.181.12 | single link → **bkk00 sfp28-12** (VLAN 400.112) | via bkk00 |

All hosts run **BIRD** and are iBGP **RR-clients** of bkk00 + bkk20 on the unified RR net
`10.155.100.0/24` / `fd00:155:100::/64` (see §3). Anycast origination lives on `lo` (see §4).

---

## 2. Physical interconnect map (from LLDP, confirmed both ends where reachable)

### Switch/router backbone

```
                         UPSTREAM TRANSIT / IX (on bkk00, HK)
              HGC-HK (Juniper ex4650, AS9304) ─ sfp28-2
              BKNIX RS (AS63529)             ─ sfp28-4
              AMS-IX / Cloudflare / HE (VLANs on HGC uplink)
                                   │
   ┌───────────────────────────────┴───────────────────────────────┐
   │                            bkk00  (EDGE-HK + RR)                │
   │  qsfp28-1-1 ─100G LAG(BKK20-LAG)─┐    sfp28-5 ─25G(BKK10-LAG)   │
   │  qsfp28-2-1 ─100G(BKK30-LAG)──┐  │    sfp28-11 ─10G(BKK50-LAG)  │
   │                               │  │    sfp28-12 ─── bkk12        │
   └───────────────┬───────────────┼──┼───────────────┬────────────┘
                   │               │  │                │
        ┌──────────▼─────┐   ┌─────▼──▼─┐        ┌──────▼───────┐
        │ bkk30 CRS504   │   │  bkk20   │        │  bkk10       │
        │ 100G leaf      │   │ EDGE-SG  │        │  core L2     │
        └────────────────┘   │  + RR    │        │ (VLAN 400)   │
        ┌────────────────┐   └────┬─────┘        │              │
        │ bkk40 CRS504   │        │ 10G          │ sfp+2/+4 LAG │
        │ 100G leaf      │        │(BKK20-LAG)   │──(BKK60-LAG)─┼──► bkk60
        └────────────────┘        │              │              │     CRS354
                             ┌────▼──────┐        │ sfp+3 ───────┼──► bkk20
                             │  bkk50    │◄───────┘ (VLAN400+210) │    (direct)
                             │ CCR2004   │  10G(BKK00-LAG,sfp+1)  │
                             │ CGNAT/mgmt│  10G(BKK20-LAG,sfp+2)  │
                             └────┬──────┘  sfp+2 ──── bkk10 ─────┘
                                  │ ether1-16 (1G)
                    cluster nodes + host mgmt + Saxemberg remote
```

Confirmed switch↔switch links (device-port ↔ device-port):

| Link | A side | B side | Speed | Notes |
|------|--------|--------|-------|-------|
| bkk00 ↔ bkk20 | bkk00 `qsfp28-1-1` (BKK20-LAG) | bkk20 (100G) | 100G | **the single inter-edge trunk**; p2p 172.16.30.0/30 |
| bkk00 ↔ bkk30 | bkk00 `qsfp28-2-1` (BKK30-LAG) | bkk30 `ether1` | 100G | leaf uplink |
| bkk00 ↔ bkk10 | bkk00 `sfp28-5` (BKK10-LAG) | bkk10 `sfp-sfpplus1` (BKK00-LAG) | 25G | VLAN400 trunk; p2p VLAN110 172.16.110.0/31 |
| bkk00 ↔ bkk50 | bkk00 `sfp28-11` (BKK50-LAG) | bkk50 `sfp-sfpplus1` (BKK00-LAG) | 10G | "atm to bkk00 hk"; 172.16.10.0/30 + 172.16.50.0/31 |
| bkk00 ↔ bkk12 | bkk00 `sfp28-12` | bkk12 | 25G | VLAN400.112, 10.155.112.0/30 |
| bkk00 ↔ HGC-HK | bkk00 `sfp28-2` (HGC-10G-HK-BKK00-LAG) | Juniper ex4650 (bkm-ac73) | 10G | transit uplink (VLANs: HGC-HK 2519, HGC-SG 2518, AMS-IX 3995) |
| bkk00 ↔ BKNIX | bkk00 `sfp28-4` (BKNIX-10G-BKK00-LAG) | BKNIX core7,8 MMR-B | 10G | IX peering (currently disabled) |
| bkk20 ↔ bkk50 | bkk20 | bkk50 `sfp-sfpplus2` (BKK20-LAG) | 10G | "atm to bkk20 sg"; 172.16.20.0/30 |
| bkk10 ↔ bkk60 | bkk10 `sfp-sfpplus2`+`sfp-sfpplus4` (BKK60-LAG) | bkk60 | 2×10G LAG | mgmt switch uplink |
| bkk10 ↔ bkk20 | bkk10 `sfp-sfpplus3` (BKK20-LAG) | bkk20 | — | VLAN400 + direct VLAN210 172.16.210.0/31 |

bkk30, bkk40, bkk60 all also appear as VLAN-400 neighbours across the fabric (`ether1`/`vlan400-bgp`),
i.e. they are bridged into the VLAN 400 L2 domain, not just point-to-point.

### Host ↔ switch links — **all LLDP-confirmed** (lldpd installed on bkk06/07/08 2026-08-06)

| Host NIC | Speed | Lands on | Path |
|----------|-------|----------|------|
| bkk03 `enp6s0` | 1G | **bkk50 ether6** | mgmt+data (single-homed) |
| bkk06 `eno2` | 1G | **bkk50 ether12** | mgmt → vmbr0 192.168.76.1, gw bkk50 |
| bkk06 `eno1` | 1G | **bkk10 ether6** | BGP **backup** (VLAN400.100) |
| bkk06 `enp193s0f1np1` | **100G** | **bkk30 `qsfp28-3-1`** | BGP **primary** (VLAN400.100) |
| bkk07 `eno2` | 1G | **bkk50 ether14** | mgmt (also sees vlan_cgnat) |
| bkk07 `eno1` | 1G | **bkk10 ether7** | BGP **backup** |
| bkk07 `enp1s0f1np1` | **100G** | **bkk30 `qsfp28-4-1`** | BGP **primary** |
| bkk08 `eno2` | 1G | **bkk50 ether2** | mgmt → vmbr0 192.168.69.218 |
| bkk08 `eno1` | 1G | **bkk10 ether8** | BGP **backup** |
| bkk08 `enp193s0f1np1` | **100G** | **bkk40 `qsfp28-4-1`** | BGP **primary** |
| bkk12 | 25G | **bkk00 sfp28-12** | single-homed |

> **Primary-leaf split (confirmed):** bkk06 + bkk07 100G uplinks both home to **bkk30**;
> bkk08 homes to **bkk40**. Every host's 1G backup goes to **bkk10** (ether6/7/8). Host mgmt
> (`eno2`) lands on **bkk50** — note the actual ports (ether12/ether14/ether2) differ from bkk50's
> stale `bkkNN-mgmt/-pub` port comments; trust the LLDP mapping above.

---

## 3. BGP topology

- **Single ASN 142108** across the whole fabric (iBGP).
- **Dual route-reflectors:** **bkk00** (cluster-id `10.155.255.4`) and **bkk20** (cluster-id `10.155.255.2`).
- **RR clients** (add-path, `RR-CLIENT-*` filters): hosts **bkk06/07/08** — sessions
  `rr-client-bkkNN-unified-v4/v6` to `10.155.100.{6,7,8}` / `fd00:155:100::{6,7,8}`.
- **iBGP mesh (non-RR):** bkk00 ↔ bkk20 (`IBGP-ROTKO-BKK20`), bkk00 ↔ bkk50 (`ibgp-bkk50`),
  bkk20 ↔ bkk50. bkk50 peers both edges (`ibgp-bkk00`, `ibgp-bkk20`), redistributes connected (CGNAT etc.).
- **bkk10 carries NO BGP** — pure L2 (its `/routing bgp connection print` is empty).
- **bkk30/bkk40/bkk60** carry no BGP either (L2 leaves/mgmt on VLAN 400).
- Full table: bkk00↔bkk20 iBGP session carries **~1.06M IPv4 / ~249k IPv6** prefixes (full transit).

### eBGP upstreams / peers (all on the edges; bkk00 HK side observed)

| Peer | ASN | AFIs | State (bkk00) |
|------|-----|------|---------------|
| HGC-SG-BACKUP | 142435 | v4+v6 | **ACTIVE** (established, ~250k v6) |
| HGC-HK-PRIMARY | 9304 | v4+v6 | configured, disabled (X) |
| BKNIX RS0/RS1 | 63529 | v4+v6 | disabled |
| AMS-IX RS1/RS2 | 6777 | v4+v6 | disabled |
| Cloudflare | 13335 | v4 | disabled |
| HE | 6939 | v4+v6 | disabled |
| RouteViews | 6447 | v4+v6 | disabled |

> bkk20 (SG edge) was not reachable; by design it mirrors bkk00 with its own SG transit and is the
> second RR. Confirm bkk20's active upstreams on-site.

---

## 4. VLANs & addressing scheme

### VLANs

| VLAN | Name / use | Where | Subnets |
|------|-----------|-------|---------|
| **400** | **QinQ outer — BGP-RR / cluster fabric** | bkk00 `bridge_vlan`, bkk10 `bridge_vlan`, bkk30/40/60, hosts (`*.400`) | L2 transport for all inner tags |
| **400.100** | **Unified BGP-RR network** (inner 100) | hosts `bond-bgp`→`vmbr2`, bkk00 `qnq-400-100` | `10.155.100.0/24`, `fd00:155:100::/64` (RR .1=bkk00, .2=bkk20) |
| 400.106/116, .107/117, .108/118 | per-host p2p (bkk06/07/08) | bkk00 `BKKnn-LAG` bonds (active-backup) | `10.155.10{6,7,8}.0/31`, `fd00:155:10{6,7,8}::/127` |
| 400.112 | bkk12 p2p | bkk00 `qnq-400-112` | `10.155.112.0/30`, `fd00:155:112::/64` |
| 400.200 | (reserved/used on bkk00) | bkk00 `qnq-400-200` | — |
| 110 | p2p bkk00↔bkk10 | `vlan-p2p-bkk00/10` | `172.16.110.0/31`, `2401:a860:1181:10::/127` |
| 210 | direct bkk10↔bkk20 | `vlan-direct-bkk20` | `172.16.210.0/31`, `2401:a860:1181:2010::/127` |
| **100** (bkk50) | **CGNAT** (`vlan_cgnat`) | bkk50 | `100.64.0.0/24`, `100.64.1.0/24` |
| 2519/2518/3995 | HGC-HK / HGC-SG / AMS-IX on transit uplink | bkk00 | provider p2p subnets |

### Address blocks

| Block | Purpose |
|-------|---------|
| `10.155.255.0/24` | **Router-ids / loopbacks** (bkk00 .4, bkk20 .2, bkk50 .3, bkk10 .1+.10; hosts .6/.7/.8) |
| `160.22.180.0/23` = 180/24 + 181/24 | **Public PI** (announced). 181 = current prod block, 180 = TE/anycast/new-DC target |
| `160.22.181.176/29` | **Edge-router public loopbacks — FIXED** (.178 bkk20, .179 bkk10, .180 bkk00, .181 bkk50) |
| `160.22.181.{6,7,8,12}` / `160.22.180.{6,7,8}` | host public IPs (primary 181 + TE-alt 180) |
| **Anycast** | site `160.22.181.81` / `2401:a860:1081::`; global `160.22.180.180` / `2401:a860::`; local-ULA `10.155.181.81` / `fd00:a860:1081::` |
| `10.155.100.0/24` | BGP-RR cluster net (VLAN400.100); `10.155.10{6,7,8}.0/31` per-host p2p |
| `100.64.0.0/24` + `100.64.1.0/24` | CGNAT customer pool (bkk50) |
| `172.16.x.0/30-31` | inter-router p2p (see §2) |
| `172.31.0.0/16` | **`wg_rotko` WireGuard overlay** (all routers+hosts: bkk00 .100, bkk50 .50, hosts .3/.6/.7/.8) |
| `172.30.50.0/24`, `172.29.169.0/24`, `10.69.169.0/24`, `10.50.0.0` | bkk50 Saxemberg (SAX-BKK-01) remote-node WG/KVM |
| `192.168.88.0/24` | device mgmt (RouterOS defconf: bkk00 .100, bkk50 .50, bkk60 .1) |
| `192.168.69.0/16` | cluster mgmt LAN (gw `192.168.69.1` = **bkk50**) |
| `192.168.76.0/16` | bkk06 vmbr0 mgmt |
| `2401:a860::/32` | IPv6 PI; site `:1081::/48`, per-host `:100{6,7,8}::/48`, infra p2p `:1181:*::/127` |
| `fd00:dead:beef::/48` | infra ULA (router loopbacks + p2p) |
| `fd00:155::/…` | cluster ULA (RR net, per-host) |

---

## 5. Reboot blast radius (firmware-upgrade planning)

Ordered by risk. "Console dep" = which host's serial port reaches this device.

| Device | What loses connectivity on reboot | Console dep | Redundancy |
|--------|-----------------------------------|-------------|------------|
| **bkk50** | ⚠️ **HIGHEST.** All host **mgmt planes** (gw 192.168.69.1 = bkk50) go gateway-less; **CGNAT** down; **Saxemberg** WG/KVM down; **bkk03 fully isolated** (its only uplink is bkk50 ether6). bkk20↔bkk50 + bkk00↔bkk50 iBGP drop. | **bkk03/USB0** — but bkk03 is isolated when bkk50 is down (mgmt path is via bkk50). **Circular dependency** → arrange out-of-band (wg/other) access to bkk03 first. | iBGP leaf; data-plane BGP (via bkk00/20) survives |
| **bkk10** | Core L2 hub for VLAN 400. Severs: host **1G backup BGP** (ether6/7/8), **bkk60** (BKK60-LAG → mgmt switch dark), bkk00↔bkk20 VLAN400 path, bkk10↔bkk20 VLAN210. | **bkk03/USB1** | Hosts keep **100G primary** path via bkk30/40 → BGP survives if leaves uplink independently. Verify before relying. |
| **bkk00** | HK transit (HGC-SG active + HGC-HK/BKNIX/AMS-IX/CF/HE), **one of two RRs**, links to bkk10/bkk50/bkk20/bkk30/**bkk12** (bkk12 single-homed → **isolated**). | **bkk06/USB1** → do NOT reboot bkk06 while needing bkk00 console | 2nd RR = bkk20; bkk20 SG transit covers internet |
| **bkk20** | SG transit, **second RR**, links to bkk00/bkk50/bkk10. | none (unreachable) | 1st RR = bkk00 |
| **bkk30** | 100G **primary** BGP uplink for **bkk06 + bkk07** → both fail over to 1G `eno1` backup (bkk10). Bandwidth-degraded, not down. | none (unreachable) | per-host 1G backup via bkk10 |
| **bkk40** | 100G **primary** BGP uplink for **bkk08** → fails over to 1G backup (bkk10). Bandwidth-degraded, not down. | none (unreachable) | 1G backup via bkk10 |
| **bkk60** | Mgmt access switch — mgmt for whatever hangs off its 48×1G. | **bkk06/USB0** (currently HELD) | mgmt-plane only |
| **bkk12** | Itself only (single-homed to bkk00). | none | none — single-homed |

**Console-server chain (critical):** the two serial console servers are **bkk03** (→ bkk50, bkk10)
and **bkk06** (→ bkk00, bkk60). Never reboot bkk06 while you may need bkk00/bkk60 console; never
reboot bkk03 while you may need bkk50/bkk10 console. bkk50↔bkk03 is a **circular** mgmt dependency —
establish independent OOB access to bkk03 before touching bkk50.

**Firmware status:** only **bkk00** has a pending upgrade staged (current 7.22 → upgrade 7.23, already
running 7.23 software). bkk10/bkk50 are current at 7.22. bkk60 already on 7.23.3. bkk20/30/40 advertise
7.22 via LLDP (upgrade state unknown — not reached).

---

## 6. Not gathered / gaps

| Device | Reason | Have from LLDP |
|--------|--------|----------------|
| **bkk20** | mgmt key rejected; no console mapping provided | model CCR2216, ROS 7.22, router-id 10.155.255.2, public lo 160.22.181.178, RR role, links to bkk00/50/10 |
| **bkk30** | mgmt key rejected; no console mapping | model CRS504-4XQ, ROS 7.22, mgmt 160.22.181.183, v6 ::30, 100G leaf, uplink bkk00 qsfp28-2-1 |
| **bkk40** | mgmt key rejected; no console mapping | model CRS504-4XQ, ROS 7.22, mgmt 160.22.181.184, v6 ::40, 100G leaf |
| **bkk60** | console port bkk06/ttyUSB0 **held by another user's `screen`** (PID 1056850) — not killed | model CRS354-48G-4S+2Q+, ROS 7.23.3, mgmt 160.22.181.186 / 192.168.88.1, mgmt switch, LAG to bkk10 |

Resolved 2026-08-06: the host-100G-NIC → bkk30/bkk40 leaf assignment is now **confirmed** via
lldpd installed on bkk06/07/08 (bkk06+bkk07→bkk30, bkk08→bkk40 — see §2).

Still to close: retry bkk60 console when the port frees; obtain console mapping or a working key for
bkk20/30/40 to capture their full config (roles/links already known via LLDP).
