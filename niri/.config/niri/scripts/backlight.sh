#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(realpath "$0")")"
BL=/sys/class/backlight/apple-panel-bl
max=$(cat "$BL/max_brightness")
cur=$(cat "$BL/brightness")

# Minimum active brightness (1% of max, e.g. 5 units for max 500)
min_val=$(( max / 100 ))
[ "$min_val" -lt 1 ] && min_val=1

# Thresholds for tiered perceptual stepping (10%, 20%, 40%)
th10=$(( max * 10 / 100 ))
th20=$(( max * 20 / 100 ))
th40=$(( max * 40 / 100 ))

# Step sizes: 1%, 2%, 5%, 10%
step1=$(( max / 100 ))
[ "$step1" -lt 1 ] && step1=1
step2=$(( max * 2 / 100 ))
[ "$step2" -lt 1 ] && step2=1
step5=$(( max * 5 / 100 ))
[ "$step5" -lt 1 ] && step5=1
step10=$(( max * 10 / 100 ))
[ "$step10" -lt 1 ] && step10=1

case "${1:-}" in
    up)
        # Tiered perceptual stepping:
        # < 10%   -> 1% step for dim environments
        # 10-20%  -> 2% step
        # 20-40%  -> 5% step
        # 40-100% -> 10% step for bright outdoors
        if [ "$cur" -lt "$th10" ]; then
            step=$step1
        elif [ "$cur" -lt "$th20" ]; then
            step=$step2
        elif [ "$cur" -lt "$th40" ]; then
            step=$step5
        else
            step=$step10
        fi
        val=$(( cur + step ))
        [ "$val" -lt "$min_val" ] && val=$min_val
        [ "$val" -gt "$max" ] && val=$max
        [ "$val" -ne "$cur" ] && printf '%s\n' "$val" > "$BL/brightness"
        # Notify ML adaptive watcher of manual adjustment
        "$DIR/kbd-backlight-watcher" --manual-adjust "$val" >/dev/null 2>&1 || true
        ;;
    down)
        # Tiered perceptual stepping downwards:
        # <= 10%  -> 1% step
        # <= 20%  -> 2% step
        # <= 40%  -> 5% step
        # > 40%   -> 10% step
        if [ "$cur" -le "$th10" ]; then
            step=$step1
        elif [ "$cur" -le "$th20" ]; then
            step=$step2
        elif [ "$cur" -le "$th40" ]; then
            step=$step5
        else
            step=$step10
        fi
        val=$(( cur - step ))
        [ "$val" -lt "$min_val" ] && val=$min_val
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
        "$DIR/kbd-backlight-watcher" --model-reset "${2:-all}"
        ;;
    reset-bias)
        "$DIR/kbd-backlight-watcher" --model-reset all
        ;;
    train-toggle|toggle-train)
        "$DIR/kbd-backlight-watcher" --train-toggle
        ;;
    train|train-days)
        "$DIR/kbd-backlight-watcher" --train-days "${2:-7}"
        ;;
    waybar)
        "$DIR/kbd-backlight-watcher" --waybar
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
        # Screen and keyboard backlight MUST turn off and remain off while lid is closed
        SAVED_FILE="${XDG_RUNTIME_DIR:-/tmp}/saved-screen-brightness"
        LID_STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/lid-closed"
        touch "$LID_STATE_FILE" 2>/dev/null || true
        if [ "$cur" -gt 0 ]; then
            printf '%s\n' "$cur" > "$SAVED_FILE"
        fi
        printf '0\n' > "$BL/brightness"

        # Turn off internal display completely so panel does not glow at minimum 1%
        has_ext=$(niri msg -j outputs 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(1 if any("eDP" not in k for k in d.keys()) else 0)
except Exception:
    print(0)
' 2>/dev/null || echo 0)

        if [ "$has_ext" = "1" ]; then
            # Clamshell mode with external display: disable only eDP-1
            niri msg output eDP-1 off >/dev/null 2>&1 || true
        else
            # Standalone: power off monitors via DPMS
            niri msg action power-off-monitors >/dev/null 2>&1 || true
        fi

        "$DIR/kbd-backlight-watcher" --lid-close >/dev/null 2>&1 || {
            "$DIR/kbd-backlight-watcher" --kbd-set 0 >/dev/null 2>&1 || true
        }
        ;;
    lid-open)
        # Restore screen and keyboard backlight on lid open
        SAVED_FILE="${XDG_RUNTIME_DIR:-/tmp}/saved-screen-brightness"
        LID_STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/lid-closed"
        rm -f "$LID_STATE_FILE" 2>/dev/null || true

        # Re-enable display and power on via Niri
        niri msg action power-on-monitors >/dev/null 2>&1 || true
        niri msg output eDP-1 on >/dev/null 2>&1 || true

        "$DIR/kbd-backlight-watcher" --lid-open >/dev/null 2>&1 || {
            if [ -f "$SAVED_FILE" ]; then
                saved=$(cat "$SAVED_FILE" 2>/dev/null || echo 150)
                [ "$saved" -lt "$min_val" ] && saved=150
                printf '%s\n' "$saved" > "$BL/brightness"
            else
                printf '150\n' > "$BL/brightness"
            fi
            "$DIR/kbd-backlight-watcher" --sync >/dev/null 2>&1 || true
        }
        ;;
    status)
        "$DIR/kbd-backlight-watcher" --status
        ;;
    *)
        echo "usage: $0 up|down|kbd-up|kbd-down|kbd-toggle|kbd-set <val>|sync|status|model|reset-model [all|battery|ac]|train [days]|train-toggle|waybar|toggle-auto-screen|lid-close|lid-open" >&2
        exit 1
        ;;
esac
