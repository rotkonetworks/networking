# bkk08 NAT44 customer IPv4 pool — turn-up runbook

Gives hosting customer VMs a **public IPv4** while they stay IPv6-first and
isolated on the tenant bridge. Public pool `160.22.180.64/26` (64 addresses,
carved clear of the node alt-IPs `.6/.7/.8/.12` and the global anycast `.180`)
is announced as an aggregate by BIRD on bkk08; each **assigned** `/32` is
NAT44'd to its paired internal tenant address `10.8.20.x`.

```
internet ──BGP 160.22.180.64/26──▶ bkk08
                                     │ prerouting DNAT  180.x/32 ─▶ 10.8.20.y
                                     ▼
                              tenant bridge 10.8.20.0/22 ──▶ VM (IPv6-first)
                                     ▲
                                     │ postrouting SNAT 10.8.20.y ─▶ 180.x/32
```

Pairing is deterministic (hermesd `ipv4pool::pair_internal`):
`internal = 10.8.20.0 + (public − 160.22.180.64)`, e.g. `.64→10.8.20.0`,
`.70→10.8.20.6`. hermesd publishes the live pairs at `GET /v1/net/ipv4-map`.

> ⚠️ Every step here is on **live bkk08**; the `/26` announce is a real BGP
> change. Do the one-time setup, verify with a throwaway mapping, and only then
> enable the pool in hermesd.

## 1. BIRD: announce the pool aggregate

Already wired into the generator (`deploy/bird/gencfg.sh`, driven by
`sites.bkk08.public_pool_v4` in `network.json`). Regenerate and deploy:

```sh
# on the config host
./deploy/bird/gencfg.sh bkk08 > generated/bkk08-bird.conf
scp generated/bkk08-bird.conf root@bkk08:/etc/bird/bird.conf

# on bkk08 — validate BEFORE committing
birdc configure check "/etc/bird/bird.conf"   # must say "Configuration OK"
birdc configure                                # apply
birdc show route 160.22.180.64/26              # originated (unreachable)
```

> **Boot-order note:** BIRD's `static4` does `include "/etc/bird/pool-routes.conf"`,
> and BIRD 2.x treats a missing include as a **fatal** parse error — so the file
> must exist before BIRD first starts, or the node comes up with no BGP at all.
> Create it as part of node prep, before the first `birdc configure`:
> `install -m644 /dev/null /etc/bird/pool-routes.conf` (the reconciler maintains
> it thereafter). The nft table and the pool blackhole are reconciler-managed and
> re-applied within ~30s of boot by the timer — they are not persisted to
> `/etc/nftables.conf`, so expect a brief post-reboot gap until the first tick.

## 2. Kernel: blackhole unassigned pool space

BIRD's static origin isn't exported to the FIB (kernel filter rejects
`RTS_STATIC`), so add a low-priority blackhole so **unassigned** pool addresses
are dropped locally instead of chasing the default route. Assigned `/32`s are
DNAT'd in prerouting (before the FIB), so they're unaffected.

```sh
# on bkk08 — persist via your interfaces/networkd tooling too
ip route add blackhole 160.22.180.64/26 metric 1000
sysctl -w net.ipv4.ip_forward=1        # ensure forwarding (persist in sysctl.d)
```

## 3. Install the NAT44 reconciler

`hermes-nat44.sh` polls `/v1/net/ipv4-map` and renders the DNAT/SNAT table
atomically; the timer reconciles every 30s (new/removed VMs converge without
manual edits).

```sh
# on bkk08
install -Dm755 hermes-nat44.sh /opt/hermes-nat44/hermes-nat44.sh
install -Dm644 README.md       /opt/hermes-nat44/README.md
install -Dm644 hermes-nat44.service /etc/systemd/system/hermes-nat44.service
install -Dm644 hermes-nat44.timer   /etc/systemd/system/hermes-nat44.timer

install -d -m700 /etc/hermes-nat44
cat > /etc/hermes-nat44/env <<'EOF'
# hermesd admin API reachable from bkk08, and its admin_token.
API_URL=http://<hermesd-host-reachable-from-bkk08>:8088
ADMIN_TOKEN=<hermesd admin_token>
EOF
chmod 600 /etc/hermes-nat44/env

systemctl daemon-reload
systemctl enable --now hermes-nat44.timer
systemctl start hermes-nat44.service      # first run
nft list table ip hermes_nat44            # inspect rendered rules
```

`API_URL` must be a path bkk08 can actually reach (hermesd listens
`127.0.0.1:8088` on its host; the `:18080`/edge is firewalled — use the
internal address, add an allowlist rule if needed). `ADMIN_TOKEN` is a secret:
keep it only in `/etc/hermes-nat44/env` (mode 600), never in the repo.

## 4. Verify with a throwaway mapping (before enabling the pool)

1. In hermesd (staging/hidden), lease one pool address to a test VM so the map
   returns one pair.
2. `systemctl start hermes-nat44.service` → `nft list table ip hermes_nat44`
   shows the DNAT/SNAT pair.
3. From an external host: `ping`/`curl` the public `/32` → reaches the VM;
   VM outbound shows the public source. Then release it.

## 5. Enable the pool in hermesd (last)

Only after 1–4 pass. In `/etc/hermeshost/hermes.yaml`:

```yaml
ipv4_pool:
  enabled: true
  cidr: 160.22.180.64/26
  tenant_v4: 10.8.20.0/22
  tenant_gw4: 10.8.0.1
  tenant_link_prefix: 16
```

Restart hermesd. Paid/net-terms VMs then lease a pool IPv4, the map picks it up,
and the reconciler NATs it within ~30s.

## Rollback

```sh
systemctl disable --now hermes-nat44.timer
nft delete table ip hermes_nat44
ip route del blackhole 160.22.180.64/26
# revert network.json / regenerate / birdc configure to drop the announce
```
Set `ipv4_pool.enabled: false` in hermesd and restart to stop new leases.
