# Fedora Asahi Linux & Niri System Architecture Reference

This reference documents the hardware, operating system, and compositor characteristics specific to this Apple Silicon machine.

---

## 1. Machine & OS Profile

- **Hardware**: Apple Silicon (MacBook Pro / M2 Pro, ARM aarch64 architecture with 16k page size kernel).
- **Distribution**: Fedora Linux Asahi Remix 44 (KDE Plasma Desktop Edition base, Niri scrollable-tiling compositor active).
- **Kernel**: `7.0.x-asahi.fc44.aarch64+16k`
- **Shell**: Bash (`/usr/bin/bash`)
- **Package Ecosystems**:
  1. `dnf`: Core system packages and native libraries.
  2. `brew` (`/home/linuxbrew/.linuxbrew`): Supplementary CLI previewers and dev tools (`yazi`, `poppler`, `resvg`, `ffmpeg`).
  3. `pip` (Python 3): Isolated user virtual environments (`~/.config/nvim/.venv`, `~/.local/share/waypaper-venv`).

---

## 2. Desktop Environment: Niri on Wayland

- **Compositor**: Niri (scrollable-tiling Wayland compositor).
- **Configuration**: `niri/.config/niri/config.kdl`
- **Dynamic Theming Bridge**:
  - `set-accent <name>` writes to `~/.config/theme/current-accent.env` and signals running components.
  - Waybar dynamic CSS: `waybar/.config/waybar/style.css`
  - Fuzzel & Wofi launchers dynamically pick up color palettes.
- **Root Configurations (Exceptions to Stow)**:
  - Keyboard remapping: `keyd/etc/keyd/default.conf` (copied to `/etc/keyd/default.conf`, needs sudo).
  - Apple Backlight & Keyboard LED udev rules: `udev/etc/udev/rules.d/90-apple-backlight.rules` (copied to `/etc/udev/rules.d/`, needs sudo).

---

## 3. Systemd User Units

User background daemons are managed via systemd user services located in:
`~/.config/systemd/user/` (symlinked via respective stow packages `waypaper`, `niri`, `waybar`):
- `waypaper-power-watcher.service`: Watches kernel AC/Battery transitions and toggles `mpvpaper` / `swaybg`.
- `kbd-backlight-watcher.service`: Apple Silicon keyboard backlight auto-dimming.
- `deep-sleep-inhibit.service`: Manages idle power states.

When adding or modifying user systemd units:
1. Place unit in `~/dotfiles/<package>/.config/systemd/user/<unit_name>.service`.
2. Restow the package: `stow -v --restow <package>`.
3. Reload daemon: `systemctl --user daemon-reload`.
4. Enable/restart service: `systemctl --user enable --now <unit_name>.service`.
