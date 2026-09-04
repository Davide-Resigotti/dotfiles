#!/usr/bin/env bash
set -euo pipefail

bat="/sys/class/power_supply/macsmc-battery"
ac="/sys/class/power_supply/macsmc-ac"

# Read battery state
status="$(cat "$bat/status" 2>/dev/null || echo "Unknown")"
cap="$(cat "$bat/capacity" 2>/dev/null || echo "0")"
ac_online="$(cat "$ac/online" 2>/dev/null || echo "0")"

# Energy readings (uWh)
energy_now="$(cat "$bat/energy_now" 2>/dev/null || echo "0")"
energy_full="$(cat "$bat/energy_full" 2>/dev/null || echo "0")"
energy_design="$(cat "$bat/energy_full_design" 2>/dev/null || echo "0")"

# Battery power draw / charge rate (uW)
bat_power="$(cat "$bat/power_now" 2>/dev/null || echo "0")"
if [[ "$bat_power" -eq 0 ]]; then
    v="$(cat "$bat/voltage_now" 2>/dev/null || echo "0")"
    c="$(cat "$bat/current_now" 2>/dev/null || echo "0")"
    c="${c#-}" # absolute value
    if [[ "$v" -gt 0 && "$c" -gt 0 ]]; then
        bat_power=$(( (v * c) / 1000000 ))
    fi
fi

# Hardware monitor power sensors (Apple Silicon SMC)
sys_power=0
ac_power=0
for h in /sys/class/hwmon/hwmon*; do
    if [[ -f "$h/name" && "$(< "$h/name")" == "macsmc_hwmon" ]]; then
        [[ -f "$h/power1_input" ]] && sys_power="$(< "$h/power1_input")"
        [[ -f "$h/power2_input" ]] && ac_power="$(< "$h/power2_input")"
        break
    fi
done

cycles="$(cat "$bat/cycle_count" 2>/dev/null || echo "")"
time_to_empty="$(cat "$bat/time_to_empty_now" 2>/dev/null || echo "0")"

# Fast formatting and JSON generation with awk
awk -v status="$status" -v cap="$cap" -v ac_online="$ac_online" \
    -v en_now="$energy_now" -v en_full="$energy_full" -v en_design="$energy_design" \
    -v bat_p="$bat_power" -v sys_p="$sys_power" -v ac_p="$ac_power" \
    -v cycles="$cycles" -v time_to_empty="$time_to_empty" '
BEGIN {
    en_now_wh = en_now / 1000000.0
    en_full_wh = en_full / 1000000.0
    bat_w = bat_p / 1000000.0
    sys_w = sys_p / 1000000.0
    ac_w = ac_p / 1000000.0

    health_str = ""
    if (en_design > 0) {
        health_str = sprintf("%.1f%%", (en_full / en_design) * 100)
    }

    tooltip = ""
    classes = ""

    if (ac_online == 1) {
        if (status == "Charging") {
            text = sprintf("bat %d%% ", cap)
            tooltip = sprintf("Status: Charging  (%d%%)\\nCharge Rate: %.2f W", cap, bat_w)
            if (ac_w > 0) {
                tooltip = tooltip sprintf("\\nAC Input: %.2f W (System: %.2f W)", ac_w, sys_w)
            }
            if (bat_p > 0 && en_full > en_now) {
                rem_h = (en_full - en_now) / bat_p
                h = int(rem_h)
                m = int((rem_h - h) * 60)
                tooltip = tooltip sprintf("\\nTime to Full: %dh %02dm", h, m)
            }
            classes = "\"plugged\", \"charging\""
        } else {
            text = sprintf("bat %d%% 󰚦", cap)
            tooltip = sprintf("Status: Plugged 󰚦 (%s)", status)
            if (sys_w > 0) tooltip = tooltip sprintf("\\nTotal System Power: %.2f W", sys_w)
            if (ac_w > 0) tooltip = tooltip sprintf("\\nAC Input Power: %.2f W", ac_w)
            classes = "\"plugged\""
        }
    } else {
        text = sprintf("bat %d%%", cap)
        draw = (bat_w > 0) ? bat_w : sys_w
        tooltip = sprintf("Status: Discharging (%d%%)\\nPower Draw: %.2f W", cap, draw)
        if (sys_w > 0 && bat_w > 0) {
            tooltip = tooltip sprintf("\\nTotal System Power: %.2f W", sys_w)
        }
        if (time_to_empty > 0) {
            h = int(time_to_empty / 3600)
            m = int((time_to_empty % 3600) / 60)
            tooltip = tooltip sprintf("\\nTime Remaining: %dh %02dm", h, m)
        } else if (draw > 0 && en_now_wh > 0) {
            rem_h = en_now_wh / draw
            h = int(rem_h)
            m = int((rem_h - h) * 60)
            tooltip = tooltip sprintf("\\nTime Remaining: %dh %02dm", h, m)
        }
        classes = "\"discharging\""
    }

    tooltip = tooltip sprintf("\\nEnergy: %.1f / %.1f Wh", en_now_wh, en_full_wh)
    if (cycles != "" && health_str != "") {
        tooltip = tooltip sprintf("\\nCycles: %s | Health: %s", cycles, health_str)
    }

    crit_warn = ""
    if (cap <= 10) crit_warn = "\"critical\", "
    else if (cap <= 20) crit_warn = "\"warning\", "

    printf "{\"text\": \"%s\", \"tooltip\": \"%s\", \"class\": [%s%s], \"percentage\": %d}\n", text, tooltip, crit_warn, classes, cap
}'
