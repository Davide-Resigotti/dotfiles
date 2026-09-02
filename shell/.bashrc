# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
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

# opencode (only active where opencode lives under ~/.opencode)
if [ -d "$HOME/.opencode/bin" ]; then
    export PATH="$HOME/.opencode/bin:$PATH"

    # Plain `opencode` attaches to the always-running web server.
    # Standalone subcommands still work (web, serve, ...).
    opencode() {
        case "${1:-}" in
            web|serve|version|upgrade|help|-h|--help|-v|--version)
                command opencode "$@"
                ;;
            *)
                command opencode attach http://localhost:4096 -p devs --dir "$PWD" "$@"
                ;;
        esac
    }
fi
