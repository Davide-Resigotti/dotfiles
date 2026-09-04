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

# Toggle action
if [[ "${1:-}" == "--toggle" ]]; then
    sudo -n /usr/local/bin/hardware-power-toggle toggle >/dev/null 2>&1 || true
    pkill -RTMIN+9 waybar 2>/dev/null || true
    exit 0
fi

# If on AC power, hide toggle
if is_on_ac; then
    echo '{"text": "", "class": "hidden"}'
    exit 0
fi

# On battery: show toggle
# When power-saving is active, standard hardware performance is "off"
status="$(sudo -n /usr/local/bin/hardware-power-toggle status 2>/dev/null || echo 'on')"

if [[ "$status" == "on" ]]; then
    echo '{"text": "[ 󰍛 hw off ]", "class": "off", "tooltip": "Hardware Power: Limited for battery savings (hw off)\n- PCIe ASPM: powersupersave\n- SD Card Reader: runtime autosuspend\n- TuneD: powersave (laptop_mode=5, writeback=15s)\nClick to turn hw ON (full performance)"}'
else
    echo '{"text": "[ 󰍛 hw on ]", "class": "on", "tooltip": "Hardware Power: Full performance (hw on)\n- Standard PCIe & CPU power settings\nClick to turn hw OFF (save battery)"}'
fi
