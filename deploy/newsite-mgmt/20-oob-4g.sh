#!/usr/bin/env bash
# Make this node the out-of-band management box: 4G uplink + WireGuard dialled
# OUT to a rendezvous that is NOT part of our infrastructure.
#
#   VPS_ENDPOINT=1.2.3.4:51820 VPS_PUBKEY=xxxx HOSTNUM=11 ./20-oob-4g.sh
#
# WHY AN EXTERNAL RENDEZVOUS:
# every existing WireGuard endpoint we have is inside our own network —
# 10.155.100.1, 10.155.20x.0, 172.16.10.1, and the single public one
# 160.22.181.178 (bkk20, old site, riding HGC). A box that dials any of those
# dies with the transit it is meant to rescue. The meeting point must sit
# somewhere we are not dismantling.
set -euo pipefail

HOSTNUM="${HOSTNUM:?set HOSTNUM}"
VPS_ENDPOINT="${VPS_ENDPOINT:?set VPS_ENDPOINT host:port of the external rendezvous}"
VPS_PUBKEY="${VPS_PUBKEY:?set VPS_PUBKEY}"
VPS_WG_IP="${VPS_WG_IP:-172.31.255.1}"
WG_NET="${WG_NET:-172.31.0.0/16}"

say() { printf '\n=== %s\n' "$*"; }

say "add the external rendezvous as a peer"
# PersistentKeepalive is mandatory here: 4G is CGNAT, so the NAT binding only
# stays open because we keep poking it. Without this the box is unreachable
# until it happens to send something.
grep -q "$VPS_PUBKEY" /etc/wireguard/wg0.conf || cat >> /etc/wireguard/wg0.conf <<EOF

[Peer]
# external rendezvous — deliberately outside our own network
PublicKey = ${VPS_PUBKEY}
Endpoint = ${VPS_ENDPOINT}
AllowedIPs = ${VPS_WG_IP}/32, ${WG_NET}
PersistentKeepalive = 25
EOF

say "MTU — WireGuard over 4G"
# 4G paths are frequently below 1500. WG's own overhead on top means large
# transfers stall silently rather than fail loudly. 1380 is conservative and
# costs nothing on a control-plane link.
if ! grep -q '^MTU' /etc/wireguard/wg0.conf; then
  sed -i '/^\[Interface\]/a MTU = 1380' /etc/wireguard/wg0.conf
fi

say "bring it up"
systemctl enable --now wg-quick@wg0
sleep 3
wg show wg0 || true

say "serial console server"
# Console duty currently lives on bkk06 (already at Telehouse, dark) and bkk03
# (holds two validators). Move it here. Adapters appear as /dev/ttyUSB*; the
# by-id symlinks are stable across reboots, plain ttyUSBn are NOT.
ls -l /dev/serial/by-id/ 2>/dev/null || echo "  (no USB serial adapters detected yet)"
cat > /etc/systemd/system/console@.service <<'EOF'
[Unit]
Description=Serial console on %I
[Service]
ExecStart=/usr/bin/picocom -b 115200 /dev/%I
Restart=no
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

cat <<EOF

=== NEXT — and do not skip step 3 ===
1. On the VPS, add THIS node as a peer:
     PublicKey  = $(cat /etc/wireguard/wg0.pub)
     AllowedIPs = 172.31.0.${HOSTNUM#0}/32
2. Confirm the tunnel:  wg show wg0   (expect a recent handshake)
     ping ${VPS_WG_IP}
3. **UNPLUG THE RACK UPLINK** and confirm you can still reach this box from
   outside over 4G. If it only works while the rack is up, it is not
   out-of-band and it will not save you at Telehouse.
4. Attach USB serial to bkk10 / bkk60 and test:
     systemctl start console@ttyUSB0
5. Watch the data usage. This is a rescue path, not transit — do not route
   RPC or chain sync over it.
EOF
