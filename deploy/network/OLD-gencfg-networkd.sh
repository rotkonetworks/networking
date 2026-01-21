#!/usr/bin/env bash
set -euo pipefail

# Find script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/../config/network.json}"

# Parse options
OUTPUT_DIR=""
while getopts ':c:o:' opt; do
  case "$opt" in
  c) CONFIG_FILE="$OPTARG" ;;
  o) OUTPUT_DIR="$OPTARG" ;;
  *)
    echo "Usage: $0 [-c <config-file>] [-o <output-dir>] <site>" >&2
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

# Set output directory
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="${SCRIPT_DIR}/output/${SITE}/systemd-network"
fi
mkdir -p "$OUTPUT_DIR"

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
BOND_MTU=$(jq -r '.bond_config.mtu // 9000' "$CONFIG_FILE")

# fix IPv6 addresses to ensure no extra colons
INTERNAL_V6_PREFIX="${INTERNAL_V6%%/*}"
while [[ "$INTERNAL_V6_PREFIX" == *: ]]; do
  INTERNAL_V6_PREFIX="${INTERNAL_V6_PREFIX%:}"
done

# Helper to write a file
write_file() {
  local filename="$1"
  local content="$2"
  echo "$content" > "${OUTPUT_DIR}/${filename}"
  echo "  Created: ${filename}"
}

echo "Generating systemd-networkd configuration for ${SITE}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Generate loopback configuration
generate_loopback() {
  local content
  content="# Loopback interface for ${SITE}
# Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")

[Match]
Name=lo

[Network]
# Router ID
Address=${ROUTER_ID}/32
# Public IPv4
Address=${PUBLIC_V4}/32"

  # Add anycast IPv4 addresses
  [[ -n "$ANYCAST_LOCAL_V4" ]] && content+="
# Anycast local (ULA) - internal services
Address=${ANYCAST_LOCAL_V4}/32"
  [[ -n "$ANYCAST_SITE_V4" ]] && content+="
# Anycast site (GUA) - Bangkok only
Address=${ANYCAST_SITE_V4}/32"
  [[ -n "$ANYCAST_GLOBAL_V4" ]] && content+="
# Anycast global (GUA) - worldwide
Address=${ANYCAST_GLOBAL_V4}/32"

  content+="

# Router ID IPv6
Address=fd00:155:255::${SITE_NUM}/128
# Public IPv6
Address=${PUBLIC_V6}/128"

  # Add anycast IPv6 addresses
  [[ -n "$ANYCAST_LOCAL_V6" ]] && content+="
# Anycast local (ULA) - internal services
Address=${ANYCAST_LOCAL_V6}/128"
  [[ -n "$ANYCAST_SITE_V6" ]] && content+="
# Anycast site (GUA) - Bangkok only
Address=${ANYCAST_SITE_V6}/128"
  [[ -n "$ANYCAST_GLOBAL_V6" ]] && content+="
# Anycast global (GUA) - worldwide
Address=${ANYCAST_GLOBAL_V6}/128"

  write_file "05-lo.network" "$content"
}

# Generate management interface configuration
generate_management() {
  local content
  content="# Management interface for ${SITE}
# Generated on $(date -u +"%Y-%m-%d %H:%M:%S UTC")

[Match]
Name=${MGMT_IFACE}

[Network]
Address=${MANAGEMENT_IP}
Gateway=${MGMT_GATEWAY}
DNS=9.9.9.9
DNS=1.1.1.1"

  # Add IPv6 management if configured
  if [[ -n "$MANAGEMENT_V6" ]]; then
    content+="
Address=${MANAGEMENT_V6}
Gateway=${MANAGEMENT_V6_GW}
DNS=2620:fe::9
DNS=2606:4700:4700::1111"
  fi

  content+="

[Route]
# Management routing table
Destination=0.0.0.0/0
Gateway=${MGMT_GATEWAY}
Table=102

[Route]
Destination=${MGMT_NETWORK}
Scope=link
Table=102

[RoutingPolicyRule]
From=${MANAGEMENT_IP%%/*}
Table=102
Priority=300

[RoutingPolicyRule]
To=${MANAGEMENT_IP%%/*}
Table=102
Priority=301"

  write_file "10-management.network" "$content"
}

# Generate unused interface configurations
generate_unused() {
  for iface in $UNUSED_IFACES; do
    local content="# Unused interface - disabled
[Match]
Name=${iface}

[Link]
Unmanaged=yes"
    write_file "09-unused-${iface}.network" "$content"
  done
}

# Generate bonded VLAN configuration (Q-in-Q with bond)
generate_bonded_vlans() {
  local uplink1 uplink2

  uplink1=$(echo "$BOND_MEMBERS" | awk '{print $1}')
  uplink2=$(echo "$BOND_MEMBERS" | awk '{print $2}')

  # Use full interface names for VLANs (e.g., enp2s0f0np0.400)
  local vlan_outer1="${uplink1}.${QINQ_OUTER}"
  local vlan_outer2="${uplink2}.${QINQ_OUTER}"
  local vlan_inner1="vlan${BGP_RR_VLAN}-p1"
  local vlan_inner2="vlan${BGP_RR_VLAN}-p2"

  # Physical uplink interfaces
  write_file "20-uplink1.network" "# Physical uplink 1
[Match]
Name=${uplink1}

[Link]
MTUBytes=${BOND_MTU}

[Network]
VLAN=${vlan_outer1}"

  write_file "20-uplink2.network" "# Physical uplink 2
[Match]
Name=${uplink2}

[Link]
MTUBytes=${BOND_MTU}

[Network]
VLAN=${vlan_outer2}"

  # Outer VLAN netdev files
  write_file "21-vlan${QINQ_OUTER}-p1.netdev" "[NetDev]
Name=${vlan_outer1}
Kind=vlan

[VLAN]
Id=${QINQ_OUTER}"

  write_file "21-vlan${QINQ_OUTER}-p2.netdev" "[NetDev]
Name=${vlan_outer2}
Kind=vlan

[VLAN]
Id=${QINQ_OUTER}"

  # Outer VLAN network files - add inner VLAN
  write_file "22-vlan${QINQ_OUTER}-p1.network" "# Outer Q-in-Q VLAN on uplink 1
[Match]
Name=${vlan_outer1}

[Link]
MTUBytes=${BOND_MTU}

[Network]
VLAN=${vlan_inner1}"

  write_file "22-vlan${QINQ_OUTER}-p2.network" "# Outer Q-in-Q VLAN on uplink 2
[Match]
Name=${vlan_outer2}

[Link]
MTUBytes=${BOND_MTU}

[Network]
VLAN=${vlan_inner2}"

  # Inner VLAN netdev files (BGP RR VLAN)
  write_file "23-vlan${BGP_RR_VLAN}-p1.netdev" "[NetDev]
Name=vlan${BGP_RR_VLAN}-p1
Kind=vlan

[VLAN]
Id=${BGP_RR_VLAN}"

  write_file "23-vlan${BGP_RR_VLAN}-p2.netdev" "[NetDev]
Name=vlan${BGP_RR_VLAN}-p2
Kind=vlan

[VLAN]
Id=${BGP_RR_VLAN}"

  # Inner VLAN network files - join bond
  write_file "24-vlan${BGP_RR_VLAN}-p1.network" "# Inner Q-in-Q VLAN for BGP RR (path 1)
[Match]
Name=vlan${BGP_RR_VLAN}-p1

[Link]
MTUBytes=1500

[Network]
Bond=bond-bgp"

  write_file "24-vlan${BGP_RR_VLAN}-p2.network" "# Inner Q-in-Q VLAN for BGP RR (path 2)
[Match]
Name=vlan${BGP_RR_VLAN}-p2

[Link]
MTUBytes=1500

[Network]
Bond=bond-bgp"

  # Bond netdev
  local bond_mode_systemd
  case "$BOND_MODE" in
    "active-backup") bond_mode_systemd="active-backup" ;;
    "802.3ad") bond_mode_systemd="802.3ad" ;;
    *) bond_mode_systemd="active-backup" ;;
  esac

  write_file "25-bond-bgp.netdev" "[NetDev]
Name=bond-bgp
Kind=bond

[Bond]
Mode=${bond_mode_systemd}
PrimaryReselectPolicy=always
MIIMonitorSec=$(( BOND_MIIMON / 1000 )).$(printf '%03d' $((BOND_MIIMON % 1000)))
TransmitHashPolicy=layer3+4"

  # Bond network - join bridge
  write_file "26-bond-bgp.network" "# BGP RR bond
[Match]
Name=bond-bgp

[Link]
MTUBytes=1500

[Network]
Bridge=vmbr2"
}

# Generate internal bridge (vmbr1)
generate_vmbr1() {
  write_file "30-vmbr1.netdev" "[NetDev]
Name=vmbr1
Kind=bridge

[Bridge]
STP=false
ForwardDelaySec=0"

  local content="# Internal services bridge
[Match]
Name=vmbr1

[Network]
Address=10.${SITE_NUM}.0.1/16
Address=${INTERNAL_V6_PREFIX}::1/48
IPv6AcceptRA=false"

  write_file "31-vmbr1.network" "$content"
}

# Generate public bridge (vmbr2 - BGP RR network)
generate_vmbr2() {
  write_file "40-vmbr2.netdev" "[NetDev]
Name=vmbr2
Kind=bridge

[Bridge]
STP=false
ForwardDelaySec=0"

  # Check if site has anycast addresses
  local has_anycast=false
  [[ -n "$ANYCAST_LOCAL_V4" || -n "$ANYCAST_SITE_V4" || -n "$ANYCAST_GLOBAL_V4" ]] && has_anycast=true

  local content="# Public services bridge (BGP RR network)

[Match]
Name=vmbr2

[Link]
MTUBytes=1500

[Network]
Address=${BGP_RR_V4}/${BGP_NETWORK_V4##*/}
Address=${BGP_RR_V6}/${BGP_NETWORK_V6##*/}
IPv6AcceptRA=false"

  # Only add anycast routing complexity if site has anycast addresses
  if [[ "$has_anycast" == "true" ]]; then
    content+="

# Default routes in anycast table (ECMP to both RRs)
[Route]
Destination=0.0.0.0/0
Gateway=${RR1_GW_V4}
Table=100
MultiPathRoute=${RR2_GW_V4} 1

[Route]
Destination=::/0
Gateway=${RR1_GW_V6}
Table=100
MultiPathRoute=${RR2_GW_V6} 1"

    # Add routing policy rules for IPv4 anycast
    local priority=45

    if [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
      content+="

[RoutingPolicyRule]
From=${ANYCAST_GLOBAL_V4}
Table=100
Priority=${priority}"
      ((priority++))
    fi

    if [[ -n "$ANYCAST_SITE_V4" ]]; then
      content+="

[RoutingPolicyRule]
From=${ANYCAST_SITE_V4}
Table=100
Priority=${priority}"
      ((priority++))
    fi

    if [[ -n "$ANYCAST_LOCAL_V4" ]]; then
      content+="

[RoutingPolicyRule]
From=${ANYCAST_LOCAL_V4}
Table=100
Priority=${priority}"
      ((priority++))
    fi

    content+="

[RoutingPolicyRule]
From=${PUBLIC_V4}
Table=100
Priority=49

[RoutingPolicyRule]
From=${PUBLIC_V4}
Table=254
Priority=50"

    priority=51
    [[ -n "$ANYCAST_LOCAL_V4" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_LOCAL_V4}
Table=254
Priority=${priority}" && ((priority++))

    [[ -n "$ANYCAST_SITE_V4" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_SITE_V4}
Table=254
Priority=${priority}" && ((priority++))

    [[ -n "$ANYCAST_GLOBAL_V4" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_GLOBAL_V4}
Table=254
Priority=${priority}" && ((priority++))

    content+="

[RoutingPolicyRule]
IncomingInterface=vmbr2
Table=254
Priority=60"

    # Add routing policy rules for IPv6 anycast
    priority=45

    [[ -n "$ANYCAST_GLOBAL_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_GLOBAL_V6}
Table=100
Priority=${priority}
Family=ipv6" && ((priority++))

    [[ -n "$ANYCAST_SITE_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_SITE_V6}
Table=100
Priority=${priority}
Family=ipv6" && ((priority++))

    [[ -n "$ANYCAST_LOCAL_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_LOCAL_V6}
Table=100
Priority=${priority}
Family=ipv6" && ((priority++))

    content+="

[RoutingPolicyRule]
From=${PUBLIC_V6}
Table=100
Priority=49
Family=ipv6

[RoutingPolicyRule]
From=${PUBLIC_V6}
Table=254
Priority=50
Family=ipv6"

    priority=51
    [[ -n "$ANYCAST_LOCAL_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_LOCAL_V6}
Table=254
Priority=${priority}
Family=ipv6" && ((priority++))

    [[ -n "$ANYCAST_SITE_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_SITE_V6}
Table=254
Priority=${priority}
Family=ipv6" && ((priority++))

    [[ -n "$ANYCAST_GLOBAL_V6" ]] && content+="

[RoutingPolicyRule]
From=${ANYCAST_GLOBAL_V6}
Table=254
Priority=${priority}
Family=ipv6" && ((priority++))

    content+="

[RoutingPolicyRule]
IncomingInterface=vmbr2
Table=254
Priority=60
Family=ipv6"
  fi

  write_file "41-vmbr2.network" "$content"
}

# Generate routing tables file (optional, for named table support)
generate_rt_tables() {
  local content="# Routing tables for ${SITE}
# Optional: add to /etc/iproute2/rt_tables for named table support
# The generated configs use numeric IDs so this file is not required
#
# 102     mgmt      # Management routing isolation
# 100     anycast   # Anycast source routing"

  write_file "rt_tables.conf" "$content"
}

# Main execution
echo "Files:"
generate_loopback
generate_management
generate_unused

if [[ "$BONDED_VLANS" == "true" ]]; then
  generate_bonded_vlans
fi

generate_vmbr1
generate_vmbr2
generate_rt_tables

echo ""
echo "Done! To deploy:"
echo "  1. Copy *.netdev and *.network files to /etc/systemd/network/"
echo "  2. Run: systemctl restart systemd-networkd"
echo ""
echo "Note: Configs use numeric table IDs (100=anycast, 102=mgmt), no rt_tables file needed."
