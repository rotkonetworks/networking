# Leaf public-IP asymmetric return — the "flapping" root cause (2026-08-08)

## Symptom
penumbra.rotko.net / ibc.rotko.net (and any container leaf public IP) accepted TCP
but the TLS handshake stalled — "you can ping it, but HTTP times out." Intermittent.

## Root cause
A container with a public leaf IP on `eth1` (the public bridge, vmbr2) but its
**default route on `eth0`** (internal fabric) answers a public request on eth1 but
sends the reply out eth0 → **asymmetric return** → upstream has no matching flow →
dropped. Combined with the edge MikroTik keeping a stale HW-offloaded FIB for the
leaf /32 (2026-08-05 incident), this presented as random "service down" / TLS stalls.

ICMP (ping) works because it's a single, stateless round trip; TCP/TLS stalls because
the return path must be symmetric.

## The fix (policy-based source routing per container)
On every container that owns a public leaf IP, force packets whose **source is the
public IP** out the public interface (`eth1`) via the host's vmbr2/RR gateway:

```
ip rule add from <PUBLIC_V4>/32 table eth2_table priority 200
ip rule add fwmark 2 table eth2_table priority 201
ip route replace default via <HOST_VMBR2_GW> dev eth1 table eth2_table
# IPv6 mirror:
ip -6 rule add from <PUBLIC_V6>/128 table eth2_table priority 200
ip -6 rule add fwmark 2 table eth2_table priority 201
ip -6 route replace default via <HOST_V6_GW> dev eth1 table eth2_table
```

- `eth2_table` = routing table id 200 (`/etc/iproute2/rt_tables` → `200 eth2_table`).
- `<HOST_VMBR2_GW>` = the host's UNIFIED/RR address on vmbr2: bkk06=`10.155.100.6`,
  bkk07=`10.155.100.7`, bkk08=`10.155.100.8` (v6: `fd00:155:100::<idx>`).
- Reference impl: `penumbra-01/02 /etc/network/if-up.d/p2p-routing` (was ansible role
  `roles/setup_networking_p2p`, now unmaintained — treat this doc as the source).

## Why it was "fine before" then "flapped"
The routing script existed on most containers, but after bkk07's 2026-08-05 reboot +
RouterOS 7.22→7.23 upgrade + the overbroad-prefix/ARP incident, some containers came
back without the runtime rule applied (script present but rule not active), so their
public IP answered asymmetrically. Re-applying the rule restores symmetry.

## Verify a container is correct
```
ip rule show | grep eth2_table          # must show: from <PUBLIC_V4> lookup eth2_table
ip route show table eth2_table          # must show: default via <host gw> dev eth1
ip route get 1.1.1.1 from <PUBLIC_V4>   # must go via dev eth1 (public), NOT eth0
```

## Related
- 2026-08-05 incidents: `docs/2026-08-05_overbroad-prefixes-and-arp-blackholes.md`,
  `deploy/fixups/2026-08-05_svc-fib-watchdog.*.rsc` (edge stale-FIB).
- Edge routers: ensure NO IPv4 conntrack/NAT on edge (bkk00 leftover TEMP NAT removed
  2026-08-08). Conntrack on an asymmetric-routing edge drops return traffic.

## TODO / longer-term
- Move the internal mgmt VLAN off 192.168.0.0/16 (it overlaps bkk50's mgmt and is
  double-used); plan a dedicated `10.181.0.0/16` carve-up. Separate task (needs IPMI +
  a window) — do NOT conflate with this public-IP fix.
