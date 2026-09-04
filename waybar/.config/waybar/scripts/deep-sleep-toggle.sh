#!/usr/bin/env bash
set -euo pipefail

SERVICE="deep-sleep-inhibit.service"

is_inhibited() {
    systemctl --user is-active --quiet "$SERVICE" 2>/dev/null || \
    pgrep -f "systemd-inhibit.*handle-lid-switch.*Waybar" >/dev/null 2>&1
}

start_inhibitor() {
    if ! systemctl --user is-active --quiet "$SERVICE" 2>/dev/null; then
        systemctl --user start "$SERVICE" 2>/dev/null || \
        systemd-run --user --unit=deep-sleep-inhibit /usr/bin/systemd-inhibit --what=handle-lid-switch --who="Waybar Deep Sleep Toggle" --why="Active tasks running with lid closed" --mode=block sleep infinity 2>/dev/null || \
        nohup /usr/bin/systemd-inhibit --what=handle-lid-switch --who="Waybar Deep Sleep Toggle" --why="Active tasks running with lid closed" --mode=block sleep infinity >/dev/null 2>&1 &
    fi
}

stop_inhibitor() {
    systemctl --user stop "$SERVICE" 2>/dev/null || true
    systemctl --user stop deep-sleep-inhibit 2>/dev/null || true
    pkill -f "systemd-inhibit.*handle-lid-switch.*Waybar" 2>/dev/null || true
}

toggle() {
    if is_inhibited; then
        # Currently inhibited (deep sleep OFF) -> turn deep sleep ON
        stop_inhibitor
    else
        # Currently not inhibited (deep sleep ON) -> turn deep sleep OFF (keep awake)
        start_inhibitor
    fi
    pkill -RTMIN+7 waybar 2>/dev/null || true
}

case "${1:-}" in
    --toggle)
        toggle
        exit 0
        ;;
    on)
        stop_inhibitor
        pkill -RTMIN+7 waybar 2>/dev/null || true
        exit 0
        ;;
    off)
        start_inhibitor
        pkill -RTMIN+7 waybar 2>/dev/null || true
        exit 0
        ;;
    status|--status)
        if is_inhibited; then
            echo "Deep sleep mode: off (lid close keeps active tasks running)"
        else
            echo "Deep sleep mode: on (lid close suspends to deep sleep)"
        fi
        exit 0
        ;;
    *)
        # Default: output JSON for Waybar
        if is_inhibited; then
            # Deep sleep is OFF: dimmed, showing it is disabled
            echo '{"text": "[ 󰒲 sleep off ]", "class": "off", "tooltip": "Deep Sleep Mode: OFF (Active Tasks)\n• Lid close: Display turns off, active tasks continue running\n• Click to turn ON (battery-saving deep sleep)"}'
        else
            # Deep sleep is ON: colored with primary accent color
            echo '{"text": "[ 󰒲 sleep on ]", "class": "on", "tooltip": "Deep Sleep Mode: ON (Battery Saving)\n• Lid close: System enters battery-saving deep sleep\n• Click to turn OFF (display turns off, active tasks continue)"}'
        fi
        ;;
esac
