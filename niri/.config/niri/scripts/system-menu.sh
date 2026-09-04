#!/usr/bin/env bash
# ==============================================================================
# system-menu.sh — Wofi-based System Shortcuts & System Details HUD for Niri
# ==============================================================================
# Features:
#  - Top-level menu: "System Details" vs "System Shortcuts"
#  - Persistent "Last Used Command" on top for instant re-run
#  - Direct in-place command execution and result viewing inside Wofi (no terminal windows)
#  - Vim motions (j/k/h/l, o/Return to open) and modal search (/)
#  - Escape returns to previous menu level
# ==============================================================================

set -euo pipefail

# Ensure wofi is installed
if ! command -v wofi >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wofi Not Found" "Please install wofi: sudo dnf install -y wofi" -u critical -i dialog-error
    fi
    echo "Error: wofi is not installed. Run: sudo dnf install -y wofi" >&2
    exit 1
fi

WOFI_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/wofi/config"
WOFI_STYLE="${XDG_CONFIG_HOME:-$HOME/.config}/wofi/style.css"

# Load current dynamic theme accents if available
ACCENT="#df6124"
FG="#f0f0f4"
ACCENT_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/theme/current-accent.env"
if [[ -f "$ACCENT_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$ACCENT_ENV" 2>/dev/null || true
    ACCENT="${PRIMARY_COLOR:-#df6124}"
fi

COLOR_KEY="$ACCENT"
COLOR_CMD="#61afef"
COLOR_DESC="#abb2bf"
COLOR_STAR="#a6e3a1"
COLOR_SHORTCUTS="#f9e2af"
COLOR_DOCS="#cba6f7"
COLOR_HEADER="$ACCENT"

# Persistence for last command used
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/system-menu"
LAST_CMD_FILE="$CACHE_DIR/last-command"
mkdir -p "$CACHE_DIR"

# Pre-seed with backlight status if file does not exist yet
if [[ ! -f "$LAST_CMD_FILE" ]]; then
    printf 'backlight status|~/.config/niri/scripts/backlight.sh status\n' > "$LAST_CMD_FILE"
fi

# Pango markup escaping & stripping helpers (supports both argument and stdin pipe)
escape_pango() {
    local input="${1:-$(cat)}"
    printf '%s' "$input" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

strip_pango() {
    local input="${1:-$(cat)}"
    printf '%s' "$input" | sed -e 's/<[^>]*>//g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

get_last_command() {
    if [[ -f "$LAST_CMD_FILE" ]]; then
        IFS='|' read -r LAST_LABEL LAST_CMD < "$LAST_CMD_FILE" || true
        export LAST_LABEL="${LAST_LABEL:-}"
        export LAST_CMD="${LAST_CMD:-}"
    else
        export LAST_LABEL=""
        export LAST_CMD=""
    fi
}

save_last_command() {
    local label="$1"
    local cmd="$2"
    mkdir -p "$CACHE_DIR"
    printf '%s|%s\n' "$label" "$cmd" > "$LAST_CMD_FILE"
}

# ------------------------------------------------------------------------------
# In-Wofi Command Execution & Result Viewer
# ------------------------------------------------------------------------------
show_command_result() {
    local label="$1"
    local raw_cmd="$2"
    local expanded_cmd="${raw_cmd/#\~/$HOME}"

    # Update persistent last command
    save_last_command "$label" "$raw_cmd"

    # Copy command to clipboard
    if command -v wl-copy >/dev/null 2>&1; then
        echo -n "$raw_cmd" | wl-copy
    fi

    while true; do
        # Execute command and capture combined output
        local raw_output
        raw_output="$(eval "$expanded_cmd" 2>&1 || true)"

        # Build in-place result view for Wofi
        local menu_content
        menu_content="$(
            printf '<span weight="bold" foreground="%s">═══  %s  ═══</span>\n' "$COLOR_HEADER" "$label"
            printf '<span foreground="%s">▶ Command:</span> <span weight="bold" foreground="%s">%s</span> <span foreground="%s">(copied to clipboard)</span>\n' \
                "$COLOR_STAR" "$COLOR_CMD" "$raw_cmd" "$COLOR_DESC"
            printf '<span weight="bold" foreground="%s">󰌌  [ Back to System Details ]</span>\n' "$COLOR_SHORTCUTS"
            printf '<span foreground="%s">────────────────────────────────────────────────────────────────────────────</span>\n' "$COLOR_DESC"

            if [[ -z "$raw_output" ]]; then
                printf '<span weight="bold" foreground="%s">✓ Command executed successfully.</span>\n' "$COLOR_STAR"
                if [[ "$raw_cmd" == *"niri msg output"* ]]; then
                    local cur_m
                    cur_m="$(niri msg outputs 2>/dev/null | grep -E "Current mode|Variable refresh" || true)"
                    if [[ -n "$cur_m" ]]; then
                        printf '<span foreground="%s">%s</span>\n' "$COLOR_DESC" "$(escape_pango "$cur_m")"
                    fi
                fi
            else
                while IFS= read -r line; do
                    local escaped
                    escaped="$(printf '%s\n' "$line" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
                    printf '<span foreground="%s">%s</span>\n' "$FG" "$escaped"
                done <<< "$raw_output"
            fi

            printf '<span foreground="%s">────────────────────────────────────────────────────────────────────────────</span>\n' "$COLOR_DESC"
            printf '<span weight="bold" foreground="%s">󰌌  [ Back to System Details ]</span>\n' "$COLOR_SHORTCUTS"
            printf '<span weight="bold" foreground="%s">󰑐  [ Re-run Command ]</span>\n' "$COLOR_CMD"
            printf '<span weight="bold" foreground="%s">📋 [ Copy Full Output to Clipboard ]</span>\n' "$COLOR_STAR"
        )"

        local res_choice
        res_choice="$(echo "$menu_content" | wofi --conf "$WOFI_CONF" \
                                                 --style "$WOFI_STYLE" \
                                                 --prompt "$label > " \
                                                 --height 600 \
                                                 --width 920 \
                                                 2>/dev/null || true)"

        # Escape closes Wofi completely
        if [[ -z "$res_choice" ]]; then
            exit 0
        fi

        # User explicitly requested returning to System Details
        if [[ "$res_choice" == *"Back to System Details"* ]]; then
            return 0
        elif [[ "$res_choice" == *"Re-run Command"* ]]; then
            continue
        elif [[ "$res_choice" == *"Copy Full Output"* ]]; then
            if command -v wl-copy >/dev/null 2>&1; then
                echo -n "$raw_output" | wl-copy
            fi
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Output Copied" "Output of $label copied to clipboard" -a "System Details" -i edit-copy -t 2500
            fi
            exit 0
        else
            # User selected a specific line: copy clean text to clipboard and exit
            local clean_line
            clean_line="$(echo "$res_choice" | sed -e 's/<[^>]*>//g' -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [[ -n "$clean_line" ]]; then
                if command -v wl-copy >/dev/null 2>&1; then
                    echo -n "$clean_line" | wl-copy
                fi
                if command -v notify-send >/dev/null 2>&1; then
                    notify-send "Line Copied" "$clean_line" -a "System Details" -i edit-copy -t 2000
                fi
            fi
            exit 0
        fi
    done
}

# ------------------------------------------------------------------------------
# Top-Level Main Menu
# ------------------------------------------------------------------------------
generate_main_menu() {
    get_last_command
    if [[ -n "${LAST_CMD:-}" ]]; then
        printf '<span weight="bold" foreground="%s">★ Last Command:</span> <span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">%s</span>\n' \
            "$COLOR_STAR" "$COLOR_CMD" "${LAST_LABEL:-command}" "$COLOR_DESC" "$LAST_CMD"
    fi
    printf '<span weight="bold" foreground="%s">%-36s</span> │ <span foreground="%s">Hardware power, backlight, tuned, services, diagnostics</span>\n' \
        "$COLOR_CMD" "󰄛  System Details" "$FG"
    printf '<span weight="bold" foreground="%s">%-36s</span> │ <span foreground="%s">Niri keybindings, window management, workspaces, launchers</span>\n' \
        "$COLOR_SHORTCUTS" "󰌌  System Shortcuts" "$FG"
    printf '<span weight="bold" foreground="%s">%-36s</span> │ <span foreground="%s">Read guides for scripts, power optimization, and dotfiles</span>\n' \
        "$COLOR_DOCS" "󰈙  Documentation" "$FG"
}

# ------------------------------------------------------------------------------
# Submenu 1: System Details Commands
# ------------------------------------------------------------------------------
generate_details_menu() {
    get_last_command
    if [[ -n "${LAST_CMD:-}" ]]; then
        printf '<span weight="bold" foreground="%s">★ Last Used:</span>   <span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">%s</span>\n' \
            "$COLOR_STAR" "$COLOR_CMD" "${LAST_LABEL:-command}" "$COLOR_DESC" "$LAST_CMD"
    fi

    # Backlight & ALS
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh status</span>\n' \
        "$COLOR_CMD" "backlight status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh model</span>\n' \
        "$COLOR_CMD" "backlight model" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh toggle-auto-screen</span>\n' \
        "$COLOR_CMD" "auto-screen toggle" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh train-toggle</span>\n' \
        "$COLOR_CMD" "ml training toggle" "$COLOR_DESC"

    # Battery & hardware power management
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/power_now</span>\n' \
        "$COLOR_CMD" "battery discharge" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/capacity</span>\n' \
        "$COLOR_CMD" "battery capacity" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/status</span>\n' \
        "$COLOR_CMD" "battery status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">sudo /usr/local/bin/hardware-power-toggle status</span>\n' \
        "$COLOR_CMD" "hardware eco status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.config/waybar/scripts/hardware-power-toggle.sh --toggle</span>\n' \
        "$COLOR_CMD" "hardware eco toggle" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">tuned-adm active</span>\n' \
        "$COLOR_CMD" "tuned profile" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">cat /sys/module/pcie_aspm/parameters/policy</span>\n' \
        "$COLOR_CMD" "pcie aspm policy" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">cat /sys/bus/pci/devices/0000:02:00.0/power/control</span>\n' \
        "$COLOR_CMD" "sdcard power state" "$COLOR_DESC"

    # Wallpaper & system services
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">ps aux | grep -E "mpvpaper|swaybg" | grep -v grep</span>\n' \
        "$COLOR_CMD" "wallpaper engine" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">ps aux | grep -iE "akonadi|mysqld" | grep -v grep</span>\n' \
        "$COLOR_CMD" "akonadi / mysql" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">systemctl --user status kbd-backlight-watcher.service</span>\n' \
        "$COLOR_CMD" "backlight service" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">systemctl --user status waypaper-power-watcher.service</span>\n' \
        "$COLOR_CMD" "wallpaper service" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">systemctl --user status deep-sleep-inhibit.service</span>\n' \
        "$COLOR_CMD" "deep sleep status" "$COLOR_DESC"

    # Displays, audio & theme
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg outputs</span>\n' \
        "$COLOR_CMD" "niri outputs" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg output eDP-1 mode 3024x1890@120.000</span>\n' \
        "$COLOR_CMD" "display 120hz (pro)" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg output eDP-1 mode 3024x1890@60.000</span>\n' \
        "$COLOR_CMD" "display 60hz (eco)" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg action power-off-monitors</span>\n' \
        "$COLOR_CMD" "display dpms off" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">pgrep -a swayidle</span>\n' \
        "$COLOR_CMD" "idle blanking status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg workspaces</span>\n' \
        "$COLOR_CMD" "niri workspaces" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">niri msg windows</span>\n' \
        "$COLOR_CMD" "niri windows" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">wpctl status</span>\n' \
        "$COLOR_CMD" "audio status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-22s</span> │ <span foreground="%s">~/.local/bin/set-accent current</span>\n' \
        "$COLOR_CMD" "theme accent" "$COLOR_DESC"
}

# ------------------------------------------------------------------------------
# Submenu 2: System Shortcuts
# ------------------------------------------------------------------------------
generate_shortcuts_menu() {
    # Core applications & launchers
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Open a Terminal (ghostty)</span>\n' \
        "$COLOR_KEY" "Mod + Return" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Open agy AI session (ghostty -e tmux)</span>\n' \
        "$COLOR_KEY" "Mod + A" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Open Firefox Browser</span>\n' \
        "$COLOR_KEY" "Mod + B" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Run Application Launcher (fuzzel)</span>\n' \
        "$COLOR_KEY" "Mod + D / Super+Space" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Neovim Anywhere (quick floating note)</span>\n' \
        "$COLOR_KEY" "Super + N" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Lock Screen (swaylock)</span>\n' \
        "$COLOR_KEY" "Super + Alt + L" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Clipboard History Picker (niri-copy-paste)</span>\n' \
        "$COLOR_KEY" "Mod + Shift + V" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Cycle Next Wallpaper (waypaper)</span>\n' \
        "$COLOR_KEY" "Mod + Shift + W" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">System Shortcuts &amp; Details Menu (wofi)</span>\n' \
        "$COLOR_KEY" "Mod + Shift + /" "$FG"

    # Hardware, backlight & media controls
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Toggle Auto Screen Brightness</span>\n' \
        "$COLOR_KEY" "Mod + Shift + B" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Display Brightness Up / Down</span>\n' \
        "$COLOR_KEY" "MonBrightnessUp/Down" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Keyboard Backlight Up / Down</span>\n' \
        "$COLOR_KEY" "Mod + BrightnessUp/Down" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Media Play / Pause / Stop</span>\n' \
        "$COLOR_KEY" "F11 / AudioStop" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Media Next / Previous Track</span>\n' \
        "$COLOR_KEY" "Home / End" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Audio Mute / Volume Adjust</span>\n' \
        "$COLOR_KEY" "F12 / AudioRaise-Lower" "$FG"

    # Screenshots
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Screenshot: Partial Area</span>\n' \
        "$COLOR_KEY" "Mod + T" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Screenshot: Full Screen</span>\n' \
        "$COLOR_KEY" "Mod + Shift + T" "$FG"

    # Layout & window actions
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Close Focused Window</span>\n' \
        "$COLOR_KEY" "Mod + Q" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Toggle Overview (Workspaces &amp; Columns)</span>\n' \
        "$COLOR_KEY" "Mod + O" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Maximize Column</span>\n' \
        "$COLOR_KEY" "Mod + F" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Fullscreen Window</span>\n' \
        "$COLOR_KEY" "Mod + Shift + F" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Maximize Window to Screen Edges</span>\n' \
        "$COLOR_KEY" "Mod + M" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Center Focused Column</span>\n' \
        "$COLOR_KEY" "Mod + C" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Center All Visible Columns</span>\n' \
        "$COLOR_KEY" "Mod + Ctrl + C" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Toggle Column Tabbed Display</span>\n' \
        "$COLOR_KEY" "Mod + W" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Toggle Window Floating / Tiling</span>\n' \
        "$COLOR_KEY" "Mod + V" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Switch Focus Between Floating and Tiling</span>\n' \
        "$COLOR_KEY" "Mod + Shift + S" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Consume or Expel Window (Left / Right)</span>\n' \
        "$COLOR_KEY" "Mod + [ / ]" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Consume Window into Column / Expel to Right</span>\n' \
        "$COLOR_KEY" "Mod + , / ." "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Cycle Preset Column Width (Forward / Back)</span>\n' \
        "$COLOR_KEY" "Mod + R / Shift+R" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Adjust Column Width (-10%% / +10%%)</span>\n' \
        "$COLOR_KEY" "Mod + - / =" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Adjust Window Height (-10%% / +10%%)</span>\n' \
        "$COLOR_KEY" "Mod + Shift + - / =" "$FG"

    # Navigation
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Focus Column or Window (Left/Down/Up/Right)</span>\n' \
        "$COLOR_KEY" "Mod + H / J / K / L" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Move Column or Window (Left/Down/Up/Right)</span>\n' \
        "$COLOR_KEY" "Mod + Ctrl + H/J/K/L" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Move Column to Workspace or Monitor</span>\n' \
        "$COLOR_KEY" "Mod + Shift + H/J/K/L" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Switch to Previous Workspace</span>\n' \
        "$COLOR_KEY" "Mod + Tab" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Focus Workspace 1 .. 9</span>\n' \
        "$COLOR_KEY" "Mod + 1 .. 9" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Move Window to Workspace 1 .. 9</span>\n' \
        "$COLOR_KEY" "Mod + Shift + 1 .. 9" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Move Column to Workspace 1 .. 9</span>\n' \
        "$COLOR_KEY" "Mod + Ctrl + 1 .. 9" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Focus Workspace Down / Up</span>\n' \
        "$COLOR_KEY" "Mod + PageDown / PageUp" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Move Workspace Down / Up</span>\n' \
        "$COLOR_KEY" "Mod + Shift + PgDn/PgUp" "$FG"

    # Session & safety
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Toggle Keyboard Shortcuts Inhibitor</span>\n' \
        "$COLOR_KEY" "Mod + Escape" "$FG"
    printf '<span weight="bold" foreground="%s">%-22s</span> • <span foreground="%s">Quit Niri Session (confirmation dialog)</span>\n' \
        "$COLOR_KEY" "Mod + Shift + E" "$FG"
}

# ------------------------------------------------------------------------------
# Submenu Handlers
# ------------------------------------------------------------------------------
handle_details_menu() {
    local selected
    selected="$(generate_details_menu | wofi --conf "$WOFI_CONF" \
                                             --style "$WOFI_STYLE" \
                                             --prompt "System Details (/ to search) > " \
                                             --height 580 \
                                             --width 880 \
                                             2>/dev/null || true)"
    [[ -z "$selected" ]] && return 1

    if [[ "$selected" == *"│"* ]]; then
        local raw_cmd label
        raw_cmd="$(echo "$selected" | awk -F'│' '{print $2}' | strip_pango)"
        label="$(echo "$selected" | awk -F'│' '{print $1}' | strip_pango | sed -e 's/★ Last Used:[[:space:]]*//')"
        show_command_result "$label" "$raw_cmd"
        return 0
    fi
    return 1
}

handle_shortcuts_menu() {
    local selected
    selected="$(generate_shortcuts_menu | wofi --conf "$WOFI_CONF" \
                                               --style "$WOFI_STYLE" \
                                               --prompt "System Shortcuts (/ to search) > " \
                                               --height 580 \
                                               --width 880 \
                                               2>/dev/null || true)"
    [[ -z "$selected" ]] && return 1

    if [[ "$selected" == *"•"* ]]; then
        local key action
        key="$(echo "$selected" | awk -F'•' '{print $1}' | strip_pango)"
        action="$(echo "$selected" | awk -F'•' '{print $2}' | strip_pango)"

        # Copy shortcut to clipboard
        if command -v wl-copy >/dev/null 2>&1; then
            echo -n "$key — $action" | wl-copy
        fi

        # Send notification
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Shortcut Copied" "$key\n$action" -a "System Shortcuts" -i input-keyboard -t 3000
        fi
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Submenu 3: Documentation
# ------------------------------------------------------------------------------
emit_doc_entry() {
    local filepath="$1"
    local custom_title="${2:-}"

    local title="$custom_title"
    if [[ -z "$title" ]]; then
        # Try to extract the first Markdown # heading from the file
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [[ "$line" =~ ^#[[:space:]]+(.+)$ ]]; then
                title="${BASH_REMATCH[1]}"
                break
            fi
        done < "$filepath"
    fi

    if [[ -z "$title" ]]; then
        local bname
        bname="$(basename "$filepath" .md)"
        title="$(echo "$bname" | tr '-' ' ' | sed -e 's/\b\(.\)/\u\1/g')"
    fi

    # Trim title if too long so the menu stays neat and aligned
    if (( ${#title} > 36 )); then
        title="${title:0:33}..."
    fi

    local rel_path="~${filepath#$HOME}"
    local title_escaped path_escaped
    title_escaped="$(escape_pango "$title")"
    path_escaped="$(escape_pango "$rel_path")"

    printf '<span weight="bold" foreground="%s">%-36s</span> │ <span foreground="%s">%s</span>\n' \
        "$COLOR_DOCS" "$title_escaped" "$COLOR_DESC" "$path_escaped"
}

generate_docs_menu() {
    local -A seen_real=()

    # Priority curated entries with clear, descriptive titles
    local -a curated=(
        "$HOME/dotfiles/docs/battery-optimization.md|Battery & Power Overview"
        "$HOME/dotfiles/docs/battery-optimization/display-and-keyboard.md|Display & Keyboard ALS"
        "$HOME/dotfiles/docs/battery-optimization/wallpaper.md|Dynamic Wallpaper Power"
        "$HOME/dotfiles/docs/battery-optimization/system-level.md|Hardware & System Tuning"
        "$HOME/.config/niri/cameras.md|RTSP Camera Viewers"
        "$HOME/dotfiles/niri/.config/niri/cameras.md|RTSP Camera Viewers"
        "$HOME/dotfiles/README.md|Dotfiles & System Guide"
    )

    for item in "${curated[@]}"; do
        local f="${item%%|*}"
        local title="${item#*|}"
        if [[ -f "$f" ]]; then
            local real
            real="$(realpath "$f" 2>/dev/null || true)"
            [[ -z "$real" || -n "${seen_real[$real]:-}" ]] && continue
            seen_real["$real"]=1
            emit_doc_entry "$f" "$title"
        fi
    done

    # Search directories for any other documentation files created by user
    local -a search_dirs=(
        "$HOME/dotfiles/docs"
        "$HOME/.config/niri"
        "$HOME/.config"
        "$HOME/docs"
        "$HOME/dotfiles"
    )

    for sdir in "${search_dirs[@]}"; do
        [[ ! -d "$sdir" ]] && continue
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            local base
            base="$(basename "$f")"
            # Ignore licenses, templates, node_modules, changelogs
            [[ "$base" =~ ^(LICENSE|CHANGELOG|bug_report|feature_request) ]] && continue
            local real
            real="$(realpath "$f" 2>/dev/null || true)"
            [[ -z "$real" || -n "${seen_real[$real]:-}" ]] && continue
            seen_real["$real"]=1
            emit_doc_entry "$f" ""
        done < <(find "$sdir" -maxdepth 3 -type f -name "*.md" ! -path "*/.*" ! -path "*/node_modules/*" ! -path "*/venv/*" ! -path "*/.venv/*" 2>/dev/null | sort || true)
    done
}

handle_docs_menu() {
    local selected
    selected="$(generate_docs_menu | wofi --conf "$WOFI_CONF" \
                                          --style "$WOFI_STYLE" \
                                          --prompt "Documentation (/ to search) > " \
                                          --height 580 \
                                          --width 880 \
                                          2>/dev/null || true)"
    [[ -z "$selected" ]] && return 1

    if [[ "$selected" == *"│"* ]]; then
        local raw_path title
        raw_path="$(echo "$selected" | awk -F'│' '{print $2}' | strip_pango)"
        title="$(echo "$selected" | awk -F'│' '{print $1}' | strip_pango)"
        local expanded_path="${raw_path/#\~/$HOME}"
        if [[ -f "$expanded_path" ]]; then
            ghostty --class=dev.nvim.docs \
                    --title="Documentation: $title" \
                    -e nvim "$expanded_path" &
            exit 0
        else
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "File Not Found" "Cannot open $expanded_path" -a "Documentation" -u critical -i dialog-error
            fi
            return 1
        fi
    fi
    return 1
}

# ------------------------------------------------------------------------------
# CLI Flags (dry-run / dump)
# ------------------------------------------------------------------------------
if [[ "${1:-}" == "--dump" || "${1:-}" == "--dump-main" ]]; then
    generate_main_menu
    exit 0
elif [[ "${1:-}" == "--dump-details" ]]; then
    generate_details_menu
    exit 0
elif [[ "${1:-}" == "--dump-shortcuts" ]]; then
    generate_shortcuts_menu
    exit 0
elif [[ "${1:-}" == "--dump-docs" ]]; then
    generate_docs_menu
    exit 0
fi

# ------------------------------------------------------------------------------
# Main Application Loop
# ------------------------------------------------------------------------------
while true; do
    CHOICE="$(generate_main_menu | wofi --conf "$WOFI_CONF" \
                                       --style "$WOFI_STYLE" \
                                       --prompt "Select Menu (/ to search) > " \
                                       --height 310 \
                                       --width 860 \
                                       2>/dev/null || true)"

    [[ -z "$CHOICE" ]] && exit 0

    CLEAN_CHOICE="$(strip_pango "$CHOICE")"

    # User chose "Last Command" directly from the top menu
    if [[ "$CLEAN_CHOICE" == *"Last"* ]]; then
        get_last_command
        if [[ -n "${LAST_CMD:-}" ]]; then
            show_command_result "${LAST_LABEL:-command}" "$LAST_CMD"
        fi
        # Returns back to main menu loop
    elif [[ "$CLEAN_CHOICE" == *"System Details"* ]]; then
        while true; do
            if ! handle_details_menu; then
                break
            fi
        done
        # If Escape was pressed in details submenu, loop back to main menu
    elif [[ "$CLEAN_CHOICE" == *"System Shortcuts"* ]]; then
        if handle_shortcuts_menu; then
            exit 0
        fi
        # If Escape was pressed in shortcuts submenu, loop back to main menu
    elif [[ "$CLEAN_CHOICE" == *"Documentation"* ]]; then
        while true; do
            if ! handle_docs_menu; then
                break
            fi
        done
        # If Escape was pressed in docs submenu, loop back to main menu
    else
        exit 0
    fi
done
