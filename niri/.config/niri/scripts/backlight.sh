#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(realpath "$0")")"
BL=/sys/class/backlight/apple-panel-bl
max=$(cat "$BL/max_brightness")
cur=$(cat "$BL/brightness")

# Step by 5% of max brightness (e.g. 25 units for max 500)
step=$((max / 20))
[ "$step" -lt 1 ] && step=1

case "${1:-}" in
    up)
        val=$(( ((cur + step) / step) * step ))
        [ "$val" -gt "$max" ] && val=$max
        [ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
        # Notify ML adaptive watcher of manual adjustment
        "$DIR/kbd-backlight-watcher" --manual-adjust "$val" >/dev/null 2>&1 || true
        ;;
    down)
        val=$(( ((cur - 1) / step) * step ))
        [ "$val" -lt 1 ] && val=1
        [ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
        # Notify ML adaptive watcher of manual adjustment
        "$DIR/kbd-backlight-watcher" --manual-adjust "$val" >/dev/null 2>&1 || true
        ;;
    toggle-auto-screen)
        "$DIR/kbd-backlight-watcher" --toggle-auto-screen
        ;;
    model|model-status|--model)
        "$DIR/kbd-backlight-watcher" --model-status
        ;;
    reset-model|model-reset|--model-reset)
        "$DIR/kbd-backlight-watcher" --model-reset
        ;;
    reset-bias)
        "$DIR/kbd-backlight-watcher" --model-reset
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
    lid-close)
        # Check if deep sleep inhibitor is active (deep sleep mode OFF / active tasks running)
        if systemctl --user is-active --quiet deep-sleep-inhibit.service 2>/dev/null || \
           pgrep -f "systemd-inhibit.*handle-lid-switch.*Waybar" >/dev/null 2>&1; then
            # Dim screen and keyboard to 0% while lid is closed
            SAVED_FILE="${XDG_RUNTIME_DIR:-/tmp}/saved-screen-brightness"
            if [ "$cur" -gt 0 ]; then
                printf '%s\n' "$cur" > "$SAVED_FILE"
            fi
            printf '0\n' > "$BL/brightness"
            "$DIR/kbd-backlight-watcher" --kbd-set 0 >/dev/null 2>&1 || true
        fi
        # If deep sleep mode is ON (not inhibited), logind will automatically suspend the laptop
        ;;
    lid-open)
        SAVED_FILE="${XDG_RUNTIME_DIR:-/tmp}/saved-screen-brightness"
        "$DIR/kbd-backlight-watcher" --sync >/dev/null 2>&1 || {
            if [ -f "$SAVED_FILE" ]; then
                saved=$(cat "$SAVED_FILE" 2>/dev/null || echo 150)
                [ "$saved" -lt 10 ] && saved=150
                printf '%s\n' "$saved" > "$BL/brightness"
            else
                printf '150\n' > "$BL/brightness"
            fi
        }
        ;;
    status)
        "$DIR/kbd-backlight-watcher" --status
        ;;
    *)
        echo "usage: $0 up|down|kbd-up|kbd-down|kbd-toggle|kbd-set <val>|sync|status|model|reset-model|toggle-auto-screen|lid-close|lid-open" >&2
        exit 1
        ;;
esac
