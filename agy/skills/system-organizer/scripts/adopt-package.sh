#!/usr/bin/env bash
# adopt-package.sh - Migrate an unmanaged file or folder into dotfiles and stow it
# Usage:
#   ./adopt-package.sh <package_name> <source_path>
# Example:
#   ./adopt-package.sh git ~/.gitconfig
#   ./adopt-package.sh fastfetch ~/.config/fastfetch
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <package_name> <source_path_in_HOME>" >&2
    echo "Example: $0 zsh ~/.zshrc" >&2
    exit 1
fi

PKG_NAME="$1"
SRC_PATH="$(realpath "$2")"

if [ ! -e "$SRC_PATH" ]; then
    echo "Error: Source path '$SRC_PATH' does not exist!" >&2
    exit 1
fi

if [ -L "$SRC_PATH" ]; then
    echo "Warning: '$SRC_PATH' is already a symlink -> $(readlink "$SRC_PATH")." >&2
    echo "It might already be managed by Stow." >&2
    exit 1
fi

# Ensure source is inside $HOME
if [[ "$SRC_PATH" != "$HOME"* ]]; then
    echo "Error: Source '$SRC_PATH' must be located inside \$HOME ($HOME)!" >&2
    exit 1
fi

# Calculate relative path from $HOME
REL_PATH="${SRC_PATH#$HOME/}"
PKG_DEST="$DOTFILES_DIR/$PKG_NAME/$REL_PATH"

echo "Adopting '$SRC_PATH' into package '$PKG_NAME'..."
echo "Destination: $PKG_DEST"

# Ensure destination parent directory exists
mkdir -p "$(dirname "$PKG_DEST")"

# Move file or directory into dotfiles
mv "$SRC_PATH" "$PKG_DEST"

# Stow the package
echo "Stowing package '$PKG_NAME'..."
cd "$DOTFILES_DIR"
stow -v --restow "$PKG_NAME"

# Verify symlink
if [ -L "$SRC_PATH" ]; then
    echo "[SUCCESS] '$SRC_PATH' is now stowed -> $(readlink "$SRC_PATH")"
else
    echo "[ERROR] Expected '$SRC_PATH' to be a symlink after stowing!" >&2
    exit 1
fi
