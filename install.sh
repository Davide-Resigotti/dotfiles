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
# Run as the regular user, not root.
stow -v --restow niri waybar mako fuzzel ghostty fontconfig xsettingsd gtk-3.0 gtk-4.0 autostart shell darkman xdg-desktop-portal theme

# Wallpapers: copied (not symlinked) so ~/Pictures keeps screenshots etc.
mkdir -p "$HOME/Pictures/Wallpapers"
for img in wallpapers/Pictures/Wallpapers/*.jpg; do
    [ -e "$img" ] || continue
    cp -n "$img" "$HOME/Pictures/Wallpapers/"
done

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
EOF
