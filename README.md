# dotfiles

Personal **Fedora Linux Asahi Remix** (Apple Silicon aarch64) desktop environment, built around the **Niri Wayland** scrollable-tiling compositor and managed via **GNU Stow**.

> [!TIP]
> All in-depth architectural guides, hardware tuning manuals, and subsystem runbooks are organized in the central [`docs/`](docs/README.md) hub.

---

## Coolest Features & System Highlights

Here are the defining features of this setup (click any highlight to read its dedicated architecture guide):

- **[Dynamic Wallpaper-Driven Color & Accent System](docs/theming/README.md)**:
  A centralized theme engine that samples wallpaper palettes and synchronizes primary accents and matching dark background tones across Niri borders, Waybar styling, Ghostty terminal, Fuzzel menus, and Firefox tabs live with zero restarts.
  <!-- Media: add desktop theme switching showcase demo/screenshot here -->

- **[Intelligent Apple Silicon Power Optimization](docs/battery-optimization/README.md)**:
  Tailored power management that switches the Liquid Retina XDR panel between fluid **120 Hz ProMotion (AC)** and power-saving **60 Hz (Battery)**, manages PCIe ASPM and SD card controller sleep, shuts down Akonadi/MySQL when unplugged (saving >534 MB RAM), and provides interactive hardware eco toggles right in Waybar.
  <!-- Media: add Waybar power toggles screenshot here -->

- **[Machine-Learning Ambient Light & Keyboard Backlight](docs/battery-optimization/display-and-keyboard.md)**:
  Continuous room illuminance sampling via Apple Silicon's ultra-low-power AOP coprocessor (`aop-sensors-als`, ~18 µs overhead). Features dual AC/Battery machine learning curves that train from user preference, 0.5% smooth display ramping, and cubic Hermite keyboard fading to 0% in daytime.
  <!-- Media: add ALS ramping and training indicator video/demo here -->

- **[Smart Home & Home Assistant Automation](docs/home-assistant/README.md)**:
  Fully decoupled, private REST API toggles (`ha-toggle`) and desktop launcher (`ha-open`) reading from uncommitted local configs (`~/.config/home-assistant/url` and `token`), alongside AI pair-programming integration via Antigravity HA-MCP.
  <!-- Media: add Home Assistant widget/menu screenshot here -->

- **[RTSP Surveillance Feeds & Yard Presence Popups](docs/cameras/yard-presence-popup.md)**:
  Low-latency RTSP camera streaming via `mpv` with PipeWire audio mixing ([guide](docs/cameras/README.md)), plus an automated mid-small video popup at the screen border triggered via Home Assistant & Mosquitto MQTT whenever presence or perimetral beam sensors are triggered.
  <!-- Media: add yard camera popup screenshot/video here -->

- **[Strict XDG Architecture & Antigravity AI Discipline](docs/system-organization/README.md)**:
  Clean `$HOME` policy enforced via XDG Base Directory environment overrides for legacy CLI tools (Cargo, Rustup, Go, Bun, NPM, GTK2), modular GNU Stow package isolation, automated system health auditing (`audit-system.sh`), and self-policing AI agent rules.

---

## GNU Stow Packages

Each top-level directory mirrors `$HOME`. Running `stow <package>` links configurations into their respective target paths:

| Package | Symlinks to `$HOME` | Description |
| :--- | :--- | :--- |
| `niri` | `~/.config/niri`, `~/.config/systemd/user/` | Compositor config (`config.kdl`), scripts, Apple ALS backlight & yard camera daemons |
| `waybar` | `~/.config/waybar`, `~/.config/systemd/user/` | Status bar layout, dynamic accent styling, hardware power & sleep inhibit toggles |
| `theme` | `~/.config/theme`, `~/.local/bin/`, `~/.local/share/` | Accent dispatcher, theme toggles, RTSP camera runners, and desktop entries |
| `waypaper` | `~/.config/waypaper`, `~/.local/bin/` | Wallpaper manager, smart AC video / Battery swaybg dispatcher & power watcher |
| `wofi` | `~/.config/wofi`, `~/.local/bin/` | System Shortcuts & Details menu (`Mod+Shift+/`) and live status browser |
| `ghostty` | `~/.config/ghostty` | High-performance terminal configuration and live color sync |
| `home-assistant` | `~/.config/home-assistant/`, `~/.local/bin/` | Private REST API entity toggle (`ha-toggle`) and browser opener (`ha-open`) |
| `npm` | `~/.config/npm/npmrc` | XDG-compliant npm configuration (`prefix` in data, `cache` in cache) |
| `gtk-2.0` | `~/.config/gtk-2.0/gtkrc` | GTK 2 settings and theme bridge |
| `gtk-3.0`, `gtk-4.0` | `~/.config/gtk-{3,4}.0` | GTK theming, Breeze-Dark styling, and window assets |
| `xsettingsd` | `~/.config/xsettingsd` | GTK XSettings bridge for Wayland |
| `fontconfig` | `~/.config/fontconfig` | Font substitution and Nerd Font aliases |
| `darkman` | `~/.config/darkman`, `~/.local/share/darkman` | Automated day/night transition hooks |
| `xdg-desktop-portal` | `~/.config/xdg-desktop-portal` | Desktop portal routing for Flatpak and native Wayland dialogs |
| `autostart` | `~/.config/autostart` | Background daemon suppression overrides (`geoclue`, `kunifiedpush`, `sealertauto`) |
| `shell` | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig`, `~/AGENTS.md` | Shell environment, XDG base directory overrides, hardware power tuning script |
| `agy` | `~/.gemini/config/skills/system-organizer` | Antigravity AI pair-programming skill, diagnostic tools, and system health audit |
| `opencode` | `~/.config/systemd/user/opencode-web.service` | OpenCode web server systemd service with uncommitted env file |
| `yazi` | `~/.config/yazi` | Terminal file manager with Neovim opener |
| `tmux` | `~/.tmux.conf` | Terminal multiplexer with vi bindings, true color, and wl-copy |
| `nvim` | `~/.config/nvim` | Fast Neovim configuration built on lazy.nvim with full LSP support |
| `wallpapers` | Copied to `~/Pictures/Wallpapers` | Categorized wallpapers (`Orange/`, `Blue/`, `Purple/`) |
| `firefox` | `~/.config/mozilla/firefox/*/chrome` | Dynamic vertical tabs theme stylesheet (`userChrome.css`) & Pywalfox bridge |
| `keyd` | Copied to `/etc/keyd` (needs root) | Hardware keyboard remapping (Caps Lock -> Ctrl/Esc) |

---

## Fresh Machine Restore

```bash
# 1. Install Fedora system packages
sudo dnf install niri waybar mako fuzzel wofi swaybg wtype wl-clipboard \
  at xsettingsd fontconfig solaar ghostty python3-astral stow darkman \
  neovim tmux mpvpaper mpv python3-pip ripgrep fd-find fzf jq

# 2. Install CLI tools & previewers via Homebrew (for Yazi and Neovim)
brew install yazi ffmpeg sevenzip jq poppler fd fzf zoxide resvg imagemagick lua-language-server

# 3. Clone dotfiles & run automated installer
git clone https://github.com/Davide-Resigotti/dotfiles.git
cd dotfiles
./install.sh
```

### Enable Background Services (in graphical session)

```bash
systemctl --user enable waybar.service
systemctl --user enable --now waypaper-power-watcher.service
systemctl --user enable --now kbd-backlight-watcher.service
systemctl --user enable --now yard-popup-watcher.service
```

For private credentials setup (Home Assistant URL & token, MQTT broker), refer to [Home Assistant Integration Guide](docs/home-assistant/README.md) and [System Organization Guide](docs/system-organization/README.md).

---

## Repository Maintenance

- **Health Audit**: `bash agy/skills/system-organizer/scripts/audit-system.sh`
- **Restow All Packages**: `bash agy/skills/system-organizer/scripts/restow-all.sh`
- **Pre-commit Hygiene & Secret Check**: `bash agy/skills/system-organizer/scripts/sync-git.sh`
