#!/usr/bin/env bash
# nftables config generator with modular structure
set -euo pipefail

# load config
CONFIG_FILE="${CONFIG_FILE:-../config.json}"
while getopts ':c:' opt; do
  case "$opt" in
    c) CONFIG_FILE="$OPTARG" ;;
    *) echo "Usage: $0 [-c <config-file>] <site>" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))


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
PUBLIC_IP4=$(echo "$SITE_CONFIG" | jq -r '.public_v4')
PUBLIC_IP6=$(echo "$SITE_CONFIG" | jq -r '.public_v6')
INTERNAL_V4=$(echo "$SITE_CONFIG" | jq -r '.internal_v4')
INTERNAL_V6=$(echo "$SITE_CONFIG" | jq -r '.internal_v6')

# generate nftables configuration
generate_nftables_config() {
    cat << NFT
#!/usr/sbin/nft -f
# nftables configuration for ${SITE^^}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

flush ruleset

$(generate_variables)

$(generate_filter_table)

$(generate_nat_table)
NFT
}

# generate variables section
generate_variables() {
    cat << VARS
# Variables from central config
define PUBLIC_IP4 = ${PUBLIC_IP4}
define PUBLIC_IP6 = ${PUBLIC_IP6}

define INTERNAL4 = ${INTERNAL_V4}
define INTERNAL6 = ${INTERNAL_V6}

define MGMT_NET = $(jq -r '.networks.management' "$CONFIG_FILE")
VARS

    # add bgp peers
    echo "define BGP_PEERS_V6 = { $(jq -r '.route_reflectors | to_entries | map(.value.v6) | join(", ")' "$CONFIG_FILE") }"
    echo "define BGP_PEERS_V4 = { $(jq -r '.route_reflectors | to_entries | map(.value.v4) | join(", ")' "$CONFIG_FILE") }"
}

# generate filter table
generate_filter_table() {
    cat << 'FILTER'

# Main filter table - IPv6 and IPv4 combined
table inet filter {
FILTER
    generate_sets
    generate_input_chain
    generate_forward_chain
    generate_output_chain
    echo "}"
}

# generate sets
generate_sets() {
    cat << 'SETS'
    set allowed_ssh {
        type ipv4_addr
        flags interval
        elements = { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 }
    }
    
    set allowed_ssh_v6 {
        type ipv6_addr
        flags interval
        elements = { fd00::/8, 2401:a860::/32 }
    }
SETS
}

# generate input chain
generate_input_chain() {
    cat << 'INPUT'
    
    chain input {
        type filter hook input priority filter; policy drop;
        
        # Connection tracking
        ct state established,related accept
        ct state invalid drop
        
        # Loopback
        iif "lo" accept
        
INPUT
    generate_icmp_rules
    generate_routing_protocols
    generate_management_services
    cat << 'INPUT_END'
        
        # Log drops
        limit rate 5/minute log prefix "[DROP-IN] "
    }
INPUT_END
}

# generate icmp rules
generate_icmp_rules() {
    cat << 'ICMP'
        # ICMPv6 (required for IPv6)
        ip6 nexthdr icmpv6 icmpv6 type {
            destination-unreachable,
            packet-too-big,
            time-exceeded,
            parameter-problem,
            echo-request,
            echo-reply,
            nd-router-solicit,
            nd-router-advert,
            nd-neighbor-solicit,
            nd-neighbor-advert
        } accept
        
        # ICMPv4 rate limited
        ip protocol icmp icmp type {
            destination-unreachable,
            time-exceeded,
            parameter-problem,
            echo-request
        } limit rate 10/second accept
ICMP
}

# generate routing protocol rules
generate_routing_protocols() {
    local iface=$(jq -r '.interfaces.bgp_vlan' "$CONFIG_FILE")
    cat << ROUTING
        
        # BGP
        tcp dport 179 ip6 saddr @BGP_PEERS_V6 accept
        tcp dport 179 ip saddr @BGP_PEERS_V4 accept
        
        # BFD
        udp dport { 3784, 4784 } ip6 saddr @BGP_PEERS_V6 accept
        udp dport { 3784, 4784 } ip saddr @BGP_PEERS_V4 accept
        
        # OSPF
        ip protocol ospf accept
        ip6 nexthdr ospf accept
ROUTING
}

# generate management services
generate_management_services() {
    local mgmt_iface=$(jq -r '.interfaces.management' "$CONFIG_FILE")
    local internal_iface=$(jq -r '.interfaces.internal' "$CONFIG_FILE")
    local storage_iface=$(jq -r '.interfaces.storage_private' "$CONFIG_FILE")
    
    cat << MGMT
        
        # SSH rate limited
        tcp dport 22 ip6 saddr @allowed_ssh_v6 accept
        tcp dport 22 ip saddr @allowed_ssh accept
        
        # Proxmox services from management
        iifname "${mgmt_iface}" tcp dport { 8006, 3128, 111, 2049 } accept
        iifname "${mgmt_iface}" udp dport { 111, 5405-5412 } accept
        
        # DNS for local networks
        iifname "${internal_iface}" udp dport 53 accept
        iifname "${internal_iface}" tcp dport 53 accept
        
        # Ceph from storage network
        iifname "${storage_iface}" tcp dport { 3300, 6789, 6800-7300 } accept
MGMT
}

# generate forward chain
generate_forward_chain() {
    local mgmt_iface=$(jq -r '.interfaces.management' "$CONFIG_FILE")
    local internal_iface=$(jq -r '.interfaces.internal' "$CONFIG_FILE")
    
    cat << FORWARD
    
    chain forward {
        type filter hook forward priority filter; policy drop;
        
        # Connection tracking
        ct state established,related accept
        ct state invalid drop
        
        # Allow from internal networks
        iifname "${internal_iface}" accept
        iifname "${mgmt_iface}" accept
        
        # Allow forwarded for NAT
        ct status dnat accept
        
        # Log drops
        limit rate 5/minute log prefix "[DROP-FWD] "
    }
FORWARD
}

# generate output chain
generate_output_chain() {
    cat << 'OUTPUT'
    
    chain output {
        type filter hook output priority filter; policy accept;
    }
OUTPUT
}

# generate nat table
generate_nat_table() {
    local public_iface=$(jq -r '.interfaces.public' "$CONFIG_FILE")
    
    cat << NAT

# NAT table - IPv4 only (IPv6 doesn't need NAT)
table ip nat {
    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        
NAT
    generate_service_mappings
    cat << NAT_POST
    }
    
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        
        # SNAT for internal networks
        ip saddr \$INTERNAL4 oifname "${public_iface}" snat to \$PUBLIC_IP4
        ip saddr \$MGMT_NET oifname "${public_iface}" snat to \$PUBLIC_IP4
    }
}

# IPv6 doesn't need NAT, but we can do NPTv6 if needed
table ip6 nat {
    # Empty for now - IPv6 uses direct routing
}
NAT_POST
}

# generate service mappings
generate_service_mappings() {
    # web services
    local web_target=$(jq -r '.services.web.target' "$CONFIG_FILE")
    jq -r '.services.web.ports[]' "$CONFIG_FILE" | while read -r port; do
        echo "        tcp dport $port dnat to $web_target"
    done
    
    # ssh containers
    echo "        "
    echo "        # SSH to specific containers"
    jq -r '.services.ssh_containers | keys[]' "$CONFIG_FILE" | while read -r port; do
        target=$(jq -r ".services.ssh_containers.\"$port\"" "$CONFIG_FILE")
        echo "        tcp dport $port dnat to $target"
    done
}

# main execution
generate_nftables_config
