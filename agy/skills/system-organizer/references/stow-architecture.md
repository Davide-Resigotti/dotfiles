# GNU Stow Architecture & Collision Management Reference

This guide details how GNU Stow works in this system, how packages mirror `$HOME`, how Stow resolves collisions, and how to use ignore files.

---

## 1. How GNU Stow Operates

GNU Stow is a symlink farm manager. When run inside `~/dotfiles`, Stow creates relative symlinks pointing from target directories (defaulting to parent `..`, which is `$HOME`) back into package directories in `~/dotfiles`.

### Directory Structure Convention
Each subdirectory in `~/dotfiles/` is an independent **package** whose internal directory layout matches `$HOME`:

```
~/dotfiles/
├── niri/
│   └── .config/
│       └── niri/
│           └── config.kdl         -> Symlinked to ~/.config/niri/config.kdl
├── theme/
│   ├── .config/
│   │   └── theme/                 -> Symlinked to ~/.config/theme/
│   ├── .local/
│   │   └── bin/
│   │       └── set-accent         -> Symlinked to ~/.local/bin/set-accent
│   └── .local/share/applications/ -> Symlinked to ~/.local/share/applications/*.desktop
```

---

## 2. Directory Folding vs. Unfolding

- **Tree Folding**: If an entire directory hierarchy belongs to a single package and the target directory does not already exist, Stow creates a symlink to the entire directory (e.g. `~/.config/niri -> ../dotfiles/niri/.config/niri`).
- **Tree Unfolding (Splitting)**: If two packages share a parent directory (e.g. `theme` and `waypaper` both place scripts in `.local/bin`), Stow creates a real directory `~/.local/bin` and individual file symlinks inside it (`~/.local/bin/set-accent`, `~/.local/bin/mpvpaper`).

---

## 3. Collision Types & Solutions

### A. Non-Symlink Target Already Exists
**Symptom**:
```text
WARNING! stowing <pkg> would cause conflicts:
  * cannot stow dotfiles/<pkg>/<path> over existing target <path> since neither a link nor a directory and --adopt not specified
```
**Cause**:
A real file or directory was manually created at the target path (e.g. via `cat > ~/.local/bin/foo` or an installer), preventing Stow from placing a symlink.

**Remediation**:
1. Check if the files differ:
   `diff -u <target_file> ~/dotfiles/<pkg>/<path>`
2. If identical or target has the desired state:
   - Remove the unlinked target: `rm <target_file>`
   - Re-run stow: `cd ~/dotfiles && stow -v --restow <pkg>`
3. If target has changes you want to bring into the repository:
   - Use `stow --adopt <pkg>`, which pulls the content from `$HOME` into `~/dotfiles/<pkg>`, then run `git diff` to review.

### B. Rogue Files in the Package Root Symlinking to `$HOME`
**Symptom**:
Files like `wofi-focus-fix.c` or `README.md` placed directly inside `dotfiles/<pkg>/` attempt to be symlinked to `~/<file>`.

**Cause**:
Because Stow mirrors `$HOME`, any file directly inside `dotfiles/<pkg>/` is interpreted as wanting to live in `$HOME/<file>`.

**Remediation**:
Add a `.stow-local-ignore` file in the package root containing regex patterns for files Stow must ignore:
```text
^wofi-focus-fix\.c$
^README\.md$
^.*\.so$
```

---

## 4. Standard Commands

- **Dry-run check (Safe)**:
  `cd ~/dotfiles && stow -n -v --restow <package_name>`
- **Restow a package**:
  `cd ~/dotfiles && stow -v --restow <package_name>`
- **Unstow (remove symlinks)**:
  `cd ~/dotfiles && stow -v -D <package_name>`
- **Adopt existing files**:
  `cd ~/dotfiles && stow -v --adopt <package_name>`
