---
name: system-organizer
description: >-
  Use this skill whenever creating, modifying, organizing, or debugging system configurations,
  shell scripts, desktop entries, or dotfiles on this Fedora Asahi system. Enforces XDG Base Directory
  specification, GNU Stow package organization, secret protection, and GitHub backup reproducibility.
---

# System Organizer & Dotfiles Workflow Skill

This skill guides the agent in maintaining a perfectly organized, XDG-compliant, and 100% restorable operating system environment on **Fedora Linux Asahi Remix 44** (Apple Silicon aarch64 / Niri Wayland).

---

## 1. Core Operating Principles

Whenever touching any file on this machine:

1. **Strict XDG Base Directory Compliance**:
   - Configuration files belong in `$XDG_CONFIG_HOME` (`~/.config`).
   - Executable user scripts belong in `$HOME/.local/bin` (`XDG_BIN_HOME`).
   - Desktop application entries belong in `$XDG_DATA_HOME/applications` (`~/.local/share/applications`).
   - State, history, and logs belong in `$XDG_STATE_HOME` (`~/.local/state`).
   - Non-essential caches belong in `$XDG_CACHE_HOME` (`~/.cache`).
   - **Never** create loose dotfiles or scripts directly in `$HOME`. Read [XDG Specification Reference](references/xdg-specification.md) for tool-specific overrides (Cargo, Rustup, Go, NPM, Python, GTK2).

2. **Author in `~/dotfiles/<package>/` First**:
   - **Never** create plain files in target locations (`~/.config/...`, `~/.local/bin/...`).
   - Always author files inside `~/dotfiles/<package>/` mirroring `$HOME`, then run `stow -v --restow <package>`.
   - Read [GNU Stow Architecture Reference](references/stow-architecture.md) for details on tree folding, unfolding, and collision prevention.

3. **Secrets Protection**:
   - **Never** commit API tokens, private URLs, or keys to git.
   - Use the template pattern (`.template`) and `chmod 600` for uncommitted secrets. Read [Secrets & Restore Reference](references/secrets-and-restore.md).

4. **Restorability & Documentation Contract**:
   - Whenever introducing a new package, system dependency, or service, immediately update `install.sh` and `README.md`.
   - Read [Fedora Asahi Architecture Reference](references/fedora-asahi-architecture.md) for hardware and compositor specifics.

---

## 2. Standard Workflows

### Workflow A: Modifying an Existing Configuration or Script

1. **Verify Symlink Source**:
   Before modifying any file (e.g. `~/.config/niri/config.kdl` or `~/.local/bin/set-accent`), verify that it is a symlink:
   ```bash
   readlink -f <path_to_file>
   ```
   Confirm that the resolved path points inside `~/dotfiles/`.
2. **Edit the Source File**:
   Apply edits directly to the file inside `~/dotfiles/<package>/...`.
3. **Verify and Reload**:
   Reload the appropriate service or compositor (e.g. `niri msg action reload-config`, or `systemctl --user restart <service>`).

---

### Workflow B: Creating a New Configuration, Script, or Package

1. **Identify or Create the Stow Package**:
   - If the file belongs to an existing tool (e.g., Waybar, Niri, Theme), place it under `~/dotfiles/<existing_package>/`.
   - If it is a new tool or standalone subsystem, create a new package directory: `mkdir -p ~/dotfiles/<new_package>/`.
2. **Mirror `$HOME` Structure**:
   - Config file: `~/dotfiles/<new_package>/.config/<tool>/<config_file>`
   - Executable script: `~/dotfiles/<new_package>/.local/bin/<script_name>` (ensure `chmod +x`)
   - Desktop entry: `~/dotfiles/<new_package>/.local/share/applications/<name>.desktop`
   - User service: `~/dotfiles/<new_package>/.config/systemd/user/<name>.service`
3. **Handle Ignore Rules**:
   If the package contains build files (`*.c`), intermediate binaries, or internal docs, create `~/dotfiles/<new_package>/.stow-local-ignore` to prevent Stow from linking them directly into `$HOME`.
4. **Dry-Run & Stow**:
   ```bash
   cd ~/dotfiles
   stow -n -v --restow <package_name>
   stow -v --restow <package_name>
   ```
5. **Update Restore Scripts & Documentation**:
   - Add the package to `install.sh` under the `stow` invocation.
   - Document the package in `~/dotfiles/README.md` and relevant guides in `~/dotfiles/docs/`.

---

### Workflow C: Adopting Unmanaged or Existing Files

If a configuration or script was created outside Stow:
1. Run the adoption helper script:
   ```bash
   bash ~/dotfiles/agy/skills/system-organizer/scripts/adopt-package.sh <package_name> <target_path>
   ```
2. Inspect `git status` in `~/dotfiles` to ensure the file was correctly placed.

---

### Workflow D: Running System Diagnostic Audit

To check for XDG violations, broken symlinks, or Stow collisions:
```bash
bash ~/dotfiles/agy/skills/system-organizer/scripts/audit-system.sh
```
If errors are reported:
- **Collision with a regular file**: Check diff with `~/dotfiles/<pkg>/<path>`. If identical, remove the unlinked target and run `stow --restow <pkg>`.
- **Broken symlink**: Remove the orphan symlink or restore the missing target.

---

### Workflow E: Pre-Commit Hygiene & GitHub Sync

Before committing changes to the `dotfiles` repository:
1. Run the sync validation helper:
   ```bash
   bash ~/dotfiles/agy/skills/system-organizer/scripts/sync-git.sh
   ```
2. Verify that no tokens, secrets, or temporary files are staged.
3. Commit with an atomic, conventional commit message:
   ```bash
   cd ~/dotfiles
   git add <files>
   git commit -m "feat(<package>): concise description"
   git push origin main
   ```
