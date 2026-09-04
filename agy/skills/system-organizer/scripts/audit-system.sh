#!/usr/bin/env bash
# audit-system.sh - Diagnostic audit for XDG compliance, GNU Stow health, and git status
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

inc_pass() { PASS_COUNT=$((PASS_COUNT + 1)); }
inc_warn() { WARN_COUNT=$((WARN_COUNT + 1)); }
inc_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); }

echo "========================================================"
echo "    Fedora Asahi / Dotfiles / XDG System Health Audit   "
echo "========================================================"
echo "Host: $(uname -n) | Kernel: $(uname -r)"
echo "Dotfiles repo: $DOTFILES_DIR"
echo ""

# 1. Check GNU Stow installation
if command -v stow >/dev/null 2>&1; then
    echo "[OK] GNU Stow is installed: $(stow --version | head -n 1)"
    inc_pass
else
    echo "[FAIL] GNU Stow is not installed! Run: sudo dnf install stow"
    inc_fail
fi

# 2. Audit Home Directory for Non-Standard Dotfiles (XDG Violations)
echo ""
echo "--- 1. Auditing \$HOME for XDG Compliance ---"
ALLOWED_HOME_ENTRIES=(
    ".bashrc" ".bash_profile" ".profile" ".gitconfig" ".tmux.conf"
    ".bash_history" ".bash_logout" ".ssh" ".config" ".local" ".cache"
    ".mozilla" ".var" ".pki" "Desktop" "Documents" "Downloads" "Music"
    "Pictures" "Videos" "dotfiles" ".gemini" ".opencode" "AGENTS.md"
)

mapfile -t HOME_DOTS < <(find "$HOME" -maxdepth 1 \( -name ".*" -o -name "*.sh" \) -printf "%f\n" 2>/dev/null | sort)
XDG_ANOMALIES=()

for item in "${HOME_DOTS[@]}"; do
    is_allowed=0
    for allowed in "${ALLOWED_HOME_ENTRIES[@]}"; do
        if [[ "$item" == "$allowed" ]]; then
            is_allowed=1
            break
        fi
    done
    if [[ $is_allowed -eq 0 ]]; then
        XDG_ANOMALIES+=("$item")
    fi
done

if [[ ${#XDG_ANOMALIES[@]} -eq 0 ]]; then
    echo "[OK] \$HOME is clean. No stray dotfiles or loose scripts detected."
    inc_pass
else
    echo "[WARN] Found ${#XDG_ANOMALIES[@]} item(s) in \$HOME that may violate XDG conventions:"
    for anomaly in "${XDG_ANOMALIES[@]}"; do
        target_path="$HOME/$anomaly"
        if [ -L "$target_path" ]; then
            echo "  - $anomaly -> $(readlink "$target_path") (symlink)"
        elif [ -d "$target_path" ]; then
            echo "  - $anomaly/ (directory - consider migrating to \$XDG_DATA_HOME or \$XDG_CONFIG_HOME)"
        else
            echo "  - $anomaly (file - consider moving to ~/.config, ~/.local/bin, or removing)"
        fi
    done
    inc_warn
fi

# 3. Check for Broken Symlinks in ~/.config and ~/.local
echo ""
echo "--- 2. Checking for Broken Symlinks ---"
mapfile -t RAW_BROKEN_LINKS < <(find "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" -xtype l 2>/dev/null || true)
BROKEN_LINKS=()
for bl in "${RAW_BROKEN_LINKS[@]}"; do
    # Skip Mozilla/browser lock symlinks (they point to hostname:+pid by design)
    if [[ "$bl" == *"/firefox/"*"/lock" ]] || [[ "$bl" == *"/lock" && "$bl" == *"mozilla"* ]]; then
        continue
    fi
    BROKEN_LINKS+=("$bl")
done

if [[ ${#BROKEN_LINKS[@]} -eq 0 ]]; then
    echo "[OK] No broken symlinks found in ~/.config or ~/.local."
    inc_pass
else
    echo "[FAIL] Found ${#BROKEN_LINKS[@]} broken symlink(s):"
    for bl in "${BROKEN_LINKS[@]}"; do
        echo "  - $bl -> $(readlink "$bl" 2>/dev/null || echo 'unresolvable')"
    done
    inc_fail
fi

# 4. GNU Stow Collision Dry-Run
echo ""
echo "--- 3. Testing GNU Stow Dry-Run (Restow All Packages) ---"
PACKAGES=(
    niri waybar mako fuzzel wofi ghostty fontconfig xsettingsd
    gtk-2.0 gtk-3.0 gtk-4.0 autostart shell darkman xdg-desktop-portal
    theme home-assistant waypaper yazi tmux nvim npm opencode
)

if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    if STOW_OUT=$(stow -n -v --restow "${PACKAGES[@]}" 2>&1); then
        echo "[OK] All Stow packages restow cleanly without collisions!"
        inc_pass
    else
        echo "[FAIL] GNU Stow detected conflicts or errors:"
        echo "$STOW_OUT" | grep -E "WARNING|cannot stow|conflict|All operations aborted" | sed 's/^/  /'
        inc_fail
    fi
else
    echo "[FAIL] Dotfiles directory $DOTFILES_DIR not found!"
    inc_fail
fi

# 5. Git Status in Dotfiles Repo
echo ""
echo "--- 4. Checking Dotfiles Git Status ---"
if [ -d "$DOTFILES_DIR/.git" ]; then
    cd "$DOTFILES_DIR"
    UNCOMMITTED=$(git status --porcelain)
    if [[ -z "$UNCOMMITTED" ]]; then
        echo "[OK] Git working directory is completely clean."
        inc_pass
    else
        echo "[INFO] Working tree has changes:"
        git status -s | sed 's/^/  /'
        inc_warn
    fi
fi

echo ""
echo "========================================================"
echo "Audit Summary: $PASS_COUNT Passed | $WARN_COUNT Warnings | $FAIL_COUNT Failures"
echo "========================================================"

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0
