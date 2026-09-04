# System Organization & Antigravity Automation Architecture

This document describes the architectural standards, directory conventions, GNU Stow workflows, and Antigravity AI skill integration implemented on this **Fedora Linux Asahi Remix 44** (Apple Silicon aarch64 / Niri Wayland) system.

---

## 1. Architectural Philosophy

A truly reproducible dotfiles system must satisfy three guarantees:
1. **Clean `$HOME` (XDG Compliance)**: No application should pollute `$HOME` with unmanaged dotfiles, cache folders, or history files.
2. **Symlink Farm Modular Isolation (GNU Stow)**: Every configuration file and user script must belong to an isolated, modular package in `~/dotfiles/` that mirrors `$HOME`.
3. **Automated AI Pair Programming Discipline (Antigravity `system-organizer`)**: The AI agent operates with an always-on rule and a specialized skill that enforces strict XDG placement, prevents stow collisions, protects private secrets, and updates restore runbooks.

---

## 2. Directory Mappings & XDG Standards

All system components and user tools adhere to the XDG Base Directory specification:

| Role | Path | Environment Variable | Git Tracking Policy |
| :--- | :--- | :--- | :--- |
| **User Configuration** | `~/.config` | `$XDG_CONFIG_HOME` | Tracked via `~/dotfiles/<pkg>/.config/<pkg>` |
| **User Binaries & Scripts** | `~/.local/bin` | `$XDG_BIN_HOME` | Tracked via `~/dotfiles/<pkg>/.local/bin/...` |
| **Desktop Entries & Assets** | `~/.local/share` | `$XDG_DATA_HOME` | Selectively tracked via `~/dotfiles/<pkg>/.local/share/...` |
| **State, Logs & History** | `~/.local/state` | `$XDG_STATE_HOME` | Never tracked (ignored by `.gitignore`) |
| **Disposable Caches** | `~/.cache` | `$XDG_CACHE_HOME` | Never tracked (ignored by `.gitignore`) |

### Tool-Specific XDG Overrides (in `.bashrc`)
Traditional tools that violate XDG by default are forced into compliance via environment variables:
- **NPM**: `NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"`, cache in `$XDG_CACHE_HOME/npm`, global prefix in `$XDG_DATA_HOME/npm`
- **Node.js**: `NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"`
- **Rust / Cargo**: `CARGO_HOME="$XDG_DATA_HOME/cargo"`, `RUSTUP_HOME="$XDG_DATA_HOME/rustup"`
- **Go**: `GOPATH="$XDG_DATA_HOME/go"`
- **Bun**: `BUN_INSTALL="$XDG_DATA_HOME/bun"`
- **Python 3.13+**: `PYTHON_HISTORY="$XDG_STATE_HOME/python/history"`
- **Mypy**: `MYPY_CACHE_DIR="$XDG_CACHE_HOME/mypy"`
- **Subversion**: `alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'`
- **Bash History**: `HISTFILE="$XDG_STATE_HOME/bash/history"`
- **Zsh**: `ZDOTDIR="$XDG_CONFIG_HOME/zsh"`
- **GTK 2**: `GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"`
- **Less**: `LESSHISTFILE="$XDG_STATE_HOME/less/history"`
- **Homebrew**: Native support for `$XDG_CONFIG_HOME/homebrew/trust.json`
- **NSS / PKI Database**: `~/.pki/nssdb` is recognized as an unmovable POSIX standard database (aligned with `.mozilla` and `.var`)

---

## 3. GNU Stow Package Structure & Collision Prevention

Every package in `~/dotfiles/<package>/` mirrors `$HOME`.

### Stow Packages Overview

| Package | Symlink Target in `$HOME` | Purpose |
| :--- | :--- | :--- |
| `agy` | `~/.gemini/config/skills/system-organizer` | Antigravity AI skill, diagnostic scripts, architecture refs |
| `shell` | `~/.bashrc`, `~/.bash_profile`, `~/.profile`, `~/.gitconfig`, `~/AGENTS.md`, `~/.local/bin/apply-hardware-power-tuning` | Shell environment, XDG exports, power tuning script |
| `niri` | `~/.config/niri`, `~/.config/systemd/user/kbd-backlight-watcher.service`, `~/.config/systemd/user/yard-popup-watcher.service` | Niri compositor config, scripts, Apple keyboard daemon, yard camera daemon |
| `waybar` | `~/.config/waybar`, `~/.config/systemd/user/deep-sleep-inhibit.service` | Waybar layout, dynamic CSS, battery toggles |
| `theme` | `~/.config/theme`, `~/.local/bin/set-accent`, `~/.local/bin/toggle-theme`, `~/.local/bin/view-camera`, `~/.local/bin/yard-popup-camera`, `~/.local/share/applications` | Dynamic accent dispatcher, desktop launchers, camera controls |
| `waypaper` | `~/.config/waypaper`, `~/.local/bin/mpvpaper`, `~/.config/systemd/user/waypaper-power-watcher.service` | Wallpaper manager, smart AC/battery video dispatcher |
| `wofi` | `~/.config/wofi`, `~/.local/bin/wofi` | Shortcuts & details launcher, dynamic theme integration |
| `npm` | `~/.config/npm/npmrc` | XDG-compliant npm configuration (`prefix` in data, `cache` in cache) |
| `gtk-2.0` | `~/.config/gtk-2.0/gtkrc` | GTK 2 theme, cursor, and font configuration |
| `opencode` | `~/.config/systemd/user/opencode-web.service` | OpenCode web server systemd service |
| `mako`, `fuzzel`, `ghostty`, `fontconfig`, `xsettingsd`, `gtk-3.0`, `gtk-4.0`, `autostart`, `darkman`, `xdg-desktop-portal`, `home-assistant`, `yazi`, `tmux`, `nvim` | Respective paths under `~/.config` and `$HOME` | Dedicated subsystems |

### Ignore Rules (`.stow-local-ignore`)
To prevent package root source files or templates from leaking into `$HOME`:
- `wofi/.stow-local-ignore`: Ignores `wofi-focus-fix.c`
- `agy/.stow-local-ignore`: Ignores `mcp_config.json` (template containing token placeholder)

---

## 4. Antigravity AI Integration: `system-organizer` Skill

The agent pair-programs with the user using a dedicated skill located at:
[`agy/skills/system-organizer/`](../../agy/skills/system-organizer/SKILL.md)

### Global Discovery & Always-On Rule
1. **Global Discovery**:
   A symlink connects `~/.gemini/config/skills/system-organizer` to `~/dotfiles/agy/skills/system-organizer`. This enables Antigravity to discover the skill across all CLI and IDE sessions on the machine.
2. **Workspace Rule (`AGENTS.md`)**:
   Stowed from [`shell/AGENTS.md`](../../shell/AGENTS.md) to `~/AGENTS.md`. Antigravity reads this file unconditionally whenever running in `$HOME`, ensuring that the agent never writes unmanaged regular files directly into target directories.

### Helper Scripts

| Script | Location | Purpose |
| :--- | :--- | :--- |
| **`audit-system.sh`** | `agy/skills/system-organizer/scripts/audit-system.sh` | Audits `$HOME` for XDG anomalies, checks for broken symlinks, tests Stow dry-runs, and checks git status. |
| **`adopt-package.sh`** | `agy/skills/system-organizer/scripts/adopt-package.sh` | Safely adopts an unmanaged file or directory from `$HOME` into `dotfiles/<pkg>/` and stows it. |
| **`restow-all.sh`** | `agy/skills/system-organizer/scripts/restow-all.sh` | Performs a dry-run check and restows all active packages cleanly. |
| **`sync-git.sh`** | `agy/skills/system-organizer/scripts/sync-git.sh` | Validates git working tree and scans for accidentally staged tokens or private keys before pushing. |

---

## 5. Maintenance & Disaster Recovery Runbook

### Modifying an Existing Tool
1. Check that the target is a symlink: `readlink -f <file>` (points into `~/dotfiles/`).
2. Edit the file inside `~/dotfiles/<package>/...`.
3. Reload the associated application or service.

### Adding a New Tool
1. Create package structure in `~/dotfiles/<package>/...` matching `$HOME`.
2. Test dry-run: `cd ~/dotfiles && stow -n -v --restow <package>`.
3. Stow package: `stow -v --restow <package>`.
4. Update `install.sh` (add package to stow list).
5. Update `README.md` and this guide.
6. Run `sync-git.sh` and commit to GitHub.

### Restoring on a Fresh Machine
```bash
git clone https://github.com/Davide-Resigotti/dotfiles.git
cd dotfiles
./install.sh
```
`install.sh` automatically backs up conflicting non-symlinks, stows all packages, creates the Antigravity skill symlink, sets up Python virtualenvs, and verifies system health.
