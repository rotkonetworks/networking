# bkk09 / bkk11 / bkk13 — Proxmox rebuild + OOB mgmt (2026-08-27)

Moving to the new DC **tomorrow**. The XC is not in yet, so anything that lands
at Telehouse is dark on arrival — bkk02, bkk12 and bkk06 already are. **At least
one of these three must come up on 4G, or the new site has no remote access at
all** and every fix becomes a site visit.

## Current state (measured 2026-08-27)

| host | state | access |
|---|---|---|
| **bkk11** | **Arch Linux**, no Proxmox, **no guests**, 2x Samsung 980 PRO 2TB NVMe | SSH works (`160.22.181.181:22801`) |
| **bkk13** | powered, SSH answering on `160.22.181.181:22803` | **no key works** — 8 tried, all denied. Console only. |
| **bkk09** | **not responding** — no ping, no :2209 from bkk08 | dead or path lost. Physical check. |

All three reach the world through **bkk50 NAT**, which is being decommissioned —
so they lose their path even if they stayed. 4G is the fix, not a workaround.

**bkk11 is the best OOB candidate**: reachable now, nothing running on it, and
two 2TB NVMe. Cleanest to prove *before* it moves.

## Target version
Fleet runs **PVE 9.2.9** (bkk07) and 9.2.6 (bkk03, bkk08). Install latest 9.x.

## Installer choices (all three)
- **Filesystem: `zfs (RAID1)`** across the two NVMe. Mirrored so a single disk
  failure doesn't strand a box that is now hard to physically reach.
- **FQDN**: `bkkNN.rotko.net`
- **Management IP**: DO NOT rely on the old `192.168.69.x`/bkk50 NAT — it is going
  away. Give it the 4G/OOB path (below) as its real route.
- Set a **strong root password** and keep it in the vault: with bkk50 gone, a
  console password may be the only way in before WireGuard is up.

## Order of work — do bkk11 FIRST and prove it
1. Install PVE on **bkk11** while it is still on-net in the old rack.
2. Run `10-postinstall.sh` (repos, keys, identity, WG mesh).
3. Attach the 4G modem, run `20-oob-4g.sh`, and **prove you can reach it from
   outside over 4G with the rack uplink unplugged.** If it only works while the
   rack is up, it is not out-of-band and the whole exercise failed.
4. Only then rebuild bkk13 and bkk09.

Do not move all three before one is proven. A box that fails to dial home from
Telehouse is unrecoverable without another site visit.

## Console duty must move here
Serial consoles currently live on **bkk06** (already at Telehouse, dark) and
**bkk03** (holds val-polkadot-01 + val-kusama-03). bkk10 and bkk60 have already
been console-only once. Put USB serial adapters on the OOB box and move that
role onto it — that is the single biggest reason this machine earns its slot.

## Before wiping
- **bkk13 is undocumented** — not in `current-infra-topology.md` or IPAM. "Spare"
  is an assumption. Look at the disks from the installer shell before you commit.
- **bkk09** — find out why it is dark before deciding it is disposable.
