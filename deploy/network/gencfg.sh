#!/usr/bin/env bash
set -euo pipefail

# Find script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/../config/network.json}"

# Parse options
while getopts ':c:' opt; do
  case "$opt" in
  c) CONFIG_FILE="$OPTARG" ;;
  *)
    echo "Usage: $0 [-c <config-file>] <site>" >&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# validate site argument
readonly SITE="${1:-}"
SITE_UPPER="$(echo "$SITE" | tr '[:lower:]' '[:upper:]')"
if [[ -z "$SITE" ]]; then
  echo "usage: $0 <site>" >&2
  echo "valid sites: $(jq -r '.sites | to_entries[] | select(.value.bgp_local_rr1_v4 != null) | .key' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# validate site exists
if ! jq -e ".sites.$SITE" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "error: invalid site: $SITE" >&2
  echo "valid sites: $(jq -r '.sites | to_entries[] | select(.value.bgp_local_rr1_v4 != null) | .key' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# Only allow generation for BIRD client sites
SITE_ROLE=$(jq -r ".sites.$SITE.role // \"client\"" "$CONFIG_FILE")
if [[ "$SITE_ROLE" != "client" ]] && [[ -z "$(jq -r ".sites.$SITE.bgp_local_rr1_v4 // empty" "$CONFIG_FILE")" ]]; then
  echo "error: site $SITE is not a BIRD client (role: $SITE_ROLE)" >&2
  echo "this generator only works for sites with BGP configuration" >&2
  exit 1
fi

# extract site config
SITE_CONFIG=$(jq -r ".sites.$SITE" "$CONFIG_FILE")
SITE_NUM="${SITE#bkk}"   # extract number from site name
SITE_NUM="${SITE_NUM#0}" # remove leading zero if present

# extract configuration values
ROUTER_ID=$(echo "$SITE_CONFIG" | jq -r '.router_id')
MANAGEMENT_IP=$(echo "$SITE_CONFIG" | jq -r '.management')
MANAGEMENT_GW=$(echo "$SITE_CONFIG" | jq -r '.management_gateway // empty')
MANAGEMENT_V6=$(echo "$SITE_CONFIG" | jq -r '.management_v6 // empty')
MANAGEMENT_V6_GW=$(echo "$SITE_CONFIG" | jq -r '.management_v6_gateway // empty')
PUBLIC_V4=$(echo "$SITE_CONFIG" | jq -r '.public_v4')
PUBLIC_V6=$(echo "$SITE_CONFIG" | jq -r '.public_v6')
INTERNAL_V4=$(echo "$SITE_CONFIG" | jq -r '.internal_v4')
INTERNAL_V6=$(echo "$SITE_CONFIG" | jq -r '.internal_v6')

# BGP addresses
BGP_RR1_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_rr1_v4')
BGP_RR1_V6=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_rr1_v6')
BGP_RR2_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_rr2_v4')
BGP_RR2_V6=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_rr2_v6')

# route reflector gateways
RR1_GW_V4=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors.rr1[$site].v4' "$CONFIG_FILE")
RR2_GW_V4=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors.rr2[$site].v4' "$CONFIG_FILE")
RR1_GW_V6=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors.rr1[$site].v6' "$CONFIG_FILE")
RR2_GW_V6=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors.rr2[$site].v6' "$CONFIG_FILE")

# anycast addresses - all three tiers
ANYCAST_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v4 // empty' | sed 's|/32||')
ANYCAST_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v6 // empty' | sed 's|/128||')
ANYCAST_SITE_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v4 // empty' | sed 's|/32||')
ANYCAST_SITE_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v6 // empty' | sed 's|/128||')
ANYCAST_GLOBAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v4 // empty' | sed 's|/32||')
ANYCAST_GLOBAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v6 // empty' | sed 's|/128||')

# physical interfaces
MGMT_IFACE=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.management // "eno2"')
BOND_MEMBERS=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.bond_members[]?' 2>/dev/null | tr '\n' ' ')
UNUSED_IFACES=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.unused[]?' 2>/dev/null | tr '\n' ' ')
BONDED_VLANS=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.bonded_vlans // false')

# global settings
MGMT_GATEWAY="${MANAGEMENT_GW:-$(jq -r '.networks.management_gateway // "192.168.69.1"' "$CONFIG_FILE")}"
MGMT_NETWORK=$(jq -r '.networks.management // "192.168.0.0/16"' "$CONFIG_FILE")
QINQ_OUTER=$(jq -r '.networks.qinq_outer // 400' "$CONFIG_FILE")

# bond configuration
BOND_MODE=$(jq -r '.bond_config.mode // "active-backup"' "$CONFIG_FILE")
BOND_MIIMON=$(jq -r '.bond_config.miimon // 100' "$CONFIG_FILE")
BOND_LACP_RATE=$(jq -r '.bond_config.lacp_rate // "fast"' "$CONFIG_FILE")
BOND_MTU=$(jq -r '.bond_config.mtu // 9000' "$CONFIG_FILE")

# VLAN IDs based on site number (pad to 2 digits)
VLAN_100="100"
VLAN_RR1_DIRECT="1$(printf "%02d" "$SITE_NUM")"
VLAN_RR2_DIRECT="2$(printf "%02d" "$SITE_NUM")"
VLAN_RR1_VIA_BKK10="11${SITE_NUM}"
VLAN_RR2_VIA_BKK10="21${SITE_NUM}"

# fix IPv6 addresses to ensure no extra colons
INTERNAL_V6_PREFIX="${INTERNAL_V6%%/*}"
while [[ "$INTERNAL_V6_PREFIX" == *: ]]; do
  INTERNAL_V6_PREFIX="${INTERNAL_V6_PREFIX%:}"
done

# Helper function to safely add routing table entries
add_rt_table() {
  local table_id="$1"
  local table_name="$2"
  echo "    up grep -q \"^${table_id}[[:space:]]${table_name}\" /etc/iproute2/rt_tables || echo \"${table_id} ${table_name}\" >> /etc/iproute2/rt_tables"
}

# generate interfaces configuration
generate_interfaces() {
  cat <<INTERFACES
# /etc/network/interfaces for ${SITE}
# Generated by $0 on $(date -u +"%Y-%m-%d %H:%M:%S UTC")
#
# Routing architecture:
#   Main table (254) - Managed by BIRD, contains full BGP routes
#   Table 102 (mgmt) - Management traffic isolation
#   Table 100 (anycast) - Anycast source routing
#
# Three-tier anycast:
#   - Local (ULA): Internal services only
#   - Site (GUA): Bangkok-only public services
#   - Global (GUA): Worldwide public services

source /etc/network/interfaces.d/*

# the loopback network interface
auto lo
iface lo inet loopback
INTERFACES

  # Add routing table creation
  add_rt_table "102" "mgmt"
  add_rt_table "100" "anycast"

  cat <<INTERFACES
    # router ID
    up ip addr add ${ROUTER_ID}/32 dev lo
    # public IPv4
    up ip addr add ${PUBLIC_V4}/32 dev lo
INTERFACES

  # add all three tiers of anycast IPv4
  if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
    echo "    # anycast local (ULA) - internal services"
    echo "    up ip addr add ${ANYCAST_LOCAL_V4}/32 dev lo"
  fi
  if [[ -n "$ANYCAST_SITE_V4" ]]; then
    echo "    # anycast site (GUA) - Bangkok only"
    echo "    up ip addr add ${ANYCAST_SITE_V4}/32 dev lo"
  fi
  if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    echo "    # anycast global (GUA) - worldwide"
    echo "    up ip addr add ${ANYCAST_GLOBAL_V4}/32 dev lo"
  fi

  cat <<INTERFACES

iface lo inet6 loopback
    # router ID
    up ip -6 addr add fd00:155:255::${SITE_NUM}/128 dev lo
    # public IPv6
    up ip -6 addr add ${PUBLIC_V6}/128 dev lo
INTERFACES

  # add all three tiers of anycast IPv6
  if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "    # anycast local (ULA) - internal services"
    echo "    up ip -6 addr add ${ANYCAST_LOCAL_V6}/128 dev lo"
  fi
  if [[ -n "$ANYCAST_SITE_V6" ]]; then
    echo "    # anycast site (GUA) - Bangkok only"
    echo "    up ip -6 addr add ${ANYCAST_SITE_V6}/128 dev lo"
  fi
  if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "    # anycast global (GUA) - worldwide"
    echo "    up ip -6 addr add ${ANYCAST_GLOBAL_V6}/128 dev lo"
  fi

  cat <<INTERFACES

# physical interfaces
iface ${MGMT_IFACE} inet manual
iface ${MGMT_IFACE} inet6 manual

# management bridge
auto vmbr0
iface vmbr0 inet static
    address ${MANAGEMENT_IP%%/*}
    netmask 255.255.0.0
    gateway ${MGMT_GATEWAY}
    bridge-ports ${MGMT_IFACE}
    bridge-stp off
    bridge-fd 0
    # management routing isolation
    post-up ip route add default via ${MGMT_GATEWAY} dev vmbr0 table mgmt
    post-up ip route add ${MGMT_NETWORK} dev vmbr0 table mgmt
    post-up ip rule add from ${MANAGEMENT_IP%%/*} table mgmt priority 300
    post-up ip rule add to ${MANAGEMENT_IP%%/*} table mgmt priority 301
    post-up ip rule add iif vmbr0 table mgmt priority 310
    pre-down ip rule del from ${MANAGEMENT_IP%%/*} table mgmt 2>/dev/null || true
    pre-down ip rule del to ${MANAGEMENT_IP%%/*} table mgmt 2>/dev/null || true
    pre-down ip rule del iif vmbr0 table mgmt 2>/dev/null || true
    pre-down ip route flush table mgmt 2>/dev/null || true
INTERFACES

  # Add IPv6 to management bridge if configured
  if [[ -n "$MANAGEMENT_V6" ]] && [[ -n "$MANAGEMENT_V6_GW" ]]; then
    cat <<MGMT_V6

iface vmbr0 inet6 static
    address ${MANAGEMENT_V6}
    gateway ${MANAGEMENT_V6_GW}
    accept_ra 0
    autoconf 0
MGMT_V6
  fi

  # Check if using bonded VLANs (new design)
  if [[ "$BONDED_VLANS" == "true" ]]; then
    # Split uplink configuration
    UPLINK1=$(echo "$BOND_MEMBERS" | awk '{print $1}')
    UPLINK2=$(echo "$BOND_MEMBERS" | awk '{print $2}')
    UP1_BASE=$(printf "%s" "$UPLINK1" | sed 's/^\(...\).*/\1/')
    UP2_BASE=$(printf "%s" "$UPLINK2" | sed 's/^\(...\).*/\1/')

    cat <<BONDED_CONFIG

# physical interfaces for split uplinks
iface ${UPLINK1} inet manual
    mtu ${BOND_MTU}

iface ${UPLINK2} inet manual
    mtu ${BOND_MTU}

# unused interfaces
BONDED_CONFIG

    for iface in $UNUSED_IFACES; do
      echo "iface $iface inet manual"
    done

    cat <<BONDED_CONFIG

# VLAN ${QINQ_OUTER} on each physical interface
auto ${UP1_BASE}.${QINQ_OUTER}
iface ${UP1_BASE}.${QINQ_OUTER} inet manual
    vlan-raw-device ${UPLINK1}
    vlan-id ${QINQ_OUTER}
    mtu ${BOND_MTU}

auto ${UP2_BASE}.${QINQ_OUTER}
iface ${UP2_BASE}.${QINQ_OUTER} inet manual
    vlan-raw-device ${UPLINK2}
    vlan-id ${QINQ_OUTER}
    mtu ${BOND_MTU}

# Q-in-Q inner VLANs on first interface (via bkk30)
auto vlan${VLAN_RR1_DIRECT}
iface vlan${VLAN_RR1_DIRECT} inet manual
    vlan-raw-device ${UP1_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_RR1_DIRECT}
    mtu 1500

auto vlan${VLAN_RR2_DIRECT}
iface vlan${VLAN_RR2_DIRECT} inet manual
    vlan-raw-device ${UP1_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_RR2_DIRECT}
    mtu 1500

# Q-in-Q inner VLANs via bkk30 for /16 network
auto ${UP1_BASE}-vlan${VLAN_100}
iface ${UP1_BASE}-vlan${VLAN_100} inet manual
    vlan-raw-device ${UP1_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_100}
    mtu 1500

# Q-in-Q inner VLANs on second interface (via bkk10)
auto vlan${VLAN_RR1_VIA_BKK10}
iface vlan${VLAN_RR1_VIA_BKK10} inet manual
    vlan-raw-device ${UP2_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_RR1_VIA_BKK10}
    mtu 1500

auto vlan${VLAN_RR2_VIA_BKK10}
iface vlan${VLAN_RR2_VIA_BKK10} inet manual
    vlan-raw-device ${UP2_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_RR2_VIA_BKK10}
    mtu 1500

# Q-in-Q inner VLANs via bkk10 for /32 network
auto ${UP2_BASE}-vlan${VLAN_100}
iface ${UP2_BASE}-vlan${VLAN_100} inet manual
    vlan-raw-device ${UP2_BASE}.${QINQ_OUTER}
    vlan-id ${VLAN_100}
    mtu 1500

# Bond to bkk00 (direct + via bkk10)
auto bond-bkk00
iface bond-bkk00 inet manual
    bond-slaves vlan${VLAN_RR1_DIRECT} vlan${VLAN_RR1_VIA_BKK10}
    bond-mode ${BOND_MODE}
    bond-primary vlan${VLAN_RR1_DIRECT}
    bond-miimon ${BOND_MIIMON}
    bond-lacp-rate ${BOND_LACP_RATE}
    bond-xmit-hash-policy layer3+4
    mtu 1500

# Bond to bkk20 (direct + via bkk10)
auto bond-bkk20
iface bond-bkk20 inet manual
    bond-slaves vlan${VLAN_RR2_DIRECT} vlan${VLAN_RR2_VIA_BKK10}
    bond-mode ${BOND_MODE}
    bond-primary vlan${VLAN_RR2_DIRECT}
    bond-miimon ${BOND_MIIMON}
    bond-lacp-rate ${BOND_LACP_RATE}
    bond-xmit-hash-policy layer3+4
    mtu 1500
    
# vlan100 bond (direct + via bkk10)
auto bond-vlan100
iface bond-vlan100 inet manual
    bond-slaves ${UP1_BASE}-vlan${VLAN_100} ${UP2_BASE}-vlan${VLAN_100}
    bond-mode ${BOND_MODE}
    bond-primary ${UP1_BASE}-vlan${VLAN_100}
    bond-miimon ${BOND_MIIMON}
    bond-lacp-rate ${BOND_LACP_RATE}
    bond-xmit-hash-policy layer3+4
    mtu 1500
BONDED_CONFIG
  fi

  # Common configuration for both designs
  cat <<COMMON_CONFIG

# internal services bridge
auto vmbr1
iface vmbr1 inet static
    address 10.${SITE_NUM}.0.1
    netmask 255.255.0.0
    bridge-ports none
    bridge-stp off
    bridge-fd 0

iface vmbr1 inet6 static
    address ${INTERNAL_V6_PREFIX}::1/48
    accept_ra 0
    autoconf 0

# public services bridge
auto vmbr2
iface vmbr2 inet static
COMMON_CONFIG

  if [[ "$BONDED_VLANS" == "true" ]]; then
    echo "    bridge-ports bond-bkk00 bond-bkk20"
    echo "    #bridge-ports bond-vlan100"
  else
    echo "    bridge-ports vlan${VLAN_RR2_DIRECT} vlan${VLAN_RR1_DIRECT}"
  fi

  cat <<COMMON_CONFIG
    bridge-stp off
    bridge-fd 0
    address ${BGP_RR1_V4}/31
    mtu 1500
    # policy-based routing for public services
    # ensures traffic from public IPs uses BIRD routes (main table)
    # anycast rules have higher priority to ensure proper routing
COMMON_CONFIG

  # Add rules for all anycast IPs with proper priorities
  local priority=45
  if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    echo "    post-up ip rule add from ${ANYCAST_GLOBAL_V4} lookup anycast priority ${priority}"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_SITE_V4" ]]; then
    echo "    post-up ip rule add from ${ANYCAST_SITE_V4} lookup anycast priority ${priority}"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
    echo "    post-up ip rule add from ${ANYCAST_LOCAL_V4} lookup anycast priority ${priority}"
    ((priority++))
  fi

  # Public IP and main table rules
  echo "    post-up ip rule add from ${PUBLIC_V4} lookup anycast priority 49"
  echo "    post-up ip rule add from ${PUBLIC_V4} lookup main priority 50"

  priority=51
  [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "    post-up ip rule add from ${ANYCAST_LOCAL_V4} lookup main priority ${priority}" && ((priority++))
  [[ -n "$ANYCAST_SITE_V4" ]] && echo "    post-up ip rule add from ${ANYCAST_SITE_V4} lookup main priority ${priority}" && ((priority++))
  [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "    post-up ip rule add from ${ANYCAST_GLOBAL_V4} lookup main priority ${priority}" && ((priority++))

  # Add default route to anycast table
  echo "    post-up ip route add default table anycast nexthop via ${RR1_GW_V4} dev vmbr2 weight 1 nexthop via ${RR2_GW_V4} dev vmbr2 weight 1 2>/dev/null || true"

  cat <<COMMON_CONFIG
    # critical: ensure return traffic uses the same interface
    post-up ip rule add iif vmbr2 lookup main priority 60
    # cleanup on interface down
    pre-down ip rule del from ${PUBLIC_V4} lookup anycast 2>/dev/null || true
    pre-down ip rule del from ${PUBLIC_V4} lookup main 2>/dev/null || true
COMMON_CONFIG

  # Cleanup rules for anycast IPs
  priority=45
  if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    echo "    pre-down ip rule del from ${ANYCAST_GLOBAL_V4} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip rule del from ${ANYCAST_GLOBAL_V4} lookup main 2>/dev/null || true"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_SITE_V4" ]]; then
    echo "    pre-down ip rule del from ${ANYCAST_SITE_V4} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip rule del from ${ANYCAST_SITE_V4} lookup main 2>/dev/null || true"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
    echo "    pre-down ip rule del from ${ANYCAST_LOCAL_V4} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip rule del from ${ANYCAST_LOCAL_V4} lookup main 2>/dev/null || true"
  fi

  echo "    pre-down ip route flush table anycast 2>/dev/null || true"
  echo "    pre-down ip rule del iif vmbr2 lookup main 2>/dev/null || true"
  cat <<COMMON_CONFIG

iface vmbr2:1 inet static
    address ${BGP_RR2_V4}/31
COMMON_CONFIG

  cat <<COMMON_CONFIG

iface vmbr2 inet6 static
    address ${BGP_RR1_V6}/127
    accept_ra 0
    autoconf 0
    # policy-based routing for IPv6 public services
    # anycast rules have higher priority to ensure proper routing
COMMON_CONFIG

  # Add IPv6 policy-based routing for all anycast tiers
  priority=45
  if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "    post-up ip -6 rule add from ${ANYCAST_GLOBAL_V6} lookup anycast priority ${priority}"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_SITE_V6" ]]; then
    echo "    post-up ip -6 rule add from ${ANYCAST_SITE_V6} lookup anycast priority ${priority}"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "    post-up ip -6 rule add from ${ANYCAST_LOCAL_V6} lookup anycast priority ${priority}"
    ((priority++))
  fi

  echo "    post-up ip -6 rule add from ${PUBLIC_V6} lookup anycast priority 49"
  echo "    post-up ip -6 rule add from ${PUBLIC_V6} lookup main priority 50"

  priority=51
  [[ -n "$ANYCAST_LOCAL_V6" ]] && echo "    post-up ip -6 rule add from ${ANYCAST_LOCAL_V6} lookup main priority ${priority}" && ((priority++))
  [[ -n "$ANYCAST_SITE_V6" ]] && echo "    post-up ip -6 rule add from ${ANYCAST_SITE_V6} lookup main priority ${priority}" && ((priority++))
  [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "    post-up ip -6 rule add from ${ANYCAST_GLOBAL_V6} lookup main priority ${priority}" && ((priority++))

  echo "    post-up ip -6 route add default table anycast nexthop via ${RR1_GW_V6} dev vmbr2 weight 1 nexthop via ${RR2_GW_V6} dev vmbr2 weight 1 2>/dev/null || true"

  cat <<POLICY_V6
    # critical: ensure return traffic uses the same interface
    post-up ip -6 rule add iif vmbr2 lookup main priority 60
    # cleanup on interface down
    pre-down ip -6 rule del from ${PUBLIC_V6} lookup anycast 2>/dev/null || true
    pre-down ip -6 rule del from ${PUBLIC_V6} lookup main 2>/dev/null || true
POLICY_V6

  # IPv6 cleanup rules
  priority=45
  if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "    pre-down ip -6 rule del from ${ANYCAST_GLOBAL_V6} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip -6 rule del from ${ANYCAST_GLOBAL_V6} lookup main 2>/dev/null || true"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_SITE_V6" ]]; then
    echo "    pre-down ip -6 rule del from ${ANYCAST_SITE_V6} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip -6 rule del from ${ANYCAST_SITE_V6} lookup main 2>/dev/null || true"
    ((priority++))
  fi
  if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "    pre-down ip -6 rule del from ${ANYCAST_LOCAL_V6} lookup anycast priority ${priority} 2>/dev/null || true"
    echo "    pre-down ip -6 rule del from ${ANYCAST_LOCAL_V6} lookup main 2>/dev/null || true"
  fi

  echo "    pre-down ip -6 route flush table anycast 2>/dev/null || true"
  echo "    pre-down ip -6 rule del iif vmbr2 lookup main 2>/dev/null || true"

  cat <<COMMON_CONFIG

iface vmbr2:1 inet6 static
    address ${BGP_RR2_V6}/127
COMMON_CONFIG
}

# main execution
generate_interfaces
