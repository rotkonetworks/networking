#!/usr/bin/env bash
# Close the penumbra double-sign window the instant bkk06 comes back.
#
# WHY: bkk06 ct 1101 holds validator key 3336C9D1DE4F54D46863F5215FE39C1235F44F15
# with penumbra+cometbft ENABLED. That same key is live and signing on bkk08
# ct 1108. The only thing preventing a double-sign (and slashing) is that bkk06
# has no network. The moment it gets one — XC, 4G tunnel, anything — ct 1101
# starts signing too.
#
# This polls both the new and old addresses and, on first successful login,
# stops the container and clears its onboot flag. Stopping the container is the
# fastest certain kill; onboot=0 stops it coming back on the next reboot.
#
# RUN IT SOMEWHERE ALWAYS-ON (bkk07/bkk08, or a laptop that stays awake).
# Needs an SSH key that works WITHOUT an agent — a passphrase-protected key with
# no agent loaded will fail silently at 03:00. Test with:
#     ssh -o BatchMode=yes -i "$SSH_KEY" root@<host> true
#
# Usage:  ./guard-penumbra-doublesign.sh [--dry-run]
set -uo pipefail

CT=1101
HOSTS=("160.22.180.6" "160.22.181.6")     # new Telehouse IP first, then old
INTERVAL="${INTERVAL:-5}"                  # seconds; keep tight, this is a race
SSH_KEY="${SSH_KEY:-$HOME/.ssh/unlabored/ansible_ssh_key}"
LOG="${LOG:-$HOME/penumbra-guard.log}"
NTFY_URL="${NTFY_URL:-}"                   # optional: ntfy/webhook for a shout
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=4 -o StrictHostKeyChecking=accept-new
          -o ServerAliveInterval=2 -o ServerAliveCountMax=2 -i "$SSH_KEY")

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG"; }

shout() {
  log "$*"
  [[ -n "$NTFY_URL" ]] && curl -s -m 10 -d "$*" "$NTFY_URL" >/dev/null 2>&1 || true
}

disarm() {
  local host="$1"
  shout "bkk06 REACHABLE at ${host} — disarming penumbra ct ${CT}"

  if (( DRY_RUN )); then
    log "DRY-RUN: would run: pct stop ${CT}; pct set ${CT} --onboot 0"
    return 0
  fi

  # Stop first — that halts signing immediately. Then prevent it returning.
  # Both are idempotent: stopping a stopped container is not an error we care about.
  ssh "${SSH_OPTS[@]}" "root@${host}" "
    pct stop ${CT} 2>&1 || true
    pct set ${CT} --onboot 0 2>&1 || true
    echo '--- verify ---'
    pct status ${CT} 2>&1
    pct config ${CT} 2>/dev/null | grep -E '^onboot:' || echo 'onboot: (unset = 0)'
  " 2>&1 | tee -a "$LOG"

  # Confirm it actually took, rather than trusting the exit code of a pipeline.
  local state
  state=$(ssh "${SSH_OPTS[@]}" "root@${host}" "pct status ${CT} 2>/dev/null" 2>/dev/null | awk '{print $2}')
  if [[ "$state" == "stopped" ]]; then
    shout "DISARMED: bkk06 ct ${CT} stopped, onboot cleared. Double-sign window closed."
    shout "STILL TO DO BY HAND: remove/rename the key on bkk06 so this cannot recur:"
    shout "  /opt/penumbra/network_data/node0.bak/cometbft/config/priv_validator_key.json"
    return 0
  fi

  shout "!! FAILED to confirm ct ${CT} stopped (status='${state}') — INTERVENE NOW"
  return 1
}

log "guard started — polling ${HOSTS[*]} every ${INTERVAL}s for ct ${CT} (dry_run=${DRY_RUN})"
[[ -f "$SSH_KEY" ]] || { log "FATAL: ssh key not found: $SSH_KEY"; exit 1; }

while true; do
  for h in "${HOSTS[@]}"; do
    if ssh "${SSH_OPTS[@]}" "root@${h}" true 2>/dev/null; then
      if disarm "$h"; then
        log "done — exiting"
        exit 0
      fi
      # Reachable but disarm failed: keep hammering, do not give up quietly.
      shout "retrying disarm on ${h} in ${INTERVAL}s"
    fi
  done
  sleep "$INTERVAL"
done
