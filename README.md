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
| `waybar`     | `~/.config/waybar`  | `config.jsonc`, `style.css` |
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
| `autostart`  | `~/.config/autostart` | XWayland video bridge |
| `shell`      | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig` | exports system color and accent variables, machine-agnostic |
| `wallpapers` | copied to `~/Pictures/Wallpapers` | Wallpapers grouped by color folder (`Orange`, `Blue`, `Purple`) |
| `waypaper`   | `~/.config/waypaper` | Wallpaper manager config, cycle scripts, and hardware power watcher daemon |
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

### 2. Wallpaper & Power-Aware Live Playback

- Wallpapers in `~/Pictures/Wallpapers/` are grouped into folders by color (`Orange/`, `Blue/`, `Purple/`).
- Press <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> to cycle wallpapers. `set-wallpaper-accent` automatically detects the parent folder and applies the matching palette.
- **Power Optimization (`power-wallpaper-watcher`)**:
  - Automatically runs as a background user service (`waypaper-power-watcher.service`).
  - Monitors hardware power state via `/sys/class/power_supply/*/online` (respects battery charge limiters like 75%).
  - **Under AC Power**: Plays full 60fps video wallpapers (`.mp4`) with GPU acceleration (`mpvpaper --hwdec=auto --no-audio`).
  - **On Battery**: Instantly swaps video wallpapers for their high-resolution 4K static frame (`~/.cache/wallpaper-frames/`) and pauses `mpv`, dropping CPU usage to **0.0%**.

### 3. Display & Keyboard Backlight Auto-Sync (`kbd-backlight-watcher`)

- **Proportional Threshold Control**:
  - Managed via user systemd service (`kbd-backlight-watcher.service`) and `~/.config/niri/scripts/backlight.sh`.
  - **Display < 50%**: Keyboard backlight automatically turns ON and scales **proportionally** to the screen brightness (e.g. 20% screen = 20% keyboard, 40% screen = 40% keyboard).
  - **Display >= 50%**: Keyboard backlight automatically turns OFF (0).
- **5% Step Increments**: Screen brightness steps in precise 5% increments (e.g. 5%, 10%, 15%... 50%... 100%).
- **Keybindings**:
  - Display Brightness: <kbd>BrightnessUp</kbd> / <kbd>BrightnessDown</kbd> (F1/F2 or `XF86MonBrightnessUp`/`Down`) steps by 5%.
  - Keyboard Brightness Scale: <kbd>Mod</kbd>+<kbd>BrightnessUp</kbd> / <kbd>Mod</kbd>+<kbd>BrightnessDown</kbd> (or dedicated <kbd>XF86KbdBrightnessUp</kbd>/<kbd>Down</kbd>) fine-tunes the proportionality scale factor.

### 4. Application Synchronizations

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
