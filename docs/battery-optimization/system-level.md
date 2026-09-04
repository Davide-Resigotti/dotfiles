# System-Level & Hardware Power Tuning

This document covers hardware-level power saving policies, kernel ASPM profiles, background service throttling, and desktop process optimization configured for Apple Silicon (M2 Pro).

---

## 1. Hardware Power Saver & Waybar Controller

### Problem Addressed
- The Genesys Logic SD Card reader (`0000:02:00.0`) was permanently locked in active `D0` state (`power/control = on`), drawing continuous power even with no SD card inserted.
- PCIe Active State Power Management (ASPM) was defaulting to standard policy instead of aggressive link-state power down.
- Kernel dirty writeback buffers were flushed frequently, preventing the CPU and NVMe storage from staying in low-power idle states.

### Root Configuration & Rules
1. **SD Card Autosuspend**: `/etc/udev/rules.d/99-pci-pm.rules`
   Enables runtime autosuspend (`auto`), allowing the card reader to enter low-power `D3hot`/`D3cold` states when idle.
2. **PCIe ASPM Supersave**: `/etc/tmpfiles.d/aspm.conf`
   Configures `/sys/module/pcie_aspm/parameters/policy` to `powersupersave` on boot.
3. **Passwordless Privilege Grant**: `/etc/sudoers.d/99-hardware-power-toggle`
   Grants unprivileged execution rights to `/usr/local/bin/hardware-power-toggle`.

### System Controller (`/usr/local/bin/hardware-power-toggle`)
- **`on` (Hardware Eco Mode)**:
  - PCIe ASPM: `powersupersave`
  - SD Card: `auto`
  - TuneD Profile: `power-saver` (`vm.laptop_mode=5`, `dirty_writeback_centisecs=1500`)
- **`off` (Standard Mode)**:
  - PCIe ASPM: `default`
  - SD Card: `on`
  - TuneD Profile: `balanced` (`vm.laptop_mode=0`, `dirty_writeback_centisecs=500`)

### Waybar Interactive Toggle (`custom/hardware`)
- **On Battery**: Displays interactive module `[ 󰍛 hw off ]`. Clicking it switches to `[ 󰍛 hw on ]` for heavy compilation or gaming tasks.
- **On AC Power**: Automatically hidden from the bar.

---

## 2. Dynamic KDE Connect Throttling

### Problem Addressed
KDE Connect runs continuous background UDP broadcasts across the local subnet for device discovery, waking up the Wi-Fi transceiver and CPU cores dozens of times per minute.

### Optimization
- **On Battery**: `kdeconnectd` is stopped by default to eliminate periodic Wi-Fi discovery traffic.
- **Waybar Module (`custom/kdeconnect`)**:
  - Displays `[ 󰄡 off ]` on battery.
  - Clicking the module toggles to `[ 󰄡 on ]` and starts `kdeconnectd` if file transfer or SMS syncing is needed.
- **On AC Power**: Starts automatically in the background; toggle is hidden from the bar.

---

## 3. Power-Aware Akonadi & MySQL Database Stack

### Problem Addressed
`/etc/xdg/autostart/org.kde.kalendarac.desktop` automatically spawned `kalendarac`, `akonadi_control`, `akonadiserver`, an embedded `mysqld` instance, and 13 Akonadi worker agents in the background under Niri.
This stack consumed:
- **> 534 MB of RAM**
- **108 active background threads**
- Continuous disk I/O and memory database heartbeats.

### Optimization
- **On Battery**: `power-wallpaper-watcher` gracefully shuts down `kalendarac` and `akonadi_control.service`, completely killing the database and freeing 534 MB of RAM and 108 threads.
- **On AC Power**: Restarts `kalendarac` for full calendar reminders and background synchronization.
- **On-Demand Socket Activation**: If a KDE PIM application (e.g. Kalendar, KMail) is launched while on battery, Akonadi is socket-activated automatically via D-Bus without errors.

---

## 4. Waybar Subshell & Fork Elimination

### Problem Addressed
Custom Waybar indicator scripts (`custom/separator5`, `custom/separator6`) were spawning separate `sh`, `pgrep`, `playerctl`, and `grep` processes every 2 seconds solely to render bracket decorations around music titles. This caused over **14,400 subshell process forks per hour**.

### Optimization
- Consolidated brackets directly into the native Waybar `mpris` module:
  ```jsonc
  "mpris": {
    "format": "[  {dynamic} ]",
    "format-paused": "<span color='grey'>[ {status_icon} {dynamic} ]</span>"
  }
  ```
- Increased polling intervals for background sensors:
  - `memory` module: 2s $\rightarrow$ **10s**
  - `battery` module: 5s $\rightarrow$ **15s**
- **Result**: Reduced Waybar child process forks from **~14,400/hr to 0**.

---

## 5. Session Autostart Overrides & System Daemons

### Autostart Overrides (`~/.config/autostart/`)
Overrides disable unneeded desktop daemons when running Niri:
- `geoclue-demo-agent.desktop` (`NotShowIn=niri;`)
- `org.kde.kunifiedpush-distributor.desktop` (`NotShowIn=niri;`)
- `sealertauto.desktop` (`NotShowIn=niri;`)

### System Services
- `ModemManager.service`: Disabled (no WWAN cellular card on MacBook).
- `cups.service`: Disabled continuous background daemon; enabled on-demand `cups.socket`.

---

## 6. Verification & Inspection Commands

| Component | Command | Expected State on Battery |
| :--- | :--- | :--- |
| **Active TuneD Profile** | `tuned-adm active` | `Current active profile: power-saver` |
| **PCIe ASPM Policy** | `cat /sys/module/pcie_aspm/parameters/policy` | `[powersupersave]` |
| **SD Card Power State** | `cat /sys/bus/pci/devices/0000:02:00.0/power/control` | `auto` |
| **Akonadi / MySQL Processes** | `ps aux \| grep -iE "akonadi\|mysqld" \| grep -v grep` | Empty (no running processes) |
| **KDE Connect Status** | `systemctl --user status app-org.kde.kdeconnect.daemon@autostart.service` | Inactive / dead |
| **Toggle Hardware Mode** | `~/.config/waybar/scripts/hardware-power-toggle.sh --toggle` | Toggles between eco and standard |
