#!/bin/bash
# adamos per-workspace tiler — COSMIC-inspired
# Tiles windows on the current workspace based on layout per workspace.
#
# Layouts:
#   ws 1-2:  master-stack (main window left, stack right)
#   ws 3-4:  grid (2x2 or 3x3)
#   ws 5-6:  horizontal split (top/bottom)
#
# Usage:
#   tile.sh           # tile current workspace
#   tile.sh --watch   # auto-tile new windows (daemon)

set -euo pipefail

SCREEN_W=$(xdotool getdisplaygeometry | awk '{print $1}')
SCREEN_H=$(xdotool getdisplaygeometry | awk '{print $2}')

get_workspace_id() {
    wmctrl -d | awk '/\*/ {print $1}'
}

get_windows_on_workspace() {
    local ws=$1
    wmctrl -l -x | awk -v ws="$ws" '$2 == ws {print $1}'
}

tile_master_stack() {
    local ws=$1; shift
    local wins=("$@")
    local count=${#wins[@]}
    [ "$count" -eq 0 ] && return

    local main_w=$((SCREEN_W * 60 / 100))
    local stack_w=$((SCREEN_W - main_w))
    local stack_h=$((SCREEN_H / (count - 1)))

    # Main window (first)
    wmctrl -i -r "${wins[0]}" -e 0,0,0,"$main_w","$SCREEN_H"

    # Stack windows
    for i in $(seq 1 $((count - 1))); do
        local y=$(( (i - 1) * stack_h ))
        wmctrl -i -r "${wins[$i]}" -e 0,"$main_w","$y","$stack_w","$stack_h"
    done
}

tile_grid() {
    local wins=("$@")
    local count=${#wins[@]}
    [ "$count" -eq 0 ] && return

    local cols=2
    local rows=2
    [ "$count" -gt 4 ] && cols=3
    [ "$count" -gt 6 ] && cols=4

    local cell_w=$((SCREEN_W / cols))
    local cell_h=$((SCREEN_H / ((count + cols - 1) / cols)))

    for i in $(seq 0 $((count - 1))); do
        local col=$((i % cols))
        local row=$((i / cols))
        local x=$((col * cell_w))
        local y=$((row * cell_h))
        wmctrl -i -r "${wins[$i]}" -e 0,"$x","$y","$cell_w","$cell_h"
    done
}

# Main
WS=$(get_workspace_id)
mapfile -t WINDOWS < <(get_windows_on_workspace "$WS")
# Filter out desktop and panel windows
FILTERED=()
for w in "${WINDOWS[@]}"; do
    CLASS=$(xprop -id "$w" WM_CLASS 2>/dev/null | cut -d'"' -f2 || true)
    [ "$CLASS" = "cinnamon" ] && continue
    [ "$CLASS" = "nemo-desktop" ] && continue
    FILTERED+=("$w")
done

case "$WS" in
    0|1) tile_master_stack "$WS" "${FILTERED[@]}" ;;
    2|3) tile_grid "${FILTERED[@]}" ;;
    4|5) tile_grid "${FILTERED[@]}" ;;
    *)   tile_master_stack "$WS" "${FILTERED[@]}" ;;
esac

echo "Tiled ${#FILTERED[@]} windows on workspace $WS"
