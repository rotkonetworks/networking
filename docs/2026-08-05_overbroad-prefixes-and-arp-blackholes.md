# Over-broad prefixes → ARP instead of routing (2026-08-05)

Three separate outages today shared **one root cause**: an interface configured with a
prefix far wider than its actual L2 segment. The host then believes every address in
that range is directly connected, **ARPs for it instead of routing to it**, and
blackholes anything that isn't literally on the wire.

This is worth internalising because it presents as "the network is broken" when
routing, BGP and the fabric are all perfectly healthy. `ping` to the gateway works,
adjacencies are Full, routes are in the RIB — and traffic still dies.

## Symptom signature

Look for **ARP entries for addresses that should never be link-local**:

```
/ip/arp/print                       # RouterOS
ip neigh show                       # Linux
```

If you see public internet addresses, or hosts you know live behind a router, in the
ARP table as `failed` / `incomplete`, you have this bug. Example from bkk50 today:

```
103.67.246.128   BKK20-LAG  failed        <-- ARPing for an internet host
185.234.65.237   BKK20-LAG  failed
112.208.66.220   BKK20-LAG  incomplete
```

## Instance 1 — bkk50 default route was interface-form (CAUSED A FULL MGMT OUTAGE)

```
0.0.0.0/0  gateway=BKK20-LAG   distance=220   ECMP
0.0.0.0/0  gateway=BKK00-LAG   distance=220   ECMP
```

An **interface** as gateway with no next-hop IP. This only works if the upstream
proxy-ARPs for every destination on earth. It survived for months because it did, then
both uplink routers (bkk00, bkk20) rebooted for the RouterOS 7.22→7.23 upgrade and
bkk50 lost the ability to resolve anything.

bkk50 is `160.22.181.181` — the NAT/jump host — so this took out SSH to bkk03, bkk06,
bkk07, bkk08 and everything behind it. bkk50 itself was up the whole time and its iBGP
to bkk00 stayed established, which made it look like a routing problem when it was an
addressing problem.

**Fix applied** (next-hop form, kept the old routes in place at distance 220):

```
/ip/route/add dst-address=0.0.0.0/0 gateway=172.16.10.1 distance=10   ;# via bkk00
/ip/route/add dst-address=0.0.0.0/0 gateway=172.16.20.1 distance=11   ;# via bkk20
```

**TODO:** bkk00 is being retired — swap the distances so bkk20 is preferred (10/11) and
delete the two interface-form routes entirely. A `pct`-style config export should never
contain `gateway=<interface>` for a default route.

## Instance 2 — Prometheus guest 996 had /16 on its container NIC

Guest `996` (`ibp.rotko.net`, the Prometheus scraper) on bkk07:

```
net1: ... ip=10.7.77.97/16       <-- claims ALL of 10.7.0.0/16
  → 10.7.0.0/16 dev eth1 proto kernel scope link
  → route to 10.7.111.35 resolves to "dev eth1", ARPs, dies
```

Its siblings on the same host and subnet (`991 haproxy-bkk07`, `992 dockers`) have **no**
10.7 interface, so they route via `192.168.69.1` and worked fine throughout. That
asymmetry is the tell.

Result: `InstanceDown` / `ReviveRpcInstanceDown` alerts for
`rpc-hydration-polkadot-01` and `rpc-asset-hub-kusama-02` — while the nodes themselves
were completely healthy (25 peers, importing blocks, ports listening, reachable from
every other vantage point).

**/24 WAS NOT ENOUGH.** First attempt narrowed eth1 to `/24`, which fixed targets in
*other* subnets but left `10.7.77.0/24` link-local — so `10.7.77.82` (penumbra-02) still
took the broken direct path and still failed. The direct vmbr1 path is unreliable for
TCP **regardless of prefix**: ICMP succeeds, ARP resolves to the correct MAC, TCP dies.

**The rule that actually works: on a dual-homed guest, eth1 must not be used for L3 at
all.** Everything routes via the eth0 gateway. Expressed as `/32`, so nothing is ever
link-local on eth1 by construction:

```
pct set 996 --net1 name=eth1,bridge=vmbr1,hwaddr=BC:24:11:3F:DF:2C,ip=10.7.77.97/32,type=veth
pct set 988 --net1 name=eth1,bridge=vmbr1,hwaddr=BC:24:11:FA:51:78,ip=10.8.78.97/32,type=veth
```

Runtime correction until the guests next restart (note the guest's OWN segment is
included — that is the part the /24 attempt missed):

```
# 996 (bkk07)
ip route replace 10.7.77.0/24  via 192.168.69.1 dev eth0    # <- its own segment
ip route replace 10.7.111.0/24 via 192.168.69.1 dev eth0
ip route replace 10.7.122.0/24 via 192.168.69.1 dev eth0
ip route replace 10.8.112.0/24 via 192.168.69.1 dev eth0
# 988 (bkk08)
ip route replace 10.8.0.0/24   via 192.168.69.1 dev eth0
ip route replace 10.8.78.0/24  via 192.168.69.1 dev eth0    # <- its own segment
ip route replace 10.8.112.0/24 via 192.168.69.1 dev eth0
```

Result: ibp-metrics 19/19 substrate targets UP; prometheus-rotko 22/30 (the 8 remaining
are stale targets for machines retired weeks ago, see below). All alerts cleared except
`Watchdog` on both instances.

**Why `/32` and not "remove eth1"?** Removing it is arguably cleaner — guests `991`
(haproxy-bkk07) and `992` (dockers) have no 10.x NIC at all and never exhibited this
fault. `/32` was chosen as the lower-risk change: it keeps the address for identity and
any inbound use, while guaranteeing no destination is ever considered link-local.

## Stale monitoring targets (prometheus-rotko) — prune these

Not faults, but they sit permanently DOWN and mask real alerts:

```
192.168.69.210  val-paseo-bkk13-01    DHCP last-seen 4 weeks ago
192.168.69.219  val-paseo-bkk13-02    DHCP last-seen 4 weeks ago
192.168.69.222  val-kusama-bkk13-01   powered off (also breaks the :32008 p2p forward)
192.168.69.202  bkk12                 not in active service
192.168.69.201  reachable, :7350/:7360 closed — live host, dead service, worth a look
vermon.rotko.net:443                  external
```

## Instance 3 — bkk50 NAT pointing at a powered-off VM (NOT this bug, but found alongside)

```
160.22.181.181:32008 → 192.168.69.222:32008
192.168.69.222 = val-kusama-bkk13-01 ("val-kusama-04"), DHCP lease WAITING, ARP INCOMPLETE
```

The validator VM that port forwards to is **not running**, which is why the p2p port
returns "no route to host" while bkk03's `:32006 → 192.168.223.10` works (that target
answers in 0.12 ms). Not CPU, not erasure chunks, not routing — the destination doesn't
exist right now.

**Not fixed** — needs `qm start` on bkk13, which rejects the `hq@rotko.net` key.
Note `192.168.69.x` is the **IPMI/BMC VLAN** (`bkk11 ipmi = .217`, `bkk03 ipmi = .221`),
so double-check whether pointing validator p2p into that range is intended at all.

## Known-good vs known-bad prefix inventory

| Where | Config | Verdict |
|---|---|---|
| bkk50 `bridge_local` | `192.168.69.1/16` | Ugly but **works** — all mgmt hosts are on one flat L2 |
| bkk06/07/08 mgmt | `192.168.76.1/16`, `.77.1/16`, `.69.218/16` | Same flat L2, verified reachable both ways |
| guest 996 `eth1` | `10.7.77.97/16` → **/24** | **Was broken**, fixed today |
| bkk50 default route | interface-form | **Was broken**, fixed today |

The `192.168.0.0/16` overlap across bkk50/bkk06/bkk07/bkk08 was investigated and is
**not** currently causing faults — they genuinely share one bridged L2 segment, so the
wide prefix is consistent with reality. It is still worth tightening, but it did not
cause any of today's outages.

## Unresolved: net.ipv4.ip_forward is inconsistent and unpersisted

```
bkk06  ip_forward=0     nothing in /etc/sysctl.conf or /etc/sysctl.d/
bkk07  ip_forward=0     nothing
bkk08  ip_forward=1     nothing
```

Nobody set this anywhere durable. It is currently **not** causing breakage — containers
are L2-bridged onto the fabric and the routers do the routing, so the hosts don't need
to forward. But three hosts disagreeing on an unpersisted kernel setting is a latent
trap during a reboot cycle.

**Recommended** (not applied — decide the intended value first, then pin it):

```
# /etc/sysctl.d/90-rotko-forwarding.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

Apply with `sysctl --system`. Do this deliberately, not mid-upgrade — flipping bkk06/07
from 0 to 1 changes forwarding behaviour on hosts currently serving traffic.

## Rules to prevent recurrence

1. **Never use an interface as a default-route gateway.** Always a next-hop IP.
   Interface-form only works while something upstream proxy-ARPs, and that is not a
   contract anyone is enforcing.
2. **A NIC's prefix must match its actual L2 segment.** If a guest has an address in a
   range whose other members live behind a router, it must be a /24 (or /32 + routes),
   never the aggregate.
3. **Check ARP first when "the network is broken" but BGP/OSPF look healthy.** Failed
   ARP entries for non-local addresses identify this class in seconds.
4. **Compare against a working sibling.** Guest 992 vs 996 on the same host and subnet
   isolated this immediately; chasing the fabric wasted far longer.
5. **Health checks: prefer L7.** Only `people-polkadot-backend` has
   `http-check expect rstring "isSyncing.*false"`. Everything else is L4-only, so a
   node that accepts TCP while serving errors reads as UP and then 503s at request
   time. That masked both the zcash and people-polkadot faults today.

## Related, same day

* `deploy/fixups/2026-08-05_amsix-eu-withdraw-and-v6-te.rsc` — AMS-IX Amsterdam
  withdrawal, IPv6 TE ordering bug, bkk20 default repoint. **Contains the BCP 214 /
  Hurricane hazard warning — read it before touching any shared OUT chain.**
* people-polkadot-01 wedged at `0.0 bps` with 10 peers for ~90 min after bkk07 went
  down for the Proxmox upgrade. Relay chain was reachable throughout (relay blocks kept
  arriving) — the parachain importer simply hung. `systemctl restart cumulus` cleared it
  and it caught up 1000+ blocks in seconds. **A parachain can hold peers, receive relay
  blocks, and still import nothing — watch `best:` advancing, not process liveness.**
