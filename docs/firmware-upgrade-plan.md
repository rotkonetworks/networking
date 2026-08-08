# RouterOS 7.23.3 fleet firmware-upgrade plan

Target: all MikroTik fabric devices → **RouterOS 7.23.3 (software) + routerboard firmware** to match.
Each device = **2 reboots** (RouterOS install, then `/system routerboard upgrade`).
Companion: `current-infra-topology.md` (blast-radius), `current-infra.clab.yml` (lab model).

## Devices
| Device | Model | Role | Now | Reachable | Notes |
|---|---|---|---|---|---|
| bkk00 | CCR2216 | edge / RR (HK) | 7.22 (7.23 staged) | net(10.155.255.4) + console(bkk06 ttyUSB1) | canary |
| bkk20 | CCR2216 | edge / RR (SG) | ? | ❌ key rejected, no console | **access first** |
| bkk10 | CCR2116 | core, L2 VLAN-400, no BGP | 7.22 | console(bkk03 ttyUSB1) | |
| bkk30 | CRS504-4XQ | 100G leaf (bkk06/07 primary) | ? | ❌ no access | **access first** |
| bkk40 | CRS504-4XQ | 100G leaf (bkk08 primary) | ? | ❌ no access | **access first** |
| bkk50 | CCR2004 | CGNAT + cluster/mgmt sw + leaf | 7.22 | net(192.168.69.1) + console(bkk03 ttyUSB0) | **highest risk** |
| bkk60 | CRS354 | mgmt access sw | 7.22 | console(bkk06 ttyUSB0, held by screen) | detach screen |

## Prerequisites (ALL before touching hardware)
1. **Close access gaps** — only upgrade what you can reach AND recover: get network creds/console for **bkk20, bkk30, bkk40**; detach the `screen` on bkk06 ttyUSB0 for **bkk60**. Do NOT upgrade a device you can't recover.
2. **Validate 7.23.3 in clab first** — load 7.23.3 CHR into `current-infra.clab.yml`, confirm configs boot + iBGP converges (the "lab before real port" rule).
3. **Stage the image offline** — download `routeros-7.23.3-arm64.npk` (CCR2216/2116/2004) + `-arm.npk` (CRS504/354) ONCE, upload to each device's file store. Pins the exact version, no per-box internet dependency mid-window.
4. **Per device pre-reboot:** `/export file=pre-723` + `/system backup save`, check `/system resource` free-hdd fits the npk, keep the 7.22 npk on-box for downgrade.

## Reboot blast radius (why the order matters)
- **bkk50** — bkk03's ONLY uplink + CGNAT + host mgmt gateway, AND **circular console dependency** (bkk50's console lives on bkk03, which loses its uplink when bkk50 reboots). If it fails to boot 7.23.3 → **no remote recovery, Netinstall onsite only.**
- **bkk40** — bkk08 (reward host + our network-jump) primary path; must fail to 1G backup (bkk10).
- **bkk30** — bkk06+bkk07 primary path → 1G backup (bkk10). bkk06 also serves bkk00/bkk60 consoles.
- **bkk10** — reboot drops host 1G *backup* + bkk60 uplink; hosts stay up on 100G primary; console via bkk03 survives.
- **bkk00** — dual-RR (bkk20 covers); only bkk12 (single-homed) blips; console via bkk06 survives.
- Console-server rule: **never reboot bkk03 or bkk06** while you need the consoles they serve.

## Upgrade order (safest → riskiest, ONE at a time, verify fully between)
1. **bkk00 — CANARY.** bkk20 covers RR, upgrade already staged, console safe. Proves 7.23.3 on CCR2216. Only bkk12 blips.
2. **bkk10.** Hosts keep 100G primary; bkk60 blips; console via bkk03 stays. Confirms CCR2116.
3. **bkk30.** First VERIFY bkk06/07 fail over to 1G backup when bkk30's uplink drops (they must stay reachable). Keep bkk06 up (console server).
4. **bkk40.** bkk08 fails to 1G backup — reward host + jump, so do it in a **clean reward window** and verify failover first.
5. **bkk20.** After bkk00 is back on 7.23.3 (it then covers RR). Needs access sorted.
6. **bkk60.** Mgmt switch; needs the console freed.
7. **bkk50 — LAST, ONSITE RECOMMENDED.** No remote recovery if it won't boot. Schedule DC presence or a window where a brief bkk03 outage is acceptable.

## Per-device procedure
1. Verify reachable + console fallback works + free space + `/export` & `/system backup save`.
2. Upload `routeros-7.23.3-<arch>.npk`; `/system package update install` (or reboot to apply) → reboots.
3. Wait ~2–3 min; verify `/system resource print` → version 7.23.3 (via console if network path was through this box).
4. `/system routerboard upgrade` → `/system reboot` → firmware applies.
5. Verify `/system routerboard print` → current-firmware 7.23.3.
6. Verify fabric: `/routing bgp session print` (sessions re-Established), LLDP neighbors back, host connectivity intact.
7. Only then move to the next device.

## Rollback
- Software: `/system package downgrade` with the 7.22 npk still on-box → reboot (keep it until stable).
- Firmware/won't-boot: Netinstall via console/onsite (this is why bkk50 wants onsite).

## What's upgradable NOW vs blocked
- **Now (reachable + recoverable):** bkk00, bkk10 — and bkk50 only with onsite.
- **Blocked on access:** bkk20, bkk30, bkk40 (creds/console), bkk60 (free the console).
