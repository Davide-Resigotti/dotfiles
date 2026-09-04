# dotfiles

My Niri-on-Fedora setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow *package* mirroring `$HOME`: running `stow niri`
symlinks `~/.config/niri` to `niri/.config/niri` inside this repo. You edit the real
files as usual; every change is a git change. No copying, no sync step.
(`keyd` and `wallpapers` are the exceptions: they're copied, not symlinked — `keyd`
targets root-owned `/etc/keyd`, so `install.sh` needs sudo for it.)

## Packages

| Package      | Symlinks to `$HOME` | Contents |
|--------------|---------------------|----------|
| `niri`       | `~/.config/niri`    | `config.kdl` (portable `$HOME` spawn paths), `scripts/` (theme apply + early-dark arming, wallpaper cycling) |
| `waybar`     | `~/.config/waybar`  | `config.jsonc`, `style.css`, battery power toggles (`hardware-power-toggle.sh`, `kdeconnect-toggle.sh`) |
| `mako`       | `~/.config/mako`    | notification daemon |
| `fuzzel`     | `~/.config/fuzzel`  | launcher used by the clipboard picker |
| `ghostty`    | `~/.config/ghostty` | terminal config (`config`) |
| `gtk-3.0`, `gtk-4.0` | `~/.config/gtk-{3,4}.0` | GTK theming + window-button assets (generated `*dank-colors.css` excluded) |
| `xsettingsd` | `~/.config/xsettingsd` | GTK settings bridge |
| `fontconfig` | `~/.config/fontconfig` | font aliases (Nerd Font -> Cascadia Code NF) |
| `darkman`    | `~/.config/darkman`, `~/.local/share/darkman` | darkman config (fixed Milan coords) + transition hook |
| `xdg-desktop-portal` | `~/.config/xdg-desktop-portal` | XDG desktop portal configuration |
| `theme`     | `~/.config/theme`, `~/.local/bin/set-accent`, `~/.local/bin/toggle-theme`, `~/.local/share/applications` | Dynamic primary & system color accent dispatcher, Fuzzel theme toggle, and app launcher shortcuts |
| `home-assistant` | `~/.config/home-assistant/scripts` | `ha-toggle <entity>` — toggles a HA entity via the local REST API (token read from `~/.config/home-assistant/token`) |
| `autostart`  | `~/.config/autostart` | XWayland video bridge, daemon autostart overrides (`geoclue`, `kunifiedpush`, `sealertauto`) |
| `shell`      | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig`, `~/.local/bin/apply-hardware-power-tuning` | exports system color and accent variables, hardware power tuning installer |
| `wallpapers` | copied to `~/Pictures/Wallpapers` | Wallpapers grouped by color folder (`Orange`, `Blue`, `Purple`) |
| `waypaper`   | `~/.config/waypaper`, `~/.local/bin/mpvpaper` | Wallpaper manager config, smart swaybg/mpvpaper dispatcher, cycle scripts, and dynamic power watcher daemon |
| `firefox`    | `~/.config/mozilla/firefox/*/chrome` | Dynamic vertical tabs theme stylesheet (`userChrome.css`) & Pywalfox integration |
| `yazi`       | `~/.config/yazi`    | terminal file manager (`yazi.toml`, opener configured for Neovim) |
| `tmux`       | `~/.tmux.conf`      | terminal multiplexer config (vi keys, wl-copy integration, mouse, true color) |
| `nvim`       | `~/.config/nvim`    | Neovim config (lazy.nvim, blink-cmp, Python/Lua LSP, snippets, UI) |
| `keyd`      | copied to `/etc/keyd` (needs root) | keyboard remap: capslock->ctrl/esc |

## Restore on a new machine (Fedora)

```sh
# System packages
sudo dnf install niri waybar mako fuzzel swaybg wtype wl-clipboard \
  at xsettingsd fontconfig solaar ghostty python3-astral stow darkman \
  neovim tmux mpvpaper mpv python3-pip ripgrep fd-find fzf jq

# CLI tools and previewers via Homebrew (for Yazi and Neovim)
brew install yazi ffmpeg sevenzip jq poppler fd fzf zoxide resvg imagemagick lua-language-server

# Neovim Python language server and formatters (optional)
pip install --user 'python-lsp-server[all]' pylsp-mypy python-lsp-black python-lsp-isort

# Clone and run automated installer (handles stow, nvim virtualenv, plugins, and helpers)
git clone https://github.com/Davide-Resigotti/dotfiles.git
cd dotfiles
./install.sh
```

Enable user services (logged into the graphical session):

```sh
systemctl --user enable waybar.service
systemctl --user enable --now waypaper-power-watcher.service
```

Home Assistant toggles need a token after restore (never committed):

```sh
mkdir -p ~/.config/home-assistant
# paste a long-lived access token from HA (Profile -> Security -> Long-lived access tokens)
umask 177 && cat > ~/.config/home-assistant/token
```

The HA base URL is in `~/.config/home-assistant/scripts/ha-toggle`; the
dashboards' URLs are hardcoded in the `.desktop` files under the `theme`
package — edit them for your network. The Fan/Studio entries call the bare
`ha-toggle` name, so keep `~/.local/bin` (symlinked by `install.sh`) on PATH.

## Dynamic Color & Accent System

The desktop uses a centralized, wallpaper-driven color engine that synchronizes primary accents and matching dark background tones across all desktop environments, terminals, and applications without layout breakage.

### 1. Palette Engine & Shared Variables

Palettes are defined in [`theme/.config/theme/palettes.conf`](file:///home/davideresigotti/dotfiles/theme/.config/theme/palettes.conf) using the format:
`NAME=PRIMARY_COLOR:SYSTEM_BG:SYSTEM_FG:SYSTEM_FIELD`

| Accent | Primary Color | System Background | System Field |
|--------|---------------|-------------------|--------------|
| `orange` | `#df6124` | `#28201e` (warm espresso) | `#201918` |
| `blue`   | `#3daee9` | `#212634` (midnight navy) | `#1a1e2a` |
| `purple` | `#a855f7` | `#221d27` (obsidian violet) | `#1c1721` |

Whenever the theme or wallpaper changes, `set-accent <name>` writes:
- **`~/.config/theme/current-accent.env`**: Sourced in `~/.bashrc` to provide `$PRIMARY_COLOR` and `$SYSTEM_COLOR` variables to all subshells and CLI tools.
- **`~/.cache/wal/colors.json`**: Provides palette colors for the Pywalfox native messaging bridge.

### 2. Wallpaper & Power-Aware Playback

- Wallpapers in `~/Pictures/Wallpapers/` are grouped into folders by color (`Orange/`, `Blue/`, `Purple/`).
- Press <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> to cycle wallpapers manually. `set-wallpaper-accent` automatically detects the parent folder and applies the matching palette.
- **Rotation Interval**:
  - **On AC Power**: Automatically rotates wallpapers every **60 minutes**.
  - **On Battery**: Automatic rotation is disabled to save CPU/storage wakeups; manual cycling with <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> remains fully available.
- **Smart Backend Delegation (`~/.local/bin/mpvpaper`)**:
  - **On AC Power with Videos**: Plays full 60fps video wallpapers (`.mp4`) with hardware acceleration via `mpvpaper-bin`.
  - **On Battery OR with Static Photos**: Automatically delegates to `swaybg` (1 thread, ~14 MB RAM, 0% CPU, 0 GPU wakeups). If the active wallpaper is a video, its crisp 4K frame is extracted (`~/.cache/wallpaper-frames/`) and displayed statically.
- **Dynamic Transition Daemon (`waypaper-power-watcher.service`)**:
  - Listens to kernel power events via `udevadm monitor -u -s power_supply`.
  - Smoothly transitions between live 60fps video on AC and static `swaybg` on battery when plugging/unplugging the charger.

### 3. Power & Battery Optimization Architecture

The system features dynamic power management tailored for Apple Silicon (M2 Pro), documented in detail in [`docs/battery-optimization.md`](docs/battery-optimization.md):

- **Hardware Power Saver (`[ 󰍛 hw off ]` / `[ 󰍛 hw on ]`)**:
  - An interactive toggle in Waybar appears only when on battery.
  - Defaults to `[ 󰍛 hw off ]` (power savings active: PCIe ASPM `powersupersave`, SD Card reader idle autosuspend in D3hot/D3cold, TuneD `power-saver` with `vm.laptop_mode=5`).
  - Clicking the module toggles to `[ 󰍛 hw on ]` (restoring full standard hardware performance).
  - Toggles are automatically hidden on AC power.
- **Dynamic KDE Connect (`[ 󰄡 off ]` / `[ 󰄡 on ]`)**:
  - Automatically disabled on battery to prevent periodic Wi-Fi discovery UDP broadcasts.
  - Interactive toggle appears in Waybar on battery to enable sync on demand; hidden on AC.
- **Akonadi & MySQL Power Management**:
  - Kalendar reminders and the Akonadi MySQL stack (`mysqld`, 13 agents) are stopped automatically on battery, saving **>534 MB RAM** and **108 threads**.
  - Automatically restarted on AC, or socket-activated on demand if a KDE PIM application is opened.
- **Waybar Zero-Subshell Efficiency**:
  - Eliminated custom separator subshell polling scripts (saving ~14,400 process forks/hr).
- **Session Autostarts & System Daemons**:
  - Autostart overrides in `autostart/.config/autostart/` suppress unneeded background daemons (`geoclue`, `kunifiedpush`, `sealertauto`) in Niri.
  - Disabled `ModemManager.service` (no WWAN card on MacBook) and converted CUPS to on-demand `cups.socket`.

### 4. Ambient Light Sensor (ALS) & Backlight Automation (`kbd-backlight-watcher`)

- **Hardware Ambient Light Sensor (ALS)**:
  - Continuously samples the room illuminance via Apple Silicon's ultra-low-power AOP sensor (`aop-sensors-als`).
  - Native sysfs read overhead is just **18 microseconds** (< 0.005% CPU); saving power by turning off LEDs in daytime.
- **Keyboard Backlight**:
  - **In Bright Light (> 55 lux)**: Automatically turns **OFF** (`0/255`), eliminating power waste when keys are already visible.
  - **In Dim/Dark Light (< 30 lux)**: Automatically turns **ON** and scales proportionally to the display brightness.
  - **Hysteresis & Clamshell Detection**: Hysteresis between 30 and 55 lux eliminates jitter. If the MacBook lid is closed, the keyboard backlight is always forced off.
- **Screen Auto-Brightness (`auto_screen = true`)**:
  - Maps ambient lux to optimal screen brightness using a smooth perceptual (logarithmic) curve in 5% increments.
  - **User Bias**: Pressing <kbd>F1</kbd>/<kbd>F2</kbd> shifts your personal preference offset ($+5\% / -5\%$) across the entire ambient curve without fighting the daemon.
- **Configuration (`~/.config/niri/ambient.conf`)**:
  - Customize `kbd_lux_dark`, `kbd_lux_bright`, `auto_screen`, `screen_min_pct`, `screen_max_pct`, and `poll_interval`.
- **Keybindings**:
  - Display Brightness: <kbd>F1</kbd> / <kbd>F2</kbd> (or `XF86MonBrightnessDown`/`Up`) steps by 5% and shifts ambient bias.
  - Keyboard Scale: <kbd>Mod</kbd>+<kbd>BrightnessUp</kbd> / <kbd>Mod</kbd>+<kbd>BrightnessDown</kbd> fine-tunes keyboard intensity.
  - Toggle Auto-Screen: <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>B</kbd> toggles automatic screen brightness on/off.

### 5. Application Synchronizations

- **Niri**: Focus ring active border updates in real-time via `~/.config/niri/accent.kdl`.
- **Waybar**: Imports `colors.css` defining `@define-color accent`. Reloads styles seamlessly without restarting.
- **Ghostty**: Automatically updates the terminal background color (`#221d27`, `#28201e`, etc.) and sends `SIGUSR2` for instant hot-reloading.
- **Fuzzel**: Includes `accent.ini` to highlight matches and borders with the primary color.
- **Firefox**:
  - Configured with a clean vertical-tabs stylesheet (`userChrome.css`) that keeps tabs intact.
  - Transparent navigation bar and vertical sidebar inherit `--lwt-accent-color` live.
  - Integrated with **Pywalfox**: `set-accent` triggers `pywalfox update`, changing Firefox's top bar, sidebar, and accents **live while open with zero restarts**.
- **GTK & Desktop Portal**:
  - Defaults to `Breeze-Dark` across GTK 3, GTK 4, and `xsettingsd`.
  - Portal is routed to `gnome;gtk;` to guarantee dark mode across Flatpak and native apps.
  - Press <kbd>Super</kbd>+<kbd>Space</kbd> and launch **Toggle Theme** (or run `toggle-theme`) to switch between Dark and Light mode on demand.

## Day-to-day

Because live paths are symlinks into this repo, just commit:

```sh
cd ~/dotfiles
git add -A && git commit -m "tweak" && git push
```

## Machine-specific notes

- `config.kdl` is portable: hardcoded `/home/<user>` paths are gone. The external
  monitor output block is commented out — uncomment and adapt the name/mode/position
  (get them from `niri msg outputs`).
- `xsettingsd` DPI (`Gdk/UnscaledDPI`) is display-specific — adjust after restore.
- Excluded on purpose: `~/.ssh`, `~/.config/gh` (tokens), `.cache`, `.local/state`,
  bash history, `node_modules`, screenshots, `*.mp4` wallpapers, and the compiled
  `niri-copy-paste` binary (built from its own repository).
