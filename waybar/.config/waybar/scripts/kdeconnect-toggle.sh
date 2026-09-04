#!/usr/bin/env bash
set -euo pipefail

is_on_ac() {
    local has_battery=0
    for ps in /sys/class/power_supply/*; do
        if [[ -f "$ps/type" ]]; then
            local type
            type="$(cat "$ps/type" 2>/dev/null || true)"
            if [[ "$type" == "Battery" ]]; then
                has_battery=1
            elif [[ "$type" == "Mains" || "$type" == "USB" || "$type" == "USB_PD" || "$type" == "AC" ]]; then
                if [[ -f "$ps/online" && "$(cat "$ps/online" 2>/dev/null || true)" == "1" ]]; then
                    return 0
                fi
            fi
        fi
    done
    if [[ "$has_battery" -eq 0 ]]; then
        return 0
    fi
    return 1
}

SERVICE="app-org.kde.kdeconnect.daemon@autostart.service"

is_kdeconnect_active() {
    systemctl --user is-active "$SERVICE" >/dev/null 2>&1 || pgrep -x kdeconnectd >/dev/null 2>&1
}

# Toggle action
if [[ "${1:-}" == "--toggle" ]]; then
    if is_kdeconnect_active; then
        systemctl --user stop "$SERVICE" 2>/dev/null || true
        pkill -x kdeconnectd 2>/dev/null || true
    else
        systemctl --user start "$SERVICE" 2>/dev/null || kdeconnectd &
    fi
    pkill -RTMIN+8 waybar 2>/dev/null || true
    exit 0
fi

# If on AC power, hide toggle (KDE Connect runs automatically on AC)
if is_on_ac; then
    echo '{"text": "", "class": "hidden"}'
    exit 0
fi

# On battery: show toggle
if is_kdeconnect_active; then
    echo '{"text": "[ 󰄡 on ]", "class": "on", "tooltip": "KDE Connect: Active on battery\nClick to turn off and save power"}'
else
    echo '{"text": "[ 󰄡 off ]", "class": "off", "tooltip": "KDE Connect: Inactive on battery\nClick to turn on"}'
fi
