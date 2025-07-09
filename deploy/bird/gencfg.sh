#!/usr/bin/env bash
# bird config generator using central config
set -euo pipefail

# load config
CONFIG_FILE="${CONFIG_FILE:-../config.json}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "error: config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# validate site argument
readonly SITE="${1:-}"
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
ROUTER_ID=$(echo "$SITE_CONFIG" | jq -r '.router_id')
LOCAL_IP4=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_v4')
LOCAL_IP6=$(echo "$SITE_CONFIG" | jq -r '.bgp_local_v6')
PUBLIC_IP4=$(echo "$SITE_CONFIG" | jq -r '.public_v4')
PUBLIC_IP6=$(echo "$SITE_CONFIG" | jq -r '.public_v6')
INTERNAL_NET6=$(echo "$SITE_CONFIG" | jq -r '.internal_v6')
INTERNAL_NET4=$(echo "$SITE_CONFIG" | jq -r '.internal_v4')

# extract global config
AS_NUMBER=$(jq -r '.as_number' "$CONFIG_FILE")

# generate bird configuration
generate_bird_config() {
    cat << BIRD
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
    cat << CONSTANTS
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

# Route Reflector IPs
CONSTANTS

    # add RR IPs from config
    jq -r '.route_reflectors | to_entries | .[] | "define \(.key | ascii_upcase)_IP4 = \(.value.v4);"' "$CONFIG_FILE"
    jq -r '.route_reflectors | to_entries | .[] | "define \(.key | ascii_upcase)_IP6 = \(.value.v6);"' "$CONFIG_FILE"
    
    cat << 'CONSTANTS_END'

# Local IPs for BGP sessions
CONSTANTS_END
    echo "define LOCAL_IP4 = ${LOCAL_IP4};"
    echo "define LOCAL_IP6 = ${LOCAL_IP6};"
    
    cat << 'PREFERENCES'

# BGP Preferences
define PREF_IPV6 = 200;
define PREF_IPV4 = 150;
define LOCAL_PREF_PRIMARY = 100;
define LOCAL_PREF_BACKUP = 90;

# Timers
define BGP_HOLD_TIME = 30;
define BGP_KEEPALIVE = 10;
define BFD_MIN_RX = 100 ms;
define BFD_MIN_TX = 100 ms;
define BFD_MULTIPLIER = 3;
define SCAN_TIME = 10;
PREFERENCES
}

# generate logging configuration
generate_logging() {
    cat << 'LOGGING'
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
    local bgp_iface=$(jq -r '.interfaces.bgp_vlan' "$CONFIG_FILE")
    cat << TEMPLATES
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
    cat << 'KERNEL'
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
    local bgp_iface=$(jq -r '.interfaces.bgp_vlan' "$CONFIG_FILE")
    cat << BASIC
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
    cat << 'STATIC'
#
# Static Routes
#
protocol static static4 {
    ipv4;
    route PUBLIC_NET4 unreachable;
    route INTERNAL_NET4 unreachable;
}

protocol static static6 {
    ipv6;
    route PUBLIC_NET6 unreachable;
    route INTERNAL_NET6 unreachable;
}
STATIC
}

# generate bfd protocol
generate_bfd() {
    local bgp_iface=$(jq -r '.interfaces.bgp_vlan' "$CONFIG_FILE")
    cat << BFD
#
# BFD Protocol
#
protocol bfd {
    interface "${bgp_iface}" {
        min rx interval BFD_MIN_RX;
        min tx interval BFD_MIN_TX;
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
    
    # generate sessions for each RR
    jq -r '.route_reflectors | keys[]' "$CONFIG_FILE" | while read -r rr_key; do
        rr_name=$(jq -r ".route_reflectors.$rr_key.name" "$CONFIG_FILE")
        rr_key_upper=$(echo "$rr_key" | tr '[:lower:]' '[:upper:]')
        
        # IPv6 session
        cat << BGP_V6

protocol bgp ${rr_key_upper}_v6 from BGP_COMMON {
    description "Route Reflector - ${rr_name} IPv6";
    neighbor ${rr_key_upper}_IP6 as LOCAL_AS;
    source address LOCAL_IP6;

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
            # Export our networks
            if net = PUBLIC_NET6 then accept;
            if net ~ INTERNAL_NET6 then accept;
            # Don't export learned routes
            reject;
        };
    };
}
BGP_V6

        # IPv4 session
        cat << BGP_V4

protocol bgp ${rr_key_upper}_v4 from BGP_COMMON {
    description "Route Reflector - ${rr_name} IPv4";
    neighbor ${rr_key_upper}_IP4 as LOCAL_AS;
    source address LOCAL_IP4;

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
            if net ~ INTERNAL_NET4 then accept;
            reject;
        };
    };
}
BGP_V4
    done
}

# main execution
generate_bird_config
