# (Config) Dotfiles Repo

Personal dotfiles managed with bare git repository method.

## Fresh Installation

```bash
curl -Lks https://raw.githubusercontent.com/andrew-tomago/dotfiles/main/.dotfiles-install.sh | bash
```

Or manually:

```bash
git clone --bare https://github.com/andrew-tomago/dotfiles.git $HOME/.dotfiles.git
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME"
# The repository is configured to hide untracked files. Without this, `config status` would show every file in your home directory:
config config --local status.showUntrackedFiles no
config checkout
```

## Daily Usage

```bash
config status          # Check for changes
config add .zshrc      # Stage a file
config commit -m "msg" # Commit changes
config push            # Push to remote
config pull            # Pull updates
```

Pre-commit hook prevents accidental commits of sensitive files.

### Convenience Aliases

These are automatically added to `.zshrc`:

```bash
cs       # config status
ca       # config add
ccom     # config commit
cpush    # config push
clist    # config ls-tree -r main --name-only
```

## Currently Tracked Files

- `.zshrc` - Shell config, aliases, NVM
- `.gitconfig` - Git settings, gh auth
- `.gitignore` - Dotfiles whitelist rules
- `.gitignore_global` - Global ignores
- `.dotfiles-install.sh` - Bootstrap script
- `setup-new-macbook.sh` - macOS dev environment setup
- `README.md` - Documentation

### Important: MacBook Setup Synchronization

Changes to `setup-new-macbook.sh` must be kept in sync with the **MacBook Setup Checklist Gist**: https://gist.github.com/andrew-tomago/35d217aa12f387c529ed188facc3d212

When adding/removing tools from `setup-new-macbook.sh`, update the gist accordingly.

## Directory Management Guide

| Directory/File Pattern | Description | Status |
|------------------------|-------------|--------|
| `.ssh/` | SSH keys and authorized_keys | Never tracked - protected |
| `.aws/` | AWS credentials and configuration | Never tracked - protected |
| `.docker/` | Docker credentials and context | Never tracked - protected |
| `.gnupg/` | GPG keys | Never tracked - protected |
| `.claude.json` | Claude API credentials | Never tracked - protected |
| `*.pem` | PEM certificate files | Never tracked - protected |
| `*.key` | Private key files | Never tracked - protected |
| `*_rsa` | RSA key files | Never tracked - protected |
| `*.p12` | PKCS#12 certificate files | Never tracked - protected |
| `*.credentials` | Credential files | Never tracked - protected |
| `.oh-my-zsh/` | Oh My Zsh framework (reinstall on new machines) | Excluded |
| `.nvm/` | Node Version Manager (reinstall on new machines) | Excluded |
| `.npm/` | npm cache | Excluded |
| `.cache/` | Application cache files | Excluded |
| `.local/` | Local application data | Excluded |
| `.Trash/` | System trash | Excluded |
| `.DS_Store` | macOS Finder metadata | Excluded |
| `.zsh_sessions/` | Zsh session data | Excluded |
| `.zsh_history` | Command history (may contain sensitive data) | Excluded |
| `.viminfo` | Vim session info | Excluded |
| `.CFUserTextEncoding` | System encoding file | Excluded |
| `go/` | Go workspace (GOPATH: packages, binaries) | Excluded |

#### Separate Git Repositories

- **`.claude/`** - Claude Code workflows separately versioned
  - [Repository](https://github.com/andrew-tomago/.claude) Install: `git clone https://github.com/andrew-tomago/.claude.git ~/.claude`

### How to Add New Configurations

1. **Inspect the file first:**
   ```bash
   cat ~/.newconfig  # Make sure no secrets!
   ```

2. **Update `.gitignore` to whitelist:**
   ```bash
   vim ~/.gitignore
   # Add: !.newconfig
   ```

3. **Stage, verify, and commit:**
   ```bash
   config add .newconfig
   config diff --cached     # Review changes
   config status           # Verify what's staged
   config commit -m "Add newconfig"
   config push
   ```

### Example: Tracking .config Subdirectories

For selective tracking within `.config/`:

```bash
# Edit .gitignore
vim ~/.gitignore

# Add these lines:
!.config/
!.config/gh/
!.config/gh/**
!.config/starship.toml

# Stage the configs
config add .config/gh/
config add .config/starship.toml
config commit -m "Add gh CLI and Starship configs"
config push
```

### Adding New Files Safely

Always verify before committing:

```bash
config add <file>       # Add the file
config status           # Verify what's staged
config diff --cached    # See exact changes
config commit -m "msg"  # Commit if safe
```

## Bare Git Repository Method

### Why This Method?

- ✅ No `.git` folder cluttering home directory
- ✅ Files remain in natural locations (no symlinks)
- ✅ Native git workflow (all git commands work)
- ✅ Explicit file tracking (safe by default)
- ✅ Coexists with other git repos perfectly

### How It Works

The `config` alias points to a bare git repository at `~/.dotfiles.git` with your home directory as the working tree:

```bash
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME"
```

This allows you to use git commands on your home directory without a `.git` folder:

```bash
config add .zshrc       # Stages ~/.zshrc
config commit -m "msg"  # Commits to ~/.dotfiles.git
config push             # Pushes to remote
```

## Troubleshooting

### "fatal: not a git repository"

```bash
# Reload shell
source ~/.zshrc

# Verify bare repo exists
ls -la ~/.dotfiles.git
```

### Too many untracked files shown

```bash
# Verify setting
config config status.showUntrackedFiles

# If not set
config config --local status.showUntrackedFiles no
```

### File won't track

```bash
# Check .gitignore
cat ~/.gitignore | grep "filename"

# Update .gitignore to whitelist
vim ~/.gitignore
# Add: !filename
```

### Pre-commit hook not running

```bash
# Verify hook is executable
ls -l ~/.dotfiles.git/hooks/pre-commit

# Make executable if needed
chmod +x ~/.dotfiles.git/hooks/pre-commit
```

## Configuration & Instructions

All critical configuration guidelines and workflow instructions are documented in this file and enforced by the pre-commit hook. This includes:
- Repository setup and daily usage commands
- Security rules for sensitive files
- Workflow for adding new configurations
- Directory management guidelines

## Environment

- **OS**: macOS (Darwin 25.2.0)
- **Shell**: Zsh with Oh My Zsh
- **Theme**: robbyrussell
- **Node**: Managed with NVM
- **Go**: Homebrew (go-grip for local Markdown rendering)
- **Git**: Using gh CLI for GitHub integration

## Repository

- **GitHub**: https://github.com/andrew-tomago/dotfiles
- **Method**: Bare git repository
- **Privacy**: Private repository

## References

- [Bare Git Repository Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Dotfiles: Best way to store in a bare git repository](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/)

## [Future] Potentially Useful to Track

Consider tracking these if you customize them:

#### Application Configurations

**`.config/`** - Modern XDG-compliant application configs:
```bash
# Example: Track GitHub CLI settings
vim ~/.gitignore
# Add these lines:
# !.config/
# !.config/gh/
# !.config/gh/**

config add .config/gh/
config commit -m "Add GitHub CLI configuration"
```

**`.cursor/`** - Cursor editor settings:
```bash
# If you use Cursor and want to sync settings
vim ~/.gitignore
# Add: !.cursor/
# Add: !.cursor/settings.json

config add .cursor/settings.json
config commit -m "Add Cursor editor settings"
```

#### Editor Configurations

- **`.vimrc`** - Vim configuration
- **`.tmux.conf`** - Tmux configuration
- **`.editorconfig`** - Editor consistency settings

#### Shell Enhancements

- **`.aliases`** - Custom shell aliases
- **`.functions`** - Custom shell functions
- **`.exports`** - Environment variables (non-sensitive)

#### Language-Specific

- **`.npmrc`** - npm configuration (exclude auth tokens!)
- **`.gemrc`** - Ruby gem configuration
- **`.pypirc`** - Python package index config (exclude credentials!)
- **`.Rprofile`** - R configuration