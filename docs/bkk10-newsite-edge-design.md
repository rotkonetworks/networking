# bkk10 → Telehouse edge router (stateless rebuild)

Status: DRAFT. Started 2026-08-21, during/after the factory reset of bkk10.
Supersedes bkk10's role in `current-infra-topology.md` (was: "Core L2 aggregation, no BGP").
Resolves open decision **§7.3** of `dc-migration-network-design.md` ("bkk10/30/40 are L2-only
today; could be repurposed as the new edge if freed") — **decision: yes, bkk10 becomes the
new-site edge router.**

## 0. Access — RESOLVED 2026-08-21

Both devices are now reachable by key from the workstation:

```
ssh pjbkk10     # ansible@192.168.88.10 via bkk08   (key auth)
ssh bkk60       # ansible@192.168.88.1  via bkk08   (key auth)
```

### bkk60: the "rejects the ansible key" conclusion was WRONG
`current-infra-topology.md` records bkk20/30/40/60 as rejecting the ansible key.
For bkk60 that is not what was happening. Its **SSH service was address-restricted**:

```
/ip/service/print where name=ssh
  ssh  22  tcp  172.104.169.64/32, 158.140.0.0/16
```

Connections from bkk08 were refused at the service level, before authentication.
The `ansible` user existed all along (`group=full`, `address=0.0.0.0/0`).
Fixed additively (existing entries kept):

```
/ip/service/set ssh address=172.104.169.64/32,158.140.0.0/16,\
    192.168.69.0/24,192.168.88.0/24,160.22.180.0/23,10.155.0.0/16
```

**Check the same thing on bkk20/30/40 before concluding their keys are wrong.**

Console fallback: `bkk06/ttyUSB0` (screen PID 1056850, logged in as admin since
2026-08-06). Never reboot bkk06 while relying on it.

### bkk10: post-reset recovery
bkk10 was factory-reset on 2026-08-21 (confirmed by bkk20 seeing MAC
`78:9A:18:80:E2:E5` reporting identity `CCR2116`). Config backups are intact in
`backup/mikrotik/bkk10-2026-08-19.rsc`; the clean slate is what we wanted anyway.

Recovered to `192.168.88.10/24` on `BKK60-LAG` (2x10G to bkk60). Two traps hit on
the way, both worth remembering:

1. **Duplicate address.** The factory defconf leaves `192.168.88.1/24` on `ether13`
   -- which is **bkk60's address**. bkk10 therefore believed it owned `.1`, so
   `/ping 192.168.88.1` from bkk10 "succeeded" in 38us by answering itself while
   never reaching bkk60. Removing the defconf address is mandatory, and deleting
   the defconf *bridge* does not remove it (it lives on ether13 separately).
2. **Missing default route.** With only `192.168.88.10/24` and no route, ARP
   resolved fine (same subnet) but every reply to an off-subnet source was dropped.
   bkk60 sources from `192.168.69.2/16` and bkk08 from `192.168.69.218`, both
   outside the /24. Symptom is the confusing one: `/ip/arp` shows the peer
   `reachable` while ping times out.

The bkk60 LAG was **not** the problem -- LACP negotiated correctly on both sides
(`lacp-partner-system-id` matched on each). An earlier diagnosis blaming a bkk60
LACP mismatch was wrong.

Recovery script: `deploy/bkk10-newsite/00-recover-mgmt.rsc`

## 1. Target topology (revised 2026-08-21 — bkk60 is the demarc)

HGC cross-connect from the **MMR** lands on **bkk60**, not on the router. bkk60 hands the
traffic to **bkk10**, which does all the BGP.

```
  MMR ── XC 10G ──> bkk60 (CRS354, L2 demarc) ── 10G / N x 10G LAG ──> bkk10 (CCR2116, BGP)
```

- **bkk60** `CRS354-48G-4S+2Q+` — 48x1G, **4x SFP+ (10G)**, 2x QSFP+ (40G)
- **bkk10** `CCR2116-12G-4S+` — 12x1G, **4x SFP+ (10G)**

### Hardware ceiling: 10G per port
**Neither box has SFP28, so 25G is not possible.** The "25G" label on bkk00<->bkk10 in
`current-infra-topology.md` refers to bkk00's `sfp28-5`; bkk10's SFP+ end runs it at 10G.
Handoff options are 1x10G, or a LAG (2x10G = 20G, max 4x10G). bkk60's QSFP+ 40G ports are
unusable here because bkk10 has no QSFP+.

Port budget on bkk60 is tight: 4x SFP+ total, minus 1 for the HGC XC, minus 1-2 for the
bkk10 handoff, leaves 1-2 spare. A second XC (e.g. if AMS-IX Bangkok is delivered separately
rather than as a VLAN on the HGC XC) consumes another.

### Consequences of putting bkk60 in the transit path
Chosen deliberately: one XC lands on a switch, so it can later fan out to a second router and
router swaps don't disturb the cross-connect. Two risks follow and must be managed:

1. **Fate-sharing with the management plane.** bkk60 is today the *mgmt access switch*. If it
   also carries transit, one L2 mistake on bkk60 takes out internet *and* management at the
   same time. Mitigation: bkk10's management path must **not** depend on bkk60.
   This is not hypothetical — on 2026-08-21 `BKK60-LAG` was chosen as bkk10's mgmt path after
   the reset and **failed to come up**, leaving the console as the only access.
2. **We cannot currently manage bkk60.** It rejects the `ansible` SSH key, and its console
   (`bkk06/ttyUSB0`) was held by another session. **Hard prerequisite:** working authenticated
   access to bkk60 before it becomes the demarcation point for paid transit.

### VLAN transport
Provider VLANs (HGC transit, and AMS-IX Bangkok if delivered on the same XC) must be trunked
**through** bkk60 to bkk10. bkk60 therefore needs vlan-filtering config: XC port tagged with
the provider VLANs, handoff port tagged with the same set. bkk10 terminates L3 on them.

### Facility + circuit (from the Telehouse XC ticket, 2026-08-21)

| Item | Value |
|---|---|
| Site | Telehouse Rama 9, **Data Hall 122**, footprint **K-03L** |
| Space / power | half rack, **3 kW** |
| Carrier | HGC IP Transit, **CID PP9094730** - **NEW circuit** (not a relocation) |
| Bandwidth | **400M committed / 500M, burstable to 800M** |
| Physical port | **10G**, single-mode fibre, **LC/UPC** |
| Requested RFS | **2026-08-27** |
| On-site contact | Tommi Niemi |

Two consequences:

1. **Sub-rate service on a 10G port -> shape, do not let HGC police.** A 10G interface
   bursts at line rate into a 500M policer; TCP responds badly (retransmits, throughput
   well under the contracted rate). Put a queue on bkk10's egress toward HGC just under
   the contracted rate so packets queue instead of being dropped. This is a real
   throughput difference, not a theoretical one.
2. **It is a NEW circuit, so nothing carries over.** VLAN id, p2p subnet and peer ASN
   are all still unknown and must come from HGC - see the blocking list below. Do not
   reuse bkk00's 2519/2518.

Optics: SMF LC/UPC is required at the bkk60 XC port (10GBASE-LR class). If the fabric
ships with DACs or multimode SR optics, the correct transceiver will not be in the crate.
**Verify before the equipment leaves Bangkok.**

Capacity is a non-issue: 800M peak against a 10G port and a 16 GB / 16-core CCR2116.
The earlier 10G-vs-25G discussion was moot for this circuit - port speed is media, not
service rate.

## 2. Bridge, not per-port VLAN sub-interfaces
Direction: **bridge with vlan-filtering** on bkk10, handoff port as a tagged member, L3 on
VLAN interfaces over the bridge.

Rationale:
- The XC carries multiple provider VLANs; the tags are the demarcation between HGC and
  AMS-IX, dictated by the providers. The trunk is not optional.
- A bridge allows a provider VLAN to be extended to another physical port later —
  contemplated in `ARCHITECTURE-decision-analysis.md` "Extend HGC VLANs to servers".
  VLAN sub-interfaces bound directly to one port cannot do this.
- Keeps hardware offload on the CCR2116 switch chip.

The old bkk10 was inconsistent — three uplinks built three different ways (BKK00-LAG as a
bridge port, BKK20-LAG with VLAN sub-ifs directly on the bond, BKK60-LAG bare L2 with no L3).
The rebuild uses **one** pattern throughout.

## 3. Identity / addressing

| Item | Value | Source |
|---|---|---|
| ASN | **142108** | owned; `dc-migration-network-design.md` §0 |
| router-id | `10.155.255.10` | bkk10's existing id (also held `.1`; both were legitimately bkk10's) |
| Public loopback | `160.22.180.179/32` **(proposed)** | mirrors the fixed `/29` edge-loopback convention: old site `160.22.181.176/29` = .178 bkk20, **.179 bkk10**, .180 bkk00, .181 bkk50 → new site uses the same offsets in `160.22.180.176/29` |
| Site v4 block | `160.22.180.0/24` | new-DC native block |
| Aggregate | `160.22.180.0/23` | announced from both sites |
| Site v6 | carve from `2401:a860::/32` | **see §6 — /40 vs /48 is unresolved** |

## 4. Communities — already reserved for bkk10
The existing scheme on bkk20 already allocates bkk10 edge identifiers. Reuse them as-is:

```
142108:16:10   Routes learned via iBGP BKK10
142108:16:11   Routes learned at HGC-SG2 BKK10
142108:16:12   Routes learned at HGC-HK1 BKK10
142108:16:13   Routes learned at BKNIX BKK10
142108:16:14   Routes learned at AMSIX BKK10
```

## 5. Peering — reuse existing templates and filter chains
bkk20 already runs AMS-IX Bangkok (`AMSIX-BAN`) and HGC. Mirror its templates rather than
inventing policy. All templates carry `remove-private-as=yes`, `as-override=no`,
`keep-sent-attributes=yes` and a `network=ipv4/ipv6-apnic-rotko` origination list.

Templates to recreate: `AMSIX-BAN-v4/v6`, `HGC-SG-v4/v6` (or `IPTX-HGC-TH-HK-v4/v6`).
Filter chains to recreate: `AMSIX-BAN-IN/OUT-v4/v6`, `HGC-*-IN/OUT-v4/v6`.
Also port the RPKI edge fixup: `deploy/fixups/2026-08-08_rpki-edge-v6-dst-len32.rsc`.

### Known AMS-IX Bangkok values (as used by bkk20 today)
These are the **existing** port's values. Whether they move to Telehouse or a new port is
issued is the open question in §6.

| Item | Value |
|---|---|
| our v4 on AMS-IX BKK LAN | `103.100.140.31` |
| our v6 | `2402:b740:15:388:a500:14:2108:1` |
| RS1 / RS2 v4 | `103.100.140.251` / `103.100.140.252` — **AS150388** |
| RS1 / RS2 v6 | `2402:b740:15:388:a500:15:388:251` / `:252` |
| HE (AS6939) v4 / v6 | `103.100.140.44` / `2402:b740:15:388:0:a500:6939:1` |

### Known HGC values (existing circuits — NOT the Telehouse circuit)
| Circuit | v4 peer | v6 peer | ASN |
|---|---|---|---|
| HGC-SG-PRIMARY (bkk20) | `118.143.234.73` | `2403:5000:165:15::1` | 9304 |
| HGC-HK-BACKUP (bkk20) | `103.168.174.177` | `2407:9540:111:7::1` (local `::2`) | 142435 |
| bkk00 uplink VLANs | HGC-HK 2519, HGC-SG 2518, AMS-IX 3995 | | |

## 6. Blocking unknowns — provider-delivered, cannot be derived
These are service-delivery values. Building the config with guessed values is worthless, so
they are placeholders in the `.rsc` until confirmed:

1. **HGC Telehouse circuit** — VLAN ID, our p2p v4 + v6 addresses, their peer addresses, and
   which ASN terminates it (9304 HK vs 142435 SG). A new cross-connect gets new values; do
   **not** copy bkk00's 2519/2518.
2. **AMS-IX Bangkok at Telehouse** — is this a *new* port (AMS-IX issues a new peering-LAN
   IP) or does the existing `103.100.140.31` port relocate? Different addressing either way.
3. **Site IPv6 prefix size — RESOLVED 2026-08-29: /36 per site.** The old site announces
   `2401:a860:1000::/36`; Telehouse gets `2401:a860:2000::/36`. Rationale: the site
   numbering plan (`10xx`/`11xx` blocks at the old site — e.g. anycast `1181::` — and
   `2xxx` at Telehouse) does not fit inside a /40 (`x000`–`x0ff` only); a /36 covers
   `x000`–`xfff`. The earlier "/40 is the RPKI minimum" claim was wrong — the ROA is
   `2401:a860::/32 maxLength 40`, so any length down to /40 validates, /36 included.
   route6 IRR objects already exist for every /34–/40 carve, `2000::/36` included.
   (Historical: §2 drafted /48s, then /40 was instructed; both superseded by this.)

## 7. Fabric consequences of removing bkk10 from Bangkok
Already documented in `decommission-bkk10-bkk50.md` / `EXECUTE-bkk10-bkk50-removal.md`.
One correction to `current-infra-topology.md` found on 2026-08-21:

> **The "1G backup BGP" via bkk10 ether6/7/8 did not exist.** `bridge/port/print` on bkk10
> listed exactly one bridge port (`BKK00-LAG`). ether6/7/8 were not bridge members, had no
> L3, and passed **0 pps**. The documented host backup path for bkk06/07/08 had been dead.
> Disabling those ports changed nothing. Topology doc should be corrected.

Also: bkk10's 2×10G LAG to bkk60 carried **no L3 and was not bridged** — it received fabric
flooding (~259 kbps) and forwarded nowhere. Those two 10G ports were doing nothing.
