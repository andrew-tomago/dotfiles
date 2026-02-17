#!/bin/bash
# =============================================================================
# setup-new-macbook.sh - Comprehensive macOS Development Environment Setup
# =============================================================================
#
# WHAT THIS DOES:
#   Sets up a fresh macOS with dev tools: Xcode CLI, Homebrew, Zsh, Node,
#   Docker, Claude Code, and more. Idempotent - safe to run multiple times.
#
# PREREQUISITES:
#   - macOS (tested on Sonoma+)
#   - Internet connection
#   - Admin account (for sudo)
#
# WILL PROMPT FOR:
#   - sudo password (Homebrew, Xcode, shell changes)
#   - Rosetta 2 license (Apple Silicon only)
#   - Chrome may open to set as default browser
#
# LONG-RUNNING STEPS:
#   - Xcode CLI Tools: 5-20 minutes (depends on connection)
#   - Homebrew install: 2-5 minutes
#   - Docker Desktop: 1-3 minutes download
#
# Installation Order (dependencies matter):
#   1. Xcode Command Line Tools (required for git, compilers)
#   2. Rosetta 2 (Apple Silicon only - required for some apps)
#   3. Homebrew (package manager)
#   4. GNU Core Utilities (modern CLI tools)
#   5. Homebrew CLI Packages (git, zsh, node, gh, etc.)
#   6. Modern CLI Tools Config (zoxide, lsd, bat, tealdeer post-install)
#   7. Homebrew Cask Applications (Raycast, Chrome, Docker, etc.)
#   8. Zsh Configuration (set Homebrew zsh as default)
#   9. Oh My Zsh (zsh framework)
#  10. NVM (Node version manager - optional, for multiple Node versions)
#  11. npm Global Packages (Codex)
#  12. Claude Config Repository (~/.claude from git)
#  13. Claude Code (AI coding assistant)
#  14. GitHub CLI Configuration
#  15. Default Browser Configuration (Chrome)
#
# Usage:
#   chmod +x setup-new-macbook.sh
#   ./setup-new-macbook.sh
#
# =============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# =============================================================================
# Error Handling
# =============================================================================

# Trap errors and provide context
trap 'print_error "Failed at line $LINENO: $BASH_COMMAND"' ERR

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
    "go"           # Go programming language
    "gh"           # GitHub CLI
    "jq"           # JSON processor
    "ripgrep"      # Fast grep alternative
    "ast-grep"     # Structural code search tool
    "fd"           # Fast find alternative
    "tree"         # Directory tree viewer
    "wget"         # Web file retriever
    "curl"         # URL transfer tool
    "zoxide"       # Smarter cd command (tracks frecency)
    "lsd"          # Modern ls with colors/icons
    "bat"          # Cat with syntax highlighting
    "tealdeer"     # Fast tldr pages client
    "uv"           # Fast Python package installer/resolver | Added: 2026-02-01 | Uninstall: brew uninstall uv
    "duckdb"       # Embeddable SQL OLAP database | Added: 2026-01-31 | Uninstall: brew uninstall duckdb
    "sqlite"       # SQLite CLI (keg-only) | Added: 2026-01-31 | Uninstall: brew uninstall sqlite
)

# Homebrew Cask applications
HOMEBREW_CASKS=(
    "raycast"          # Spotlight replacement
    "google-chrome"    # Web browser
    "appcleaner"       # App uninstaller
    "docker"           # Docker Desktop
    "discord"          # Community chat and voice
    "cursor"           # AI-powered code editor
    "linear-linear"    # Issue tracking and project management
    "granola"          # Meeting notes and transcription
    "obsidian"         # Knowledge base and note-taking
    "blackhole-2ch"    # Virtual audio driver (2-channel) | Added: 2026-02-16 | Uninstall: brew uninstall --cask blackhole-2ch
    # Note: Amphetamine (keep-awake utility) is Mac App Store only - install manually from App Store
)

# npm global packages
NPM_PACKAGES=(
    "@openai/codex"        # OpenAI Codex CLI
    "@openai/codex-sdk"    # OpenAI Codex SDK - programmatic agent control | Added: 2026-01-28 | Uninstall: npm uninstall -g @openai/codex-sdk
    "typescript"           # TypeScript compiler and language server | Added: 2026-02-13 | Uninstall: npm uninstall -g typescript
    "vercel"               # Vercel deployment CLI | Added: 2026-02-13 | Uninstall: npm uninstall -g vercel
)

# Go packages (installed via go install)
GO_PACKAGES=(
    "github.com/chrishrb/go-grip@latest"    # go-grip - Local GitHub-styled Markdown renderer | Added: 2026-01-28 | Uninstall: rm $(go env GOPATH)/bin/go-grip
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

# Centralized Homebrew requirement check
require_brew() {
    if ! command_exists brew; then
        print_error "Homebrew is required but not installed."
        print_info "Run the Homebrew installation step first."
        return 1
    fi
    return 0
}

brew_package_installed() {
    brew list --formula "$1" &> /dev/null 2>&1
}

# Map cask names to their .app names (cask name → app name without .app)
get_app_name_for_cask() {
    case "$1" in
        google-chrome)   echo "Google Chrome" ;;
        docker)          echo "Docker" ;;
        raycast)         echo "Raycast" ;;
        appcleaner)      echo "AppCleaner" ;;
        visual-studio-code) echo "Visual Studio Code" ;;
        slack)           echo "Slack" ;;
        discord)         echo "Discord" ;;
        spotify)         echo "Spotify" ;;
        zoom)            echo "Zoom" ;;
        firefox)         echo "Firefox" ;;
        iterm2)          echo "iTerm" ;;
        rectangle)       echo "Rectangle" ;;
        1password)       echo "1Password" ;;
        notion)          echo "Notion" ;;
        obsidian)        echo "Obsidian" ;;
        cursor)          echo "Cursor" ;;
        linear-linear)   echo "Linear" ;;
        granola)         echo "Granola" ;;
        # Default: capitalize first letter of each hyphenated word
        *)
            echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
            ;;
    esac
}

app_installed() {
    [ -d "/Applications/$1.app" ] || [ -d "$HOME/Applications/$1.app" ]
}

# Check if cask is installed via brew OR if app exists in Applications
brew_cask_installed() {
    local cask="$1"
    # First check if brew knows about it
    if brew list --cask "$cask" &> /dev/null 2>&1; then
        return 0
    fi
    # Fall back to checking Applications folder
    local app_name
    app_name=$(get_app_name_for_cask "$cask")
    app_installed "$app_name"
}

npm_package_installed() {
    npm list -g "$1" &> /dev/null 2>&1
}

# =============================================================================
# Package Installation Helper (with retry on failure for diagnostics)
# =============================================================================

# Install a brew formula, showing stderr only on failure
brew_install_formula() {
    local package="$1"
    local output
    local exit_code

    # First attempt - capture output
    if output=$(brew install "$package" 2>&1); then
        return 0
    else
        exit_code=$?
        # Show the error output on failure
        print_error "brew install $package failed:"
        echo "$output" >&2
        return $exit_code
    fi
}

# Install a brew cask, showing stderr only on failure
brew_install_cask() {
    local cask="$1"
    local output
    local exit_code

    # First attempt - capture output
    if output=$(brew install --cask "$cask" 2>&1); then
        return 0
    else
        exit_code=$?
        # Show the error output on failure
        print_error "brew install --cask $cask failed:"
        echo "$output" >&2
        return $exit_code
    fi
}

# Install an npm package, showing stderr only on failure
npm_install_global() {
    local package="$1"
    local output
    local exit_code

    # First attempt - capture output
    if output=$(npm install -g "$package" 2>&1); then
        return 0
    else
        exit_code=$?
        # Show the error output on failure
        print_error "npm install -g $package failed:"
        echo "$output" >&2
        return $exit_code
    fi
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
            print_info "Updates available - this may take several minutes..."
            sudo softwareupdate --install "Command Line Tools for Xcode" --agree-to-license || true
            print_success "Xcode CLI Tools updated"
        else
            print_info "Already up to date"
        fi
        return 0
    fi

    print_step "Installing Xcode Command Line Tools..."
    print_info "This may take 5-20 minutes depending on your connection"
    print_info "A dialog will appear - click 'Install' to proceed"

    # Trigger the install prompt
    xcode-select --install &> /dev/null || true

    # Wait for installation to complete
    print_step "Waiting for installation to complete (this takes a while)..."
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
    if /usr/bin/pgrep -q oahd 2>/dev/null; then
        print_success "Rosetta 2 already installed and running"
        return 0
    fi

    # Check if Rosetta binary exists
    if [ -f "/Library/Apple/usr/share/rosetta/rosetta" ]; then
        print_success "Rosetta 2 already installed"
        return 0
    fi

    print_step "Installing Rosetta 2 for Apple Silicon..."
    print_info "You may be prompted to agree to the license"
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
        print_info "This may take a minute..."
        brew update
        print_success "Homebrew updated"

        print_step "Upgrading installed packages..."
        print_info "This may take several minutes for large upgrades..."
        brew upgrade || true
        print_success "Packages upgraded"

        print_step "Running cleanup..."
        brew cleanup
        print_success "Cleanup complete"
        return 0
    fi

    print_step "Installing Homebrew..."
    print_info "This will take 2-5 minutes and requires your password"
    print_info "The installer may appear to hang - this is normal"

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

    require_brew || return 1

    print_info "Installing GNU utilities (these replace outdated macOS versions)"

    local installed=0
    local skipped=0

    for package in "${GNU_PACKAGES[@]}"; do
        if brew_package_installed "$package"; then
            print_info "$package already installed"
            ((skipped++))
        else
            print_step "Installing $package..."
            if brew_install_formula "$package"; then
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
    print_info "Summary: $installed installed, $skipped already present"
}

# =============================================================================
# Homebrew CLI Packages
# =============================================================================

install_homebrew_packages() {
    print_section "Homebrew CLI Packages"

    require_brew || return 1

    local installed=0
    local upgraded=0
    local failed=0

    for package in "${HOMEBREW_PACKAGES[@]}"; do
        if brew_package_installed "$package"; then
            print_info "$package already installed"
            # Check if upgrade available
            if brew outdated "$package" &> /dev/null; then
                print_step "Upgrading $package..."
                if brew upgrade "$package" 2>&1; then
                    print_success "$package upgraded"
                    ((upgraded++))
                fi
            fi
        else
            print_step "Installing $package..."
            if brew_install_formula "$package"; then
                print_success "$package installed"
                ((installed++))
            else
                print_error "Failed to install $package"
                ((failed++))
            fi
        fi
    done

    echo ""
    print_info "Summary: $installed installed, $upgraded upgraded, $failed failed"
}

# =============================================================================
# Go Packages (via go install)
# =============================================================================

install_go_packages() {
    print_section "Go Packages"

    if ! command_exists go; then
        print_warning "Go not installed. Skipping Go packages."
        return 0
    fi

    # Ensure GOPATH/bin is in PATH for current session
    export PATH="$(go env GOPATH)/bin:$PATH"

    local installed=0
    local skipped=0
    local failed=0

    for package in "${GO_PACKAGES[@]}"; do
        # Extract binary name from package path (last segment before @)
        local binary_name
        binary_name=$(echo "$package" | sed 's|.*/||; s|@.*||')

        if command_exists "$binary_name"; then
            print_info "$binary_name already installed"
            ((skipped++))
        else
            print_step "Installing $package..."
            if go install "$package" 2>&1; then
                print_success "$binary_name installed"
                ((installed++))
            else
                print_error "Failed to install $binary_name"
                ((failed++))
            fi
        fi
    done

    # Ensure GOPATH/bin is in shell profile
    if ! grep -q 'go/bin' "$HOME/.zshrc" 2>/dev/null; then
        print_step "Adding Go bin to PATH in .zshrc..."
        # Handled by dotfiles — just remind
        print_info "Add to .zshrc: export PATH=\"\$HOME/go/bin:\$PATH\""
    fi

    echo ""
    print_info "Summary: $installed installed, $skipped already present, $failed failed"
}

# =============================================================================
# Modern CLI Tools Configuration
# =============================================================================

configure_modern_cli_tools() {
    print_section "Modern CLI Tools Configuration"

    # tealdeer: Update cache for tldr pages
    if command_exists tldr; then
        print_step "Updating tealdeer cache..."
        if tldr --update &> /dev/null; then
            print_success "tealdeer cache updated"
        else
            print_warning "tealdeer cache update failed (run 'tldr --update' manually)"
        fi
    fi

    # zoxide: Print shell configuration reminder
    if command_exists zoxide; then
        print_info "zoxide installed - add to your .zshrc:"
        echo -e "    ${CYAN}eval \"\$(zoxide init zsh)\"${NC}"
    fi

    # lsd: Print optional alias info
    if command_exists lsd; then
        print_info "lsd installed - optional alias: alias ls='lsd'"
        print_info "For full icon support, install a Nerd Font"
    fi

    # bat: No configuration needed, just confirm
    if command_exists bat; then
        print_info "bat installed - use 'bat' instead of 'cat' for syntax highlighting"
    fi
}

# =============================================================================
# Homebrew Cask Applications
# =============================================================================

install_homebrew_casks() {
    print_section "Homebrew Cask Applications"

    require_brew || return 1

    print_info "Installing desktop applications (this may take a few minutes)..."

    local installed=0
    local skipped=0
    local failed=0

    for cask in "${HOMEBREW_CASKS[@]}"; do
        if brew_cask_installed "$cask"; then
            print_info "$cask already installed"
            ((skipped++))
        else
            print_step "Installing $cask..."
            # Docker is large, give extra notice
            if [[ "$cask" == "docker" ]]; then
                print_info "Docker Desktop is ~600MB - this may take 1-3 minutes..."
            fi
            if brew_install_cask "$cask"; then
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
        print_info "Using system zsh: $(command -v zsh || echo 'not found')"
        return 0
    fi

    print_success "Homebrew zsh found at $brew_zsh"

    # Check if it's already in /etc/shells
    if ! grep -q "$brew_zsh" /etc/shells; then
        print_step "Adding Homebrew zsh to /etc/shells (requires sudo)..."
        echo "$brew_zsh" | sudo tee -a /etc/shells > /dev/null
        print_success "Added to /etc/shells"
    else
        print_info "Already in /etc/shells"
    fi

    # Check current default shell
    if [ "${SHELL:-}" != "$brew_zsh" ]; then
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
    print_info "This will download and configure Oh My Zsh"

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

    # Ensure 80-macos.zsh exists with macOS-specific config
    local macos_config="$zshrc_d/80-macos.zsh"
    if [ -f "$macos_config" ]; then
        print_info "80-macos.zsh already exists"
    else
        print_step "Creating 80-macos.zsh..."
        cat > "$macos_config" << 'EOF'
# macOS-specific configuration
[[ ! "$OSTYPE" == darwin* ]] && return

# Homebrew (Apple Silicon or Intel)
if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Go binaries
export PATH="$HOME/go/bin:$PATH"

# Claude Code tool search
export ENABLE_TOOL_SEARCH=auto:5
EOF
        print_success "Created 80-macos.zsh"
    fi

    # Check if ENABLE_TOOL_SEARCH is configured somewhere in modules
    if grep -rq "ENABLE_TOOL_SEARCH" "$zshrc_d" 2>/dev/null; then
        print_success "ENABLE_TOOL_SEARCH already configured in modules"
    fi
}

# =============================================================================
# NVM (Node Version Manager) - Optional
# =============================================================================

install_nvm() {
    print_section "NVM (Node Version Manager)"

    print_info "NVM provides flexibility to switch between Node versions"
    print_info "Homebrew Node is also installed for general use"

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM already installed"

        # Source NVM for current session
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        local current_version
        current_version=$(nvm --version 2>/dev/null || echo 'unknown')
        print_step "Current version: $current_version"

        print_step "Checking for updates..."
        print_info "This will checkout the latest NVM release tag"

        # Update NVM by fetching latest tag
        (
            cd "$NVM_DIR"
            git fetch --tags origin
            local latest_tag
            latest_tag=$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")
            print_info "Moving NVM to latest tag: $latest_tag"
            git checkout "$latest_tag" --quiet
        ) && print_success "NVM updated to latest release" || print_warning "Update check failed"

        return 0
    fi

    print_step "Installing NVM $NVM_VERSION..."
    print_info "This will download and configure NVM"

    # Install NVM
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

    # Source NVM for current session
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if [ -d "$NVM_DIR" ]; then
        print_success "NVM installed"

        # Install latest LTS Node via NVM
        print_step "Installing latest LTS Node.js via NVM..."
        print_info "This may take a minute..."
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

    print_info "Using npm from: $(command -v npm)"
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
            if npm_install_global "$package"; then
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
# Claude Code
# =============================================================================

install_claude_code() {
    print_section "Claude Code"
    # Native installer — no Node.js dependency. Auto-updates in background.

    # Check if Claude Code is already installed
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

    # Install Claude Code
    curl -fsSL https://claude.ai/install.sh | bash

    # Verify installation
    if command_exists claude; then
        print_success "Claude Code installed"
        claude doctor 2>/dev/null || print_step "Version: $(claude --version 2>/dev/null || echo 'installed')"

        # Configure Claude Code environment
        configure_claude_code_env
    else
        # Claude might be installed but not in PATH yet
        if [ -f "$HOME/.claude/local/bin/claude" ]; then
            print_success "Claude Code installed (restart terminal to use)"
            # Still configure env for future use
            configure_claude_code_env
        else
            print_error "Claude Code installation may have failed"
            print_info "Try running manually: curl -fsSL https://claude.ai/install.sh | bash"
        fi
    fi
}

# Configure Claude Code environment variables
configure_claude_code_env() {
    local zshrc_d="$HOME/.zshrc.d"

    # Check if ENABLE_TOOL_SEARCH is configured in modular config
    if [ -d "$zshrc_d" ] && grep -rq "ENABLE_TOOL_SEARCH" "$zshrc_d" 2>/dev/null; then
        print_info "ENABLE_TOOL_SEARCH already configured in .zshrc.d modules"
        return 0
    fi

    # Fall back to checking .zshrc directly
    if [ -f "$HOME/.zshrc" ] && grep -q "ENABLE_TOOL_SEARCH" "$HOME/.zshrc" 2>/dev/null; then
        print_info "ENABLE_TOOL_SEARCH already configured in .zshrc"
        return 0
    fi

    print_info "ENABLE_TOOL_SEARCH will be configured when zshrc modules are set up"
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

    # Check if already authenticated and configure git credentials
    if gh auth status &> /dev/null; then
        print_success "Already authenticated with GitHub"
        gh auth status
        # Configure git to use gh for credential helper
        print_step "Configuring git credential helper..."
        gh auth setup-git
        print_success "Git credential helper configured"
    else
        print_info "GitHub CLI not authenticated"
        print_info "Run 'gh auth login' to authenticate with GitHub"
        print_info "Then run 'gh auth setup-git' to configure git credentials"
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
    print_info "Chrome will open - you may see a dialog to set it as default"
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
    if [ -d "${NVM_DIR:-$HOME/.nvm}" ]; then
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

    # Codex
    if command_exists npm && npm_package_installed "@openai/codex" 2>/dev/null; then
        echo -e "    ${CHECK_MARK} OpenAI Codex"
    else
        echo -e "    ${CROSS_MARK} OpenAI Codex"
    fi

    echo ""
    echo -e "  ${BOLD}GNU Core Utilities:${NC}"
    echo ""
    if command_exists brew; then
        for package in "${GNU_PACKAGES[@]}"; do
            if brew_package_installed "$package" 2>/dev/null; then
                echo -e "    ${CHECK_MARK} $package"
            else
                echo -e "    ${CROSS_MARK} $package"
            fi
        done
    else
        echo -e "    ${CROSS_MARK} (Homebrew not installed)"
    fi

    echo ""
    echo -e "  ${BOLD}Modern CLI Tools:${NC}"
    echo ""

    # zoxide
    if command_exists zoxide; then
        echo -e "    ${CHECK_MARK} zoxide (smarter cd)"
    else
        echo -e "    ${CROSS_MARK} zoxide"
    fi

    # lsd
    if command_exists lsd; then
        echo -e "    ${CHECK_MARK} lsd (modern ls)"
    else
        echo -e "    ${CROSS_MARK} lsd"
    fi

    # bat
    if command_exists bat; then
        echo -e "    ${CHECK_MARK} bat (syntax highlighting)"
    else
        echo -e "    ${CROSS_MARK} bat"
    fi

    # tealdeer (tldr command)
    if command_exists tldr; then
        echo -e "    ${CHECK_MARK} tealdeer (tldr pages)"
    else
        echo -e "    ${CROSS_MARK} tealdeer"
    fi

    echo ""
    echo -e "  ${BOLD}Go Tools:${NC}"
    echo ""

    # go-grip
    if command_exists go-grip || [ -f "$(go env GOPATH 2>/dev/null)/bin/go-grip" ]; then
        echo -e "    ${CHECK_MARK} go-grip (Markdown renderer)"
    else
        echo -e "    ${CROSS_MARK} go-grip"
    fi

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

    # Only check gh auth if gh is installed
    if command_exists gh; then
        if ! gh auth status &> /dev/null 2>&1; then
            echo -e "    3. ${CYAN}Authenticate GitHub CLI:${NC}"
            echo -e "       gh auth login"
            echo ""
        fi
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
    echo ""
    print_info "This script will prompt for sudo at various points."
    print_info "Long-running steps will be noted before they begin."

    # Run installation steps in order
    install_xcode_cli_tools
    install_rosetta
    install_homebrew
    install_gnu_utils
    install_homebrew_packages
    install_go_packages
    configure_modern_cli_tools
    install_homebrew_casks
    configure_zsh
    install_oh_my_zsh
    configure_zshrc_modules
    install_nvm
    install_npm_packages
    setup_claude_config
    install_claude_code
    configure_github_cli
    configure_default_browser
    print_dotfiles_reminder
    print_summary
}

# Run main function
main "$@"
