# XDG Base Directory Specification Reference

This guide details the XDG Base Directory standard and provides explicit rules for keeping `$HOME` clean, modular, and version-controlled.

---

## 1. Standard XDG Directory Mappings

| Variable | Default Path | Purpose | Backup / Dotfiles Policy |
| :--- | :--- | :--- | :--- |
| `XDG_CONFIG_HOME` | `~/.config` | User-specific configuration files | **Tracked** in `~/dotfiles/<pkg>/.config/<pkg>` via Stow |
| `XDG_DATA_HOME` | `~/.local/share` | User-specific data (desktop files, fonts, themes, plugins) | **Selectively Tracked** in `~/dotfiles/<pkg>/.local/share/...` |
| `XDG_STATE_HOME` | `~/.local/state` | Persistent runtime state (logs, shell history, recent files) | **Ignored** (never committed to git) |
| `XDG_CACHE_HOME` | `~/.cache` | Disposable cached files (thumbnails, wallpaper frames, bytecode) | **Ignored** (never committed to git) |
| `XDG_BIN_HOME` | `~/.local/bin` | User-executable scripts and binaries | **Tracked** in `~/dotfiles/<pkg>/.local/bin/...` |
| `XDG_RUNTIME_DIR` | `/run/user/$UID` | Ephemeral sockets, pipes, session data | **Ignored** (managed by systemd-logind) |

---

## 2. Shell Environment Exports

To ensure all child processes, subshells, and CLI tools honor the specification, the following exports must be set in `~/.bashrc` (managed via `shell/.bashrc`):

```bash
# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
```

---

## 3. Overriding Non-Compliant Tools

Many traditional UNIX and language-specific tools place files directly into `$HOME` unless instructed otherwise. Use these standardized variable overrides:

### Node.js / NPM
- **Default violation**: `~/.npmrc`, `~/.npm/`, `~/.node_repl_history`
- **Solution**:
  ```bash
  export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
  export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
  ```
  Ensure directory exists: `mkdir -p "$XDG_CONFIG_HOME/npm"`

### Rust / Cargo
- **Default violation**: `~/.cargo/`, `~/.rustup/`
- **Solution**:
  ```bash
  export CARGO_HOME="$XDG_DATA_HOME/cargo"
  export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
  ```
  Ensure PATH includes `$CARGO_HOME/bin`:
  ```bash
  [ -d "$CARGO_HOME/bin" ] && export PATH="$CARGO_HOME/bin:$PATH"
  ```

### Go Language
- **Default violation**: `~/go/`
- **Solution**:
  ```bash
  export GOPATH="$XDG_DATA_HOME/go"
  [ -d "$GOPATH/bin" ] && export PATH="$GOPATH/bin:$PATH"
  ```

### Python
- **Default violation**: `~/.python_history`
- **Solution** (Python 3.13+):
  ```bash
  export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
  ```

### GTK 2
- **Default violation**: `~/.gtkrc-2.0`
- **Solution**:
  ```bash
  export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
  ```

### Less & Pagers
- **Default violation**: `~/.lesshst`
- **Solution**:
  ```bash
  export LESSHISTFILE="$XDG_STATE_HOME/less/history"
  ```

### Bun Runtime
- **Default violation**: `~/.bun/`
- **Solution**:
  ```bash
  export BUN_INSTALL="$XDG_DATA_HOME/bun"
  [ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
  ```

### Mypy Type Checker
- **Default violation**: `~/.mypy_cache/`
- **Solution**:
  ```bash
  export MYPY_CACHE_DIR="$XDG_CACHE_HOME/mypy"
  ```

### Subversion
- **Default violation**: `~/.subversion/`
- **Solution**:
  ```bash
  alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'
  ```

### Bash History
- **Default violation**: `~/.bash_history`
- **Solution**:
  ```bash
  export HISTFILE="$XDG_STATE_HOME/bash/history"
  ```

### Zsh Completion Cache
- **Default violation**: `~/.zcompdump*`
- **Solution**:
  ```bash
  export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
  ```

### NSS / PKI Database
- **Standard Linux Location**: `~/.pki/nssdb` (managed by libnss3 for cryptographic stores; allowed exception alongside `.mozilla` and `.var`).

---

## 4. The Clean `$HOME` Principle

`$HOME` should strictly contain:
1. Standard user-facing directories (`Desktop`, `Documents`, `Downloads`, `Music`, `Pictures`, `Videos`).
2. Main repository workspace(s) (e.g. `dotfiles`).
3. Only the minimal required root symlinks that POSIX tools mandate:
   - `~/.bashrc -> dotfiles/shell/.bashrc`
   - `~/.bash_profile -> dotfiles/shell/.bash_profile`
   - `~/.profile -> dotfiles/shell/.profile`
   - `~/.gitconfig -> dotfiles/shell/.gitconfig`
   - `~/.tmux.conf -> dotfiles/tmux/.tmux.conf`
4. Essential secure directories:
   - `~/.ssh/` (mode 700)

**Any other file or dot-directory in `$HOME` is considered an anomaly and should either be migrated to `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, or redirected via environment variable.**
