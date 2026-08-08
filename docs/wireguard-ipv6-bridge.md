# WireGuard IPv6 bridge — v4-only home → Rotko → HE 10G egress (scenario A)

Goal: a v4-only home gets real, routed IPv6 (GUA from 2401:a860::/32),
egressing via Rotko's HE 10G. **No NAT64, no DNS64, no nat64rs** — this
is plain WireGuard carrying IPv6 over a v4 underlay, plus routing. Home
stays dual-stack (ISP v4 local + tunnelled v6).

## Architecture decision: single-node termination, NOT anycast

WireGuard is stateful (per-peer session/handshake). **Do not anycast the
WG endpoint across bkk06/07/08** — packets must always reach the node
holding the session. Anycast is for the stateless haproxy tier only.

- Terminate WG on ONE node. Recommended: a small VM/CT on **bkk07**
  (Proxmox already; matches the services-on-bkk0x pattern).
- That node needs a **public IPv4** the home can reach (the v4 underlay).
- Egress is independent of termination: the home /64 is routed to the
  WG node internally; its v6 traffic egresses the normal path
  (WG node → RouterOS edge → HE 10G). It is your own GUA over your own
  transit — no NAT, just routing.
- Redundancy (optional, later): active/standby — home has a primary
  Endpoint + failover; ~seconds of re-handshake on failover. NOT ECMP.

## Decisions to fill before deploying

- [ ] WG node + its public IPv4  (e.g. bkk07 VM, <rotko-pub-v4>)
- [ ] Home prefix: a /64 (one LAN) or /56 (subnettable) from 2401:a860::/32
- [ ] WG link /64 (small, separate from the home prefix)
- [ ] Home router OS (Linux/OpenWrt/RouterOS) — client syntax below is wg-quick

## Rotko WG node  /etc/wireguard/wg0.conf

    [Interface]
    Address    = 2401:a860:<wglink>::1/64
    ListenPort = 51820
    PrivateKey = <server-priv>
    PostUp = sysctl -wq net.ipv6.conf.all.forwarding=1
    PostUp = ip -6 route add 2401:a860:<home>::/64 dev wg0

    [Peer]                                  # home
    PublicKey  = <home-pub>
    AllowedIPs = 2401:a860:<home>::/64

Internally: route 2401:a860:<home>::/64 to this node (static/IGP), let it
egress via the existing v6 default to HE 10G. It's within the
2401:a860::/32 your ASN already originates, so the internet side is
automatic — you only wire the internal route. No NAT.

## Home router  /etc/wireguard/wg0.conf

    [Interface]
    Address = 2401:a860:<wglink>::2/64
    PrivateKey = <home-priv>
    MTU = 1420                              # 1500 underlay − WG overhead

    [Peer]                                  # Rotko
    PublicKey  = <server-pub>
    Endpoint   = <rotko-pub-v4>:51820
    AllowedIPs = ::/0                       # IPv6 only out the tunnel
    PersistentKeepalive = 25                # behind home v4 NAT

`AllowedIPs = ::/0` ONLY (not 0.0.0.0/0): local v4 stays on the ISP.

Home LAN: assign from 2401:a860:<home>::/64, run radvd / RouterOS ND
advertising that /64 + default route, forward LAN v6 → wg0.

## The two things that bite

1. MTU/MSS: MTU=1420 on wg0 AND clamp TCPv6 MSS on the home router:
   ip6tables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
     -j TCPMSS --clamp-mss-to-pmtu   (or nft / RouterOS mangle change-mss)
   Without this, large HTTPS pages silently black-hole via PMTU.
2. Return path: the home /64 must be routed to the WG node inside Rotko.
   Internet side is automatic (covered by the originated /32).

## Validation

From a home LAN device: `ping6 2606:4700:4700::1111`,
`curl -6 https://ifconfig.co` → should show a 2401:a860:: address.
`traceroute6` → egresses HE 10G, not the home ISP.

Status: design complete. Remaining is operator config on the chosen
WG node + home router (decisions above) — not software work.

## Concrete Rotko grounding (from this repo, not placeholders)

Egress reality (correcting "HE 10G"): transit is **HGC** — HK
AS9304 primary, SG AS142435 backup. BKNIX is IX peering (HE is a
peer there). You originate **2401:a860::/32**, so any /64 you carve
is internet-reachable to your AS automatically.

Terminate WG on **bkk07** (Proxmox; eBGP/iBGP node):
- WG `Endpoint` for the home = a **globally-reachable public v4 via
  transit**. Use an HGC-HK /29 address on bkk07 — the table gives
  `118.143.211.188/29` (6 usable, 1 used). A home on an arbitrary
  v4 ISP reaches that via HGC transit. (203.159.68.170 is the
  BKNIX/peering-facing v4 — reachability from random homes depends
  on peer propagation; prefer the transit IP for the endpoint.)
- Run WG in a CT/VM on bkk07; bind it to that public v4 (or forward
  51820/udp from the host to the WG CT).

Home prefix: a /64 (or /56) from **2401:a860::/32**. There is no
existing customer/delegation block in the repo's allocation table
(it lists server infra only: 2401:a860:10NN:: per node). **Action:
allocate a dedicated remote/WG delegation block in IPAM** (e.g. a
/48 or /56 reserved for tunnelled sites) and assign the home a /64
from it — do not reuse a node's 2401:a860:10NN:: range.

Internal routing/egress (fits the v2 iBGP-mesh/RR design):
- bkk07 originates the home /64 into BIRD (a `protocol static`
  exported to the iBGP mesh / RR), next-hop = the WG node — exactly
  the mechanism used for anycast prefixes, but a normal /64, not
  anycast (single-homed; WG is stateful).
- Return v6 from the internet enters via HGC transit on whichever
  bkk node, iBGP carries it to bkk07, out the WG tunnel.
- Home→internet v6 egresses bkk07's eBGP (HGC-HK primary). All
  native GUA within the originated /32 — no NAT, no NAT64, no DNS64.

Status: design + Rotko grounding complete. Remaining is purely
operator execution on bkk07 (WG CT + BIRD static export) and the
home router, plus the IPAM allocation decision. No software work,
and nothing of this is doable from the nat64rs dev box.

## IXP-not-HGC path policy (corrected, honest placement)

CORRECTION: backup/bird/bkk07.conf is iBGP-to-RR only — it has NO
BKNIX/AMSIX eBGP. External eBGP (HGC + BKNIX + AMSIX-BAN) is on the
RouterOS edge today; moving it to bkk0x is ebgp-edge-migration-plan,
not done. So the IXP-preference change goes on RouterOS NOW (bkk0x
post-migration, where LOCAL_PREF_PRIMARY/BACKUP scaffolding exists).

Hard fact: WG endpoint MUST be v4 (home is v4-only). Use a
Rotko-originated v4 (e.g. bkk07 160.22.181.7). You cannot force a
remote home's INBOUND path to an IXP — that's the home ISP's BGP
decision; you only influence it by advertising your space to the
IXPs.

What IS controllable = egress/return + advertisement, at the eBGP
edge (RouterOS today):
- Advertise the home /64 (or the originated 2401:a860:: aggregate)
  to BKNIX-v6 and AMSIX-BAN-v6 sessions.
- For that prefix's outbound: raise local-pref on BKNIX/AMSIX,
  leave HGC-HK at backup → home v6 egress + return ride the IXPs,
  HGC only on failover. No HGC transit burned for the tunnel.
- IPv4 underlay for the WG endpoint still rides whatever path the
  home ISP picks — accept this; it's not controllable for an
  arbitrary remote home and does not affect the v6 egress goal.

Owner: network team / RouterOS edge config. Not software, not
nat64rs, not doable from the dev box. Get the tunnel up on the
Rotko v4 endpoint first ("one way or another"); apply the IXP
egress-preference as the immediately-following policy step.
