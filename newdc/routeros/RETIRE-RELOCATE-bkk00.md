# Retire bkk00 (old rack) → firmware → ship to new DC as the edge

bkk00 is the CCR2216 to relocate. Its circuits are all being retired (HGC-HK dropping,
AMS-IX-EU deprioritized, SG-backup redundant), so pulling it disrupts nothing — bkk20 carries
the old rack alone (HGC-SG primary + AMS-IX-Bangkok/HK). **No cables move to bkk20.**

## 0. Pre-check (do NOT pull until true)
- [ ] bkk20 healthy and carrying full transit alone: `/routing/bgp/session/print` shows HGC-SG-PRIMARY + AMS-IX established, full table received.
- [ ] Old-rack egress verified via bkk20 (bkk00 down = no impact). Test: disable bkk00's sessions first (step 1) and watch traffic.

## 1. Graceful withdraw (drain to bkk20)
```
# on bkk00 — announce graceful-shutdown so upstream drains us, then disable
/routing/bgp/connection/set [find name~"HGC-HK"] disabled=yes
/routing/bgp/connection/set [find name~"AMSIX-EU"] disabled=yes
/routing/bgp/connection/set [find name~"HGC-SG-BACKUP"] disabled=yes
# watch old-rack traffic stays up via bkk20 for ~10 min
```
- [ ] Coordinate with **HGC** to decommission the HK circuit (or park the fiber for reuse). This is a circuit action on their side — schedule it.
- [ ] `/export file=bkk00-final` and copy it off (archive the old config).

## 2. Firmware update (do it on the bench, before shipping)
```
/system/package/update/check-for-updates
/system/package/update/set channel=stable
/system/package/update/download        ;# pulls 7.23.x (matches our validated unnumbered build)
/system/reboot                          ;# installs the package
# after reboot:
/system/routerboard/print               ;# note current-firmware vs upgrade-firmware
/system/routerboard/upgrade             ;# RouterBOOT firmware
/system/reboot
/system/resource/print                  ;# confirm version = 7.23.x
```

## 3. Wipe + load the new-DC config
```
/system/reset-configuration no-defaults=yes skip-backup=no keep-users=yes
# reconnect (serial/MAC-winbox), then:
# upload edge-newdc.rsc, FILL the HGC handoff placeholders, then:
/import file-name=edge-newdc.rsc
```

## 4. Physically pull (label everything)
Unplug from bkk00 and coil/label: `sfp28-2` (HGC fiber), `sfp28-4` (BKNIX), and the fabric
LAG uplinks (BKK10-LAG / BKK20-LAG / BKK30-LAG on the qsfp/sfp ports). Rack rails off. Box ready.

## 5. At the new DC (per ONSITE-RUNBOOK)
- Rack, power, console-verify the config imported.
- Plug the **HGC new-DC cross-connect** into `sfp28-1` (or whatever HGC lands on — set HGCPORT).
- Verify HGC eBGP established + full table; your prefixes visible from outside.
- Plug the fabric link (`sfp28-3`) to the new switch; verify the unnumbered session (`enhe`).
- Then bring compute up behind it (Flare reward stack last).

## Notes
- The new-DC HGC handoff (VLAN/IPs) is the one unknown — get it from HGC's LOA and fill
  edge-newdc.rsc. If HGC MOVES the SG circuit here, the SG values already in the file are reused.
- bkk20 stays running the old rack throughout; retire it only after the old rack is decommissioned.
