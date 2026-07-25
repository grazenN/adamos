#!/usr/bin/env bash
#
# adamos monthly maintenance reboot — reboots ONLY if a reboot is pending,
# and ONLY once any in-progress update has finished (never mid-dpkg).
#
set -euo pipefail
FLAG="/var/run/reboot-required"
LOCK="/var/log/adamos-update/.running.lock"

log() { logger -t adamos-reboot "$*"; echo "adamos-reboot: $*"; }

if [ ! -f "$FLAG" ]; then
  log "no reboot-required flag present — nothing to do."
  exit 0
fi

# Wait up to 30 min for any running update to release its lock.
if [ -e "$LOCK" ]; then
  exec 9>"$LOCK"
  if ! flock -w 1800 9; then
    log "updater still holding lock after 30 min — skipping reboot this cycle."
    exit 0
  fi
fi

# Never reboot mid-dpkg/apt transaction.
if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
  log "dpkg/apt is busy — skipping reboot this cycle."
  exit 0
fi

log "pending kernel/library detected — scheduling reboot in 2 minutes."
shutdown -r +2 "adamos monthly maintenance reboot (pending kernel) in 2 minutes"
