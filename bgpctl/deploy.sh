#!/bin/bash
# deploy bgpctl to target host
# usage: ./deploy.sh <target-host>

set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo "usage: $0 <target-host>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "building bgpctl..."
cargo build --release --manifest-path "$SCRIPT_DIR/Cargo.toml"

echo "deploying to $TARGET..."

# copy binary
scp "$SCRIPT_DIR/target/release/bgpctl" "$TARGET:/tmp/bgpctl"
ssh "$TARGET" "sudo mv /tmp/bgpctl /usr/local/bin/bgpctl && sudo chmod 755 /usr/local/bin/bgpctl"

# create user if needed
ssh "$TARGET" "id bgpctl >/dev/null 2>&1 || sudo useradd -r -s /usr/sbin/nologin bgpctl"

# create config directory
ssh "$TARGET" "sudo mkdir -p /etc/bgpctl && sudo chown bgpctl:bgpctl /etc/bgpctl && sudo chmod 750 /etc/bgpctl"

# copy config (template)
scp "$SCRIPT_DIR/config.example.toml" "$TARGET:/tmp/config.toml"
ssh "$TARGET" "sudo mv /tmp/config.toml /etc/bgpctl/config.toml && sudo chown bgpctl:bgpctl /etc/bgpctl/config.toml && sudo chmod 640 /etc/bgpctl/config.toml"

# copy systemd service
scp "$SCRIPT_DIR/bgpctl.service" "$TARGET:/tmp/bgpctl.service"
ssh "$TARGET" "sudo mv /tmp/bgpctl.service /etc/systemd/system/bgpctl.service && sudo systemctl daemon-reload"

echo "
deployment complete. next steps:
1. edit /etc/bgpctl/config.toml with actual router credentials
2. create /etc/bgpctl/env with:
   BGPCTL_BKK00_PASSWORD=xxx
   BGPCTL_BKK20_PASSWORD=xxx
3. sudo systemctl enable --now bgpctl
4. check logs: journalctl -u bgpctl -f
"
