# Telehouse install — preflight (2026-08-26)

## STOP — resolve this first, it decides the whole trip

`docs/bkk10-newsite-edge-design.md` says:
> CID **PP9094730** — **NEW circuit (not a relocation)** … nothing carries over.
> VLAN id, p2p subnet and peer ASN are all unknown. Do **not** reuse bkk00's 2519/2518.

HGC on WhatsApp 2026-08-26 says:
> PEH8001158 will be relocated to Telehouse from STT, and 3 circuits
> (**PP9094730** / PAX9100173 / PP9094735) need relocated/reconfigured/downgraded …
> but **VLAN assignment for each circuit under NNI/HE will keep the same**

Both cannot be true.
- **NEW circuit** → new VLAN/p2p/ASN, and it can run in PARALLEL with STT → no outage.
- **RELOCATION** → values carry over, STT is cut, hard outage during the move.

Ask HGC, in writing, before travelling:
1. Is PP9094730 at Telehouse a **new** circuit or the **relocated** STT one?
2. If relocated — confirm the **VLAN id, our p2p v4+v6, their peer addresses, and
   which ASN terminates** (9304 HK vs 142435 SG). "Same VLAN" is not enough to build on.
3. Can the Telehouse circuit be delivered **before** STT is torn down, even briefly
   overlapping? ODF 27/28 are already reserved, so a short parallel window may be
   orderable as a new circuit rather than a move.
4. Fix the **v4 feed on the backup sessions** as part of this work, in writing.
   `HGC-SG-BACKUP` establishes but advertises **0 v4 prefixes** — so the backups
   are not backups. They are already reconfiguring these circuits; this is the moment.
5. Sequence the 4 circuits **separately**, not all at once.

## Order the cross-connect
HGC reserved **ODF ports 27/28**; LOA already sent. The XC must be ordered with the
**Telehouse** team. Until it exists, bkk06 stays offline at the new DC.

## Physical checklist
- [ ] **Optic**: SMF **LC/UPC, 10GBASE-LR class** for the bkk60 XC port. If the crate
      shipped DACs or SR multimode, the link will not come up. Verify before leaving.
- [ ] Console cable + USB serial (bkk10 recovery is console-only if the LAG fails)
- [ ] Site: Telehouse Rama 9, **Data Hall 122**, footprint **K-03L**, half rack, 3 kW
- [ ] On-site contact: Tommi Niemi. Requested RFS was 2026-08-27.

## Access prerequisites — both have bitten before
- [ ] **bkk60 must be manageable before it becomes the transit demarc.** It rejected
      the ansible key; root cause was an `/ip/service` **address allowlist**, not the
      key. Check `/ip/service/print detail`.
- [ ] **bkk10 mgmt must not depend solely on BKK60-LAG.** On 2026-08-21 that bond
      failed to come up after a reset and console was the only way in. Enable
      `vlan-filtering` from the console, never from the LAG-dependent session.

## Paste order
1. `00-recover-mgmt.rsc` — only if bkk10 was reset. Set a real password (CHANGEME).
2. `01-bkk10-edge.rsc` sections 1-6 — identity, loopback, bridge, filters, templates.
   Safe without provider values.
3. `02-bkk60-demarc.rsc` sections 1-2 — identity, verify XC port + optic.
4. **STOP.** Sections needing HGC values stay commented until confirmed.
5. Once HGC confirms: fill `<<<...>>>`, paste the VLAN/BGP block, then the shaper,
   then enable `vlan-filtering` from the console.

## Do not forget the shaper
400M committed / 500M burstable on a **10G** port. Without an egress queue just
under contract, the interface bursts at line rate into HGC's policer and TCP
throughput lands far below what you pay for. `/queue/simple` at ~480M.

## Known-good values to mirror (from live bkk20)
- ASN **142108**, router-id `10.155.255.10`, loopback `160.22.180.179/32`
- Origination: `160.22.180.0/23` (v4), `2401:a860::/32` (v6)
- Export limits: v4 max **/24**, v6 max **/40** (a /48 would be RPKI-invalid)
- Communities already reserved: `142108:16:10..14` (iBGP / HGC-SG / HGC-HK / BKNIX / AMSIX at bkk10)
