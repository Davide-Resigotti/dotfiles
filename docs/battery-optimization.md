# Battery & Power Optimization Setup Guide

This document provides a complete reference for the power and battery optimization architecture configured on this system.

---

## 1. System Specifications

- **Device**: Apple Silicon MacBook Pro (M2 Pro — Blizzard efficiency cores + Avalanche performance cores)
- **OS**: Fedora Linux Asahi Remix 44 (aarch64, 16k page size)
- **Desktop Environment**: Niri (Scrollable Tiling Wayland Compositor) + Waybar
- **Power Subsystem**: Apple macsmc (`macsmc-battery`, `macsmc-ac`), TuneD (`tuned-ppd`)

---

## 2. Architecture Overview

The system dynamically adapts its resource usage based on whether it is connected to **AC power** or discharging on **Battery**.

```
                           ┌───────────────────────────────┐
                           │   udevadm Power Monitor       │
                           │   (power-wallpaper-watcher)   │
                           └───────────────┬───────────────┘
                                           │
                    ┌──────────────────────┴──────────────────────┐
                    ▼                                             ▼
          [ AC Power Connected ]                        [ Battery Discharging ]
  ────────────────────────────────────────       ────────────────────────────────────────
  • Wallpaper: mpvpaper-bin (60fps video)         • Wallpaper: swaybg (0% CPU, 14MB RAM)
  • Hardware Mode: Standard (balanced)           • Hardware Mode: Eco ([ 󰍛 hw off ])
  • KDE Connect: Running (toggle hidden)         • KDE Connect: Stopped ([ 󰄡 off ])
  • Akonadi & MySQL: Running                     • Akonadi & MySQL: Stopped (frees 534MB)
  • Waybar Toggles: Hidden                       • Waybar Toggles: Interactive buttons
```

---

## 3. Detailed Component Configuration

### A. Smart Wallpaper Engine (`mpvpaper` ↔ `swaybg`)

- **Problem Solved**: `mpvpaper` was previously running 24/7 even for static images or paused video on battery, consuming 17 threads, ~175 MB to 1.3 GB RAM, active OpenGL subsurfaces, and >33,000 context switches.
- **Smart Dispatcher**: `~/.local/bin/mpvpaper`
  - Real ELF binary renamed to `~/.local/bin/mpvpaper-bin`.
  - Dispatcher detects power state and media extension:
    - **On Battery OR static photos**: spawns `/usr/bin/swaybg` (1 thread, 14 MB RAM, 0% CPU, 0 GPU wakeups) and terminates `mpvpaper-bin`.
    - **On AC power with videos**: passes arguments to `mpvpaper-bin` for 60fps hardware-decoded video playback.
- **Power Transition Daemon**: `~/.config/waypaper/scripts/power-wallpaper-watcher`
  - Managed by systemd user service `waypaper-power-watcher.service`.
  - Listens to kernel power events via `udevadm monitor -u -s power_supply`.
  - On AC disconnect: extracts a static 4K frame to `~/.cache/wallpaper-frames/<name>.jpg` (if video), seamlessly maps it with `swaybg`, and terminates `mpvpaper-bin`.
  - On AC connect: starts `mpvpaper-bin` with the video and terminates `swaybg`.
- **Manual Rotation**: `~/.config/waypaper/scripts/waypaper-cycle-once`
  - Bound to `Mod+Shift+W` in Niri. Calls `waypaper --random` through the smart dispatcher without hardcoded socket dependencies.
- **Accent Theme Extraction**: `~/.config/waypaper/scripts/set-wallpaper-accent`
  - Instantly updates Pywal/Niri/Waybar accents without waiting on socket timeouts.

---

### B. Hardware Power Saver & Waybar Toggle

- **Problem Solved**:
  - The Genesys SD Card reader (`0000:02:00.0`) was pinned in active D0 state (`power/control = on`).
  - PCIe ASPM was running in `[default]` mode instead of deep link power states.
  - TuneD was set to `manual` and did not auto-tune dirty page writebacks on battery.
- **Persistent Root Configuration**:
  - `/etc/udev/rules.d/99-pci-pm.rules`: Enables runtime autosuspend (D3hot/D3cold) for the SD card reader when no card is inserted.
  - `/etc/tmpfiles.d/aspm.conf`: Sets `/sys/module/pcie_aspm/parameters/policy` to `powersupersave`.
  - `/etc/sudoers.d/99-hardware-power-toggle`: Grants passwordless execution for `/usr/local/bin/hardware-power-toggle`.
- **System Controller**: `/usr/local/bin/hardware-power-toggle`
  - `on`: sets ASPM `powersupersave`, SD card `auto`, TuneD `power-saver` (`vm.laptop_mode=5`, `dirty_writeback_centisecs=1500`).
  - `off`: sets ASPM `default`, SD card `on`, TuneD `balanced` (`vm.laptop_mode=0`, `dirty_writeback_centisecs=500`).
  - `toggle` / `status`.
- **Waybar Module**: `custom/hardware` in `~/.config/waybar/config.jsonc`
  - Exec script: `~/.config/waybar/scripts/hardware-power-toggle.sh`
  - **On Battery**: Shows `[ 󰍛 hw off ]` (hardware performance limited for battery savings). Clicking it toggles to `[ 󰍛 hw on ]` (full performance).
  - **On AC Power**: Automatically hidden from the bar.

---

### C. Dynamic KDE Connect

- **Problem Solved**: KDE Connect continuously broadcasts UDP discovery packets on Wi-Fi and runs background listener threads.
- **Waybar Module**: `custom/kdeconnect` in `~/.config/waybar/config.jsonc`
  - Exec script: `~/.config/waybar/scripts/kdeconnect-toggle.sh`
  - **On Battery**: Disabled by default to save Wi-Fi wakeups. Displays `[ 󰄡 off ]` in Waybar. Clicking it turns KDE Connect on (`[ 󰄡 on ]`) if syncing is needed.
  - **On AC Power**: Enabled automatically; toggle is hidden from Waybar.

---

### D. Power-Aware Akonadi & MySQL

- **Problem Solved**: `/etc/xdg/autostart/org.kde.kalendarac.desktop` was pulling in `kalendarac`, `akonadi_control`, `akonadiserver`, `mysqld` (MySQL), and 13 Akonadi agent processes under Niri, using over **534 MB RAM** and **108 background threads**.
- **Management**:
  - Automatically handled by `power-wallpaper-watcher`.
  - **On Battery**: Gracefully stops `kalendarac` and `akonadi_control.service`, stopping database heartbeats and background memory overhead.
  - **On AC Power**: Restarts `kalendarac` for full calendar reminders and PIM synchronization.
  - **On Demand**: If any KDE PIM application (KMail, Kalendar) is launched on battery, Akonadi is socket-activated automatically via D-Bus.

---

### E. Waybar Subshell & Fork Reduction

- **Problem Solved**: `custom/separator5` and `custom/separator6` were running subshell scripts every 2 seconds (`sh`, `pgrep`, `playerctl`, `grep`) just to show brackets around the music title, creating ~14,400 process forks per hour.
- **Changes in `~/.config/waybar/config.jsonc`**:
  - Removed `custom/separator5` and `custom/separator6`.
  - Added brackets directly into the native `mpris` module:
    ```jsonc
    "mpris": {
      "format": "[  {dynamic} ]",
      "format-paused": "<span color='grey'>[ {status_icon} {dynamic} ]</span>"
    }
    ```
  - Increased `memory` polling interval from 2s to 10s.
  - Increased `battery` polling interval from 5s to 15s.
  - Result: **0 child process forks** from Waybar.

---

### F. Session Autostart & System Daemons

- **Autostart Overrides** in `~/.config/autostart/` (managed via `dotfiles/autostart`):
  - `geoclue-demo-agent.desktop` (`NotShowIn=niri;`)
  - `org.kde.kunifiedpush-distributor.desktop` (`NotShowIn=niri;`)
  - `sealertauto.desktop` (`NotShowIn=niri;`)
- **System Daemons**:
  - `ModemManager.service`: Disabled (no WWAN cellular card on MacBook).
  - `cups.service`: Disabled 24/7 daemon; enabled on-demand `cups.socket`.

---

## 4. Waybar Layout Reference

### On Battery:
```
[ 󰍛 hw off ] [ 󰄡 off ] [ bat 41% 󰿟 vol 40% 󰿟 mem 22% 󰿟 cpu 2% ]
```
- Click `[ 󰍛 hw off ]` → Toggles to `[ 󰍛 hw on ]` (restores full hardware power/perf).
- Click `[ 󰄡 off ]` → Toggles to `[ 󰄡 on ]` (starts KDE Connect).

### On AC Power:
```
[ bat 80%  󰿟 vol 40% 󰿟 mem 22% 󰿟 cpu 5% ]
```
- Both toggles hide automatically to keep the bar minimal and clean.

---

## 5. Useful Commands & Verification

| Action | Command |
| :--- | :--- |
| **Check battery discharge rate** | `cat /sys/class/power_supply/macsmc-battery/power_now` |
| **Check battery details** | `upower -i /org/freedesktop/UPower/devices/battery_macsmc_battery` |
| **Check active TuneD profile** | `tuned-adm active` |
| **Check PCIe ASPM policy** | `cat /sys/module/pcie_aspm/parameters/policy` |
| **Check SD card power state** | `cat /sys/bus/pci/devices/0000:02:00.0/power/control` |
| **Check active wallpaper process** | `ps aux \| grep -E "mpvpaper\|swaybg" \| grep -v grep` |
| **Check Akonadi / MySQL state** | `ps aux \| grep -iE "akonadi\|mysqld" \| grep -v grep` |
| **Cycle wallpaper manually** | `~/.config/waypaper/scripts/waypaper-cycle-once` (or `Mod+Shift+W`) |
| **Toggle hardware eco mode** | `~/.config/waybar/scripts/hardware-power-toggle.sh --toggle` |
| **Toggle KDE Connect** | `~/.config/waybar/scripts/kdeconnect-toggle.sh --toggle` |
| **Restart power watcher service** | `systemctl --user restart waypaper-power-watcher.service` |
| **Restart Waybar** | `systemctl --user restart waybar.service` |

---

## 6. Files & Dotfiles Mapping

All user configurations are tracked under GNU Stow in `~/dotfiles/`:

- `dotfiles/waypaper/.config/waypaper/scripts/power-wallpaper-watcher`
- `dotfiles/waypaper/.config/waypaper/scripts/set-wallpaper-accent`
- `dotfiles/waypaper/.config/waypaper/scripts/waypaper-cycle-once`
- `dotfiles/waybar/.config/waybar/config.jsonc`
- `dotfiles/waybar/.config/waybar/style.css`
- `dotfiles/waybar/.config/waybar/scripts/hardware-power-toggle.sh`
- `dotfiles/waybar/.config/waybar/scripts/kdeconnect-toggle.sh`
- `dotfiles/autostart/.config/autostart/*.desktop`
- `dotfiles/shell/apply-hardware-power-tuning.sh`
- `~/.local/bin/mpvpaper` (smart wrapper)
- `~/.local/bin/mpvpaper-bin` (compiled executable)
- `/usr/local/bin/hardware-power-toggle` (root controller)
- `/etc/sudoers.d/99-hardware-power-toggle`
- `/etc/udev/rules.d/99-pci-pm.rules`
- `/etc/tmpfiles.d/aspm.conf`
