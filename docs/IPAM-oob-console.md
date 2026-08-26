# Out-of-band console map — 192.168.69.0/24

**Captured 2026-08-27 from bkk50's DHCP lease table, because that is currently the
only place this mapping exists — and bkk50 is being decommissioned.** Losing it
means losing the address of every IPMI and KVM device we own.

Source: `/ip dhcp-server lease print detail` on bkk50, cross-checked against
`ip neigh` from bkk08 and `ipmitool lan print 1` on bkk11.

## IPMI / BMC

| Addr | Host | MAC | Vendor | Verified |
|---|---|---|---|---|
| `192.168.69.215` | **bkk12** ipmi | `9C:6B:00:9F:F5:57` | ASRock | lease comment |
| `192.168.69.216` | **bkk13** ipmi | `9C:6B:00:84:CF:63` | ASRock | lease + :443 open |
| `192.168.69.217` | **bkk11** ipmi | `9C:6B:00:84:CF:85` | ASRock | **confirmed via ipmitool on bkk11** |
| `192.168.69.220` | **bkk08** ipmi | `3C:EC:EF:73:30:8B` | Supermicro | lease + :443 open |
| `192.168.69.221` | **bkk03** ipmi | `9C:6B:00:1C:E3:A1` | ASRock | lease + :443 open |
| `192.168.69.227` | **bkk07** ipmi | `3C:EC:EF:E3:5C:BF` | Supermicro | lease + :443 open |

BMC addresses are **DHCP**, not static — if bkk50's DHCP goes away before these
are pinned, the BMCs may not come back on the same addresses. Pin them to static
(or recreate the reservations on whatever replaces bkk50) BEFORE retiring it.

## Standalone KVM devices

| Addr | Device | MAC | Notes |
|---|---|---|---|
| `192.168.69.232` | **bkk09 NanoKVM** | `48:DA:35:6F:6B:66` | web KVM on **port 80** |
| `192.168.69.231` | **BliKVM** (Raspberry Pi) | `E4:5F:01:DE:47:96` | host-name `blikvm` |

Both stopped answering from bkk08 on 2026-08-27 — they moved to the new site
with bkk09.

## Host management addresses

| Addr | Host | MAC | Notes |
|---|---|---|---|
| `192.168.69.201` | bkk11 host | `9C:6B:00:84:CD:B4` | Arch Linux; also held `.214` as `archiso` |
| `192.168.69.212` | bkk13 host | `3E:80:02:B7:1E:5A` | bridge MAC — it is a hypervisor |
| `192.168.69.218` | bkk08 host | `3C:EC:EF:73:2F:7B` | |
| `192.168.69.223` / `.230` | bkk09 host | `58:47:CA:78:CD:48` | lease DISABLED, last seen 30w |
| `192.168.69.103` | bkk03 host | | from topology doc |

## bkk13 guest VMs — DORMANT, treat the disks as key-bearing

| Addr | VM | MAC | Last DHCP |
|---|---|---|---|
| `192.168.69.210` | `val-paseo-bkk13-01` | `52:54:00:DD:41:AE` | 7w2d |
| `192.168.69.219` | `val-paseo-bkk13-02` | `52:54:00:DD:1E:D8` | 7w2d |
| `192.168.69.222` | `val-kusama-bkk13-01` (host-name `val-kusama-04`) | `52:54:00:96:39:9C` | 3w3d |

`52:54:00` = QEMU. All three probed **down** (no p2p/RPC/metrics ports answering)
and their leases are weeks stale — but **down is not safe-to-erase**:

1. Confirm via `virsh list --all` from inside bkk13 that they are intentionally
   shut off, not a crashed active validator.
2. **Treat the disks as key-bearing.** If `val-kusama-04` is a warm backup of an
   active Kusama validator, its disk may hold a copy of that validator's session
   keys. Powering it on while the active one runs = equivocation = slashing.
   Same failure mode as the penumbra key duplicated on bkk06
   (see the penumbra double-sign note).

## Legacy access path — dies with bkk50

bkk50 DNATs `160.22.181.181:228xx` to these hosts:

| Port | → |
|---|---|
| `22801` | `192.168.69.201` (bkk11) |
| `22802` | `192.168.69.202` |
| `22803` | `192.168.69.212` (bkk13) |

`~/.ssh/config` still points bkk11/bkk13 at those NAT ports. **They break when
bkk50 goes.** Repoint to the mgmt addresses via a jump host:

```
Host bkk13
    HostName 192.168.69.212
    User root
    ProxyJump bkk08
```

Note the jump host itself (bkk08) is on the move list — this path is temporary.

`192.168.69.202` is live in bkk50's NAT table and **unidentified**. Work out what
it is before bkk50 is retired.
