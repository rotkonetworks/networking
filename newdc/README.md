# new-DC fabric — unnumbered eBGP (single-edge, redundancy-ready)

Runnable containerlab that validates the new-DC network **before any hardware is racked**
(the "every change goes through a lab before it touches a real port" rule). Built on the
pattern from `github.com/rotkonetworks/unnumbered-bgp` / niemi.lol/blog/unnumbered-bgp.

## Topology
```
[transit1 AS64500]  ── numbered eBGP (the ONE cross-connect) ──  [edge1 AS142108]
                                                                       │ unnumbered eBGP
                                                                  [sw1 AS65100]  (spine)
                                                                   │        │  unnumbered eBGP
                                                              [h1 65110] [h2 65111]  (Proxmox leaves)
```
Interior links carry **no addresses and no /31s** — FRR peers over IPv6 link-local, IPv4 rides
an IPv6 next-hop (RFC 5549/8950). Only the cross-connect (transit) is numbered.

## ASN plan (redundancy-ready)
| Role | ASN | Notes |
|---|---|---|
| Edge (public face) | **142108** | edge1 now; edge2 later shares this AS + one unnumbered iBGP link |
| Spine / ToR | 65100 | sw2 = 65101 for dual-ToR later |
| Host leaves | 65110, 65111, … | per Proxmox host |
| Upstream (lab stub) | 64500 | real upstream ASN at turn-up |

## Run it
```sh
cd ~/rotko/networking/newdc
sudo clab deploy -t rotko-newdc.clab.yml
# verify the fabric
docker exec clab-rotko-newdc-edge1 vtysh -c 'show bgp summary'      # eth2 (sw1) + transit up
docker exec clab-rotko-newdc-h1    vtysh -c 'show ip route 0.0.0.0/0'  # default via IPv6 next-hop (RFC5549)
docker exec clab-rotko-newdc-edge1 vtysh -c 'show bgp ipv4 unicast 203.0.113.10/32'  # host route learned
sudo clab destroy -t rotko-newdc.clab.yml
```
What proves it works: `h1`'s service /32 (`203.0.113.10/32`) appears at `edge1` and is announced
to `transit1`, and `h1` has a default route whose next-hop is an `fe80::` address on an
**unnumbered** link. That's IPv4-over-IPv6-nexthop end to end.

## Grow to redundancy (all additive — no renumbering)
- **2nd cross-connect:** add a numbered transit neighbor on edge1 (or edge2).
- **2nd edge (full HA):** rack edge2 (AS142108), uncomment the `edge1:eth3 <-> edge2:eth3`
  link + the `neighbor eth3 interface remote-as 142108` iBGP block. One iBGP session, no RR.
- **2nd ToR:** rack sw2 (AS65101); hosts add `neighbor eth2 interface remote-as external`.
- **Another host:** new node + ASN + one `neighbor ethN interface` line.

## Before production
- Swap lab prefixes `203.0.113.0/24` + `2001:db8::/44` → the assigned new-DC `/24` + `2401:a860::/…`.
- Port the full **MANRS/RPKI/bogon** hardening + communities from the reference edge
  (`unnumbered-bgp/configs/vyos/vyos1.conf`) onto `edge1.conf` — kept minimal here to focus the
  fabric test.
- Known lab caveat (from your blog): cEOS/BFD-on-numbered quirks don't apply here (all-FRR lab);
  on real Arista/Mikrotik spine, re-check BFD on the numbered transit leg.
