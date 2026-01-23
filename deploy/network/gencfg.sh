#!/usr/bin/env bash
set -euo pipefail

# Find script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/../config/network.json}"
SERVICES_FILE="${SERVICES_FILE:-${SCRIPT_DIR}/../config/services.json}"

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
  echo "valid sites: $(jq -r '.sites | to_entries[] | select(.value.bgp_rr_v4 != null) | .key' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# validate site exists
if ! jq -e ".sites.$SITE" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "error: invalid site: $SITE" >&2
  echo "valid sites: $(jq -r '.sites | to_entries[] | select(.value.bgp_rr_v4 != null) | .key' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# Only allow generation for sites with BGP configuration
SITE_CONFIG=$(jq -r ".sites.$SITE" "$CONFIG_FILE")
BGP_RR_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v4 // empty')
if [[ -z "$BGP_RR_V4" ]]; then
  echo "error: site $SITE does not have BGP configuration" >&2
  echo "this generator only works for sites with BGP configuration" >&2
  exit 1
fi

# extract site config
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

# BGP RR network addresses
BGP_RR_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v4')
BGP_RR_V6=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v6')

# Get BGP network configuration
BGP_NETWORK_V4=$(jq -r '.networks.bgp_rr_network.v4' "$CONFIG_FILE")
BGP_NETWORK_V6=$(jq -r '.networks.bgp_rr_network.v6' "$CONFIG_FILE")
BGP_RR_VLAN=$(jq -r '.networks.bgp_rr_network.vlan' "$CONFIG_FILE")

# Get RR gateway IPs (for routing tables)
RR1_GW_V4=$(jq -r '.sites.bkk00.bgp_rr_v4' "$CONFIG_FILE")
RR2_GW_V4=$(jq -r '.sites.bkk20.bgp_rr_v4' "$CONFIG_FILE")
RR1_GW_V6=$(jq -r '.sites.bkk00.bgp_rr_v6' "$CONFIG_FILE")
RR2_GW_V6=$(jq -r '.sites.bkk20.bgp_rr_v6' "$CONFIG_FILE")

# anycast addresses - all three tiers
ANYCAST_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v4 // empty' | sed 's|/32||')
ANYCAST_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v6 // empty' | sed 's|/128||')
ANYCAST_SITE_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v4 // empty' | sed 's|/32||')
ANYCAST_SITE_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v6 // empty' | sed 's|/128||')
ANYCAST_GLOBAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v4 // empty' | sed 's|/32||')
ANYCAST_GLOBAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v6 // empty' | sed 's|/128||')

# VM public IPs and bridges from services.json
VM_IP4S=()
VM_IP6S=()
VM_BRIDGES=()
if [[ -f "$SERVICES_FILE" ]] && jq -e ".vms.$SITE" "$SERVICES_FILE" >/dev/null 2>&1; then
  while IFS='|' read -r ip4 ip6 bridge; do
    [[ -n "$ip4" ]] && VM_IP4S+=("$ip4") && VM_IP6S+=("$ip6") && VM_BRIDGES+=("${bridge:-vmbr2}")
  done < <(jq -r ".vms.$SITE | to_entries[] | \"\(.value.public_ip.ip4 // empty)|\(.value.public_ip.ip6 // empty)|\(.value.bridge // \"vmbr2\")\"" "$SERVICES_FILE" 2>/dev/null)
fi

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
# Using unified BGP RR network on VLAN ${QINQ_OUTER}.${BGP_RR_VLAN}
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

  # Check if using bonded VLANs (new design)
  if [[ "$BONDED_VLANS" == "true" ]]; then
    # Split uplink configuration
    UPLINK1=$(echo "$BOND_MEMBERS" | awk '{print $1}')
    UPLINK2=$(echo "$BOND_MEMBERS" | awk '{print $2}')

    # Generate simple interface names based on prefix
    # enp* -> enp, eno* -> eno
    if [[ "$UPLINK1" == enp* ]]; then
      UP1_BASE="enp"
    elif [[ "$UPLINK1" == eno* ]]; then
      UP1_BASE="eno"
    else
      UP1_BASE="${UPLINK1%%[0-9]*}"
    fi

    if [[ "$UPLINK2" == enp* ]]; then
      UP2_BASE="enp"
    elif [[ "$UPLINK2" == eno* ]]; then
      UP2_BASE="eno"
    else
      UP2_BASE="${UPLINK2%%[0-9]*}"
    fi

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

# Q-in-Q VLAN ${QINQ_OUTER}.${BGP_RR_VLAN} - Unified BGP RR network
auto vlan${BGP_RR_VLAN}-p1
iface vlan${BGP_RR_VLAN}-p1 inet manual
    vlan-raw-device ${UP1_BASE}.${QINQ_OUTER}
    vlan-id ${BGP_RR_VLAN}
    mtu 1500

auto vlan${BGP_RR_VLAN}-p2
iface vlan${BGP_RR_VLAN}-p2 inet manual
    vlan-raw-device ${UP2_BASE}.${QINQ_OUTER}
    vlan-id ${BGP_RR_VLAN}
    mtu 1500

# Bond for BGP RR connectivity
auto bond-bgp
iface bond-bgp inet manual
    bond-slaves vlan${BGP_RR_VLAN}-p1 vlan${BGP_RR_VLAN}-p2
    bond-mode ${BOND_MODE}
    bond-primary vlan${BGP_RR_VLAN}-p1
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

# public services bridge (BGP RR network)
auto vmbr2
iface vmbr2 inet static
    bridge-ports bond-bgp
    bridge-stp off
    bridge-fd 0
    address ${BGP_RR_V4}/${BGP_NETWORK_V4##*/}
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

  # Add VM routes (VMs with public IPs on vmbr2)
  for i in "${!VM_IP4S[@]}"; do
    local ip4="${VM_IP4S[$i]}"
    local bridge="${VM_BRIDGES[$i]}"
    if [[ "$bridge" == "vmbr2" && -n "$ip4" ]]; then
      echo "    # VM public IP route"
      echo "    post-up ip route add ${ip4}/32 dev vmbr2 2>/dev/null || true"
    fi
  done

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

  # Cleanup VM routes
  for i in "${!VM_IP4S[@]}"; do
    local ip4="${VM_IP4S[$i]}"
    local bridge="${VM_BRIDGES[$i]}"
    if [[ "$bridge" == "vmbr2" && -n "$ip4" ]]; then
      echo "    pre-down ip route del ${ip4}/32 dev vmbr2 2>/dev/null || true"
    fi
  done

  cat <<COMMON_CONFIG

iface vmbr2 inet6 static
    address ${BGP_RR_V6}/${BGP_NETWORK_V6##*/}
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

  # Add VM IPv6 routes
  for i in "${!VM_IP6S[@]}"; do
    local ip6="${VM_IP6S[$i]}"
    local bridge="${VM_BRIDGES[$i]}"
    if [[ "$bridge" == "vmbr2" && -n "$ip6" ]]; then
      echo "    # VM public IPv6 route"
      echo "    post-up ip -6 route add ${ip6}/128 dev vmbr2 2>/dev/null || true"
    fi
  done

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

  # Cleanup VM IPv6 routes
  for i in "${!VM_IP6S[@]}"; do
    local ip6="${VM_IP6S[$i]}"
    local bridge="${VM_BRIDGES[$i]}"
    if [[ "$bridge" == "vmbr2" && -n "$ip6" ]]; then
      echo "    pre-down ip -6 route del ${ip6}/128 dev vmbr2 2>/dev/null || true"
    fi
  done
}

# main execution
generate_interfaces
