#!/usr/bin/env bash
# ==============================================================================
# system-menu.sh — Wofi-based System Shortcuts & System Details Menu for Niri
# ==============================================================================
# Provides a searchable HUD with two sections:
#  1. System Shortcuts: Keybindings from Niri config (copies shortcut to clipboard)
#  2. System Details: Terminal diagnostic commands (copies & runs in floating Ghostty)
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

# Load current dynamic theme accents if available
ACCENT="#df6124"
FG="#dcdfe4"
ACCENT_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/theme/current-accent.env"
if [[ -f "$ACCENT_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$ACCENT_ENV" 2>/dev/null || true
    ACCENT="${PRIMARY_COLOR:-#df6124}"
    FG="${SYSTEM_FG:-#dcdfe4}"
fi

# Secondary colors for rich visual distinction
COLOR_KEY="$ACCENT"
COLOR_CMD="#61afef"
COLOR_DESC="#abb2bf"
COLOR_HEADER="$ACCENT"

generate_menu() {
    # --------------------------------------------------------------------------
    # SECTION 1: SYSTEM SHORTCUTS
    # --------------------------------------------------------------------------
    echo "<span weight=\"bold\" foreground=\"$COLOR_HEADER\">═══  SYSTEM SHORTCUTS  ══════════════════════════════════════════════════</span>"
    
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

    # --------------------------------------------------------------------------
    # SECTION 2: SYSTEM DETAILS
    # --------------------------------------------------------------------------
    echo "<span weight=\"bold\" foreground=\"$COLOR_HEADER\">═══  SYSTEM DETAILS (RUN &amp; VIEW)  ══════════════════════════════════════</span>"

    # Backlight & ALS
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh status</span>\n' \
        "$COLOR_CMD" "backlight status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh model</span>\n' \
        "$COLOR_CMD" "backlight model" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh toggle-auto-screen</span>\n' \
        "$COLOR_CMD" "auto-screen toggle" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.config/niri/scripts/backlight.sh train-toggle</span>\n' \
        "$COLOR_CMD" "ml training toggle" "$COLOR_DESC"

    # Battery & hardware power management
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/power_now</span>\n' \
        "$COLOR_CMD" "battery discharge" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/capacity</span>\n' \
        "$COLOR_CMD" "battery capacity" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">cat /sys/class/power_supply/macsmc-battery/status</span>\n' \
        "$COLOR_CMD" "battery status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">sudo /usr/local/bin/hardware-power-toggle status</span>\n' \
        "$COLOR_CMD" "hardware eco status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.config/waybar/scripts/hardware-power-toggle.sh --toggle</span>\n' \
        "$COLOR_CMD" "hardware eco toggle" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">tuned-adm active</span>\n' \
        "$COLOR_CMD" "tuned profile" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">cat /sys/module/pcie_aspm/parameters/policy</span>\n' \
        "$COLOR_CMD" "pcie aspm policy" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">cat /sys/bus/pci/devices/0000:02:00.0/power/control</span>\n' \
        "$COLOR_CMD" "sdcard power state" "$COLOR_DESC"

    # Wallpaper & system services
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">ps aux | grep -E "mpvpaper|swaybg" | grep -v grep</span>\n' \
        "$COLOR_CMD" "wallpaper engine" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">ps aux | grep -iE "akonadi|mysqld" | grep -v grep</span>\n' \
        "$COLOR_CMD" "akonadi / mysql" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">systemctl --user status kbd-backlight-watcher.service</span>\n' \
        "$COLOR_CMD" "backlight service" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">systemctl --user status waypaper-power-watcher.service</span>\n' \
        "$COLOR_CMD" "wallpaper service" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">systemctl --user status deep-sleep-inhibit.service</span>\n' \
        "$COLOR_CMD" "deep sleep status" "$COLOR_DESC"

    # Displays, audio & theme
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">niri msg outputs</span>\n' \
        "$COLOR_CMD" "niri outputs" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">niri msg workspaces</span>\n' \
        "$COLOR_CMD" "niri workspaces" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">niri msg windows</span>\n' \
        "$COLOR_CMD" "niri windows" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">wpctl status</span>\n' \
        "$COLOR_CMD" "audio status" "$COLOR_DESC"
    printf '<span weight="bold" foreground="%s">%-20s</span> │ <span foreground="%s">~/.local/bin/set-accent current</span>\n' \
        "$COLOR_CMD" "theme accent" "$COLOR_DESC"
}

# Allow dry-run dump for verification or headless checks
if [[ "${1:-}" == "--dump" || "${1:-}" == "--test" ]]; then
    generate_menu
    exit 0
fi

# Run Wofi
SELECTED="$(generate_menu | wofi --conf "${XDG_CONFIG_HOME:-$HOME/.config}/wofi/config" \
                                --style "${XDG_CONFIG_HOME:-$HOME/.config}/wofi/style.css" \
                                2>/dev/null || true)"

# Exit if user cancelled or pressed Escape
[[ -z "$SELECTED" ]] && exit 0

# If user clicked a section header, ignore and exit
if [[ "$SELECTED" =~ ^[═\─] ]]; then
    exit 0
fi

# ------------------------------------------------------------------------------
# Process System Details Selection (contains │)
# ------------------------------------------------------------------------------
if [[ "$SELECTED" == *"│"* ]]; then
    RAW_CMD="$(echo "$SELECTED" | awk -F'│' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    LABEL="$(echo "$SELECTED" | awk -F'│' '{print $1}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Expand ~ to $HOME in command
    EXPANDED_CMD="${RAW_CMD/#\~/$HOME}"

    # Copy exact command to clipboard
    if command -v wl-copy >/dev/null 2>&1; then
        echo -n "$RAW_CMD" | wl-copy
    fi

    # Launch floating Ghostty terminal running the command
    ghostty --class=system-details \
            --title="System Details: $LABEL" \
            -e bash -c '
                raw_cmd="$1"
                expanded_cmd="$2"
                printf "\033[1;38;2;223;97;36m▶ Command:\033[0m \033[1;37m%s\033[0m\n\n" "$raw_cmd"
                eval "$expanded_cmd"
                printf "\n\033[2m───────────────────────────────────────────────────────────\033[0m\n"
                printf "\033[2m✓ Copied to clipboard. Press Enter or Ctrl+C to close.\033[0m\n"
                read -r _
            ' bash "$RAW_CMD" "$EXPANDED_CMD" &
    exit 0
fi

# ------------------------------------------------------------------------------
# Process System Shortcuts Selection (contains •)
# ------------------------------------------------------------------------------
if [[ "$SELECTED" == *"•"* ]]; then
    KEY="$(echo "$SELECTED" | awk -F'•' '{print $1}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    ACTION="$(echo "$SELECTED" | awk -F'•' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Copy shortcut info to clipboard
    if command -v wl-copy >/dev/null 2>&1; then
        echo -n "$KEY — $ACTION" | wl-copy
    fi

    # Display desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Shortcut Copied" "$KEY\n$ACTION" -a "System Shortcuts" -i input-keyboard -t 3000
    fi
    exit 0
fi
