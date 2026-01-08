#!/usr/bin/env bash
# bird config generator with unified BGP RR network and three-tier anycast support
set -euo pipefail

# Find script directory and config file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/../config/network.json"

# If no config dir exists at parent level, try current dir
if [[ ! -f "$DEFAULT_CONFIG" ]] && [[ -f "${SCRIPT_DIR}/config/network.json" ]]; then
  DEFAULT_CONFIG="${SCRIPT_DIR}/config/network.json"
fi

CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG}"

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
  echo "tried: $CONFIG_FILE" >&2
  echo "you can specify config with: $0 -c /path/to/config.json <site>" >&2
  exit 1
fi

# validate site argument
readonly SITE="${1:-}"
SITE_UPPER="$(echo "$SITE" | tr '[:lower:]' '[:upper:]')"
if [[ -z "$SITE" ]]; then
  echo "usage: $0 [-c config.json] <site>" >&2
  echo "valid sites: $(jq -r '.sites | keys[]' "$CONFIG_FILE" | tr '\n' ' ')" >&2
  exit 1
fi

# validate site exists
if ! jq -e ".sites.$SITE" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "error: invalid site: $SITE" >&2
  exit 1
fi

# Check if site has BGP configuration
SITE_CONFIG=$(jq -r ".sites.$SITE" "$CONFIG_FILE")
BGP_RR_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v4 // empty')
if [[ -z "$BGP_RR_V4" ]]; then
  echo "error: site $SITE does not have BGP configuration (no bgp_rr_v4)" >&2
  echo "this generator only works for BGP-enabled sites" >&2
  exit 1
fi

# extract site config
ROUTER_ID=$(echo "$SITE_CONFIG" | jq -r '.router_id')
PUBLIC_IP4=$(echo "$SITE_CONFIG" | jq -r '.public_v4')
PUBLIC_IP6=$(echo "$SITE_CONFIG" | jq -r '.public_v6')
INTERNAL_NET6=$(echo "$SITE_CONFIG" | jq -r '.internal_v6')
INTERNAL_NET4=$(echo "$SITE_CONFIG" | jq -r '.internal_v4')

# Extract BGP RR network IPs
BGP_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v4')
BGP_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.bgp_rr_v6')

# Get RR IPs from the network config
BGP_NETWORK_V4=$(jq -r '.networks.bgp_rr_network.v4' "$CONFIG_FILE")
BGP_NETWORK_V6=$(jq -r '.networks.bgp_rr_network.v6' "$CONFIG_FILE")

# Get RR IPs
RR1_IP4=$(jq -r '.sites.bkk00.bgp_rr_v4 // empty' "$CONFIG_FILE")
RR1_IP6=$(jq -r '.sites.bkk00.bgp_rr_v6 // empty' "$CONFIG_FILE")
RR2_IP4=$(jq -r '.sites.bkk20.bgp_rr_v4 // empty' "$CONFIG_FILE")
RR2_IP6=$(jq -r '.sites.bkk20.bgp_rr_v6 // empty' "$CONFIG_FILE")

# extract all three anycast tiers if present
# Local (ULA) - internal only
ANYCAST_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v4 // empty' 2>/dev/null | sed 's|/32||')
ANYCAST_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v6 // empty' 2>/dev/null)

# Site (GUA) - Bangkok only
ANYCAST_SITE_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v4 // empty' 2>/dev/null | sed 's|/32||')
ANYCAST_SITE_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v6 // empty' 2>/dev/null)

# Global (GUA) - worldwide
ANYCAST_GLOBAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v4 // empty' 2>/dev/null | sed 's|/32||')
ANYCAST_GLOBAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v6 // empty' 2>/dev/null)

# extract anycast network prefixes from global config
ANYCAST_LOCAL_V6_PREFIX=$(jq -r '.networks.anycast_v6.local // empty' "$CONFIG_FILE")
ANYCAST_SITE_V6_PREFIX=$(jq -r '.networks.anycast_v6.site // empty' "$CONFIG_FILE")
ANYCAST_GLOBAL_V6_PREFIX=$(jq -r '.networks.anycast_v6.global // empty' "$CONFIG_FILE")

# extract global config
AS_NUMBER=$(jq -r '.as_number' "$CONFIG_FILE")

# generate bird configuration
generate_bird_config() {
  cat <<BIRD
# BIRD 2.x configuration for ${SITE^^}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Config hash: $(echo -n "$SITE_CONFIG" | sha256sum | cut -d' ' -f1)

$(generate_constants)

$(generate_logging)

$(generate_templates)

$(generate_kernel_protocols)

$(generate_basic_protocols)

$(generate_static_routes)

$(generate_bfd)

$(generate_bgp_sessions)
BIRD
}

# generate constants section
generate_constants() {
  cat <<CONSTANTS
#
# Router Identity and Constants
#
router id ${ROUTER_ID};

# AS Numbers
define LOCAL_AS = ${AS_NUMBER};

# Public IPs
define PUBLIC_IP4 = ${PUBLIC_IP4};
define PUBLIC_IP6 = ${PUBLIC_IP6};

# Network Prefixes
define PUBLIC_NET4 = ${PUBLIC_IP4}/32;
define PUBLIC_NET6 = ${PUBLIC_IP6}/128;
define INTERNAL_NET4 = ${INTERNAL_NET4};
define INTERNAL_NET6 = ${INTERNAL_NET6};

# BGP RR Network (unified)
define BGP_NETWORK_V4 = ${BGP_NETWORK_V4};
define BGP_NETWORK_V6 = ${BGP_NETWORK_V6};

# Route Reflector IPs
define RR1_IP4 = ${RR1_IP4};
define RR1_IP6 = ${RR1_IP6};
define RR2_IP4 = ${RR2_IP4};
define RR2_IP6 = ${RR2_IP6};

# Local BGP IPs
define LOCAL_IP4 = ${BGP_LOCAL_V4};
define LOCAL_IP6 = ${BGP_LOCAL_V6};
CONSTANTS

  # Add anycast constants - all three tiers
  if [[ -n "$ANYCAST_LOCAL_V4" ]] || [[ -n "$ANYCAST_SITE_V4" ]] || [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
    echo ""
    echo "# Anycast IPv4 addresses (/32)"
    [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "define ANYCAST_LOCAL_V4 = ${ANYCAST_LOCAL_V4}/32;  # ULA - internal only"
    [[ -n "$ANYCAST_SITE_V4" ]] && echo "define ANYCAST_SITE_V4 = ${ANYCAST_SITE_V4}/32;    # Bangkok site-local"
    [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "define ANYCAST_GLOBAL_V4 = ${ANYCAST_GLOBAL_V4}/32; # Global multi-site"
  fi

  if [[ -n "$ANYCAST_LOCAL_V6" ]] || [[ -n "$ANYCAST_SITE_V6" ]] || [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo ""
    echo "# Anycast IPv6 host addresses (/128 - for loopback)"
    [[ -n "$ANYCAST_LOCAL_V6" ]] && echo "define ANYCAST_LOCAL_V6_HOST = ${ANYCAST_LOCAL_V6}/128;  # ULA - internal"
    [[ -n "$ANYCAST_SITE_V6" ]] && echo "define ANYCAST_SITE_V6_HOST = ${ANYCAST_SITE_V6}/128;    # GUA - Bangkok"
    [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "define ANYCAST_GLOBAL_V6_HOST = ${ANYCAST_GLOBAL_V6}/128; # GUA - global"

    echo ""
    echo "# Anycast IPv6 network prefixes (for BGP announcement)"
    [[ -n "$ANYCAST_LOCAL_V6_PREFIX" ]] && echo "define ANYCAST_LOCAL_V6_PREFIX = ${ANYCAST_LOCAL_V6_PREFIX};  # ULA /48 - internal only"
    [[ -n "$ANYCAST_SITE_V6_PREFIX" ]] && echo "define ANYCAST_SITE_V6_PREFIX = ${ANYCAST_SITE_V6_PREFIX};    # GUA /48 - Bangkok"
    [[ -n "$ANYCAST_GLOBAL_V6_PREFIX" ]] && echo "define ANYCAST_GLOBAL_V6_PREFIX = ${ANYCAST_GLOBAL_V6_PREFIX}; # GUA /36 - global"
  fi

  cat <<'PREFERENCES'

# BGP Preferences
define PREF_IPV6 = 200;
define PREF_IPV4 = 150;
define LOCAL_PREF_PRIMARY = 100;
define LOCAL_PREF_BACKUP = 90;

# Timers
define BGP_HOLD_TIME = 30;
define BGP_KEEPALIVE = 10;
define BFD_MIN_RX = 100;
define BFD_MIN_TX = 100;
define BFD_MULTIPLIER = 3;
define SCAN_TIME = 10;
PREFERENCES
}

# generate logging configuration
generate_logging() {
  cat <<'LOGGING'
#
# Logging Configuration
#
log syslog all;
log "/var/log/bird.log" all;

timeformat base iso long;
timeformat log iso long;
timeformat protocol iso long;
timeformat route iso long;
LOGGING
}

# generate bgp templates
generate_templates() {
  local bgp_iface=$(jq -r '.interfaces.bgp_vlan // "vmbr2"' "$CONFIG_FILE")
  cat <<TEMPLATES
#
# BGP Templates
#
template bgp BGP_COMMON {
    local as LOCAL_AS;
    # Direct connection over ${bgp_iface}
    direct;
    
    # Faster convergence
    hold time BGP_HOLD_TIME;
    keepalive time BGP_KEEPALIVE;
    
    # BFD for fast failure detection
    bfd on;
    
    # Graceful restart
    graceful restart on;
    graceful restart time 120;
}
TEMPLATES
}

# generate kernel protocols
generate_kernel_protocols() {
  cat <<'KERNEL'
#
# Kernel Protocols
#
protocol kernel kernel4 {
    ipv4 {
        export filter {
            # Don't export kernel routes back
            if source = RTS_DEVICE then reject;
            if source = RTS_STATIC then reject;
            accept;
        };
        import all;
    };
    learn;
    scan time SCAN_TIME;
    merge paths on;
}

protocol kernel kernel6 {
    ipv6 {
        export filter {
            if source = RTS_DEVICE then reject;
            if source = RTS_STATIC then reject;
            accept;
        };
        import all;
    };
    learn;
    scan time SCAN_TIME;
    merge paths on;
}
KERNEL
}

# generate basic protocols
generate_basic_protocols() {
  local bgp_iface=$(jq -r '.interfaces.bgp_vlan // "vmbr2"' "$CONFIG_FILE")
  cat <<BASIC
#
# Basic Protocols
#
protocol device {
    scan time SCAN_TIME;
}

protocol direct {
    ipv4;
    ipv6;
    interface "vmbr*", "lo", "${bgp_iface}";
}
BASIC
}

# generate static routes
generate_static_routes() {
  cat <<'STATIC'
#
# Static Routes
#
protocol static static4 {
    ipv4;
    route PUBLIC_NET4 unreachable;
STATIC

  # Add IPv4 anycast routes - all three tiers
  [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "    route ${ANYCAST_LOCAL_V4}/32 unreachable;  # ULA - internal only"
  [[ -n "$ANYCAST_SITE_V4" ]] && echo "    route ${ANYCAST_SITE_V4}/32 unreachable;    # Bangkok site-local"
  [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "    route ${ANYCAST_GLOBAL_V4}/32 unreachable;  # Global multi-site"

  cat <<'STATIC_CONT'
    route INTERNAL_NET4 unreachable;
}

protocol static static6 {
    ipv6;
    route PUBLIC_NET6 unreachable;
STATIC_CONT

  # Add IPv6 anycast routes - all three tiers with both /128 and prefix routes
  if [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "    # Local anycast (ULA) - internal use only"
    echo "    route ${ANYCAST_LOCAL_V6}/128 unreachable;"
    [[ -n "$ANYCAST_LOCAL_V6_PREFIX" ]] && echo "    route ${ANYCAST_LOCAL_V6_PREFIX} unreachable;"
  fi

  if [[ -n "$ANYCAST_SITE_V6" ]]; then
    echo "    # Site anycast (GUA) - Bangkok only"
    echo "    route ${ANYCAST_SITE_V6}/128 unreachable;"
    [[ -n "$ANYCAST_SITE_V6_PREFIX" ]] && echo "    route ${ANYCAST_SITE_V6_PREFIX} unreachable;"
  fi

  if [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "    # Global anycast (GUA) - multi-site"
    echo "    route ${ANYCAST_GLOBAL_V6}/128 unreachable;"
    [[ -n "$ANYCAST_GLOBAL_V6_PREFIX" ]] && echo "    route ${ANYCAST_GLOBAL_V6_PREFIX} unreachable;"
  fi

  cat <<'STATIC_V6_CONT'
    route INTERNAL_NET6 unreachable;
}
STATIC_V6_CONT
}

# generate bfd protocol
generate_bfd() {
  local bgp_iface=$(jq -r '.interfaces.bgp_vlan // "vmbr2"' "$CONFIG_FILE")
  cat <<BFD
#
# BFD Protocol
#
protocol bfd {
    interface "${bgp_iface}" {
        min rx interval BFD_MIN_RX ms;
        min tx interval BFD_MIN_TX ms;
        multiplier BFD_MULTIPLIER;
    };
}
BFD
}

# generate bgp sessions
generate_bgp_sessions() {
  echo "#"
  echo "# BGP Sessions to Route Reflectors"
  echo "#"
  
  # Generate IPv6 session to RR1
  cat <<BGP_V6_RR1

protocol bgp RR1_v6 from BGP_COMMON {
    description "Route Reflector 1 - bkk00 IPv6";
    neighbor ${RR1_IP6} as LOCAL_AS;
    source address ${BGP_LOCAL_V6};
    
    ipv6 {
        next hop self;
        import filter {
            # Prefer IPv6 routes
            preference = PREF_IPV6;
            
            # Accept default route
            if net = ::/0 then {
                bgp_local_pref = LOCAL_PREF_PRIMARY;
                accept;
            }
            
            # Accept all other routes
            accept;
        };
        export filter {
            # Export our unicast
            if net = PUBLIC_NET6 then accept;
            
            # Export GUA anycast prefixes for external BGP
            # Site-local /48 - Bangkok only services
            if net = ANYCAST_SITE_V6_PREFIX then accept;
            # Global /36 - worldwide services
            if net = ANYCAST_GLOBAL_V6_PREFIX then accept;
            
            # ULA anycast stays internal only (not exported to eBGP)
            # But we can export to iBGP for internal routing
            if net = ANYCAST_LOCAL_V6_PREFIX then accept;
            
            # Internal networks
            if net ~ INTERNAL_NET6 then accept;
            
            # Don't export learned routes
            reject;
        };
    };
}
BGP_V6_RR1

  # Generate IPv4 session to RR1
  cat <<BGP_V4_RR1

protocol bgp RR1_v4 from BGP_COMMON {
    description "Route Reflector 1 - bkk00 IPv4";
    neighbor ${RR1_IP4} as LOCAL_AS;
    source address ${BGP_LOCAL_V4};
    
    ipv4 {
        next hop self;
        import filter {
            # Lower preference for IPv4
            preference = PREF_IPV4;
            
            # Accept default
            if net = 0.0.0.0/0 then {
                bgp_local_pref = LOCAL_PREF_BACKUP;
                accept;
            }
            accept;
        };
        export filter {
            if net = PUBLIC_NET4 then accept;
            
            # Export all anycast /32 addresses
            if net = ANYCAST_LOCAL_V4 then accept;  # ULA - internal
            if net = ANYCAST_SITE_V4 then accept;   # Bangkok only
            if net = ANYCAST_GLOBAL_V4 then accept; # Global
            
            if net ~ INTERNAL_NET4 then accept;
            reject;
        };
    };
}
BGP_V4_RR1

  # Generate IPv6 session to RR2
  cat <<BGP_V6_RR2

protocol bgp RR2_v6 from BGP_COMMON {
    description "Route Reflector 2 - bkk20 IPv6";
    neighbor ${RR2_IP6} as LOCAL_AS;
    source address ${BGP_LOCAL_V6};
    
    ipv6 {
        next hop self;
        import filter {
            # Prefer IPv6 routes
            preference = PREF_IPV6;
            
            # Accept default route
            if net = ::/0 then {
                bgp_local_pref = LOCAL_PREF_PRIMARY;
                accept;
            }
            
            # Accept all other routes
            accept;
        };
        export filter {
            # Export our unicast
            if net = PUBLIC_NET6 then accept;
            
            # Export GUA anycast prefixes for external BGP
            # Site-local /48 - Bangkok only services
            if net = ANYCAST_SITE_V6_PREFIX then accept;
            # Global /36 - worldwide services
            if net = ANYCAST_GLOBAL_V6_PREFIX then accept;
            
            # ULA anycast stays internal only (not exported to eBGP)
            # But we can export to iBGP for internal routing
            if net = ANYCAST_LOCAL_V6_PREFIX then accept;
            
            # Internal networks
            if net ~ INTERNAL_NET6 then accept;
            
            # Don't export learned routes
            reject;
        };
    };
}
BGP_V6_RR2

  # Generate IPv4 session to RR2
  cat <<BGP_V4_RR2

protocol bgp RR2_v4 from BGP_COMMON {
    description "Route Reflector 2 - bkk20 IPv4";
    neighbor ${RR2_IP4} as LOCAL_AS;
    source address ${BGP_LOCAL_V4};
    
    ipv4 {
        next hop self;
        import filter {
            # Lower preference for IPv4
            preference = PREF_IPV4;
            
            # Accept default
            if net = 0.0.0.0/0 then {
                bgp_local_pref = LOCAL_PREF_BACKUP;
                accept;
            }
            accept;
        };
        export filter {
            if net = PUBLIC_NET4 then accept;
            
            # Export all anycast /32 addresses
            if net = ANYCAST_LOCAL_V4 then accept;  # ULA - internal
            if net = ANYCAST_SITE_V4 then accept;   # Bangkok only
            if net = ANYCAST_GLOBAL_V4 then accept; # Global
            
            if net ~ INTERNAL_NET4 then accept;
            reject;
        };
    };
}
BGP_V4_RR2
}

# main execution
generate_bird_config
