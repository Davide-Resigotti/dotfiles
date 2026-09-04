# Battery & Power Optimization Setup Guide

This document serves as the central index and architecture overview for the power and battery optimization systems configured on this laptop.

Detailed documentation for each specialized component is organized in the [`docs/battery-optimization/`](battery-optimization/) directory:
- [**Wallpaper Power Optimization**](battery-optimization/wallpaper.md)
- [**Ambient Light Sensor & Backlight Automation**](battery-optimization/display-and-keyboard.md)
- [**System-Level & Hardware Power Tuning**](battery-optimization/system-level.md)

---

## 1. System Specifications

- **Device**: Apple Silicon MacBook Pro (M2 Pro — Blizzard efficiency cores + Avalanche performance cores)
- **OS**: Fedora Linux Asahi Remix 44 (aarch64, 16k page size)
- **Desktop Environment**: Niri (Scrollable Tiling Wayland Compositor) + Waybar
- **Power Subsystem**: Apple macsmc (`macsmc-battery`, `macsmc-ac`), TuneD (`tuned-ppd`), AOP Sensors (`aop-sensors-als`, `aop-sensors-las`)

---

## 2. High-Level Architecture Overview

The system continuously balances peak performance on **AC power** with aggressive power savings on **Battery**:

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
  • Ambient Backlight: Always active             • Ambient Backlight: Always active
```

---

## 3. Optimization Domains

### A. Dynamic Wallpaper Power Management
- **Full Guide**: [`docs/battery-optimization/wallpaper.md`](battery-optimization/wallpaper.md)
- **Summary**: `mpvpaper` is dynamically replaced by `/usr/bin/swaybg` on battery power or when viewing static images. Eliminates 17 background threads, >33,000 context switches/sec, and over 1.3 GB of memory allocations, reducing wallpaper CPU usage to **0.0%**.
- **Daemon**: `waypaper-power-watcher.service` smoothly extracts 4K static frames from video wallpapers and hot-swaps between video on AC and static image on battery without screen flash.

### B. Ambient Light Sensor (ALS), Dual-Profile ML & Backlight Automation
- **Full Guide**: [`docs/battery-optimization/display-and-keyboard.md`](battery-optimization/display-and-keyboard.md)
- **Summary**: Uses the Apple Always-On Processor (`aop-sensors-als`) to continuously monitor room lux (sampling takes 18 µs, < 0.02% CPU).
- **Dual-Profile Machine Learning**: Pure Python Kernel Anchor Spline learns separate curves for AC Power (55% baseline at 485 lux, max visual experience) and Battery (30% baseline at 485 lux, power saver).
- **Training Window & Waybar Indicator**: Actively learns for 7 days with a dedicated `[ 󰃠 train: 7d ]` indicator in Waybar, then automatically locks in your personalized curves.
- **Smooth Gradual Ramping**: Transitions smoothly by **0.5% increments** every 50ms across light changes and AC plug/unplug events.
- **Continuous Keyboard Backlight**: Uses cubic Hermite smoothstep fade with distinct thresholds for Battery (> 15 lux completely OFF) and AC Power (> 35 lux completely OFF). Dissolves gradually over ~1.5–2.0 seconds (1 unit / 30ms) instead of sudden single commands. Capped at **50% max** on battery and **75% max** on AC.
- **Lid Clamshell & Niri DRM DPMS**: In keep-awake mode (`sleep off`), combines multi-source lid sensing with Niri DRM compositor controls (`niri msg action power-off-monitors` / `output eDP-1 off`), completely cutting panel power to 0.0 W and overcoming Apple DCP hardware minimum iDAC 1% glow.

### C. System-Level & Hardware Power Tuning
- **Full Guide**: [`docs/battery-optimization/system-level.md`](battery-optimization/system-level.md)
- **Summary**:
  - **Hardware Eco Mode**: Automatically enables PCIe ASPM `powersupersave`, Genesys SD Card reader autosuspend (`D3hot`/`D3cold`), and TuneD `power-saver` (`vm.laptop_mode=5`, 15-second writebacks). Interactive toggle in Waybar: `[ 󰍛 hw off ]`.
  - **Dynamic KDE Connect**: Prevents background Wi-Fi UDP discovery broadcasts on battery. Toggleable on demand via Waybar: `[ 󰄡 off ]`.
  - **Lid Sleep Mode Toggle**: Interactive toggle in Waybar's left cluster: `[ 󰒲 sleep on ]`. When enabled, closing the lid suspends the system (`s2idle`) to maximize battery life. When disabled (`[ 󰒲 sleep off ]`), `systemd-inhibit` prevents deep sleep so background compilations, downloads, or servers continue running uninterrupted while Niri turns off the display.
  - **Akonadi & MySQL**: Shuts down background PIM database servers on battery, freeing >534 MB of RAM and 108 background threads.
  - **Waybar Zero-Forking**: Replaced shell subshells with native formatting, eliminating ~14,400 process forks/hr.
  - **Session Autostarts**: Suppresses background bloat (`geoclue`, `kunifiedpush`, `sealertauto`, `ModemManager`).

---

## 4. Waybar Interactive Layout Reference

### Left Cluster (Workspaces, Sleep & ML Training):
```
[ 1 2 3 ] [ tray ] [ 󰒲 sleep on ] [ 󰃠 train: 7d ] [  mpris ]
```
- Click `[ 󰒲 sleep on ]` $\rightarrow$ Toggles to `[ 󰒲 sleep off ]` (inhibits deep sleep on lid close; screen turns off but tasks keep running).
- Click `[ 󰒲 sleep off ]` $\rightarrow$ Toggles to `[ 󰒲 sleep on ]` (restores battery-saving deep sleep on lid close).
- `[ 󰃠 train: 7d ]` $\rightarrow$ Shows active training countdown. Click to toggle training mode or reset timer. Hides automatically when training is complete.

### Right Cluster (Discharging on Battery):
```
[ 󰍛 hw off ] [ 󰄡 off ] [ bat 41% 󰿟 vol 40% 󰿟 mem 22% 󰿟 cpu 2% ]
```
- Click `[ 󰍛 hw off ]` $\rightarrow$ Toggles to `[ 󰍛 hw on ]` (restores full hardware performance).
- Click `[ 󰄡 off ]` $\rightarrow$ Toggles to `[ 󰄡 on ]` (starts KDE Connect sync).

### Right Cluster (Connected to AC Power):
```
[ bat 80%  󰿟 vol 40% 󰿟 mem 22% 󰿟 cpu 5% ]
```
- Hardware and KDE Connect toggles hide automatically to keep the bar minimal and clean.

---

## 5. Master Commands Reference

| Action | Command |
| :--- | :--- |
| **Check battery discharge rate** | `cat /sys/class/power_supply/macsmc-battery/power_now` |
| **Check ambient light & backlight** | `~/.config/niri/scripts/backlight.sh status` |
| **Toggle screen auto-brightness** | `~/.config/niri/scripts/backlight.sh toggle-auto-screen` (or `Mod+Shift+B`) |
| **Check active TuneD profile** | `tuned-adm active` |
| **Check PCIe ASPM policy** | `cat /sys/module/pcie_aspm/parameters/policy` |
| **Check SD card power state** | `cat /sys/bus/pci/devices/0000:02:00.0/power/control` |
| **Check active wallpaper process** | `ps aux \| grep -E "mpvpaper\|swaybg" \| grep -v grep` |
| **Check Akonadi / MySQL state** | `ps aux \| grep -iE "akonadi\|mysqld" \| grep -v grep` |
| **Cycle wallpaper manually** | `~/.config/waypaper/scripts/waypaper-cycle-once` (or `Mod+Shift+W`) |
| **Toggle hardware eco mode** | `~/.config/waybar/scripts/hardware-power-toggle.sh --toggle` |
| **Toggle KDE Connect** | `~/.config/waybar/scripts/kdeconnect-toggle.sh --toggle` |
| **Toggle Lid Deep Sleep mode** | `~/.config/waybar/scripts/deep-sleep-toggle.sh --toggle` |
| **Restart power watcher service** | `systemctl --user restart waypaper-power-watcher.service` |
| **Restart backlight watcher service** | `systemctl --user restart kbd-backlight-watcher.service` |
| **Restart Waybar** | `systemctl --user restart waybar.service` |

---

## 6. Files & Dotfiles Mapping

All power optimization configurations are tracked under GNU Stow in `~/dotfiles/`:

- **Documentation**:
  - `docs/battery-optimization.md` (this index file)
  - `docs/battery-optimization/wallpaper.md`
  - `docs/battery-optimization/display-and-keyboard.md`
  - `docs/battery-optimization/system-level.md`
- **Backlight & Ambient Sensing**:
  - `niri/.config/niri/ambient.conf`
  - `niri/.config/niri/scripts/adaptive_model.py`
  - `niri/.config/niri/scripts/kbd-backlight-watcher`
  - `niri/.config/niri/scripts/backlight.sh`
  - `niri/.config/systemd/user/kbd-backlight-watcher.service`
  - `udev/etc/udev/rules.d/90-apple-backlight.rules`
- **Wallpaper Power Management**:
  - `waypaper/.config/waypaper/scripts/power-wallpaper-watcher`
  - `waypaper/.config/systemd/user/waypaper-power-watcher.service`
  - `waypaper/.config/waypaper/scripts/set-wallpaper-accent`
  - `waypaper/.config/waypaper/scripts/waypaper-cycle-once`
  - `~/.local/bin/mpvpaper` (smart wrapper)
  - `~/.local/bin/mpvpaper-bin` (compiled executable)
- **Hardware & Session Power Tuning**:
  - `/usr/local/bin/hardware-power-toggle` (root controller)
  - `waybar/.config/waybar/scripts/hardware-power-toggle.sh`
  - `waybar/.config/waybar/scripts/kdeconnect-toggle.sh`
  - `waybar/.config/waybar/scripts/deep-sleep-toggle.sh`
  - `waybar/.config/systemd/user/deep-sleep-inhibit.service`
  - `/etc/sudoers.d/99-hardware-power-toggle`
  - `/etc/udev/rules.d/99-pci-pm.rules`
  - `/etc/tmpfiles.d/aspm.conf`
  - `autostart/.config/autostart/*.desktop`
