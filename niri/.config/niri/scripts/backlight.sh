#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(realpath "$0")")"
BL=/sys/class/backlight/apple-panel-bl
max=$(cat "$BL/max_brightness")
cur=$(cat "$BL/brightness")

# Step by 5% of max brightness (e.g. 25 for max 500)
step=$((max / 20))
[ "$step" -lt 1 ] && step=1

case "${1:-}" in
    up)
        val=$(( ((cur + step) / step) * step ))
        [ "$val" -gt "$max" ] && val=$max
        [ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
        "$DIR/kbd-backlight-watcher" --sync
        ;;
    down)
        val=$(( ((cur - 1) / step) * step ))
        [ "$val" -lt 1 ] && val=1
        [ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
        "$DIR/kbd-backlight-watcher" --sync
        ;;
    kbd-up)
        "$DIR/kbd-backlight-watcher" --kbd-up
        ;;
    kbd-down)
        "$DIR/kbd-backlight-watcher" --kbd-down
        ;;
    kbd-toggle)
        "$DIR/kbd-backlight-watcher" --kbd-toggle
        ;;
    kbd-set)
        "$DIR/kbd-backlight-watcher" --kbd-set "${2:-0}"
        ;;
    sync)
        "$DIR/kbd-backlight-watcher" --sync
        ;;
    status)
        "$DIR/kbd-backlight-watcher" --status
        ;;
    *)
        echo "usage: $0 up|down|kbd-up|kbd-down|kbd-toggle|kbd-set <val>|sync|status" >&2
        exit 1
        ;;
esac
