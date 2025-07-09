#!/usr/bin/env bash
# bird config generator with strict error handling
set -euo pipefail

# site-specific configuration
declare -A SITES=(
    [bkk06]="10.155.255.6|10.155.106.0|fd00:155:106::0|160.22.181.6|2401:a860:181::6|2401:a860:6::/48|10.6.0.0/16"
    [bkk07]="10.155.255.7|10.155.107.0|fd00:155:107::0|160.22.181.7|2401:a860:181::7|2401:a860:7::/48|10.7.0.0/16"
    [bkk08]="10.155.255.8|10.155.108.0|fd00:155:108::0|160.22.181.8|2401:a860:181::8|2401:a860:8::/48|10.8.0.0/16"
)

# validate site argument
readonly SITE="${1:-}"
if [[ -z "$SITE" ]] || [[ -z "${SITES[$SITE]:-}" ]]; then
    echo "usage: $0 <site>" >&2
    echo "valid sites: ${!SITES[*]}" >&2
    exit 1
fi

# parse site configuration
IFS='|' read -r ROUTER_ID LOCAL_IP4 LOCAL_IP6 PUBLIC_IP4 PUBLIC_IP6 INTERNAL_NET6 INTERNAL_NET4 <<< "${SITES[$SITE]}"

# generate config with heredoc
cat << EOF
# BIRD 2.x configuration for ${SITE^^}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# SHA256: $(echo -n "${SITES[$SITE]}" | sha256sum | cut -d' ' -f1)

#
# Router Identity and Constants
#
router id ${ROUTER_ID};

# AS Numbers
define LOCAL_AS = 142108;

# Public IPs
define PUBLIC_IP4 = ${PUBLIC_IP4};
define PUBLIC_IP6 = ${PUBLIC_IP6};

# Network Prefixes
define PUBLIC_NET4 = ${PUBLIC_IP4}/32;
define PUBLIC_NET6 = ${PUBLIC_IP6}/128;
define INTERNAL_NET4 = ${INTERNAL_NET4};
define INTERNAL_NET6 = ${INTERNAL_NET6};

# Route Reflector IPs (point-to-point addresses)
define RR1_IP4 = 10.155.108.1;      # RR1 IPv4 /31
define RR1_IP6 = fd00:155:108::1;   # RR1 IPv6 /127
define RR2_IP4 = 10.155.208.1;      # RR2 IPv4 /31
define RR2_IP6 = fd00:155:208::1;   # RR2 IPv6 /127

# Local IPs for BGP sessions
define LOCAL_IP4 = ${LOCAL_IP4};
define LOCAL_IP6 = ${LOCAL_IP6};

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

#
# Logging Configuration
#
log syslog all;
log "/var/log/bird.log" all;

timeformat base iso long;
timeformat log iso long;
timeformat protocol iso long;
timeformat route iso long;

#
# BGP Templates
#
template bgp BGP_COMMON {
    local as LOCAL_AS;
    # Direct connection over vlan208
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

#
# Basic Protocols
#
protocol device {
    scan time SCAN_TIME;
}

protocol direct {
    ipv4;
    ipv6;
    interface "vmbr*", "lo", "vlan208";
}

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

#
# BFD Protocol
#
protocol bfd {
    interface "vlan208" {
        min rx interval BFD_MIN_RX;
        min tx interval BFD_MIN_TX;
        multiplier BFD_MULTIPLIER;
    };
}

#
# BGP Sessions to Route Reflectors
#
protocol bgp RR1_v6 from BGP_COMMON {
    description "Route Reflector 1 - BKK00 IPv6";
    neighbor RR1_IP6 as LOCAL_AS;
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

protocol bgp RR1_v4 from BGP_COMMON {
    description "Route Reflector 1 - BKK00 IPv4";
    neighbor RR1_IP4 as LOCAL_AS;
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

protocol bgp RR2_v6 from BGP_COMMON {
    description "Route Reflector 2 - BKK10 IPv6";
    neighbor RR2_IP6 as LOCAL_AS;
    source address LOCAL_IP6;
    
    ipv6 {
        next hop self;
        import filter {
            preference = PREF_IPV6;
            if net = ::/0 then {
                bgp_local_pref = LOCAL_PREF_BACKUP;
                accept;
            }
            accept;
        };
        export filter {
            if net = PUBLIC_NET6 then accept;
            if net ~ INTERNAL_NET6 then accept;
            reject;
        };
    };
}
EOF

