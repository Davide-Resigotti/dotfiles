# Secrets Isolation & GitHub Restorability Reference

This reference details the rules for preventing credential leakage to GitHub and maintaining 100% reproducible disaster-recovery on a fresh machine.

---

## 1. Secrets Management Rules

Never commit the following items to the git repository:
- API tokens, bearer tokens, or session tokens.
- Private URLs containing embedded access tokens or private routing hashes.
- SSH private keys (`id_rsa`, `id_ed25519`).
- GPG secret keys.
- Wi-Fi credentials or passwords.

### The Template Pattern
For files that require secret tokens or private endpoints:
1. Commit a `.template` or sanitized example in the repository (e.g. `agy/mcp_config.json` with `INSERT_TOKEN`).
2. Do **not** symlink the live config if the live tool writes back credentials into that file.
3. Use `install.sh` to copy the template to the live path only if the live file does not exist.
4. Keep the live file with restricted permissions (`chmod 600`) in `$XDG_CONFIG_HOME`.
5. Add patterns to `.gitignore` to prevent accidental staging.

### Example: Home Assistant REST Token
- Live token: `~/.config/home-assistant/token` (mode `0600`).
- Ignored in git.
- Script `dotfiles/home-assistant/.config/home-assistant/scripts/ha-toggle` reads the token at runtime from `~/.config/home-assistant/token`.

---

## 2. Restorability Contract (`install.sh` & `README.md`)

Whenever a new package or dependency is added:
1. **System Packages**: Add required `dnf` or `brew` packages to `README.md` and `install.sh`.
2. **Package List in `install.sh`**: Add the package name to the `stow -v --restow ...` invocation in `install.sh`.
3. **Services**: If the package includes a systemd unit, ensure `install.sh` runs `systemctl --user enable`.
4. **README Table**: Document the new package, what files it creates, and what it does in `README.md`.
5. **Fresh Machine Test**: Verify that running `./install.sh` from the repository root completes with exit code 0 and restores all symlinks.
