# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
export EDITOR="nvim"
export VISUAL="nvim"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Force non-compliant CLI tools to respect XDG directories
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export MYPY_CACHE_DIR="$XDG_CACHE_HOME/mypy"
export HISTFILE="$XDG_STATE_HOME/bash/history"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
[ -d "$CARGO_HOME/bin" ] && PATH="$CARGO_HOME/bin:$PATH"
[ -d "$GOPATH/bin" ] && PATH="$GOPATH/bin:$PATH"
[ -d "$BUN_INSTALL/bin" ] && PATH="$BUN_INSTALL/bin:$PATH"
[ -d "$XDG_DATA_HOME/npm/bin" ] && PATH="$XDG_DATA_HOME/npm/bin:$PATH"
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Load current UI primary accent color environment variables
if [ -f "$HOME/.config/theme/current-accent.env" ]; then
    . "$HOME/.config/theme/current-accent.env"
fi

# opencode (only active where opencode lives under ~/.opencode)
if [ -d "$HOME/.opencode/bin" ]; then
    export PATH="$HOME/.opencode/bin:$PATH"
fi

# Subversion XDG configuration wrapper
if command -v svn >/dev/null 2>&1; then
    alias svn='svn --config-dir "$XDG_CONFIG_HOME/subversion"'
fi

# Added by Antigravity CLI installer
alias agy='agy --dangerously-skip-permissions'

# Homebrew environment
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi
