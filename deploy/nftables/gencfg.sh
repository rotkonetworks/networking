#!/usr/bin/env bash
# nftables config generator with three-tier anycast support
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"
CONFIG_FILE="${CONFIG_DIR}/network.json"
SERVICES_FILE="${CONFIG_DIR}/services.json"

# Parse arguments
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

if [[ ! -f "$SERVICES_FILE" ]]; then
 echo "error: services file not found: $SERVICES_FILE" >&2
 exit 1
fi

# Validate site argument
readonly SITE="${1:-}"
SITE_UPPER="$(echo "$SITE" | tr '[:lower:]' '[:upper:]')"
if [[ -z "$SITE" ]]; then
 echo "usage: $0 <site>" >&2
 echo "valid sites: $(jq -r '.sites | keys[]' "$CONFIG_FILE" | tr '\n' ' ')" >&2
 exit 1
fi

# Validate site exists
if ! jq -e ".sites.$SITE" "$CONFIG_FILE" >/dev/null 2>&1; then
 echo "error: invalid site: $SITE" >&2
 exit 1
fi

# Extract site config
SITE_CONFIG=$(jq -r ".sites.$SITE" "$CONFIG_FILE")
PUBLIC_IP4=$(echo "$SITE_CONFIG" | jq -r '.public_v4')
PUBLIC_IP6=$(echo "$SITE_CONFIG" | jq -r '.public_v6')
INTERNAL_V4=$(echo "$SITE_CONFIG" | jq -r '.internal_v4')
INTERNAL_V6=$(echo "$SITE_CONFIG" | jq -r '.internal_v6')

# Extract anycast IPs - all three tiers
ANYCAST_LOCAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v4 // empty' | sed 's|/32||')
ANYCAST_LOCAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_local_v6 // empty' | sed 's|/128||')
ANYCAST_SITE_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v4 // empty' | sed 's|/32||')
ANYCAST_SITE_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_site_v6 // empty' | sed 's|/128||')
ANYCAST_GLOBAL_V4=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v4 // empty' | sed 's|/32||')
ANYCAST_GLOBAL_V6=$(echo "$SITE_CONFIG" | jq -r '.anycast_global_v6 // empty' | sed 's|/128||')

# Generate nftables configuration
generate_nftables_config() {
 cat <<NFT
#!/usr/sbin/nft -f
# nftables configuration for ${SITE^^}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Three-tier anycast: local (ULA), site (Bangkok), global (worldwide)

flush ruleset

$(generate_variables)

$(generate_filter_table)

$(generate_nat_table)
NFT
}

# Generate variables section
generate_variables() {
 cat <<VARS
# Variables from central config
define PUBLIC_IP4 = ${PUBLIC_IP4}
define PUBLIC_IP6 = ${PUBLIC_IP6}

define INTERNAL4 = ${INTERNAL_V4}
define INTERNAL6 = ${INTERNAL_V6}

define MGMT_NET = $(jq -r '.networks.management' "$CONFIG_FILE")

# Interface definitions
define WAN = vmbr2
define INTERNAL = vmbr1
define MGMT = vmbr0
VARS

 # Add storage interface if defined
 local storage_iface=$(jq -r '.interfaces.storage_private // "null"' "$CONFIG_FILE")
 if [[ "$storage_iface" != "null" ]]; then
   echo "define STORAGE = ${storage_iface}"
 fi

 # Define anycast IPs if present - all three tiers
 if [[ -n "$ANYCAST_LOCAL_V4" ]] || [[ -n "$ANYCAST_SITE_V4" ]] || [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
   echo ""
   echo "# Anycast IPv4 addresses"
   [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "define ANYCAST_LOCAL_V4 = ${ANYCAST_LOCAL_V4}  # ULA - internal only"
   [[ -n "$ANYCAST_SITE_V4" ]] && echo "define ANYCAST_SITE_V4 = ${ANYCAST_SITE_V4}    # Bangkok site-local"
   [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "define ANYCAST_GLOBAL_V4 = ${ANYCAST_GLOBAL_V4} # Global multi-site"
 fi

  if [[ -n "$ANYCAST_LOCAL_V6" ]] || [[ -n "$ANYCAST_SITE_V6" ]] || [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo ""
    echo "# Anycast IPv6 addresses"
    [[ -n "$ANYCAST_LOCAL_V6" ]] && echo "define ANYCAST_LOCAL_V6 = ${ANYCAST_LOCAL_V6}  # ULA - internal"
    [[ -n "$ANYCAST_SITE_V6" ]] && echo "define ANYCAST_SITE_V6 = ${ANYCAST_SITE_V6}    # GUA - Bangkok"
    [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "define ANYCAST_GLOBAL_V6 = ${ANYCAST_GLOBAL_V6} # GUA - global"
  fi

  # Add BGP peers - extract site-specific IPs for current site
  local bgp_peers_v6=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors | to_entries | map(.value[$site].v6) | join(", ")' "$CONFIG_FILE")
  local bgp_peers_v4=$(jq -r --arg site "$SITE_UPPER" '.route_reflectors | to_entries | map(.value[$site].v4) | join(", ")' "$CONFIG_FILE")

 echo ""
 echo "# BGP peers"
 echo "define BGP_PEERS_V6 = { $bgp_peers_v6 }"
 echo "define BGP_PEERS_V4 = { $bgp_peers_v4 }"
 
 echo ""
 echo "# SSH access control (customize as needed)"
 # echo "define ssh_allowed_v4 = { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 }"
 #NOTE: accept all for now, so wedont get locked out
 echo "define ssh_allowed_v4 = { 0.0.0.0/0 }"
 echo "define ssh_allowed_v6 = { fd00::/8, 2401:a860::/32 }"
}

# Generate filter table
generate_filter_table() {
 cat <<'FILTER'

# Main filter table - IPv6 and IPv4 combined
table inet filter {
FILTER
 generate_sets
 generate_input_chain
 generate_forward_chain
 generate_output_chain
 echo "}"
}

# Generate sets
generate_sets() {
 cat <<'SETS'
   set allowed_ssh {
       type ipv4_addr
       flags interval
       elements = { 0.0.0.0/0 }
   }

   set allowed_ssh_v6 {
       type ipv6_addr
       flags interval
       elements = { fd00::/8, 2401:a860::/32 }
   }
SETS
}

# Generate input chain
generate_input_chain() {
 cat <<'INPUT'

   chain input {
       type filter hook input priority filter; policy drop;

       # Management network bypass (optional - uncomment if needed)
       # iifname $MGMT ip saddr $MGMT_NET accept

        # Connection tracking
        ct state established,related accept
        ct state invalid drop

        # Loopback - critical for anycast addresses on lo interface
        iif "lo" accept

INPUT
 generate_icmp_rules
 generate_routing_protocols
 generate_management_services
 generate_anycast_services
 generate_public_services
 cat <<'INPUT_END'

       # Log drops (rate limited)
       limit rate 5/minute log prefix "[DROP-IN] "
   }
INPUT_END
}

# Generate ICMP rules
generate_icmp_rules() {
 cat <<'ICMP'
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

# Generate routing protocol rules
generate_routing_protocols() {
 cat <<'ROUTING'

       # BGP from configured peers only
       tcp dport 179 ip saddr $BGP_PEERS_V4 accept
       tcp dport 179 ip6 saddr $BGP_PEERS_V6 accept

       # BFD for fast failover
       udp dport { 3784, 4784 } ip saddr $BGP_PEERS_V4 accept
       udp dport { 3784, 4784 } ip6 saddr $BGP_PEERS_V6 accept

       # OSPF (if used internally)
       ip protocol ospf accept
       ip6 nexthdr ospf accept
ROUTING
}

# Generate management services
generate_management_services() {
 cat <<'MGMT'

       # SSH rate limited
       tcp dport 22 ip saddr $ssh_allowed_v4 accept
       tcp dport 22 ip6 saddr $ssh_allowed_v6 accept

       # Proxmox services from management network only
       iifname $MGMT tcp dport { 8006, 3128, 111, 2049 } accept
       iifname $MGMT udp dport { 111, 5405-5412 } accept

       # DNS for local networks only
       iifname $INTERNAL udp dport 53 accept
       iifname $INTERNAL tcp dport 53 accept
       iifname $MGMT udp dport 53 accept
       iifname $MGMT tcp dport 53 accept
MGMT

 # Only add Ceph rules if storage interface is defined
 local storage_iface=$(jq -r '.interfaces.storage_private // "null"' "$CONFIG_FILE")
 if [[ "$storage_iface" != "null" ]]; then
   cat <<'CEPH'

       # Ceph from storage network
       iifname $STORAGE tcp dport { 3300, 6789, 6800-7300 } accept
CEPH
 fi
}

# Generate anycast-specific services
generate_anycast_services() {
 # Only generate if we have anycast IPs configured
 if [[ -z "$ANYCAST_LOCAL_V4" && -z "$ANYCAST_LOCAL_V6" && \
       -z "$ANYCAST_SITE_V4" && -z "$ANYCAST_SITE_V6" && \
       -z "$ANYCAST_GLOBAL_V4" && -z "$ANYCAST_GLOBAL_V6" ]]; then
   return
 fi

 echo ""
 echo "        # Anycast services"

  # Local anycast (ULA) - internal services only
  if [[ -n "$ANYCAST_LOCAL_V4" ]] || [[ -n "$ANYCAST_LOCAL_V6" ]]; then
    echo "        # Local anycast (internal services)"
    [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "        ip daddr \$ANYCAST_LOCAL_V4 tcp dport { 53, 853 } accept  # DNS"
    [[ -n "$ANYCAST_LOCAL_V4" ]] && echo "        ip daddr \$ANYCAST_LOCAL_V4 udp dport 53 accept"
    [[ -n "$ANYCAST_LOCAL_V6" ]] && echo "        ip6 daddr \$ANYCAST_LOCAL_V6 tcp dport { 53, 853 } accept"
    [[ -n "$ANYCAST_LOCAL_V6" ]] && echo "        ip6 daddr \$ANYCAST_LOCAL_V6 udp dport 53 accept"
  fi

  # Site anycast (Bangkok GUA) - public services for Bangkok
  if [[ -n "$ANYCAST_SITE_V4" ]] || [[ -n "$ANYCAST_SITE_V6" ]]; then
    echo "        # Site anycast (Bangkok-only services)"
    [[ -n "$ANYCAST_SITE_V4" ]] && echo "        ip daddr \$ANYCAST_SITE_V4 tcp dport { 80, 443 } accept  # HTTP/HTTPS"
    [[ -n "$ANYCAST_SITE_V4" ]] && echo "        ip daddr \$ANYCAST_SITE_V4 tcp dport { 53, 853 } accept  # DNS"
    [[ -n "$ANYCAST_SITE_V4" ]] && echo "        ip daddr \$ANYCAST_SITE_V4 udp dport 53 accept"
    [[ -n "$ANYCAST_SITE_V6" ]] && echo "        ip6 daddr \$ANYCAST_SITE_V6 tcp dport { 80, 443 } accept"
    [[ -n "$ANYCAST_SITE_V6" ]] && echo "        ip6 daddr \$ANYCAST_SITE_V6 tcp dport { 53, 853 } accept"
    [[ -n "$ANYCAST_SITE_V6" ]] && echo "        ip6 daddr \$ANYCAST_SITE_V6 udp dport 53 accept"
  fi

  # Global anycast (worldwide GUA) - global services
  if [[ -n "$ANYCAST_GLOBAL_V4" ]] || [[ -n "$ANYCAST_GLOBAL_V6" ]]; then
    echo "        # Global anycast (worldwide services)"
    [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "        ip daddr \$ANYCAST_GLOBAL_V4 tcp dport { 80, 443 } accept  # HTTP/HTTPS"
    [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "        ip daddr \$ANYCAST_GLOBAL_V4 tcp dport { 53, 853 } accept  # DNS"
    [[ -n "$ANYCAST_GLOBAL_V4" ]] && echo "        ip daddr \$ANYCAST_GLOBAL_V4 udp dport 53 accept"
    [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "        ip6 daddr \$ANYCAST_GLOBAL_V6 tcp dport { 80, 443 } accept"
    [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "        ip6 daddr \$ANYCAST_GLOBAL_V6 tcp dport { 53, 853 } accept"
    [[ -n "$ANYCAST_GLOBAL_V6" ]] && echo "        ip6 daddr \$ANYCAST_GLOBAL_V6 udp dport 53 accept"
  fi
}

# Generate public services (HAProxy)
generate_public_services() {
 cat <<'PUBLIC'

       # Public services on unicast IPs
       # HAProxy (HTTP/HTTPS)
       tcp dport { 80, 443 } accept

        # HAProxy stats (localhost only)
        iif "lo" tcp dport 8404 accept

        # Bootnode P2P ports
PUBLIC

 # Collect p2p ports - handle both simple values and site-specific objects
 local p2p_ports
 p2p_ports=$(jq -r --arg site "$SITE" '
   .bootnodes[] 
   | select(.ports.p2p != null) 
   | .ports.p2p 
   | if type == "object" then 
       .[$site] // empty 
     else 
       . 
     end 
   | select(. != "" and . != null)' "$SERVICES_FILE" 2>/dev/null |
   sort -nu |
   tr '\n' ',' |
   sed 's/,$//')

 # Collect p2p_wss ports - handle both simple values and site-specific objects  
 local p2p_wss_ports
 p2p_wss_ports=$(jq -r --arg site "$SITE" '
   .bootnodes[] 
   | select(.ports.p2p_wss != null) 
   | .ports.p2p_wss 
   | if type == "object" then 
       .[$site] // empty 
     else 
       . 
     end 
   | select(. != "" and . != null)' "$SERVICES_FILE" 2>/dev/null |
   sort -nu |
   tr '\n' ',' |
   sed 's/,$//')

 # emit IPv4 rules only if we have ports
 if [[ -n "$p2p_ports" ]]; then
   echo "        tcp dport { ${p2p_ports} } accept"
   echo "        udp dport { ${p2p_ports} } accept"
 fi

  # only emit WS rule if there's at least one port
  if [[ -n "$p2p_wss_ports" ]]; then
    echo "        tcp dport { ${p2p_wss_ports} } accept"
  fi
}

# Generate forward chain
generate_forward_chain() {
 cat <<'FORWARD'

   chain forward {
       type filter hook forward priority filter; policy drop;

        # Connection tracking
        ct state established,related accept
        ct state invalid drop

       # Allow from internal networks
       iifname $INTERNAL accept
       iifname $MGMT accept
        # Allow forwarded traffic that's been DNATed
        ct status dnat accept

       # Allow forwarding from NAT network
       ip saddr $MGMT_NET accept

       # Log drops
       limit rate 5/minute log prefix "[DROP-FWD] "
   }
FORWARD
}

# Generate output chain
generate_output_chain() {
 cat <<'OUTPUT'

   chain output {
       type filter hook output priority filter; policy accept;

       # Block RFC1918 on WAN interface (optional - uncomment if needed)
       # oifname $WAN ip daddr 10.0.0.0/8 reject
       # oifname $WAN ip daddr 172.16.0.0/12 reject
       # oifname $WAN ip daddr 192.168.0.0/16 reject
       # oifname $WAN ip daddr 169.254.0.0/16 reject
   }
OUTPUT
}

# Generate NAT table
generate_nat_table() {
 cat <<'NAT'

# NAT table - IPv4 only (IPv6 doesn't need NAT)
table ip nat {
   chain prerouting {
       type nat hook prerouting priority dstnat; policy accept;

       # Port forwards - examples (customize as needed)
       # Web services
       # tcp dport 80 dnat to 10.6.10.80
       # tcp dport 443 dnat to 10.6.10.80

NAT

  # Generate port forwards for VMs and services
  generate_port_forwards

  # Generate bootnode port mappings
  generate_bootnode_mappings

 # Add anycast DNAT if needed
 if [[ -n "$ANYCAST_SITE_V4" ]] || [[ -n "$ANYCAST_GLOBAL_V4" ]]; then
   echo ""
   echo "        # Anycast DNAT rules (if services are on different containers)"
   echo "        # Add specific DNAT rules here if anycast services aren't local"
 fi

 cat <<'NAT_POST'
   }

   chain postrouting {
       type nat hook postrouting priority srcnat; policy accept;

       # SNAT for internal networks going out
       ip saddr $INTERNAL4 oifname $WAN snat to $PUBLIC_IP4
       ip saddr $MGMT_NET oifname $WAN snat to $PUBLIC_IP4
   }
}

# IPv6 doesn't need NAT - we have real addresses
table ip6 nat {
   # Empty - IPv6 uses direct routing
}
NAT_POST
}

# Generate port forwards for VMs and services
generate_port_forwards() {
 echo "        # VM and service port forwards"

 # Read port forwards from services.json for current site
 if jq -e ".port_forwards.\"$SITE\"" "$SERVICES_FILE" >/dev/null 2>&1; then
   jq -r --arg site "$SITE" '
     .port_forwards[$site][]
     | "\(.name) \(.external_port) \(.internal_ip) \(.internal_port) \(.protocol)"
   ' "$SERVICES_FILE" | while read -r name ext_port int_ip int_port protocol; do
     if [[ -n "$ext_port" && "$ext_port" != "null" ]]; then
       echo "        # ${name}"
       echo "        ${protocol} dport ${ext_port} dnat to ${int_ip}:${int_port}"
       echo
     fi
   done
 fi
}

# Generate bootnode port mappings
generate_bootnode_mappings() {
    echo "        # Bootnode P2P ports"
    
    # Process each bootnode entry - use site-specific container and ports for nftables NAT
    jq -r --arg site "$SITE" '
        .bootnodes
        | to_entries[]
        | select(.value.ports != null and .value.container != null)
        | {
            chain: .key,
            container: (
                .value.container 
                | if type == "object" then 
                    .[$site] // empty
                  else 
                    . 
                  end
            ),
            p2p: (
                .value.ports.p2p
                | if type == "object" then
                    .[$site] // empty
                  else
                    .
                  end
            ),
            p2p_wss: (
                (.value.ports.p2p_wss // null)
                | if type == "object" then
                    .[$site] // null
                  else
                    .
                  end
            )
          }
        | select(.container != null and .container != "" and .p2p != null and .p2p != "")
        | "\(.chain)|\(.container)|\(.p2p)|\(.p2p_wss)"
    ' "$SERVICES_FILE" | while IFS='|' read -r chain container p2p p2p_wss; do
        
        # Skip if essential values are missing
        if [[ -z "$chain" || -z "$container" || -z "$p2p" || "$p2p" == "null" ]]; then
            continue
        fi
        
        echo "        # ${chain}"
        echo "        tcp dport ${p2p} dnat to ${container}:${p2p}"
        echo "        udp dport ${p2p} dnat to ${container}:${p2p}"
        
        # Add WebSocket port if present
        if [[ -n "$p2p_wss" && "$p2p_wss" != "null" ]]; then
            echo "        tcp dport ${p2p_wss} dnat to ${container}:${p2p_wss}"
        fi
        echo
    done
}
# Main execution
generate_nftables_config
