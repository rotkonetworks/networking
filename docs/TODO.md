# network tasks

## amsix/hgc connectivity issues

- [ ] contact amsix mailing list or hgc about route server issues on bkk20:
  - amsix-rs1-th-v4/v6 down
  - amsix-rs2-th-v4/v6 down
  - amsix-rs1-hk-v4 down
  - amsix-rs2-hk-v4 down
  - hgc-hk-backup-v4 down (on bkk20)
  - hgc-sg-backup-v4 down (on bkk00)
  - this causes traffic imbalance: hgc-hk handles 810TB vs hgc-sg 4TB
  - ask hgc: what triggers backup session activation? automatic or manual noc action?
  - ask hgc: what's the failover time? can they enable bfd for faster detection?

## bgp optimization

- [ ] investigate getting v4 transit from he at bknix (currently peering only)
  - would shift significant inbound traffic from hgc to bknix
  - current state: 99% inbound via hgc, only 1% via bknix

## ecmp / dual-router uplink project

to enable proper ecmp between uplinks, need second ip on each for dual-router peering:

- [ ] request from bknix: second ip for bkk20
- [ ] request from amsix-bkk: second ip for bkk00
- [ ] request from amsix-hk: second ip for bkk00
- [ ] request from amsix-eu: second ip for bkk20
- [ ] request from hgc: second ip on hk vlan for bkk20
- [ ] request from hgc: second ip on sg vlan for bkk00
- [ ] once ips obtained: bridge wan vlans across bkk00-bkk20 lag
- [ ] configure duplicate bgp sessions on both routers
- [ ] enable bgp multipath for ecmp

## pending infrastructure

- [ ] fix ecmp for anycast routes on bkk00/bkk20
- [ ] clean up old qnq vlans (106/107/108/116/117/118) after migration
- [ ] trace sfp28-12 on bkk00/bkk20 to bkk60
