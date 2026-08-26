#!/usr/bin/env bash
# Common post-install for a freshly-installed Proxmox node (bkk09/11/13).
# Run AS ROOT ON THE NODE, straight after the installer reboots.
#
#   HOSTNUM=11 ./10-postinstall.sh
#
# Idempotent: safe to re-run.
set -euo pipefail

HOSTNUM="${HOSTNUM:?set HOSTNUM (09|11|13)}"
HOST="bkk${HOSTNUM}"
WG_ADDR="172.31.0.${HOSTNUM#0}/16"      # mesh convention: 172.31.0.<hostnum>
PUBKEYS="${PUBKEYS:-/root/authorized_keys.in}"

say() { printf '\n=== %s\n' "$*"; }

say "identity"
hostnamectl set-hostname "${HOST}.rotko.net"
grep -q "${HOST}" /etc/hosts || echo "127.0.1.1 ${HOST}.rotko.net ${HOST}" >> /etc/hosts

say "repos: drop enterprise, add no-subscription"
# PVE 9 uses deb822 .sources files; remove both forms so this works either way.
rm -f /etc/apt/sources.list.d/pve-enterprise.list \
      /etc/apt/sources.list.d/pve-enterprise.sources \
      /etc/apt/sources.list.d/ceph.list \
      /etc/apt/sources.list.d/ceph.sources
cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
apt-get update -qq

say "packages we always want on a remote box"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  wireguard-tools nftables lldpd chrony curl jq tmux \
  minicom picocom setserial usbutils ethtool mtr-tiny

say "ssh hardening — key only"
install -d -m 700 /root/.ssh
[[ -f "$PUBKEYS" ]] && cat "$PUBKEYS" >> /root/.ssh/authorized_keys || \
  echo "!! no $PUBKEYS — ADD YOUR KEY BEFORE THIS BOX LEAVES THE RACK"
sort -u -o /root/.ssh/authorized_keys /root/.ssh/authorized_keys 2>/dev/null || true
chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true
cat > /etc/ssh/sshd_config.d/99-rotko.conf <<'EOF'
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
# Deliberately NOT restarting sshd here — if the key is wrong you lock yourself
# out of a box that is about to become physically remote. Verify, then:
#   sshd -t && systemctl reload ssh

say "wireguard mesh stub (${WG_ADDR})"
install -d -m 700 /etc/wireguard
if [[ ! -f /etc/wireguard/wg0.key ]]; then
  umask 077; wg genkey > /etc/wireguard/wg0.key
  wg pubkey < /etc/wireguard/wg0.key > /etc/wireguard/wg0.pub
fi
echo "  public key (add this to the peers): $(cat /etc/wireguard/wg0.pub)"
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = ${WG_ADDR}
PrivateKey = $(cat /etc/wireguard/wg0.key)
# ListenPort intentionally unset: behind 4G CGNAT we dial OUT only.

# Peers are added by 20-oob-4g.sh (external rendezvous) and by
# deploy/wireguard/add-servers-to-vpn.sh for the existing mesh.
EOF
chmod 600 /etc/wireguard/wg0.conf

say "time + lldp"
systemctl enable --now chrony lldpd >/dev/null 2>&1 || true

say "done — ${HOST}"
echo "NEXT:"
echo "  1. verify your key works from another shell BEFORE reloading sshd"
echo "  2. run 20-oob-4g.sh if this is the OOB box"
echo "  3. prove reachability over 4G with the rack uplink UNPLUGGED"
