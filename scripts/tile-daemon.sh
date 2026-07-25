#!/bin/bash
# adamos auto-tile daemon — watches for new windows
# Run once at startup. Watches workspace changes and new windows.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TILER="$SCRIPT_DIR/tile.sh"

# Tile on workspace switch
while true; do
    inotifywait -q -e close_write /dev/null 2>/dev/null || true
    # Use wmctrl to detect workspace changes
    bash "$TILER" 2>/dev/null
    sleep 0.5
done
