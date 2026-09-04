# Operating Guidelines for System & Dotfiles Management

Whenever creating, modifying, organizing, or debugging system configurations, shell scripts, desktop entries, or dotfiles on this Fedora Asahi system:

1. **Strict XDG Base Directory Compliance**:
   - Store configurations in `$XDG_CONFIG_HOME` (`~/.config`).
   - Store executable scripts in `~/.local/bin` (`$XDG_BIN_HOME`).
   - Store desktop entries in `$XDG_DATA_HOME/applications` (`~/.local/share/applications`).
   - Store systemd user units in `~/.config/systemd/user/`.
   - Never create loose dotfiles or standalone scripts directly in `$HOME`.
   - Respect XDG overrides for non-compliant tools (Cargo, Rustup, Go, NPM, Python, GTK2).

2. **Author in `~/dotfiles/<package>/` First**:
   - Never create plain, unmanaged regular files directly in `~/.config` or `~/.local/bin`.
   - Always author configurations and scripts inside `~/dotfiles/<package>/...` mirroring `$HOME`, and stow them using GNU Stow:
     `cd ~/dotfiles && stow -v --restow <package>`
   - When editing an existing file, confirm it is a symlink pointing into `~/dotfiles/` before applying edits.

3. **Collision & Ignore Handling**:
   - Maintain `.stow-local-ignore` files in packages that contain build sources (`*.c`), binaries (`*.so`), or documentation so Stow does not attempt to link them into `$HOME`.

4. **Secrets & GitHub Protection**:
   - Never commit tokens, passwords, private keys, or machine-specific authentication strings to git.
   - Use the template pattern (`.template`) and `chmod 600` for uncommitted secrets.

5. **Restorability & Documentation Contract**:
   - Whenever introducing a new package or dependency, update `install.sh` (package list, service enablement) and `README.md`.
   - Document architectural changes and automation procedures in `docs/`.

6. **Activate the `system-organizer` Skill**:
   - For multi-step system tasks, package adoption, or diagnostics, activate the `system-organizer` skill. Run `~/dotfiles/agy/skills/system-organizer/scripts/audit-system.sh` to verify system health.
