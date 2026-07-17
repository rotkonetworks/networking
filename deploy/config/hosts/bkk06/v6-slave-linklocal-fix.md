# bkk06 (and bkk08) IPv6 slave-link-local fix

## Problem
bkk06's `bond-bgp` is active-backup over QinQ vlans on physical NICs. The physical slave
`enp193s0f1np1` (and its `.400` child `enp.400`) auto-generate an EUI-64 link-local from the slave
MAC (`b4:96:91:b3:af:a3` -> `fe80::b696:91ff:feb3:afa3`). BIRD can pick that slave LL as the v6 BGP
next-hop, but L2 frames egress with the **bond** MAC (`3c:ec:ef:73:2e:e8`). The upstream MikroTik
(bkk00) then cannot ND-resolve the advertised next-hop on `qnq-400-100` -> the route to
`2401:a860:1006::/48` is installed but dead -> all return v6 traffic dropped (egress-only symptom).

bkk00 *does* resolve the bond LL `fe80::3eec:efff:fe73:2ee8` -> `3C:EC:EF:73:2E:E8`. The fix is to
make sure only the bond/`vmbr2` link-local exists, so BIRD can only advertise the resolvable one.

## Live fix already applied (2026-07-17) — NOT reboot-durable
`systemctl restart bird` on bkk06 made BIRD recompute the next-hop off `vmbr2` and re-advertise the
bond LL. Verified working (inbound + egress). But the stale slave LL still exists, so a reboot can
reintroduce the bug.

## Durable fix (apply in a maintenance window)
Suppress link-local generation on the slave interfaces so only `vmbr2`/`bond-bgp` carries one.
In `/etc/network/interfaces`, add to the slave stanzas (ifupdown, Proxmox):

```
iface enp193s0f1np1 inet manual
    post-up ip link set dev enp193s0f1np1 addrgenmode none

auto enp.400
iface enp.400 inet manual
    vlan-raw-device enp193s0f1np1
    post-up ip link set dev enp.400 addrgenmode none
```

`addrgenmode none` stops the kernel generating an EUI-64 link-local; it does NOT disable the v6
stack (frames still pass up through the bond to `vmbr2`, which keeps its LL). Prefer this over
`disable_ipv6=1`.

Apply live without a full network restart:
```
ip -6 addr flush dev enp.400 scope link
ip -6 addr flush dev enp193s0f1np1 scope link
ip link set dev enp193s0f1np1 addrgenmode none
ip link set dev enp.400 addrgenmode none
systemctl restart bird        # v6 sessions only flap; v4/SSH stays up
```
Verify: bkk00 `/ipv6/route/print where dst-address="2401:a860:1006::/48"` shows gateway
`fe80::3eec:efff:fe73:2ee8`, and v6 egress from bkk06 gets replies.

WARNING: bkk06 is the fleet SSH jump (160.22.181.181) + RPC haproxy. Do NOT do incremental live LL
surgery (removing the LL + `birdc reload out` leaves bkk00's cache stale, and `birdc restart RRx_v6`
wedges the v6 sessions in Idle). A full `systemctl restart bird` is what cleanly re-derives the
next-hop. Keep a dead-man auto-revert armed.

## bkk08 has the same latent artifact
bkk00's neighbor table shows an unresolved slave LL `fe80::b696:91ff:feb3:b0ad` (MAC `...b3:b0:ad`)
on `qnq-400-100`, likely bkk08's. Not affecting bkk08 today (its active v6 route is via bkk20 /
BKK20-LAG), but apply the same `addrgenmode none` suppression on bkk08's bond slaves so a path shift
can't trigger it. bkk07 is fine (its bond LL == what it advertises).
