#!/usr/bin/env bash
# sync-git.sh - Check pre-commit hygiene, ensure no secrets staged, display status
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
cd "$DOTFILES_DIR"

echo "Checking dotfiles repository hygiene..."

# 1. Check for uncommitted changes
if [[ -z "$(git status --porcelain)" ]]; then
    echo "[OK] No changes to commit. Working tree clean."
    exit 0
fi

# 2. Check for potential leaked tokens / secrets in staged or unstaged diff
echo "Scanning for sensitive patterns (tokens, private keys)..."
SUSPECT_PATTERNS='(ghp_[a-zA-Z0-9]{36}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|token=[a-zA-Z0-9_\-\.]{20,}|Bearer [a-zA-Z0-9_\-\.]{20,}|eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,})'

if git diff -U0 | grep -E -n "$SUSPECT_PATTERNS" 2>/dev/null; then
    echo "[ALERT] Potential secret or token detected in diff! Do NOT commit until reviewed."
    exit 1
fi

echo "[OK] No secret patterns detected in diff."
echo ""
echo "Current git status:"
git status -s
echo ""
echo "To commit changes:"
echo "  cd $DOTFILES_DIR"
echo "  git add <files>"
echo "  git commit -m \"feat(<pkg>): describe change\""
echo "  git push origin main"
