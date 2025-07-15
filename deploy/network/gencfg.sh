#!/usr/bin/env bash
# network interfaces config generator
set -euo pipefail

# Load config
CONFIG_FILE="${CONFIG_FILE:-../config.json}"
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
  echo "valid sites: $(jq -r '.sites | keys[]' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# validate site exists
if ! jq -e ".sites.$SITE" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "error: invalid site: $SITE" >&2
  exit 1
fi

# extract site config
SITE_CONFIG=$(jq -r ".sites.$SITE" "$CONFIG_FILE")
SITE_NUM="${SITE#bkk}"  # Extract number from site name

# extract configuration values
ROUTER_ID=$(echo "$SITE_CONFIG" | jq -r '.router_id')
MANAGEMENT_IP=$(echo "$SITE_CONFIG" | jq -r '.management')
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

# anycast addresses
ANYCAST_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v4 // empty' | sed 's|/32||')
ANYCAST_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v6 // empty' | sed 's|/128||')
ANYCAST_GLOBAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v4 // empty' | sed 's|/32||')
ANYCAST_GLOBAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v6 // empty' | sed 's|/128||')

# ohysical interfaces
MGMT_IFACE=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.management // "eno2"')
BOND_MEMBERS=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.bond_members[]?' 2>/dev/null | tr '\n' ' ')
UNUSED_IFACES=$(echo "$SITE_CONFIG" | jq -r '.physical_interfaces.unused[]?' 2>/dev/null | tr '\n' ' ')

# global settings
MGMT_GATEWAY=$(jq -r '.networks.management_gateway // "192.168.69.1"' "$CONFIG_FILE")
QINQ_OUTER=$(jq -r '.networks.qinq_outer // 400' "$CONFIG_FILE")

# bond configuration
BOND_MODE=$(jq -r '.bond_config.mode // "802.3ad"' "$CONFIG_FILE")
BOND_MIIMON=$(jq -r '.bond_config.miimon // 100' "$CONFIG_FILE")
BOND_LACP_RATE=$(jq -r '.bond_config.lacp_rate // "fast"' "$CONFIG_FILE")
BOND_MTU=$(jq -r '.bond_config.mtu // 9000' "$CONFIG_FILE")

# VLAN IDs based on site number
VLAN_RR1="1${SITE_NUM}"
VLAN_RR2="2${SITE_NUM}"

# generate interfaces configuration
generate_interfaces() {
  cat <<INTERFACES
# /etc/network/interfaces for ${SITE}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
    # Router ID
    up ip addr add ${ROUTER_ID}/32 dev lo
INTERFACES

  # Add anycast IPs if present
  if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
    echo "    # Anycast local IPv4"
    echo "    up ip addr add ${ANYCAST_LOCAL_V4}/32 dev lo"
  fi
  if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    echo "    # Anycast global IPv4"
    echo "    up ip addr add ${ANYCAST_GLOBAL_V4}/32 dev lo"
  fi

  cat <<INTERFACES

iface lo inet6 loopback
    # Router ID
    up ip -6 addr add fd00:155:255::${SITE_NUM}/128 dev lo
    # Public IPv6
    up ip -6 addr add ${PUBLIC_V6}/128 dev lo
INTERFACES

  # Add IPv6 anycast if present
  if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "    # Anycast local IPv6"
    echo "    up ip -6 addr add ${ANYCAST_LOCAL_V6}/128 dev lo"
  fi
  if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "    # Anycast global IPv6"
    echo "    up ip -6 addr add ${ANYCAST_GLOBAL_V6}/128 dev lo"
  fi

  cat <<INTERFACES

# Physical interfaces
iface ${MGMT_IFACE} inet manual
iface ${MGMT_IFACE} inet6 manual

# Management bridge
auto vmbr0
iface vmbr0 inet static
    address ${MANAGEMENT_IP%%/*}
    netmask 255.255.0.0
    gateway ${MGMT_GATEWAY}
    bridge-ports ${MGMT_IFACE}
    bridge-stp off
    bridge-fd 0

# Physical interfaces for bonding
INTERFACES

  # List bond member interfaces
  for iface in $BOND_MEMBERS; do
    echo "iface $iface inet manual"
  done

  # List unused interfaces if any
  if [[ -n "$UNUSED_IFACES" ]]; then
    for iface in $UNUSED_IFACES; do
      echo "iface $iface inet manual"
    done
  fi

  cat <<INTERFACES

# LACP bond of both trunks
auto bond0
iface bond0 inet manual
    bond-slaves ${BOND_MEMBERS}
    bond-mode ${BOND_MODE}
    bond-miimon ${BOND_MIIMON}
    bond-lacp-rate ${BOND_LACP_RATE}
    mtu ${BOND_MTU}

# QinQ outer VLAN ${QINQ_OUTER} on the bond
auto bond0.${QINQ_OUTER}
iface bond0.${QINQ_OUTER} inet manual
    vlan-raw-device bond0
    vlan-id ${QINQ_OUTER}
    mtu ${BOND_MTU}

# Q-in-Q inner VLAN ${VLAN_RR1} (to bkk00/rr1)
auto vlan${VLAN_RR1}
iface vlan${VLAN_RR1} inet manual
    vlan-raw-device bond0.${QINQ_OUTER}
    vlan-id ${VLAN_RR1}
    mtu 1500

# Q-in-Q inner VLAN ${VLAN_RR2} (to bkk20/rr2)
auto vlan${VLAN_RR2}
iface vlan${VLAN_RR2} inet manual
    vlan-raw-device bond0.${QINQ_OUTER}
    vlan-id ${VLAN_RR2}
    mtu 1500

# Internal services bridge
auto vmbr1
iface vmbr1 inet static
    address 10.${SITE_NUM}.0.1
    netmask 255.255.0.0
    bridge-ports none
    bridge-stp off
    bridge-fd 0

iface vmbr1 inet6 static
    address ${INTERNAL_V6%%/*}::1/48
    accept_ra 0
    autoconf 0

# Public services bridge (Q-in-Q terminated)
auto vmbr2
iface vmbr2 inet static
    bridge-ports vlan${VLAN_RR2} vlan${VLAN_RR1}
    bridge-stp off
    bridge-fd 0
    address ${BGP_RR1_V4}/31
    address ${BGP_RR2_V4}/31
    mtu 1500
INTERFACES

  # Add anycast routing if anycast IPs are present
  if [[ -n "$ANYCAST_LOCAL_V4" ]] || [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    cat <<ANYCAST_V4
    # Anycast source routing for IPv4
    post-up echo "100 anycast" >> /etc/iproute2/rt_tables 2>/dev/null || true
ANYCAST_V4
    
    if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
      echo "    post-up ip rule add from ${ANYCAST_LOCAL_V4} table anycast priority 100 2>/dev/null || true"
    fi
    if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
      echo "    post-up ip rule add from ${ANYCAST_GLOBAL_V4} table anycast priority 100 2>/dev/null || true"
    fi
    
    echo "    post-up ip route add default table anycast nexthop via ${RR1_GW_V4} dev vmbr2 weight 1 nexthop via ${RR2_GW_V4} dev vmbr2 weight 1 2>/dev/null || true"
    echo "    # Cleanup on interface down"
    
    if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
      echo "    pre-down ip rule del from ${ANYCAST_LOCAL_V4} table anycast 2>/dev/null || true"
    fi
    if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
      echo "    pre-down ip rule del from ${ANYCAST_GLOBAL_V4} table anycast 2>/dev/null || true"
    fi
    
    echo "    pre-down ip route flush table anycast 2>/dev/null || true"
  fi

  cat <<INTERFACES

iface vmbr2 inet6 static
    address ${BGP_RR1_V6}/127
    address ${BGP_RR2_V6}/127
    accept_ra 0
    autoconf 0
INTERFACES

  # Add IPv6 anycast routing if present
  if [[ -n "$ANYCAST_LOCAL_V6" ]] || [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    cat <<ANYCAST_V6
    # Anycast source routing for IPv6
    post-up echo "100 anycast" >> /etc/iproute2/rt_tables 2>/dev/null || true
ANYCAST_V6
    
    if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
      echo "    post-up ip -6 rule add from ${ANYCAST_LOCAL_V6} table anycast priority 100 2>/dev/null || true"
    fi
    if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
      echo "    post-up ip -6 rule add from ${ANYCAST_GLOBAL_V6} table anycast priority 100 2>/dev/null || true"
    fi
    
    echo "    post-up ip -6 route add default table anycast nexthop via ${RR1_GW_V6} dev vmbr2 weight 1 nexthop via ${RR2_GW_V6} dev vmbr2 weight 1 2>/dev/null || true"
    echo "    # Cleanup on interface down"
    
    if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
      echo "    pre-down ip -6 rule del from ${ANYCAST_LOCAL_V6} table anycast 2>/dev/null || true"
    fi
    if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
      echo "    pre-down ip -6 rule del from ${ANYCAST_GLOBAL_V6} table anycast 2>/dev/null || true"
    fi
    
    echo "    pre-down ip -6 route flush table anycast 2>/dev/null || true"
  fi

  # Add any remaining unused interfaces at the end
  if [[ -n "$UNUSED_IFACES" ]]; then
    echo ""
    echo "# Unused interfaces"
    for iface in $UNUSED_IFACES; do
      echo "iface $iface inet manual"
    done
  fi
}

# main execution
generate_interfaces
