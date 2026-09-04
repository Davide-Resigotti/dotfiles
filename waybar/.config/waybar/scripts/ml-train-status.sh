#!/usr/bin/env bash
set -euo pipefail

SCRIPT="$HOME/.config/niri/scripts/backlight.sh"

case "${1:-}" in
    --toggle|toggle)
        "$SCRIPT" train-toggle
        exit 0
        ;;
    *)
        "$SCRIPT" waybar
        ;;
esac
