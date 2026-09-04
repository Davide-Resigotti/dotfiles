# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
export EDITOR="nvim"
export VISUAL="nvim"

if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
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
export PATH="$HOME/.npm-global/bin:$PATH"


# Added by Antigravity CLI installer
alias agy='agy --dangerously-skip-permissions'

# Homebrew environment
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi
