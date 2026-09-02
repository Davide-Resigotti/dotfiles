#!/usr/bin/env bash
set -euo pipefail

BL=/sys/class/backlight/apple-panel-bl
max=$(cat "$BL/max_brightness")
cur=$(cat "$BL/brightness")
step=$((max / 10))

case "${1:-}" in
    up)
        val=$((cur + step))
        [ "$val" -gt "$max" ] && val=$max
        ;;
    down)
        val=$((cur - step))
        [ "$val" -lt 1 ] && val=1
        ;;
    *)
        echo "usage: $0 up|down" >&2
        exit 1
        ;;
esac

[ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
