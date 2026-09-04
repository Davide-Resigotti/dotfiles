#!/usr/bin/env bash
# restow-all.sh - Validate and restow all packages listed in dotfiles
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

PACKAGES=(
    niri waybar mako fuzzel wofi ghostty fontconfig xsettingsd
    gtk-2.0 gtk-3.0 gtk-4.0 autostart shell darkman xdg-desktop-portal
    theme home-assistant waypaper yazi tmux nvim npm opencode
)

echo "Starting dry-run validation..."
cd "$DOTFILES_DIR"

if ! stow -n -v --restow "${PACKAGES[@]}" >/dev/null 2>&1; then
    echo "[FAIL] Dry-run failed with conflicts! Running with verbose output:"
    stow -n -v --restow "${PACKAGES[@]}" || true
    exit 1
fi

echo "[OK] Dry-run passed with zero conflicts. Restowing packages..."
stow -v --restow "${PACKAGES[@]}"

echo "[DONE] All ${#PACKAGES[@]} packages successfully restowed."
