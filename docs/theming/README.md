# Dynamic Color & Theming Architecture

This document describes the centralized wallpaper-driven color engine and live UI accent synchronization implemented on this **Niri Wayland** system.

---

## 1. Palette Engine & Shared Variables

Palettes are defined in [`theme/.config/theme/palettes.conf`](../../theme/.config/theme/palettes.conf) using the format:
`NAME=PRIMARY_COLOR:SYSTEM_BG:SYSTEM_FG:SYSTEM_FIELD`

| Accent | Primary Color | System Background | System Field |
|--------|---------------|-------------------|--------------|
| `orange` | `#df6124` | `#28201e` (warm espresso) | `#201918` |
| `blue`   | `#3daee9` | `#212634` (midnight navy) | `#1a1e2a` |
| `purple` | `#a855f7` | `#221d27` (obsidian violet) | `#1c1721` |

Whenever the theme or wallpaper changes, `set-accent <name>` writes:
- **`~/.config/theme/current-accent.env`**: Sourced in `~/.bashrc` to provide `$PRIMARY_COLOR` and `$SYSTEM_COLOR` variables to all subshells and CLI tools.
- **`~/.cache/wal/colors.json`**: Provides palette colors for the Pywalfox native messaging bridge.

---

## 2. Desktop Application Synchronizations

- **Niri Compositor**: Focus ring active border updates in real-time via `~/.config/niri/accent.kdl`.
- **Waybar**: Imports `colors.css` defining `@define-color accent`. Reloads styles seamlessly without restarting.
- **Ghostty Terminal**: Automatically updates the terminal background color and sends `SIGUSR2` for instant hot-reloading.
- **Fuzzel**: Includes `accent.ini` to dynamically synchronize background color, text, matches, and borders with the system theme.
- **Firefox Browser**:
  - Configured with a clean vertical-tabs stylesheet (`userChrome.css`) that keeps tabs intact.
  - Transparent navigation bar and vertical sidebar inherit `--lwt-accent-color` live.
  - Integrated with **Pywalfox**: `set-accent` triggers `pywalfox update`, changing Firefox's top bar, sidebar, and accents **live while open with zero restarts**.
- **GTK 2 / 3 / 4 & Desktop Portal**:
  - Synchronized across Breeze and Breeze-Dark.
  - Press <kbd>Super</kbd>+<kbd>Space</kbd> and launch **Toggle Theme** (or run `toggle-theme`) to switch between Dark and Light mode on demand.

---

## 3. Wallpaper Management & Power Delegation

- Wallpapers in `~/Pictures/Wallpapers/` are grouped into folders by color (`Orange/`, `Blue/`, `Purple/`).
- Press <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> to cycle wallpapers manually. `set-wallpaper-accent` automatically detects the parent folder and applies the matching palette.
- **On AC Power**: Automatically rotates wallpapers every **60 minutes**, playing 60fps video wallpapers (`.mp4`) with hardware acceleration via `mpvpaper-bin`.
- **On Battery**: Rotation is disabled to eliminate storage and CPU wakeups; dynamically delegates video wallpapers to `swaybg` using cached static frames.
