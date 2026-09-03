#!/usr/bin/env bash
# Restore dotfiles on a fresh machine.
# Run from the repo root after `git clone`:
#   ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v stow >/dev/null 2>&1; then
    echo "GNU stow is required:  sudo dnf install stow   (or apt install stow)" >&2
    exit 1
fi

# Packages -> stow symlinks them into $HOME (e.g. ~/.config/niri -> repo).
stow -v --restow niri waybar mako fuzzel ghostty fontconfig xsettingsd gtk-3.0 gtk-4.0 autostart shell darkman xdg-desktop-portal theme home-assistant waypaper

# HA toggles (.desktop Exec uses the bare name; needs ~/.local/bin on PATH)
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.config/home-assistant/scripts/ha-toggle" "$HOME/.local/bin/ha-toggle"

# Wallpapers: copied (not symlinked) so ~/Pictures keeps screenshots etc.
mkdir -p "$HOME/Pictures/Wallpapers"
for img in wallpapers/Pictures/Wallpapers/*.jpg; do
    [ -e "$img" ] || continue
    cp -n "$img" "$HOME/Pictures/Wallpapers/"
done

# keyd config lives in root-owned /etc/keyd, so it's copied (needs sudo).
if sudo -v; then
    sudo install -D -m 644 keyd/etc/keyd/default.conf /etc/keyd/default.conf
    sudo rm -f /etc/keyd/mx-mechanical-mini.conf
    sudo systemctl try-restart keyd.service
    echo "keyd config installed."
else
    echo "keyd config NOT installed (sudo unavailable)." >&2
    echo "  Re-run as root: install -D -m 644 keyd/etc/keyd/*.conf /etc/keyd/ && systemctl restart keyd" >&2
fi

cat <<'EOF'

Done.

Optional next steps:
  systemctl --user enable --now darkman.service   # auto light/dark via sunrise/sunset
  systemctl --user enable waybar.service     # if you use the systemd-managed bar
  systemctl --user daemon-reload

Machine-specific adjustments after restore:
  * niri: uncomment/adapt the external-monitor output block in ~/.config/niri/config.kdl
    (names/modes come from `niri msg outputs`).
  * xsettingsd: adjust Gdk/UnscaledDPI in ~/.config/xsettingsd/xsettingsd.conf for your display.
  * The clipboard daemon binding expects `niri-copy-paste` on PATH (build from its own repo).
  * Home Assistant: create ~/.config/home-assistant/token (chmod 600) with a long-lived
    access token from your HA instance; ha-toggle reads it to call the local API.
    The HA base URL lives in ~/.config/home-assistant/scripts/ha-toggle.
  * ~/.local/bin must be on PATH for the Fan/Studio launcher entries to work.
EOF
