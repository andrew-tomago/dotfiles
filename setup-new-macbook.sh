#!/bin/bash
# =============================================================================
# setup-new-macbook.sh - Comprehensive macOS Development Environment Setup
# =============================================================================
#
# This script sets up a fresh macOS installation with development tools.
# It is idempotent - safe to run multiple times. Existing installations
# will be updated rather than reinstalled.
#
# Installation Order (dependencies matter):
#   1. Xcode Command Line Tools (required for git, compilers)
#   2. Rosetta 2 (Apple Silicon only - required for some apps)
#   3. Homebrew (package manager)
#   4. GNU Core Utilities (modern CLI tools)
#   5. Homebrew CLI Packages (git, zsh, node, gh, etc.)
#   6. Homebrew Cask Applications (Raycast, Chrome, Docker, etc.)
#   7. Zsh Configuration (set Homebrew zsh as default)
#   8. Oh My Zsh (zsh framework)
#   9. NVM (Node version manager - optional, for multiple Node versions)
#  10. npm Global Packages (Codex)
#  11. Claude Code (AI coding assistant)
#  12. GitHub CLI Configuration
#  13. Default Browser Configuration (Chrome)
#
# Usage:
#   chmod +x setup-new-macbook.sh
#   ./setup-new-macbook.sh
#
# =============================================================================

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# =============================================================================
# Configuration
# =============================================================================

# GNU Core Utilities
GNU_PACKAGES=(
    "coreutils"    # GNU core utilities (ls, cat, etc.)
    "moreutils"    # Additional Unix utilities
    "findutils"    # GNU find, locate, updatedb, xargs
    "gnu-sed"      # GNU sed
)

# Homebrew CLI packages
HOMEBREW_PACKAGES=(
    "git"
    "zsh"
    "node"         # Node.js and npm
    "gh"           # GitHub CLI
    "jq"           # JSON processor
    "ripgrep"      # Fast grep alternative
    "fd"           # Fast find alternative
    "tree"         # Directory tree viewer
    "wget"         # Web file retriever
    "curl"         # URL transfer tool
)

# Homebrew Cask applications
HOMEBREW_CASKS=(
    "raycast"          # Spotlight replacement
    "google-chrome"    # Web browser
    "appcleaner"       # App uninstaller
    "docker"           # Docker Desktop
)

# npm global packages
NPM_PACKAGES=(
    "@openai/codex"    # OpenAI Codex CLI
)

# NVM version to install
NVM_VERSION="v0.40.1"

# =============================================================================
# Color & Output Helpers
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECK_MARK="${GREEN}✓${NC}"
CROSS_MARK="${RED}✗${NC}"
ARROW="${CYAN}→${NC}"
INFO="${BLUE}ℹ${NC}"
WARN="${YELLOW}⚠${NC}"

print_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA}  $1${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
}

print_step() {
    echo -e "  ${ARROW} $1"
}

print_success() {
    echo -e "  ${CHECK_MARK} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "  ${CROSS_MARK} ${RED}$1${NC}"
}

print_warning() {
    echo -e "  ${WARN} ${YELLOW}$1${NC}"
}

print_info() {
    echo -e "  ${INFO} ${BLUE}$1${NC}"
}

print_result() {
    if [ "$1" -eq 0 ]; then
        print_success "$2"
    else
        print_error "$2 (exit code: $1)"
        return "$1"
    fi
}

# =============================================================================
# Detection Helpers
# =============================================================================

is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

get_homebrew_prefix() {
    if is_apple_silicon; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

command_exists() {
    command -v "$1" &> /dev/null
}

brew_package_installed() {
    brew list --formula "$1" &> /dev/null 2>&1
}

brew_cask_installed() {
    brew list --cask "$1" &> /dev/null 2>&1
}

npm_package_installed() {
    npm list -g "$1" &> /dev/null 2>&1
}

app_installed() {
    [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]
}

# =============================================================================
# Xcode Command Line Tools
# =============================================================================

install_xcode_cli_tools() {
    print_section "Xcode Command Line Tools"

    if xcode-select --print-path &> /dev/null; then
        print_success "Xcode CLI Tools already installed"
        print_step "Checking for updates..."

        # Check for Xcode CLI updates via softwareupdate
        if softwareupdate --list 2>&1 | grep -q "Command Line Tools"; then
            print_info "Updates available, installing..."
            sudo softwareupdate --install "Command Line Tools for Xcode" --agree-to-license || true
            print_success "Xcode CLI Tools updated"
        else
            print_info "Already up to date"
        fi
        return 0
    fi

    print_step "Installing Xcode Command Line Tools..."
    print_info "This may take several minutes and require your password"

    # Trigger the install prompt
    xcode-select --install &> /dev/null || true

    # Wait for installation to complete
    print_step "Waiting for installation to complete..."
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? "Xcode Command Line Tools installed"

    # Point xcode-select to the correct directory if Xcode.app is installed
    if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
        print_step "Configuring xcode-select developer directory..."
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
        print_result $? "Developer directory configured"

        # Accept Xcode license
        print_step "Accepting Xcode license (requires sudo)..."
        sudo xcodebuild -license accept &> /dev/null || {
            print_warning "Could not auto-accept license. You may need to run: sudo xcodebuild -license"
        }
    fi

    print_success "Xcode Command Line Tools setup complete"
}

# =============================================================================
# Rosetta 2 (Apple Silicon only)
# =============================================================================

install_rosetta() {
    print_section "Rosetta 2"

    if ! is_apple_silicon; then
        print_info "Intel Mac detected - Rosetta 2 not needed"
        return 0
    fi

    # Check if Rosetta is already installed
    if /usr/bin/pgrep -q oahd; then
        print_success "Rosetta 2 already installed and running"
        return 0
    fi

    # Check if Rosetta binary exists
    if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
        print_success "Rosetta 2 already installed"
        return 0
    fi

    print_step "Installing Rosetta 2 for Apple Silicon..."
    softwareupdate --install-rosetta --agree-to-license

    print_success "Rosetta 2 installed"
}

# =============================================================================
# Homebrew
# =============================================================================

install_homebrew() {
    print_section "Homebrew"

    local brew_prefix
    brew_prefix=$(get_homebrew_prefix)

    if command_exists brew; then
        print_success "Homebrew already installed at $(brew --prefix)"
        print_step "Updating Homebrew..."
        brew update
        print_success "Homebrew updated"

        print_step "Upgrading installed packages..."
        brew upgrade || true
        print_success "Packages upgraded"

        print_step "Running cleanup..."
        brew cleanup
        print_success "Cleanup complete"
        return 0
    fi

    print_step "Installing Homebrew..."
    print_info "This will require your password"

    # Install Homebrew (non-interactive)
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if is_apple_silicon; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # Verify installation
    if command_exists brew; then
        print_success "Homebrew installed successfully"

        # Add to shell profile if not already present
        if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
            print_step "Adding Homebrew to shell profile..."
            echo '' >> "$HOME/.zprofile"
            echo '# Homebrew' >> "$HOME/.zprofile"
            echo "eval \"\$(${brew_prefix}/bin/brew shellenv)\"" >> "$HOME/.zprofile"
            print_success "Added Homebrew to .zprofile"
        fi
    else
        print_error "Homebrew installation failed"
        return 1
    fi

    # Disable analytics
    brew analytics off
    print_info "Homebrew analytics disabled"
}

# =============================================================================
# GNU Core Utilities
# =============================================================================

install_gnu_utils() {
    print_section "GNU Core Utilities"

    if ! command_exists brew; then
        print_error "Homebrew not installed. Skipping GNU utilities."
        return 1
    fi

    print_info "Installing GNU utilities (these replace outdated macOS versions)"

    local installed=0
    local updated=0

    for package in "${GNU_PACKAGES[@]}"; do
        if brew_package_installed "$package"; then
            print_info "$package already installed"
            ((updated++))
        else
            print_step "Installing $package..."
            if brew install "$package" 2>/dev/null; then
                print_success "$package installed"
                ((installed++))
            else
                print_error "Failed to install $package"
            fi
        fi
    done

    # Add GNU utils to PATH info
    print_info "GNU utilities installed with 'g' prefix (e.g., gfind, gsed)"
    print_info "To use without prefix, add to PATH: export PATH=\"\$(brew --prefix)/opt/coreutils/libexec/gnubin:\$PATH\""

    echo ""
    print_info "Summary: $installed installed, $updated already present"
}

# =============================================================================
# Homebrew CLI Packages
# =============================================================================

install_homebrew_packages() {
    print_section "Homebrew CLI Packages"

    if ! command_exists brew; then
        print_error "Homebrew not installed. Skipping packages."
        return 1
    fi

    local installed=0
    local updated=0
    local failed=0

    for package in "${HOMEBREW_PACKAGES[@]}"; do
        if brew_package_installed "$package"; then
            print_info "$package already installed"
            # Check if upgrade available
            if brew outdated "$package" &> /dev/null; then
                print_step "Upgrading $package..."
                if brew upgrade "$package" 2>/dev/null; then
                    print_success "$package upgraded"
                    ((updated++))
                fi
            fi
        else
            print_step "Installing $package..."
            if brew install "$package" 2>/dev/null; then
                print_success "$package installed"
                ((installed++))
            else
                print_error "Failed to install $package"
                ((failed++))
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $updated upgraded, $failed failed"
}

# =============================================================================
# Homebrew Cask Applications
# =============================================================================

install_homebrew_casks() {
    print_section "Homebrew Cask Applications"

    if ! command_exists brew; then
        print_error "Homebrew not installed. Skipping cask applications."
        return 1
    fi

    local installed=0
    local skipped=0
    local failed=0

    for cask in "${HOMEBREW_CASKS[@]}"; do
        if brew_cask_installed "$cask"; then
            print_info "$cask already installed"
            ((skipped++))
        else
            print_step "Installing $cask..."
            if brew install --cask "$cask" 2>/dev/null; then
                print_success "$cask installed"
                ((installed++))
            else
                print_error "Failed to install $cask"
                ((failed++))
            fi
        fi
    done

    # Docker-specific post-install message
    if brew_cask_installed "docker"; then
        print_info "Docker Desktop installed. Launch it from Applications to complete setup."
        print_info "First launch may take time due to macOS security checks."
    fi

    echo ""
    print_info "Summary: $installed installed, $skipped already present, $failed failed"
}

# =============================================================================
# Zsh Configuration
# =============================================================================

configure_zsh() {
    print_section "Zsh Configuration"

    # Check if Homebrew zsh is installed
    local brew_zsh
    brew_zsh="$(get_homebrew_prefix)/bin/zsh"

    if [ ! -f "$brew_zsh" ]; then
        print_warning "Homebrew zsh not found at $brew_zsh"
        print_info "Using system zsh: $(which zsh)"
        return 0
    fi

    print_success "Homebrew zsh found at $brew_zsh"

    # Check if it's already in /etc/shells
    if ! grep -q "$brew_zsh" /etc/shells; then
        print_step "Adding Homebrew zsh to /etc/shells..."
        echo "$brew_zsh" | sudo tee -a /etc/shells > /dev/null
        print_success "Added to /etc/shells"
    else
        print_info "Already in /etc/shells"
    fi

    # Check current default shell
    if [ "$SHELL" != "$brew_zsh" ]; then
        print_step "Setting Homebrew zsh as default shell..."
        chsh -s "$brew_zsh"
        print_success "Default shell changed to Homebrew zsh"
        print_warning "Please restart your terminal for changes to take effect"
    else
        print_info "Homebrew zsh is already the default shell"
    fi
}

# =============================================================================
# Oh My Zsh
# =============================================================================

install_oh_my_zsh() {
    print_section "Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
        print_step "Checking for updates..."

        # Update Oh My Zsh
        (
            cd "$HOME/.oh-my-zsh"
            git pull --quiet origin master
        ) && print_success "Oh My Zsh updated" || print_warning "Update check failed"

        return 0
    fi

    print_step "Installing Oh My Zsh..."

    # Install Oh My Zsh (non-interactive, don't change shell - we handle that)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh installed"
    else
        print_error "Oh My Zsh installation failed"
        return 1
    fi
}

# =============================================================================
# NVM (Node Version Manager) - Optional
# =============================================================================

install_nvm() {
    print_section "NVM (Node Version Manager)"

    print_info "NVM provides flexibility to switch between Node versions"
    print_info "Homebrew Node is also installed for general use"

    export NVM_DIR="$HOME/.nvm"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM already installed"

        # Source NVM for current session
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        print_step "Current version: $(nvm --version 2>/dev/null || echo 'unknown')"
        print_step "Checking for updates..."

        # Update NVM by fetching latest tag
        (
            cd "$NVM_DIR"
            git fetch --tags origin
            local latest_tag
            latest_tag=$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")
            git checkout "$latest_tag" --quiet
        ) && print_success "NVM updated" || print_warning "Update check failed"

        return 0
    fi

    print_step "Installing NVM $NVM_VERSION..."

    # Install NVM
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

    # Source NVM for current session
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM installed"

        # Install latest LTS Node via NVM
        print_step "Installing latest LTS Node.js via NVM..."
        nvm install --lts
        nvm alias default 'lts/*'
        print_success "Node.js LTS installed via NVM: $(nvm current)"
    else
        print_error "NVM installation failed"
        return 1
    fi
}

# =============================================================================
# npm Global Packages
# =============================================================================

install_npm_packages() {
    print_section "npm Global Packages"

    if ! command_exists npm; then
        print_error "npm not found. Skipping npm packages."
        return 1
    fi

    print_info "Using npm from: $(which npm)"
    print_info "Node version: $(node --version)"

    local installed=0
    local skipped=0
    local failed=0

    for package in "${NPM_PACKAGES[@]}"; do
        if npm_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++))
        else
            print_step "Installing $package..."
            if npm install -g "$package" 2>/dev/null; then
                print_success "$package installed"
                ((installed++))
            else
                print_error "Failed to install $package"
                ((failed++))
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $skipped already present, $failed failed"
}

# =============================================================================
# Claude Code
# =============================================================================

install_claude_code() {
    print_section "Claude Code"

    # Check if Claude Code is already installed
    if command_exists claude; then
        print_success "Claude Code already installed"
        print_step "Version: $(claude --version 2>/dev/null || echo 'unknown')"

        print_step "Checking for updates..."
        # Claude Code can self-update
        claude update 2>/dev/null || print_info "Run 'claude update' to check for updates"
        return 0
    fi

    print_step "Installing Claude Code..."

    # Install Claude Code
    curl -fsSL https://claude.ai/install.sh | bash

    # Verify installation
    if command_exists claude; then
        print_success "Claude Code installed"
        print_step "Version: $(claude --version 2>/dev/null || echo 'installed')"
    else
        # Claude might be installed but not in PATH yet
        if [ -f "$HOME/.claude/local/bin/claude" ]; then
            print_success "Claude Code installed (restart terminal to use)"
        else
            print_error "Claude Code installation may have failed"
            print_info "Try running manually: curl -fsSL https://claude.ai/install.sh | bash"
        fi
    fi
}

# =============================================================================
# GitHub CLI Configuration
# =============================================================================

configure_github_cli() {
    print_section "GitHub CLI Configuration"

    if ! command_exists gh; then
        print_warning "GitHub CLI not installed. Skipping configuration."
        return 0
    fi

    print_success "GitHub CLI installed: $(gh --version | head -n1)"

    # Check if already authenticated
    if gh auth status &> /dev/null; then
        print_success "Already authenticated with GitHub"
        gh auth status
    else
        print_info "GitHub CLI not authenticated"
        print_info "Run 'gh auth login' to authenticate with GitHub"
    fi
}

# =============================================================================
# Default Browser Configuration
# =============================================================================

configure_default_browser() {
    print_section "Default Browser Configuration"

    if ! app_installed "Google Chrome"; then
        print_warning "Google Chrome not installed. Skipping default browser setup."
        return 0
    fi

    print_success "Google Chrome is installed"

    # Check current default browser
    local current_browser
    current_browser=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -A2 "LSHandlerURLScheme = https" | grep LSHandlerRoleAll | head -1 | awk -F'"' '{print $2}' || echo "unknown")

    if [[ "$current_browser" == "com.google.chrome" ]]; then
        print_success "Google Chrome is already the default browser"
        return 0
    fi

    print_step "To set Chrome as default browser:"
    print_info "1. Open System Settings > Desktop & Dock"
    print_info "2. Scroll to 'Default web browser'"
    print_info "3. Select 'Google Chrome'"
    echo ""
    print_info "Or open Chrome and accept when prompted to set as default"

    # Attempt to open Chrome's default browser prompt
    print_step "Opening Chrome to prompt for default browser..."
    open -a "Google Chrome" --args --make-default-browser 2>/dev/null || true
}

# =============================================================================
# Dotfiles Setup Reminder
# =============================================================================

print_dotfiles_reminder() {
    print_section "Dotfiles Setup"

    if [ -d "$HOME/.dotfiles.git" ]; then
        print_success "Dotfiles repository already configured"
        print_info "Use 'config status' to check your dotfiles"
    else
        print_info "Dotfiles not yet configured"
        echo ""
        echo -e "  To set up your dotfiles, run:"
        echo -e "  ${CYAN}curl -fsSL https://raw.githubusercontent.com/andrew-tomago/dotfiles/main/.dotfiles-install.sh | bash${NC}"
        echo ""
    fi
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    print_header "Setup Complete!"

    echo -e "  ${BOLD}Core Components:${NC}"
    echo ""

    # Xcode
    if xcode-select --print-path &> /dev/null; then
        echo -e "    ${CHECK_MARK} Xcode CLI Tools"
    else
        echo -e "    ${CROSS_MARK} Xcode CLI Tools"
    fi

    # Rosetta (Apple Silicon only)
    if is_apple_silicon; then
        if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
            echo -e "    ${CHECK_MARK} Rosetta 2"
        else
            echo -e "    ${CROSS_MARK} Rosetta 2"
        fi
    fi

    # Homebrew
    if command_exists brew; then
        echo -e "    ${CHECK_MARK} Homebrew ($(brew --version | head -n1))"
    else
        echo -e "    ${CROSS_MARK} Homebrew"
    fi

    # Git
    if command_exists git; then
        echo -e "    ${CHECK_MARK} Git ($(git --version | cut -d' ' -f3))"
    else
        echo -e "    ${CROSS_MARK} Git"
    fi

    # Zsh
    if command_exists zsh; then
        echo -e "    ${CHECK_MARK} Zsh ($(zsh --version | cut -d' ' -f2))"
    else
        echo -e "    ${CROSS_MARK} Zsh"
    fi

    # Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "    ${CHECK_MARK} Oh My Zsh"
    else
        echo -e "    ${CROSS_MARK} Oh My Zsh"
    fi

    # Node
    if command_exists node; then
        echo -e "    ${CHECK_MARK} Node.js ($(node --version))"
    else
        echo -e "    ${CROSS_MARK} Node.js"
    fi

    # NVM
    if [ -d "$HOME/.nvm" ]; then
        echo -e "    ${CHECK_MARK} NVM"
    else
        echo -e "    ${CROSS_MARK} NVM"
    fi

    echo ""
    echo -e "  ${BOLD}CLI Tools:${NC}"
    echo ""

    # GitHub CLI
    if command_exists gh; then
        echo -e "    ${CHECK_MARK} GitHub CLI ($(gh --version | head -n1 | cut -d' ' -f3))"
    else
        echo -e "    ${CROSS_MARK} GitHub CLI"
    fi

    # Claude Code
    if command_exists claude || [ -f "$HOME/.claude/local/bin/claude" ]; then
        echo -e "    ${CHECK_MARK} Claude Code"
    else
        echo -e "    ${CROSS_MARK} Claude Code"
    fi

    # Codex
    if npm_package_installed "@openai/codex" 2>/dev/null; then
        echo -e "    ${CHECK_MARK} OpenAI Codex"
    else
        echo -e "    ${CROSS_MARK} OpenAI Codex"
    fi

    echo ""
    echo -e "  ${BOLD}GNU Core Utilities:${NC}"
    echo ""
    for package in "${GNU_PACKAGES[@]}"; do
        if brew_package_installed "$package" 2>/dev/null; then
            echo -e "    ${CHECK_MARK} $package"
        else
            echo -e "    ${CROSS_MARK} $package"
        fi
    done

    echo ""
    echo -e "  ${BOLD}Applications:${NC}"
    echo ""

    # Raycast
    if app_installed "Raycast"; then
        echo -e "    ${CHECK_MARK} Raycast"
    else
        echo -e "    ${CROSS_MARK} Raycast"
    fi

    # Google Chrome
    if app_installed "Google Chrome"; then
        echo -e "    ${CHECK_MARK} Google Chrome"
    else
        echo -e "    ${CROSS_MARK} Google Chrome"
    fi

    # AppCleaner
    if app_installed "AppCleaner"; then
        echo -e "    ${CHECK_MARK} AppCleaner"
    else
        echo -e "    ${CROSS_MARK} AppCleaner"
    fi

    # Docker
    if app_installed "Docker"; then
        echo -e "    ${CHECK_MARK} Docker Desktop"
    else
        echo -e "    ${CROSS_MARK} Docker Desktop"
    fi

    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "    1. ${CYAN}Restart your terminal${NC} for all changes to take effect"
    echo ""

    if ! [ -d "$HOME/.dotfiles.git" ]; then
        echo -e "    2. ${CYAN}Set up dotfiles:${NC}"
        echo -e "       curl -fsSL https://raw.githubusercontent.com/andrew-tomago/dotfiles/main/.dotfiles-install.sh | bash"
        echo ""
    fi

    if ! gh auth status &> /dev/null 2>&1; then
        echo -e "    3. ${CYAN}Authenticate GitHub CLI:${NC}"
        echo -e "       gh auth login"
        echo ""
    fi

    if app_installed "Docker" && ! docker info &> /dev/null 2>&1; then
        echo -e "    4. ${CYAN}Start Docker Desktop:${NC}"
        echo -e "       Open Docker from Applications"
        echo ""
    fi

    echo ""
    echo -e "${BOLD}${GREEN}Setup complete! Happy coding! 🎉${NC}"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "macOS Development Environment Setup"

    echo -e "  ${INFO} Architecture: $(uname -m)"
    echo -e "  ${INFO} macOS Version: $(sw_vers -productVersion)"
    echo -e "  ${INFO} Homebrew Prefix: $(get_homebrew_prefix)"

    # Run installation steps in order
    install_xcode_cli_tools
    install_rosetta
    install_homebrew
    install_gnu_utils
    install_homebrew_packages
    install_homebrew_casks
    configure_zsh
    install_oh_my_zsh
    install_nvm
    install_npm_packages
    install_claude_code
    configure_github_cli
    configure_default_browser
    print_dotfiles_reminder
    print_summary
}

# Run main function
main "$@"
