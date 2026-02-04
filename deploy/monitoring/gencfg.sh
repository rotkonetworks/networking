#!/usr/bin/env bash
# Prometheus config generator for IBP RPC infrastructure
# Generates scrape targets from services.json for traffic monitoring
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
SERVICES_CONFIG="${CONFIG_DIR}/services.json"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# HAProxy nodes configuration
HAPROXY_NODES='[
  {"name": "bkk06", "ip": "192.168.6.1", "metrics_port": 8405},
  {"name": "bkk07", "ip": "192.168.7.1", "metrics_port": 8405},
  {"name": "bkk08", "ip": "192.168.8.1", "metrics_port": 8405}
]'

# Node exporter port (standard)
NODE_EXPORTER_PORT=9100

generate_header() {
  cat <<EOF
# Prometheus configuration for HAProxy and P2P traffic monitoring
# Generated: ${TIMESTAMP}
#
# This configuration enables comprehensive traffic monitoring:
# - RPC traffic via HAProxy Prometheus exporter (per-endpoint bytes in/out)
# - P2P traffic via node_exporter (per-node network interface stats)
#
# Key metrics for traffic analysis:
#   HAProxy:
#     - haproxy_backend_bytes_in_total{proxy="<chain>-backend"}
#     - haproxy_backend_bytes_out_total{proxy="<chain>-backend"}
#     - haproxy_backend_http_requests_total{proxy="<chain>-backend"}
#   Node:
#     - node_network_receive_bytes_total{chain="<chain>"}
#     - node_network_transmit_bytes_total{chain="<chain>"}

global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'rotko-bkk'
    environment: 'production'

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
EOF
}

generate_haproxy_scrape() {
  cat <<'EOF'
  # ============================================
  # HAProxy Prometheus Exporter
  # ============================================
  # Metrics endpoint: http://<haproxy>:8405/metrics
  # Key metrics for network consumption:
  #   - haproxy_backend_bytes_in_total (bytes received per backend/endpoint)
  #   - haproxy_backend_bytes_out_total (bytes sent per backend/endpoint)
  #   - haproxy_backend_http_requests_total (request count per endpoint)
  #   - haproxy_server_bytes_in_total (per-server traffic for load analysis)
  #   - haproxy_server_bytes_out_total

  - job_name: 'haproxy'
    static_configs:
      - targets:
EOF

  echo "$HAPROXY_NODES" | jq -r '.[] | "          - \(.ip):\(.metrics_port)  # \(.name)"'

  cat <<'EOF'
        labels:
          service: 'haproxy'
    relabel_configs:
      - source_labels: [__address__]
        regex: '192\.168\.6\..*'
        target_label: haproxy_instance
        replacement: 'bkk06'
      - source_labels: [__address__]
        regex: '192\.168\.7\..*'
        target_label: haproxy_instance
        replacement: 'bkk07'
      - source_labels: [__address__]
        regex: '192\.168\.8\..*'
        target_label: haproxy_instance
        replacement: 'bkk08'
EOF
}

generate_node_scrape_targets() {
  local rpc_nodes=$(jq -r '.rpc_nodes' "$SERVICES_CONFIG")

  cat <<'EOF'

  # ============================================
  # Node Exporter - P2P and System Traffic
  # ============================================
  # Scrapes node_exporter on each blockchain node
  # Key metrics for P2P traffic:
  #   - node_network_receive_bytes_total{device!="lo"}
  #   - node_network_transmit_bytes_total{device!="lo"}
  # Labels: chain, chain_type

  - job_name: 'node-blockchain'
    static_configs:
EOF

  # Process each chain and its instances
  echo "$rpc_nodes" | jq -c 'to_entries[]' | while read -r entry; do
    local chain=$(echo "$entry" | jq -r '.key')
    local chain_type=$(echo "$entry" | jq -r '.value.type')
    local instances=$(echo "$entry" | jq -r '.value.instances')

    # Generate targets for this chain
    echo "      # ${chain} (${chain_type})"
    echo "      - targets:"
    echo "$instances" | jq -r 'to_entries[] | "          - \(.value.address):9100  # \(.key)"'
    echo "        labels:"
    echo "          chain: '${chain}'"
    echo "          chain_type: '${chain_type}'"
  done
}

generate_relabeling() {
  cat <<'EOF'
    metric_relabel_configs:
      # Drop high-cardinality metrics we don't need
      - source_labels: [__name__]
        regex: 'node_scrape_collector_.*'
        action: drop
      # Keep only network metrics for efficiency (optional - remove for full metrics)
      # - source_labels: [__name__]
      #   regex: 'node_network_.*|node_cpu_.*|node_memory_.*|node_disk_.*'
      #   action: keep
EOF
}

main() {
  if [[ ! -f "$SERVICES_CONFIG" ]]; then
    echo "error: $SERVICES_CONFIG not found" >&2
    exit 1
  fi

  generate_header
  generate_haproxy_scrape
  generate_node_scrape_targets
  generate_relabeling
}

main "$@"
