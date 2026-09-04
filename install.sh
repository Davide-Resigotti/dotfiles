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

# Ensure target config directories exist
mkdir -p "$HOME/.config" "$HOME/.local/bin"

# Back up existing non-symlink default files that would conflict with stow
for f in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.gitconfig"; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
        echo "Backing up non-symlink $(basename "$f") to $(basename "$f").bak"
        mv "$f" "${f}.bak"
    fi
done

if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    echo "Backing up non-symlink ~/.config/nvim to ~/.config/nvim.bak"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi

# Replace any legacy absolute dotfiles symlinks with clean stow-managed relative symlinks
for l in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.gitconfig" \
         "$HOME/.config/niri" "$HOME/.config/waybar" "$HOME/.config/mako" "$HOME/.config/fuzzel" \
         "$HOME/.config/xsettingsd" "$HOME/.config/fontconfig" "$HOME/.config/autostart" \
         "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/ghostty"; do
    if [ -L "$l" ]; then
        target="$(readlink "$l")"
        if [[ "$target" = /*dotfiles* ]]; then
            rm "$l"
        fi
    fi
done

# Packages -> stow symlinks them into $HOME (e.g. ~/.config/niri -> repo).
stow -v --restow niri waybar mako fuzzel ghostty fontconfig xsettingsd gtk-3.0 gtk-4.0 autostart shell darkman xdg-desktop-portal theme home-assistant waypaper yazi tmux nvim

# HA toggles (.desktop Exec uses the bare name; needs ~/.local/bin on PATH)
ln -sf "$HOME/.config/home-assistant/scripts/ha-toggle" "$HOME/.local/bin/ha-toggle"

# Battery & power optimization reference guide
ln -sf "$PWD/docs/battery-optimization.md" "$HOME/.config/battery-optimization.md"

# Wallpapers: copied (not symlinked) so ~/Pictures keeps screenshots etc.
mkdir -p "$HOME/Pictures/Wallpapers"
cp -rn wallpapers/Pictures/Wallpapers/* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

# Neovim Python provider virtualenv & plugins
if command -v python3 >/dev/null 2>&1; then
    if [ ! -d "$HOME/.config/nvim/.venv" ]; then
        echo "Creating Neovim Python virtualenv at ~/.config/nvim/.venv..."
        python3 -m venv "$HOME/.config/nvim/.venv"
        "$HOME/.config/nvim/.venv/bin/pip" install --upgrade pip
        "$HOME/.config/nvim/.venv/bin/pip" install pynvim
    fi
fi

if command -v nvim >/dev/null 2>&1; then
    echo "Syncing Neovim plugins via lazy.nvim..."
    nvim --headless "+Lazy! sync" +qa || true
fi

# nvim-wl-anywhere (bind for Super+N in niri)
if [ ! -d "$HOME/.local/share/nvim-wl-anywhere" ]; then
    echo "Cloning nvim-wl-anywhere..."
    git clone --depth=1 https://github.com/abdullah-albanna/nvim-wl-anywhere.git "$HOME/.local/share/nvim-wl-anywhere" || true
fi

# Waypaper virtualenv helper
if ! command -v waypaper >/dev/null 2>&1; then
    if [ ! -d "$HOME/.local/share/waypaper-venv" ] && command -v python3 >/dev/null 2>&1; then
        echo "Creating waypaper virtualenv..."
        python3 -m venv --system-site-packages "$HOME/.local/share/waypaper-venv"
        "$HOME/.local/share/waypaper-venv/bin/pip" install --upgrade pip
        "$HOME/.local/share/waypaper-venv/bin/pip" install waypaper screeninfo || true
        ln -sf "$HOME/.local/share/waypaper-venv/bin/waypaper" "$HOME/.local/bin/waypaper"
    fi
fi

# Firefox customization & Pywalfox integration
mkdir -p "$HOME/.mozilla"
if [ -d "$HOME/.config/mozilla/firefox" ] && [ ! -L "$HOME/.mozilla/firefox" ]; then
    ln -sfn "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"
fi
for pdir in "$HOME/.config/mozilla/firefox/"*.default* "$HOME/.mozilla/firefox/"*.default*; do
    if [ -d "$pdir" ]; then
        mkdir -p "$pdir/chrome"
        cp -f firefox/chrome/userChrome.css "$pdir/chrome/userChrome.css"
        cp -f firefox/user.js "$pdir/user.js"
    fi
done

if command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user pywalfox >/dev/null 2>&1 || true
    if command -v pywalfox >/dev/null 2>&1; then
        pywalfox install --profile-path "$HOME/.config/mozilla/firefox" >/dev/null 2>&1 || true
    fi
fi

# Enable background watcher services
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    systemctl --user enable --now waypaper-power-watcher.service >/dev/null 2>&1 || true
    systemctl --user enable --now kbd-backlight-watcher.service >/dev/null 2>&1 || true
fi

# keyd config and udev rules live in root-owned /etc, so they're copied (needs sudo).
if [ "${NONINTERACTIVE:-0}" != "1" ] && sudo -v; then
    sudo install -D -m 644 keyd/etc/keyd/default.conf /etc/keyd/default.conf
    sudo rm -f /etc/keyd/mx-mechanical-mini.conf
    sudo systemctl try-restart keyd.service
    echo "keyd config installed."

    if [ -f udev/etc/udev/rules.d/90-apple-backlight.rules ]; then
        sudo install -D -m 644 udev/etc/udev/rules.d/90-apple-backlight.rules /etc/udev/rules.d/90-apple-backlight.rules
        sudo udevadm control --reload-rules
        sudo udevadm trigger -s backlight -s leds || true
        echo "backlight & keyboard backlight udev rules installed."
    fi
else
    echo "root configs NOT installed (sudo unavailable)." >&2
    echo "  Re-run as root: install -D -m 644 keyd/etc/keyd/*.conf /etc/keyd/ && systemctl restart keyd" >&2
fi

cat <<'EOF'

Done.

Optional next steps:
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
  * Neovim: Python provider is configured in ~/.config/nvim/.venv. For Python LSPs/formatters:
    pip install --user 'python-lsp-server[all]' pylsp-mypy python-lsp-black python-lsp-isort
  * ~/.local/bin must be on PATH for HA and custom scripts.
EOF
