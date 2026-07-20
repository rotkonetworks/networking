#!/usr/bin/env bash
# hermes-nat44 — render bkk08 NAT44 rules from hermesd's IPv4 pool map.
#
# Polls  GET <API_URL>/v1/net/ipv4-map  (admin-gated) and builds an nftables
# table that, for each assigned public pool address, maps:
#
#     inbound   ip daddr <public 180.x>  DNAT -> <internal 10.8.20.x>   (VM)
#     outbound  ip saddr <internal>       SNAT -> <public 180.x>
#
# The pool /26 is announced as an aggregate by BIRD (PUBLIC_POOL4). Assigned
# /32s are DNAT'd here in prerouting (before the FIB), so they reach the VM on
# the tenant bridge; unassigned pool addresses hit the kernel blackhole (see the
# README one-time setup) and are dropped.
#
# Idempotent and atomic (single `nft -f` flush+replace). Safe on a timer.
set -euo pipefail

CONF="${HERMES_NAT44_ENV:-/etc/hermes-nat44/env}"
# shellcheck disable=SC1090
[[ -f "$CONF" ]] && . "$CONF"

# How to fetch the pool map. Either:
#   MAP_FETCH="ssh -i <key> mapfetch@web.rotko.net"   (SSH forced-command; token
#             stays on web — preferred, no public admin surface), or
#   API_URL + ADMIN_TOKEN                              (direct HTTPS to hermesd).
MAP_FETCH="${MAP_FETCH:-}"
TABLE="${TABLE:-hermes_nat44}"
# The announced pool aggregate. Unassigned addresses in it must be dropped
# locally (BIRD's static origin isn't in the kernel FIB), else inbound to an
# unassigned pool IP chases the default route and loops.
POOL_CIDR="${POOL_CIDR:-160.22.180.64/26}"
# Interface customer traffic egresses on (must match the node's existing egress
# SNAT). bkk08 SNATs 10.8.0.0/16 out vmbr2, so per-VM SNAT matches that oif.
EGRESS_IFACE="${EGRESS_IFACE:-vmbr2}"
# Priorities placed BEFORE the node's own nat table (dstnat=-100, srcnat=100) so
# the per-VM 1:1 mapping wins over the node's blanket 10.8.0.0/16 → shared-IP
# SNAT. First NAT base chain to match binds the conntrack mapping.
PRE_PRIO="${PRE_PRIO:--110}"
POST_PRIO="${POST_PRIO:-90}"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Fetch the pool map. Fail closed: on any error, leave the current table intact
# (don't tear down live customer NAT because the fetch blipped).
if [[ -n "$MAP_FETCH" ]]; then
    map="$($MAP_FETCH 2>/dev/null)" || { echo "hermes-nat44: MAP_FETCH failed, keeping rules" >&2; exit 1; }
else
    : "${API_URL:?set MAP_FETCH or API_URL+ADMIN_TOKEN in $CONF}"
    : "${ADMIN_TOKEN:?set MAP_FETCH or API_URL+ADMIN_TOKEN in $CONF}"
    map="$(curl -fsS -m 10 -H "authorization: Bearer ${ADMIN_TOKEN}" \
        "${API_URL%/}/v1/net/ipv4-map")" || { echo "hermes-nat44: fetch failed, keeping rules" >&2; exit 1; }
fi

# Validate JSON before touching nft.
if ! echo "$map" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "hermes-nat44: map is not a JSON array, aborting" >&2
    exit 1
fi

# Render the ruleset. The `table {}` + `delete table` + `table { … }` idiom makes
# the whole apply one atomic transaction (create-if-absent, drop, rebuild).
{
    echo "#!/usr/sbin/nft -f"
    echo "table ip ${TABLE} {}"
    echo "delete table ip ${TABLE}"
    echo "table ip ${TABLE} {"
    echo "  chain prerouting {"
    echo "    type nat hook prerouting priority ${PRE_PRIO}; policy accept;"
    echo "$map" | jq -r '.[] | select(.public_v4 and .internal_v4) |
        "    ip daddr \(.public_v4) dnat to \(.internal_v4)  # vmid \(.vmid // "-")"'
    echo "  }"
    echo "  chain postrouting {"
    echo "    type nat hook postrouting priority ${POST_PRIO}; policy accept;"
    echo "$map" | jq -r --arg oif "$EGRESS_IFACE" '.[] | select(.public_v4 and .internal_v4) |
        "    ip saddr \(.internal_v4) oifname \"\($oif)\" snat to \(.public_v4)  # vmid \(.vmid // "-")"'
    echo "  }"
    echo "}"
} > "$TMP"

nft -f "$TMP"

# Blackhole unassigned pool space (idempotent). Assigned /32s are DNAT'd in
# prerouting before the FIB, so this never affects them.
ip route replace blackhole "$POOL_CIDR" 2>/dev/null || true

# Announce each assigned pool address as a /32 in BIRD. The /26 aggregate does
# NOT propagate to transit; only /32s do (like the rest of our public IPs). We
# maintain an included routes file and reload BIRD only when it changes.
POOL_ROUTES="${POOL_ROUTES:-/etc/bird/pool-routes.conf}"
new_routes="$(echo "$map" | jq -r '.[] | select(.public_v4) |
    "route \(.public_v4)/32 unreachable;  # vmid \(.vmid // "-")"' | sort)"
if [ ! -f "$POOL_ROUTES" ] || [ "$new_routes" != "$(cat "$POOL_ROUTES" 2>/dev/null)" ]; then
    printf '%s\n' "$new_routes" > "$POOL_ROUTES"
    if command -v birdc >/dev/null 2>&1; then
        birdc configure >/dev/null 2>&1 \
            && logger -t hermes-nat44 "bird reconfigured: $(printf '%s' "$new_routes" | grep -c .) pool /32(s)"
    fi
fi

n="$(echo "$map" | jq '[.[] | select(.public_v4 and .internal_v4)] | length')"
logger -t hermes-nat44 "applied ${n} NAT44 mapping(s)"
echo "hermes-nat44: applied ${n} mapping(s)"
