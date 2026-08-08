#!/usr/bin/env bash
# audit-dualhomed-guests.sh — find guests that are dual-homed onto both the mgmt bridge
# and the host-local container bridge, which is the configuration that broke on 2026-08-05.
#
# WHAT ACTUALLY HAPPENED (2026-08-05):
#   Guests 996 (ibp.rotko.net @ bkk07) and 988 (ibp.rotko.net @ bkk08) each had:
#       eth0  192.168.<n>.97/16 on vmbr0   <- carries the DEFAULT ROUTE
#       eth1  10.<n>.77.97/16   on vmbr1   <- host-local container bridge
#   with net.ipv4.conf.*.rp_filter = 2 (loose).
#
#   Traffic to containers took the eth1 path. ARP resolved correctly and ICMP worked,
#   but TCP connections failed. Routing the same destinations via the eth0 gateway
#   (192.168.69.1) worked immediately and reliably.
#
#   Single-homed guests were NEVER affected:
#     - RPC containers (one NIC on vmbr1) - fine, even with /16
#     - haproxy-bkkNN, dockers (one NIC on vmbr0, no 10.x NIC at all) - fine
#
#   So the fault is the DUAL-HOMING, not the prefix width per se. A /16 on a
#   single-homed container is harmless. Narrowing 996/988 to /24 fixed them because it
#   pushed the container subnets onto the eth0 gateway path.
#
# THE RULE: utility/scraper guests should be SINGLE-HOMED on the mgmt bridge and reach
# containers via the host gateway. If a guest must be dual-homed, its container-side NIC
# must be /24 or narrower so only its true local segment is link-scope.
#
# Usage:  ./audit-dualhomed-guests.sh [host ...]      (default: bkk06 bkk07 bkk08)
# Read-only.

set -uo pipefail

NAT="root@160.22.181.181"
declare -A SSHPORT=( [bkk06]=22786 [bkk07]=22787 [bkk08]=22788 )
SSHOPTS="-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=no"

targets=("$@")
[ $# -eq 0 ] && targets=(bkk06 bkk07 bkk08)

for host in "${targets[@]}"; do
  port="${SSHPORT[$host]:-}"
  if [ -z "$port" ]; then echo "unknown host: $host" >&2; continue; fi
  echo "======== $host"

  ssh $SSHOPTS -p "$port" "$NAT" '
    for id in $(pct list 2>/dev/null | awk "NR>1 {print \$1}"); do
      name=$(pct list 2>/dev/null | awk -v i=$id "\$1==i {print \$3}")
      cfg=$(pct config "$id" 2>/dev/null)
      nvmbr0=$(echo "$cfg" | grep -cE "^net[0-9]+:.*bridge=vmbr0")
      nvmbr1=$(echo "$cfg" | grep -cE "^net[0-9]+:.*bridge=vmbr1")
      [ "$nvmbr0" -ge 1 ] && [ "$nvmbr1" -ge 1 ] || continue

      echo "  !! $id ($name) is DUAL-HOMED"
      echo "$cfg" | grep -E "^net[0-9]+:" | sed "s/^/       /"

      # container-side NIC prefix width
      echo "$cfg" | grep -E "^net[0-9]+:.*bridge=vmbr1" | while read -r line; do
        ipx=$(echo "$line" | grep -oE "ip=[0-9.]+/[0-9]+" | cut -d= -f2)
        [ -n "$ipx" ] || continue
        plen=${ipx##*/}
        if [ "$plen" -lt 24 ]; then
          echo "       ^^ container NIC is /$plen (WIDE) - narrow to /24 or remove the NIC"
        else
          echo "       ^^ container NIC is /$plen (ok)"
        fi
      done

      # runtime evidence
      if pct status "$id" 2>/dev/null | grep -q running; then
        rp=$(pct exec "$id" -- sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null)
        bad=$(pct exec "$id" -- ip neigh show 2>/dev/null | grep -cE "(FAILED|INCOMPLETE)")
        echo "       rp_filter=${rp:-?}  failed/incomplete-ARP=${bad:-0}"
      fi
    done
    true
  ' 2>&1 | grep -viE "warning: perman|post-quantum|store now|openssh.com|may be vulnerable|server may need"
done

cat <<'NOTE'

--- what to do with findings ---
  Preferred: make the guest single-homed on vmbr0 and let it route to containers via the
  host gateway (192.168.69.1). This is how haproxy-bkkNN and dockers are configured and
  they have never exhibited this fault.

  If the container-side NIC must stay, narrow it to its real segment:
      pct set <id> --net<N> name=<nic>,bridge=vmbr1,hwaddr=<hw>,ip=<addr>/24,type=veth
  Verify first that nothing else needs link-local access in that /24:
      pct exec <id> -- ip neigh show dev <nic> | grep -c '<a.b.c>.'
  0 means narrowing is free.

  pct set applies at next guest start. Correct a RUNNING guest immediately with:
      pct exec <id> -- ip route replace <peer-subnet>/24 via 192.168.69.1 dev eth0

  Runtime fingerprint of the bug: ICMP works, TCP fails, and
      pct exec <id> -- ip route get <addr>
  returns "dev <container-nic>" rather than "via <gateway>".
NOTE
