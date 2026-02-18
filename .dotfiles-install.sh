#!/bin/bash
# Dotfiles Bootstrap Script

set -e

DOTFILES_REPO="https://github.com/andrew-tomago/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles.git"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Dotfiles Installation ==="

# Check git
if ! command -v git &> /dev/null; then
    echo "Error: git not installed. Install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Clone bare repository
echo "Cloning dotfiles repository..."
git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"

# Define alias
function config {
    /usr/bin/git --git-dir=$DOTFILES_DIR --work-tree=$HOME "$@"
}

# Configure
echo "Configuring repository..."
config config --local status.showUntrackedFiles no

# Backup existing dotfiles
echo "Backing up existing dotfiles..."
mkdir -p "$BACKUP_DIR"
FILES_TO_CHECKOUT=$(config ls-tree -r main --name-only)

for file in $FILES_TO_CHECKOUT; do
    if [ -f "$HOME/$file" ]; then
        echo "  Backing up: $file"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$HOME/$file" "$BACKUP_DIR/$file"
    fi
done

# Checkout dotfiles
echo "Checking out dotfiles..."
config checkout

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Run the setup script to generate .zshrc and install tools:"
echo "   ./setup-new-macbook.sh   (macOS)"
echo "   ./setup-new-ubuntu.sh    (Ubuntu)"
echo "2. Reload shell: source ~/.zshrc"
echo "3. Verify: config status"
echo ""
echo "Existing files backed up to: $BACKUP_DIR"
