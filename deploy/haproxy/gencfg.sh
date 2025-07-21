#!/usr/bin/env bash
# HAProxy config generator for IBP RPC nodes - minimal attack surface
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
SERVICES_CONFIG="${CONFIG_DIR}/services.json"

# Generate timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Helper function to normalize chain names
normalize_chain() {
    echo "$1" | tr '_' '-'
}

# Generate global section
generate_global() {
    cat << 'EOF'
# Global settings
global
    log 127.0.0.1:514 local0 info  # Log more for monitoring
    chroot /var/lib/haproxy
    pidfile /var/run/haproxy.pid
    maxconn 500000
    user haproxy
    group haproxy
    daemon
    
    # Security hardening
    ssl-default-bind-ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!PSK:!SRP:!DSS:!RC4:!3DES:!MD5
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
    ssl-default-server-ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!PSK:!SRP:!DSS:!RC4:!3DES:!MD5
    ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
    
    # Performance tuning for high throughput
    nbthread 16
    cpu-map auto:1/1-16 0-15
    tune.bufsize 131072
    tune.ssl.default-dh-param 2048
    tune.maxrewrite 16384
    tune.http.maxhdr 1000
    
    # Admin socket
    stats socket /var/run/haproxy.sock mode 660 level admin
    stats timeout 2m
EOF
}

# Generate defaults section
generate_defaults() {
    cat << 'EOF'
# Defaults
defaults
    log global
    mode http
    option httplog
    option dontlognull    # Don't log null connections
    option log-health-checks
    
    # Timeouts (generous for RPC nodes)
    timeout connect 5s
    timeout client 300s   # Long for subscriptions
    timeout server 300s   # Long for heavy queries
    timeout http-request 60s
    timeout http-keep-alive 300s
    timeout queue 60s
    
    # WebSocket support
    timeout tunnel 3600s  # 1 hour for WS connections
    
    # Connection settings
    maxconn 250000
    retries 3
    option redispatch
    option http-server-close
EOF
}

# Generate minimal stats
generate_stats() {
    cat << 'EOF'
# Stats - internal only
listen stats
    bind 127.0.0.1:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats admin if TRUE
EOF
}

# Generate HTTP frontend
generate_http_frontend() {
    cat << 'EOF'
# HTTP Frontend - redirect only
frontend http-frontend
    bind *:80
    mode http
    
    # Track requests for monitoring (no limiting)
    stick-table type ip size 1m expire 30s store http_req_rate(10s),http_req_cnt
    http-request track-sc0 src
    
    # Redirect to HTTPS
    redirect scheme https code 301 if !{ ssl_fc }
EOF
}

# Generate SSL frontend
generate_ssl_frontend() {
    local chains="$1"
    local domain_suffixes=$(jq -r '.haproxy.domain_suffixes[]' "$SERVICES_CONFIG" | tr '\n' ' ')
    
    cat << 'EOF'
# SSL Frontend
frontend ssl-frontend
    bind *:443 ssl crt /etc/haproxy/certs/ alpn h2,http/1.1
    mode http
    
    # Security headers
    http-response set-header X-Frame-Options "DENY"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Referrer-Policy "no-referrer-when-downgrade"
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    
    # Remove server headers
    http-response del-header Server
    http-response del-header X-Powered-By
    
    # Track requests for monitoring/alerting (NO rate limiting)
    stick-table type ip size 10m expire 60s store http_req_rate(10s),http_req_cnt,bytes_out_rate(10s)
    http-request track-sc0 src
    
    # Log high-rate IPs for alerting (but don't block)
    http-request set-var(txn.req_rate) sc_http_req_rate(0)
    http-request capture var(txn.req_rate) len 10 if { var(txn.req_rate) gt 1000 }
    
    # Compression
    compression algo gzip
    compression type text/html text/plain text/css application/json application/javascript
    
    # ACLs
    acl is_websocket hdr(Upgrade) -i websocket
    acl is_options method OPTIONS
    
    # CORS for public RPC
    http-response set-header Access-Control-Allow-Origin "*"
    http-response set-header Access-Control-Allow-Methods "POST, GET, OPTIONS"
    http-response set-header Access-Control-Allow-Headers "Content-Type"
    http-response set-header Access-Control-Max-Age "86400"
    
    # CORS preflight
    http-request return status 200 if is_options
    
EOF

    # Generate domain ACLs only for configured chains
    echo "$chains" | jq -r 'keys[]' | while read -r chain; do
        echo "    # ${chain} ACLs"
        echo "    acl is_${chain} hdr(host) -i ${chain}.ibp.network ${chain}.dotters.network ${chain}.rotko.net"
    done
    
    # Path-based ACLs for centralized endpoints
    echo ""
    echo "    # Centralized endpoint ACLs"
    echo "    acl is_rpc hdr_beg(host) -i rpc."
    echo "    acl is_sys hdr_beg(host) -i sys."
    
    echo "$chains" | jq -r 'keys[]' | while read -r chain; do
        echo "    acl path_${chain} path_beg -i /${chain}"
    done

    echo ""
    echo "    # Backend routing"
    
    # Direct domain routing
    echo "$chains" | jq -r 'keys[]' | while read -r chain; do
        echo "    use_backend ${chain}-backend if is_${chain}"
    done
    
    echo ""
    # Path-based routing
    echo "$chains" | jq -r 'keys[]' | while read -r chain; do
        echo "    use_backend ${chain}-backend if is_rpc path_${chain}"
        echo "    use_backend ${chain}-backend if is_sys path_${chain}"
    done
    
    echo ""
    echo "    # Default backend"
    echo "    default_backend no-access"
}

# Generate backends
generate_backends() {
    local chains="$1"
    
    echo ""
    echo "# RPC Backends"
    
    echo "$chains" | jq -c 'to_entries[]' | while read -r entry; do
        local chain=$(echo "$entry" | jq -r '.key')
        local instances=$(echo "$entry" | jq -r '.value.instances')
        
        echo ""
        echo "backend ${chain}-backend"
        echo "    mode http"
        echo "    balance leastconn"
        echo "    "
        echo "    # Health checks"
        echo "    option httpchk POST / HTTP/1.1\\r\\nHost:localhost\\r\\nContent-Type:application/json\\r\\nContent-Length:58\\r\\n\\r\\n{\"jsonrpc\":\"2.0\",\"method\":\"system_health\",\"params\":[],\"id\":1}"
        echo "    http-check expect rstring \"isSyncing.*false\""
        echo "    "
        echo "    # Retry and timeout"
        echo "    retries 2"
        echo "    option redispatch"
        echo "    timeout server 30s"
        echo "    "
        echo "    # Servers"
        echo "$instances" | jq -r --arg c "$chain" 'to_entries[] | "    server rpc-\($c)-\(.key) \(.value.address):\(.value.port) check inter 5s fall 3 rise 2 maxconn 10000"'
    done
    
    # Minimal deny backend
    cat << 'EOF'

# Deny backend
backend no-access
    mode http
    http-request deny
EOF
}

# Main function
main() {
    if [[ ! -f "$SERVICES_CONFIG" ]]; then
        echo "error: $SERVICES_CONFIG not found" >&2
        exit 1
    fi
    
    # Load configuration
    local rpc_nodes=$(jq -r '.rpc_nodes' "$SERVICES_CONFIG")
    
    echo "#"
    echo "# HAProxy configuration for IBP RPC nodes"
    echo "# Generated: ${TIMESTAMP}"
    echo "#"
    echo ""
    
    generate_global
    echo ""
    generate_defaults
    echo ""
    generate_stats
    echo ""
    generate_http_frontend
    echo ""
    generate_ssl_frontend "$rpc_nodes"
    echo ""
    generate_backends "$rpc_nodes"
}

# Run main
main "$@"
