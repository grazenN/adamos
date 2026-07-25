#!/usr/bin/env bash
#
# adamos server updater — safe, schedulable system update for Debian 13.
#
# Runs two ways:
#   * interactively (TTY)      -> shows fastfetch + offers a reboot/shutdown prompt
#   * non-interactively (timer)-> logs only, NO prompt, NEVER auto-reboots
#
# Security patches are handled separately/daily by unattended-upgrades; this is
# the broader weekly sweep (full package upgrades + flatpak/snap + cleanup).
#
# Usage:
#   sudo adamos-update.sh            # standard: apt update + upgrade + flatpak/snap + cleanup
#   sudo adamos-update.sh --full     # use apt full-upgrade (may add/remove pkgs, incl. kernels)
#   sudo adamos-update.sh --quiet    # minimal stdout (used by the timer)
#
set -euo pipefail

# --- privilege: use sudo only if not already root --------------------------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || { echo "Run as root or install sudo." >&2; exit 1; }
  SUDO="sudo"
fi

# --- options ----------------------------------------------------------------
APT_UP="upgrade"; QUIET=0
for a in "$@"; do
  case "$a" in
    --full)  APT_UP="full-upgrade" ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $a" >&2; exit 2 ;;
  esac
done

# --- logging (to a dir the current user can write) --------------------------
if [ "$(id -u)" -eq 0 ]; then LOG_DIR="/var/log/adamos-update"; else LOG_DIR="$HOME/.local/log/adamos-update"; fi
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/update-$TS.log"

# --- single-instance lock (kept in the writable log dir) --------------------
exec 9>"$LOG_DIR/.running.lock"
if ! flock -n 9; then echo "Another updater run is active — exiting."; exit 0; fi

# tee all output to the log from here on
exec > >(tee -a "$LOG") 2>&1
trap 'rc=$?; echo "!! updater FAILED (exit $rc) — see $LOG"; exit $rc' ERR

say() { echo; echo "=== $* ==="; }
echo "adamos updater | $(date) | mode=apt $APT_UP | host=$(hostname) | user=$(id -un)"

export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef)

say "apt update"
$SUDO apt-get update

say "apt $APT_UP"
$SUDO apt-get "${APT_OPTS[@]}" "$APT_UP"

say "apt autoremove --purge"
$SUDO apt-get "${APT_OPTS[@]}" --purge autoremove

say "apt autoclean"
$SUDO apt-get -y autoclean

if command -v flatpak >/dev/null 2>&1; then
  say "flatpak update"
  $SUDO flatpak update -y --noninteractive || echo "(flatpak update non-zero — continuing)"
fi

if command -v snap >/dev/null 2>&1; then
  say "snap refresh"
  $SUDO snap refresh || echo "(snap refresh non-zero — continuing)"
fi

# --- reboot-required detection (needrestart not installed) ------------------
REBOOT=0
[ -f /var/run/reboot-required ] && REBOOT=1
NEWEST_KERNEL="$(ls -1 /boot/vmlinuz-* 2>/dev/null | sed 's#.*/vmlinuz-##' | sort -V | tail -1)"
RUNNING_KERNEL="$(uname -r)"
if [ -n "$NEWEST_KERNEL" ] && [ "$NEWEST_KERNEL" != "$RUNNING_KERNEL" ]; then REBOOT=1; fi

say "summary"
echo "running kernel : $RUNNING_KERNEL"
echo "newest kernel  : ${NEWEST_KERNEL:-unknown}"
if [ "$REBOOT" -eq 1 ]; then
  echo ">>> REBOOT RECOMMENDED (new kernel or core library pending)"
  $SUDO touch /var/run/reboot-required 2>/dev/null || true
else
  echo "no reboot required"
fi

# rotate logs: keep newest 20
ls -1t "$LOG_DIR"/update-*.log 2>/dev/null | tail -n +21 | xargs -r rm -f 2>/dev/null || true

# --- interactive tail: only on a real TTY ----------------------------------
if [ -t 0 ] && [ "$QUIET" -eq 0 ]; then
  command -v fastfetch >/dev/null 2>&1 && fastfetch || true
  [ "$REBOOT" -eq 1 ] && { echo; echo "A reboot is recommended."; }
  while true; do
    read -rp "Reboot, shutdown, or continue? (r/s/c) " choice
    case "$choice" in
      r|R) $SUDO reboot; break ;;
      s|S) $SUDO shutdown -h now; break ;;
      c|C) break ;;
      *) echo "Please choose r, s, or c." ;;
    esac
  done
fi

echo
echo "updater complete | $(date) | reboot_recommended=$REBOOT | log: $LOG"
