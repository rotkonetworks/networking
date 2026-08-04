# New-DC onsite runbook — rack, route, cable, verify

Goal: one well-prepared trip. Everything the DC visit must achieve is: **connectivity up (HGC BGP)
+ out-of-band management reachable** — so all remaining work (OS, sync, migrations) is remote.
Design already settled: single RouterOS edge (HGC transit + unnumbered fabric), a data switch,
a management/IPMI switch, seed compute.

## A. BEFORE you go (do NOT skip — this makes it cable-and-power)
### Coordinate with HGC (lead time!) — you cannot BGP without this
- [ ] Cross-connect ordered + demarc location/port known
- [ ] Handoff media/optic confirmed (1G/10G? LC fiber? which SFP do you bring)
- [ ] Their **/30 or /31** peer addressing + **VLAN tag** (if any) for the session
- [ ] Peer ASN (9304) + their neighbor IP + your assigned IP; max-prefix/policy expectations
- [ ] Your prefix announcement pre-authorized (IRR/RPKI ROA covers 160.22.180.0/23 + 2401:a860::/32 from your ASN)

### Pre-config the gear (rack-and-go)
- [ ] **Edge router**: load the tested config — numbered eBGP to HGC (from the HGC handoff) +
      unnumbered fabric downlink (the proven `~/rotko/networking/newdc/routeros/` set:
      `/ipv6 nd add` + `/ipv6 nd prefix add prefix=none` + the bgp connection) + mgmt/SSH ACL that
      includes your remote source so you can get back in.
- [ ] **Data switch**: config for the fabric downlinks (unnumbered to edge; numbered legs for BIRD hosts).
- [ ] **Mgmt/IPMI switch**: mirror bkk60's role — one port per node's BMC + one per mgmt NIC; an uplink
      + OVPN/mgmt path so you can reach IPMI remotely afterward. (Use a SPARE, keep bkk60 in the old rack.)
- [ ] Print a **port map** (which cable → which port) and label both ends of every cable.

### Pack
- [ ] Pre-configured edge router, data switch, mgmt switch, seed compute host
- [ ] SFP/optics matching HGC handoff + fabric; patch cables (fiber + copper), spares
- [ ] MikroTik serial console cable (RJ45→USB) + laptop; PDU/power cables; labels; a phone hotspot
- [ ] Rack rails/screws; the DC's access/security paperwork

## B. ONSITE sequence (order matters — OOB first)
1. **Rack + power the mgmt/IPMI switch.** Bring up its uplink → confirm you have OOB before anything else.
2. **Rack the edge router.** Console in, confirm config loaded. Connect to the **HGC cross-connect**.
   - Bring the link up; verify the **eBGP session to HGC establishes** and you **receive routes**.
3. **Rack the data switch.** Cable **edge ↔ switch** (the unnumbered fabric link). Verify the
   unnumbered eBGP session comes up (`/routing/bgp/session/print` → established, `enhe`).
4. **Rack the seed compute host.** Two cables: **data** → data switch, **IPMI + mgmt NIC** → mgmt switch.
5. Power on; give each node's BMC a mgmt address (DHCP-relay like bkk60, or static).

## C. Routing / cabling map (what connects to what)
```
HGC cross-connect ──(numbered eBGP, /30, AS9304)── [EDGE router, AS142108]
                                                         │ unnumbered eBGP (RA + nd prefix=none)
                                                    [DATA switch, private ASN]
                                                     │ (numbered /127 legs — BIRD hosts)
                                                [compute / validator hosts]

[MGMT/IPMI switch] ── per node: BMC port + mgmt-NIC port ── every host   (OOB, + OVPN uplink)
```
- **Edge↔switch**: unnumbered (cable + the two ND lines). **Host legs**: numbered (BIRD can't do RFC5549).
- **Mgmt**: physically separate switch, one uplink out (OVPN/allow-listed SSH) for remote reach.

## D. VERIFY before you leave the building (the gate)
- [ ] HGC eBGP **established**, receiving full/default routes
- [ ] Your prefixes **visible from the outside** (check a looking glass / phone off the DC wifi)
- [ ] Unnumbered fabric session **established** (edge↔switch)
- [ ] **IPMI/BMC reachable remotely** for the seed host (power/console from your laptop over the mgmt path)
- [ ] Serial console access to router + switch confirmed (for recovery)
- [ ] Write down: rack/U positions, port map as-built, HGC handoff details, all mgmt IPs

If **HGC BGP up + IPMI reachable remotely** are both ✅, you can leave — the rest is remote.

## E. After the trip (remote)
- Sync data (per the migration runbook), migrate services in waves, **Flare reward stack last**,
  decommission old rack only after ≥1–2 clean reward epochs.

## Notes
- **bkk60** is the current OOB hub (every node's IPMI + mgmt, DHCP-relay + OVPN + mgmt routing at
  192.168.88.1). SSH ACL = `172.104.169.64/32,158.140.0.0/16`. Don't move bkk60 itself first —
  new DC gets a spare mgmt switch; bkk60 stays until the old rack is decommissioned.
- Don't move both edges: relocate one CCR2216; keep the other + bkk50 (fallback) running the old rack.
