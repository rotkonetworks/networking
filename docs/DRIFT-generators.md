# Generator drift — bkk07 / bkk08 (found 2026-08-14)

`deploy/bird/gencfg.sh` and `deploy/nftables/gencfg.sh` no longer reproduce what
is running on bkk07 and bkk08. **Do not deploy their output to those hosts** until
this is reconciled — both would cause an outage.

Found while adding the four `neobits-val-0X` public IPs (`.212`–`.215`) to
`services.json`. The `services.json` change itself is correct and committed; only
the *deployment* of regenerated config is blocked.

## bird — would break BGP entirely

Live has four "UNIFIED" sessions to the route reflectors carrying an explicit
per-session local AS:

```
description "Route Reflector 1 - bkk00 IPv4 UNIFIED (eBGP)";
local as 4200000007;                     # 4200000008 on bkk08
```

The generator emits the pre-migration iBGP-RR form with no `local as`. Deploying it
drops that line from all four sessions, they fail to establish, and the host stops
announcing **every** prefix it originates — including the paid RPC and validator
services. This is the eBGP-to-host migration described in
`docs/2026-08-08_ebgp-to-host-simplification-design.md`; the hosts were migrated,
the generator was not.

## nftables — would delete live rules

Per-guest public IPs do **not** appear in nftables at all (verified: neither the
new `.212`–`.215` nor the existing `.209`/`.210` are referenced), so nothing here
is needed for public guests. But regenerating drops rules that only exist on the
hosts:

| Host | Would be deleted |
|------|------------------|
| bkk07 | `DMZ_NET` define + `vmbr-dmz` egress accept (CI runners lose internet); paseo DNAT `33342`; `udp dport 443`; guest ports `33957,33967,34031,34042,34052,34071` |
| bkk08 | v6 SMTP egress blocks + `vmbr1` ssh accepts on `2401:a860:1008::/48`; `passet-hub-paseo` and `collectives-paseo` DNATs; guest ports `34032,34072` |

## What a public guest actually needs

Only bird. The `/32` is announced via a `route VM_IP4_N unreachable;` static plus a
matching `if net = VM_IP4_N then accept;` in each session's export filter. Traffic
then reaches the container over the `10.155.100.<host>` p2p link and the container's
`/etc/network/if-up.d/p2p-routing` source-policy table. nftables is not involved.

## To reconcile

1. Teach `bird/gencfg.sh` the unified-eBGP session form (`local as` from
   `network.json`), regenerate, and confirm a zero-diff against live before deploying.
2. Fold the host-only nftables rules above back into `services.json` /
   `network.json` so they survive regeneration.
3. Refresh `IPAM-160.22.181.md` — it is from 2026-08-04 and lists `.207`, `.209`,
   `.210`, `.211` as free when all four are in use.

Until then, changes to these two hosts are hand-applied and recorded here.
