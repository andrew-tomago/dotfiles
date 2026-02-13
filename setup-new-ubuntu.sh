#!/bin/bash
# =============================================================================
# setup-new-ubuntu.sh - Comprehensive Ubuntu Development Environment Setup
# =============================================================================
#
# WHAT THIS DOES:
#   Sets up a fresh Ubuntu with dev tools: build essentials, Zsh, Node,
#   Docker, Claude Code, and more. Idempotent - safe to run multiple times.
#
# PREREQUISITES:
#   - Ubuntu (tested on 22.04+)
#   - Internet connection
#   - sudo access
#
# RECOMMENDED BEFORE RUNNING:
#   - Install Firefox (usually pre-installed on Ubuntu)
#   - Configure Firefox privacy settings (Enhanced Tracking Protection, etc.)
#   - Install LastPass browser extension for password management
#
# WILL PROMPT FOR:
#   - sudo password (apt, shell changes)
#
# Installation Order (dependencies matter):
#   1. System Update (apt update/upgrade)
#   2. Build Essentials (compilers, make, etc.)
#   3. Core CLI Packages (git, curl, wget, zsh, etc.)
#   4. Modern CLI Tools via apt (ripgrep, fd, bat, fzf)
#   5. Additional CLI Tools via manual install (zoxide, lsd, tealdeer)
#   6. Zsh Configuration (set as default shell)
#   7. Oh My Zsh (zsh framework)
#   8. GitHub CLI (needed for Claude config clone)
#   9. NVM + Node.js LTS
#  10. Claude Config Repository (~/.claude from git)
#  11. Claude Code (AI coding assistant)
#  12. Docker (via official repository — independent, heavy)
#  13. Wine (Windows compatibility layer via WineHQ)
#  14. Obsidian (Note-taking app via AppImage)
#  15. Cursor (AI-powered code editor via AppImage)
#  16. Snap Packages (Discord — independent, optional)
#
# Usage:
#   chmod +x setup-new-ubuntu.sh
#   ./setup-new-ubuntu.sh
#
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# Error Handling
# =============================================================================

trap 'print_error "Failed at line $LINENO: $BASH_COMMAND"' ERR

# =============================================================================
# Configuration - CUSTOMIZE THESE ARRAYS
# =============================================================================

# Build essentials and core development tools
BUILD_PACKAGES=(
    "build-essential"   # gcc, g++, make
    "git"
    "curl"
    "wget"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "software-properties-common"
)

# Core CLI packages (via apt)
APT_PACKAGES=(
    "zsh"
    "jq"               # JSON processor
    "tree"             # Directory tree viewer
    "htop"             # Process viewer
    "tmux"             # Terminal multiplexer
    "unzip"
    "zip"
    "nautilus-share"   # Samba folder sharing in Nautilus
)

# Modern CLI tools available via apt
MODERN_CLI_PACKAGES=(
    "ripgrep"          # Fast grep alternative (rg)
    "fd-find"          # Fast find alternative (fdfind -> fd)
    "bat"              # Cat with syntax highlighting (batcat -> bat)
    "fzf"              # Fuzzy finder
)

# Modern CLI tools requiring manual installation (not in apt or outdated)
# These will be installed via their official install scripts or cargo
MANUAL_CLI_TOOLS=(
    "zoxide"           # Smarter cd with frecency tracking
    "lsd"              # Modern ls with colors/icons
    "tealdeer"         # Fast tldr pages client
)

# Snap packages (optional GUI apps or tools not in apt)
SNAP_PACKAGES=(
    "discord"          # Community chat
)

# npm global packages
NPM_PACKAGES=(
    "@openai/codex"        # OpenAI Codex CLI | Added: 2026-02-13 | Uninstall: npm uninstall -g @openai/codex
    "@openai/codex-sdk"    # OpenAI Codex SDK - programmatic agent control | Added: 2026-02-13 | Uninstall: npm uninstall -g @openai/codex-sdk
    "@ast-grep/cli"        # Structural code search tool | Added: 2026-02-13 | Uninstall: npm uninstall -g @ast-grep/cli
    "typescript"           # TypeScript compiler and language server | Added: 2026-02-13 | Uninstall: npm uninstall -g typescript
    "vercel"               # Vercel deployment CLI | Added: 2026-02-13 | Uninstall: npm uninstall -g vercel
)

# NVM version to install
NVM_VERSION="v0.40.1"

# Node.js LTS version (used if installing via apt instead of NVM)
NODE_MAJOR_VERSION="20"

# =============================================================================
# Color & Output Helpers
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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
    echo -e "  ${CROSS_MARK} ${RED}$1${NC}" >&2
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

command_exists() {
    command -v "$1" &> /dev/null
}

apt_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

snap_package_installed() {
    snap list "$1" &> /dev/null 2>&1
}

npm_package_installed() {
    npm list -g "$1" &> /dev/null 2>&1
}

# =============================================================================
# System Update
# =============================================================================

update_system() {
    print_section "System Update"

    print_step "Updating package lists..."
    sudo apt update

    print_step "Upgrading installed packages..."
    sudo apt upgrade -y

    print_success "System updated"
}

# =============================================================================
# Build Essentials
# =============================================================================

install_build_essentials() {
    print_section "Build Essentials"

    local installed=0
    local skipped=0

    for package in "${BUILD_PACKAGES[@]}"; do
        if apt_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++)) || true
        else
            print_step "Installing $package..."
            if sudo apt install -y "$package"; then
                print_success "$package installed"
                ((installed++)) || true
            else
                print_error "Failed to install $package"
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $skipped already present"
}

# =============================================================================
# Core CLI Packages
# =============================================================================

install_apt_packages() {
    print_section "Core CLI Packages"

    local installed=0
    local skipped=0

    for package in "${APT_PACKAGES[@]}"; do
        if apt_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++)) || true
        else
            print_step "Installing $package..."
            if sudo apt install -y "$package"; then
                print_success "$package installed"
                ((installed++)) || true
            else
                print_error "Failed to install $package"
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $skipped already present"
}

# =============================================================================
# Modern CLI Tools
# =============================================================================

install_modern_cli_tools() {
    print_section "Modern CLI Tools"

    local installed=0
    local skipped=0

    for package in "${MODERN_CLI_PACKAGES[@]}"; do
        if apt_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++)) || true
        else
            print_step "Installing $package..."
            if sudo apt install -y "$package"; then
                print_success "$package installed"
                ((installed++)) || true
            else
                print_error "Failed to install $package"
            fi
        fi
    done

    # Create convenience symlinks for Ubuntu's renamed binaries
    configure_modern_cli_aliases

    echo ""
    print_info "Summary: $installed installed, $skipped already present"
}

configure_modern_cli_aliases() {
    print_step "Configuring CLI tool aliases..."

    # fd-find installs as 'fdfind' on Ubuntu
    if command_exists fdfind && ! command_exists fd; then
        print_info "Creating symlink: fd -> fdfind"
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd 2>/dev/null || \
            print_warning "Could not create fd symlink (add alias to shell config)"
    fi

    # bat installs as 'batcat' on Ubuntu
    if command_exists batcat && ! command_exists bat; then
        print_info "Creating symlink: bat -> batcat"
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat 2>/dev/null || \
            print_warning "Could not create bat symlink (add alias to shell config)"
    fi
}

# =============================================================================
# Manual CLI Tools (zoxide, lsd, tealdeer)
# =============================================================================

install_manual_cli_tools() {
    print_section "Additional CLI Tools (Manual Install)"

    # zoxide - smarter cd
    if command_exists zoxide; then
        print_info "zoxide already installed"
    else
        print_step "Installing zoxide..."
        if curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
            print_success "zoxide installed"
            print_info "Add to your shell config: eval \"\$(zoxide init bash)\" or eval \"\$(zoxide init zsh)\""
        else
            print_error "Failed to install zoxide"
        fi
    fi

    # lsd - modern ls
    if command_exists lsd; then
        print_info "lsd already installed"
    else
        print_step "Installing lsd..."
        local lsd_version="1.1.5"
        local lsd_deb="lsd_${lsd_version}_amd64.deb"
        local arch=$(dpkg --print-architecture)
        if [ "$arch" = "arm64" ]; then
            lsd_deb="lsd_${lsd_version}_arm64.deb"
        fi
        if curl -fsSLO "https://github.com/lsd-rs/lsd/releases/download/v${lsd_version}/${lsd_deb}" && \
           sudo dpkg -i "$lsd_deb" && \
           rm -f "$lsd_deb"; then
            print_success "lsd installed"
            print_info "Optional alias: alias ls='lsd'"
        else
            print_error "Failed to install lsd"
            rm -f "$lsd_deb" 2>/dev/null
        fi
    fi

    # tealdeer - fast tldr
    if command_exists tldr; then
        print_info "tealdeer already installed"
    else
        print_step "Installing tealdeer..."
        local tldr_version="1.7.1"
        local tldr_bin="tealdeer-linux-x86_64-musl"
        local arch=$(dpkg --print-architecture)
        if [ "$arch" = "arm64" ]; then
            tldr_bin="tealdeer-linux-arm64-musl"
        fi
        if curl -fsSL "https://github.com/tealdeer-rs/tealdeer/releases/download/v${tldr_version}/${tldr_bin}" -o /tmp/tldr && \
           chmod +x /tmp/tldr && \
           sudo mv /tmp/tldr /usr/local/bin/tldr; then
            print_success "tealdeer installed"
            print_step "Updating tldr cache..."
            tldr --update || print_warning "Cache update failed (run 'tldr --update' manually)"
        else
            print_error "Failed to install tealdeer"
        fi
    fi
}

# =============================================================================
# Snap Packages (Optional)
# =============================================================================

install_snap_packages() {
    print_section "Snap Packages"

    if [ ${#SNAP_PACKAGES[@]} -eq 0 ]; then
        print_info "No snap packages configured"
        return 0
    fi

    if ! command_exists snap; then
        print_warning "Snap not installed. Skipping snap packages."
        return 0
    fi

    # Refresh snap cache to ensure fresh metadata
    print_step "Refreshing snap cache..."
    sudo snap refresh 2>/dev/null || print_info "Snap refresh skipped (may auto-update later)"

    local installed=0
    local skipped=0

    for package in "${SNAP_PACKAGES[@]}"; do
        # Extract package name (first word, before any flags)
        local pkg_name
        pkg_name=$(echo "$package" | awk '{print $1}')

        if snap_package_installed "$pkg_name"; then
            print_info "$pkg_name already installed"
            ((skipped++)) || true
        else
            print_step "Installing $package..."
            if sudo snap install $package; then
                print_success "$pkg_name installed"
                ((installed++)) || true
            else
                print_error "Failed to install $pkg_name"
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $skipped already present"
}

# =============================================================================
# Zsh Configuration
# =============================================================================

configure_zsh() {
    print_section "Zsh Configuration"

    if ! command_exists zsh; then
        print_warning "Zsh not installed. Installing..."
        sudo apt install -y zsh
    fi

    print_success "Zsh installed: $(zsh --version)"

    # Check current default shell
    if [ "${SHELL:-}" != "$(which zsh)" ]; then
        print_step "Setting zsh as default shell..."
        if sudo chsh -s "$(which zsh)" "$USER"; then
            print_success "Default shell changed to zsh"
            print_warning "Please log out and back in for changes to take effect"
        else
            print_warning "Could not change shell automatically"
            print_info "Run manually: chsh -s $(which zsh)"
        fi
    else
        print_info "Zsh is already the default shell"
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
        (
            cd "$HOME/.oh-my-zsh"
            git pull --quiet origin master
        ) && print_success "Oh My Zsh updated" || print_warning "Update check failed"
    else
        print_step "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

        if [ -d "$HOME/.oh-my-zsh" ]; then
            print_success "Oh My Zsh installed"
        else
            print_error "Oh My Zsh installation failed"
            return 1
        fi
    fi

    # Fix insecure directory permissions (prevents compaudit warnings)
    print_step "Fixing Oh My Zsh directory permissions..."
    find "$HOME/.oh-my-zsh" -type d -perm /go+w -exec chmod g-w,o-w {} \; 2>/dev/null
    print_success "Permissions fixed"
}

# =============================================================================
# Zshrc Modules Configuration
# =============================================================================

configure_zshrc_modules() {
    print_section "Zshrc Modules Configuration"

    local zshrc_d="$HOME/.zshrc.d"

    # Create .zshrc.d directory if it doesn't exist
    if [ ! -d "$zshrc_d" ]; then
        print_step "Creating $zshrc_d directory..."
        mkdir -p "$zshrc_d"
        print_success "Created $zshrc_d"
    else
        print_info "$zshrc_d directory already exists"
    fi

    # Check if .zshrc is the modular loader (look for ZSHRC_D pattern)
    if [ -f "$HOME/.zshrc" ] && grep -q 'ZSHRC_D' "$HOME/.zshrc" 2>/dev/null; then
        print_success "Modular .zshrc loader already configured"
    else
        print_warning ".zshrc is not using modular loader"
        print_info "If you have dotfiles configured, run: config checkout"
        print_info "Otherwise, update .zshrc manually to source .zshrc.d/*.zsh"
    fi

    # Ensure 85-linux.zsh exists with Linux-specific config
    local linux_config="$zshrc_d/85-linux.zsh"
    if [ -f "$linux_config" ]; then
        print_info "85-linux.zsh already exists"
    else
        print_step "Creating 85-linux.zsh..."
        cat > "$linux_config" << 'EOF'
# Linux-specific configuration
[[ ! "$OSTYPE" == linux-gnu* ]] && return

# fd-find / bat fallbacks (Ubuntu renames these packages)
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'

# Claude Code tool search
export ENABLE_TOOL_SEARCH=auto:5
EOF
        print_success "Created 85-linux.zsh"
    fi

    # Check if ENABLE_TOOL_SEARCH is configured somewhere
    if grep -rq "ENABLE_TOOL_SEARCH" "$zshrc_d" 2>/dev/null; then
        print_success "ENABLE_TOOL_SEARCH already configured in modules"
    fi
}

# =============================================================================
# NVM (Node Version Manager)
# =============================================================================

install_nvm() {
    print_section "NVM (Node Version Manager)"

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM already installed"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        print_step "Current NVM version: $(nvm --version 2>/dev/null || echo 'unknown')"
        print_step "Checking for NVM updates..."
        (
            cd "$NVM_DIR"
            git fetch --tags origin
            local latest_tag
            latest_tag=$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")
            git checkout "$latest_tag" --quiet
        ) && print_success "NVM updated" || print_warning "NVM update check failed"

        # Reload NVM after update
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Update Node.js to latest LTS
        print_step "Current Node.js version: $(node --version 2>/dev/null || echo 'none')"
        print_step "Installing latest LTS Node.js..."
        if nvm install --lts; then
            nvm alias default 'lts/*'
            print_success "Node.js updated to latest LTS: $(nvm current)"
        else
            print_warning "Failed to update Node.js"
        fi
        return 0
    fi

    print_step "Installing NVM $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM installed"
        print_step "Installing latest LTS Node.js..."
        nvm install --lts
        nvm alias default 'lts/*'
        print_success "Node.js LTS installed: $(nvm current)"
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

    if [ ${#NPM_PACKAGES[@]} -eq 0 ]; then
        print_info "No npm packages configured"
        return 0
    fi

    if ! command_exists npm; then
        print_error "npm not found. Skipping npm packages."
        return 1
    fi

    print_info "Using npm from: $(command -v npm)"
    print_info "Node version: $(node --version)"

    local installed=0
    local skipped=0

    for package in "${NPM_PACKAGES[@]}"; do
        if npm_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++)) || true
        else
            print_step "Installing $package..."
            if npm install -g "$package"; then
                print_success "$package installed"
                ((installed++)) || true
            else
                print_error "Failed to install $package"
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $skipped already present"
}

# =============================================================================
# Docker
# =============================================================================

install_docker() {
    print_section "Docker"

    if command_exists docker; then
        print_success "Docker already installed: $(docker --version)"
        print_step "Checking Docker service..."
        if sudo systemctl is-active --quiet docker; then
            print_success "Docker service is running"
        else
            print_step "Starting Docker service..."
            sudo systemctl start docker
            sudo systemctl enable docker
            print_success "Docker service started and enabled"
        fi
        return 0
    fi

    print_step "Installing Docker via official repository..."

    # Add Docker's official GPG key
    print_step "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository
    print_step "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    print_step "Installing Docker packages..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    print_step "Adding user to docker group..."
    sudo usermod -aG docker "$USER"

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    print_success "Docker installed"
    print_warning "Log out and back in for docker group membership to take effect"
}

# =============================================================================
# GitHub CLI
# =============================================================================

install_github_cli() {
    print_section "GitHub CLI"

    if command_exists gh; then
        print_success "GitHub CLI already installed: $(gh --version | head -n1)"
    else
        print_step "Installing GitHub CLI..."

        # Add GitHub CLI repository
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

        sudo apt update
        sudo apt install -y gh

        print_success "GitHub CLI installed"
    fi

    # Check auth status and configure git credentials
    if gh auth status &> /dev/null; then
        print_success "Already authenticated with GitHub"
        gh auth status
        # Configure git to use gh for credential helper
        print_step "Configuring git credential helper..."
        gh auth setup-git
        print_success "Git credential helper configured"
    else
        print_info "GitHub CLI not authenticated"
        print_info "Run 'gh auth login' to authenticate"
        print_info "Then run 'gh auth setup-git' to configure git credentials"
    fi
}

# =============================================================================
# Claude Config Repository
# =============================================================================

setup_claude_config() {
    print_section "Claude Config Repository"

    local claude_config_dir="$HOME/.claude"
    local claude_config_repo="https://github.com/andrew-tomago/.claude.git"

    # Already cloned — pull latest
    if [ -d "$claude_config_dir/.git" ]; then
        print_success "Claude config repo already cloned"
        print_step "Pulling latest changes..."
        if (cd "$claude_config_dir" && git pull --quiet); then
            print_success "Claude config updated"
        else
            print_warning "Could not pull updates (check connectivity/auth)"
        fi
        return 0
    fi

    # Directory exists without git — don't clobber
    if [ -d "$claude_config_dir" ]; then
        print_warning "$claude_config_dir exists without git history — skipping clone"
        print_info "To set up manually:"
        print_info "  mv $claude_config_dir ${claude_config_dir}.bak"
        print_info "  git clone $claude_config_repo $claude_config_dir"
        print_info "  cp -rn ${claude_config_dir}.bak/* $claude_config_dir/"
        return 0
    fi

    # Fresh clone
    print_step "Cloning Claude config repository..."
    if git clone "$claude_config_repo" "$claude_config_dir"; then
        print_success "Claude config repo cloned to $claude_config_dir"
    else
        print_error "Failed to clone Claude config repo"
        if command_exists gh && ! gh auth status &> /dev/null 2>&1; then
            print_info "GitHub CLI not authenticated — run 'gh auth login' then re-run"
        else
            print_info "Ensure you have access to $claude_config_repo"
        fi
        return 1
    fi
}

# =============================================================================
# Wine (Windows Compatibility Layer)
# =============================================================================

install_wine() {
    print_section "Wine (Windows Compatibility Layer)"

    if command_exists wine; then
        print_success "Wine already installed: $(wine --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    print_step "Installing Wine via WineHQ repository..."

    # Enable 32-bit architecture (required for Wine)
    print_step "Enabling 32-bit architecture support..."
    sudo dpkg --add-architecture i386

    # Download and add WineHQ GPG key (convert to binary format)
    print_step "Adding WineHQ GPG key..."
    sudo mkdir -pm755 /etc/apt/keyrings
    wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/winehq-archive.key

    # Add WineHQ repository
    print_step "Adding WineHQ repository..."
    local ubuntu_version
    ubuntu_version=$(lsb_release -cs)
    sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${ubuntu_version}/winehq-${ubuntu_version}.sources"

    # Update package list and install Wine
    print_step "Installing Wine packages..."
    sudo apt update
    sudo apt install -y --install-recommends winehq-stable

    if command_exists wine; then
        print_success "Wine installed: $(wine --version)"
        print_info "Run 'winecfg' to configure Wine for the first time"
    else
        print_error "Wine installation failed"
        print_info "Visit https://gitlab.winehq.org/wine/wine/-/wikis/Download for manual installation"
        return 1
    fi
}

# =============================================================================
# Obsidian (Note-taking app)
# =============================================================================

install_obsidian() {
    print_section "Obsidian (Note-taking App)"

    local install_dir="$HOME/.local/bin"
    local obsidian_path="$install_dir/obsidian"

    if [ -f "$obsidian_path" ]; then
        print_success "Obsidian already installed"
        print_step "Installed at: $obsidian_path"
        return 0
    fi

    print_step "Installing Obsidian AppImage..."

    # Install FUSE library (required for AppImages)
    if ! apt_package_installed "libfuse2t64"; then
        print_step "Installing libfuse2t64 (required for AppImages)..."
        sudo apt install -y libfuse2t64
        print_success "libfuse2t64 installed"
    else
        print_info "libfuse2t64 already installed"
    fi

    # Create installation directory
    mkdir -p "$install_dir"

    # Get latest release info from GitHub API
    print_step "Fetching latest version..."
    local latest_url
    local arch=$(uname -m)

    if [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then
        latest_url=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | \
                     grep -o 'https://.*arm64\.AppImage' | head -1)
    else
        latest_url=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | \
                     grep -o 'https://.*\.AppImage' | grep -v 'arm64' | head -1)
    fi

    if [ -z "$latest_url" ]; then
        print_error "Could not find Obsidian AppImage download URL"
        return 1
    fi

    local version=$(echo "$latest_url" | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
    print_step "Downloading Obsidian v${version}..."

    if curl -fsSL "$latest_url" -o "$obsidian_path"; then
        chmod +x "$obsidian_path"
        print_success "Obsidian v${version} installed to $obsidian_path"

        # Create desktop entry
        print_step "Creating desktop entry..."
        local desktop_file="$HOME/.local/share/applications/obsidian.desktop"
        mkdir -p "$(dirname "$desktop_file")"
        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Obsidian
Exec=$obsidian_path --no-sandbox %u
Terminal=false
Type=Application
Icon=obsidian
StartupWMClass=obsidian
Comment=Obsidian - A knowledge base that works on local Markdown files
Categories=Office;
MimeType=x-scheme-handler/obsidian;
EOF
        print_success "Desktop entry created"
        print_info "Launch from applications menu or run: obsidian --no-sandbox"
    else
        print_error "Failed to download Obsidian"
        return 1
    fi
}

# =============================================================================
# Cursor (AI-powered Code Editor)
# =============================================================================

install_cursor() {
    print_section "Cursor (AI-powered Code Editor)"

    if command_exists cursor; then
        print_success "Cursor already installed"
        print_step "Version: $(cursor --version 2>/dev/null | head -n1 || echo 'unknown')"
        return 0
    fi

    print_step "Installing Cursor via .deb package..."

    # Cursor provides direct download links from their CDN
    # They use a standard naming pattern for their Linux builds
    local arch=$(dpkg --print-architecture)
    local download_url

    if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
        download_url="https://downloader.cursor.sh/linux/appImage/arm64"
        print_warning "ARM64 detected - using AppImage method"

        local install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"

        print_step "Downloading Cursor AppImage..."
        if curl -fsSL "$download_url" -o "$install_dir/cursor"; then
            chmod +x "$install_dir/cursor"
            print_success "Cursor installed to $install_dir/cursor"

            # Create desktop entry
            print_step "Creating desktop entry..."
            local desktop_file="$HOME/.local/share/applications/cursor.desktop"
            mkdir -p "$(dirname "$desktop_file")"
            cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Cursor
Exec=$install_dir/cursor --no-sandbox %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=AI-powered code editor
Categories=Development;IDE;
MimeType=text/plain;
EOF
            print_success "Desktop entry created"
            print_info "Launch from applications menu or run: cursor"
        else
            print_error "Failed to download Cursor"
            return 1
        fi
    else
        # AMD64 - use .deb package
        download_url="https://downloader.cursor.sh/linux/appImage/x64"

        # For AMD64, try to download the .deb if available
        # Otherwise fall back to AppImage
        local temp_deb="/tmp/cursor.deb"

        print_step "Downloading Cursor for AMD64..."
        # Try the AppImage URL first since it's more reliable
        if curl -fsSL "$download_url" -o "$HOME/.local/bin/cursor"; then
            chmod +x "$HOME/.local/bin/cursor"
            print_success "Cursor installed (AppImage)"

            # Create desktop entry
            print_step "Creating desktop entry..."
            local desktop_file="$HOME/.local/share/applications/cursor.desktop"
            mkdir -p "$(dirname "$desktop_file")"
            cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Cursor
Exec=$HOME/.local/bin/cursor --no-sandbox %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=AI-powered code editor
Categories=Development;IDE;
MimeType=text/plain;
EOF
            print_success "Desktop entry created"
            print_info "Launch from applications menu or run: cursor"
        else
            print_error "Failed to download Cursor"
            return 1
        fi
    fi
}

# =============================================================================
# Claude Code
# =============================================================================

install_claude_code() {
    print_section "Claude Code"
    # Native installer — no Node.js dependency. Auto-updates in background.

    if command_exists claude; then
        print_success "Claude Code already installed"
        claude doctor 2>/dev/null || print_step "Version: $(claude --version 2>/dev/null || echo 'unknown')"

        print_step "Checking for updates..."
        claude update 2>/dev/null || print_info "Run 'claude update' to check for updates"

        # Add ENABLE_TOOL_SEARCH if not already present
        configure_claude_code_env
        return 0
    fi

    print_step "Installing Claude Code via native installer..."
    curl -fsSL https://claude.ai/install.sh | bash

    if command_exists claude || [ -f "$HOME/.claude/local/bin/claude" ]; then
        print_success "Claude Code installed"
        claude doctor 2>/dev/null || true

        # Configure Claude Code environment
        configure_claude_code_env
    else
        print_error "Claude Code installation may have failed"
        print_info "Try running manually: curl -fsSL https://claude.ai/install.sh | bash"
    fi
}

# Configure Claude Code environment variables
configure_claude_code_env() {
    local zshrc_d="$HOME/.zshrc.d"

    if [ -d "$zshrc_d" ] && grep -rq "ENABLE_TOOL_SEARCH" "$zshrc_d" 2>/dev/null; then
        print_info "ENABLE_TOOL_SEARCH already configured in .zshrc.d modules"
        return 0
    fi

    if [ -f "$HOME/.zshrc" ] && grep -q "ENABLE_TOOL_SEARCH" "$HOME/.zshrc" 2>/dev/null; then
        print_info "ENABLE_TOOL_SEARCH already configured in .zshrc"
        return 0
    fi

    print_info "ENABLE_TOOL_SEARCH will be configured when zshrc modules are set up"
}

# =============================================================================
# Dotfiles Reminder
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
        echo -e "  ${CYAN}gh repo clone andrew-tomago/dotfiles /tmp/dotfiles && /tmp/dotfiles/.dotfiles-install.sh${NC}"
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

    # Build essentials
    if apt_package_installed "build-essential"; then
        echo -e "    ${CHECK_MARK} Build Essentials"
    else
        echo -e "    ${CROSS_MARK} Build Essentials"
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

    # NVM
    if [ -d "${NVM_DIR:-$HOME/.nvm}" ]; then
        echo -e "    ${CHECK_MARK} NVM"
    else
        echo -e "    ${CROSS_MARK} NVM"
    fi

    # Node
    if command_exists node; then
        echo -e "    ${CHECK_MARK} Node.js ($(node --version))"
    else
        echo -e "    ${CROSS_MARK} Node.js"
    fi

    # Docker
    if command_exists docker; then
        echo -e "    ${CHECK_MARK} Docker ($(docker --version | cut -d' ' -f3 | tr -d ','))"
    else
        echo -e "    ${CROSS_MARK} Docker"
    fi

    # Wine
    if command_exists wine; then
        echo -e "    ${CHECK_MARK} Wine ($(wine --version 2>/dev/null | cut -d'-' -f2))"
    else
        echo -e "    ${CROSS_MARK} Wine"
    fi

    echo ""
    echo -e "  ${BOLD}Applications:${NC}"
    echo ""

    # Obsidian
    if [ -f "$HOME/.local/bin/obsidian" ]; then
        echo -e "    ${CHECK_MARK} Obsidian"
    else
        echo -e "    ${CROSS_MARK} Obsidian"
    fi

    # Cursor
    if command_exists cursor || [ -f "$HOME/.local/bin/cursor" ]; then
        echo -e "    ${CHECK_MARK} Cursor"
    else
        echo -e "    ${CROSS_MARK} Cursor"
    fi

    echo ""
    echo -e "  ${BOLD}CLI Tools:${NC}"
    echo ""

    # GitHub CLI
    if command_exists gh; then
        echo -e "    ${CHECK_MARK} GitHub CLI"
    else
        echo -e "    ${CROSS_MARK} GitHub CLI"
    fi

    # Claude Config
    if [ -d "$HOME/.claude/.git" ]; then
        echo -e "    ${CHECK_MARK} Claude Config (~/.claude repo)"
    else
        echo -e "    ${CROSS_MARK} Claude Config (~/.claude repo)"
    fi

    # Claude Code
    if command_exists claude || [ -f "$HOME/.claude/local/bin/claude" ]; then
        echo -e "    ${CHECK_MARK} Claude Code"
    else
        echo -e "    ${CROSS_MARK} Claude Code"
    fi

    # ripgrep
    if command_exists rg; then
        echo -e "    ${CHECK_MARK} ripgrep"
    else
        echo -e "    ${CROSS_MARK} ripgrep"
    fi

    # fd
    if command_exists fd || command_exists fdfind; then
        echo -e "    ${CHECK_MARK} fd"
    else
        echo -e "    ${CROSS_MARK} fd"
    fi

    # bat
    if command_exists bat || command_exists batcat; then
        echo -e "    ${CHECK_MARK} bat"
    else
        echo -e "    ${CROSS_MARK} bat"
    fi

    # fzf
    if command_exists fzf; then
        echo -e "    ${CHECK_MARK} fzf"
    else
        echo -e "    ${CROSS_MARK} fzf"
    fi

    # zoxide
    if command_exists zoxide; then
        echo -e "    ${CHECK_MARK} zoxide"
    else
        echo -e "    ${CROSS_MARK} zoxide"
    fi

    # lsd
    if command_exists lsd; then
        echo -e "    ${CHECK_MARK} lsd"
    else
        echo -e "    ${CROSS_MARK} lsd"
    fi

    # tealdeer
    if command_exists tldr; then
        echo -e "    ${CHECK_MARK} tealdeer (tldr)"
    else
        echo -e "    ${CROSS_MARK} tealdeer (tldr)"
    fi

    echo ""
    echo -e "  ${BOLD}GUI Applications:${NC}"
    echo ""

    # Cursor
    if command_exists cursor || [ -f "$HOME/.local/bin/cursor" ]; then
        echo -e "    ${CHECK_MARK} Cursor IDE"
    else
        echo -e "    ${CROSS_MARK} Cursor IDE"
    fi

    echo ""
    echo -e "  ${BOLD}Snap Applications:${NC}"
    echo ""

    # Discord
    if snap_package_installed "discord"; then
        echo -e "    ${CHECK_MARK} Discord"
    else
        echo -e "    ${CROSS_MARK} Discord"
    fi

    # Obsidian
    if snap_package_installed "obsidian"; then
        echo -e "    ${CHECK_MARK} Obsidian"
    else
        echo -e "    ${CROSS_MARK} Obsidian"
    fi

    echo ""
    echo -e "  ${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "    1. ${CYAN}Log out and back in${NC} for shell and group changes"
    echo ""

    if ! [ -d "$HOME/.dotfiles.git" ]; then
        echo -e "    2. ${CYAN}Set up dotfiles${NC} (see above)"
        echo ""
    fi

    if command_exists gh && ! gh auth status &> /dev/null 2>&1; then
        echo -e "    3. ${CYAN}Authenticate GitHub CLI:${NC} gh auth login"
        echo ""
    fi

    echo ""
    echo -e "${BOLD}${GREEN}Setup complete! Happy coding!${NC}"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "Ubuntu Development Environment Setup"

    echo -e "  ${INFO} Architecture: $(uname -m)"
    echo -e "  ${INFO} Ubuntu Version: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "  ${INFO} Kernel: $(uname -r)"
    echo ""
    print_info "This script will prompt for sudo at various points."

    # Run installation steps in order
    update_system
    install_build_essentials
    install_apt_packages
    install_modern_cli_tools
    install_manual_cli_tools
    configure_zsh
    install_oh_my_zsh
    configure_zshrc_modules
    install_github_cli
    install_nvm
    install_npm_packages
    setup_claude_config
    install_claude_code
    install_docker
    install_wine
    install_obsidian
<<<<<<< HEAD
    install_cursor
    install_snap_packages
||||||| parent of 1066efc (feat(ubuntu): add Cursor IDE installer)
    install_claude_code
=======
    install_cursor
    install_claude_code
>>>>>>> 1066efc (feat(ubuntu): add Cursor IDE installer)
    print_dotfiles_reminder
    print_summary
}

# Run main function
main "$@"
