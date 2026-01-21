# Dotfiles

Personal dotfiles managed with bare git repository method.

## Fresh Installation

```bash
curl -Lks https://raw.githubusercontent.com/andrew-tomago/dotfiles/main/.dotfiles-install.sh | bash
```

Or manually:

```bash
git clone --bare https://github.com/andrew-tomago/dotfiles.git $HOME/.dotfiles.git
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME"
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

- `.zshrc` - Zsh configuration with Oh My Zsh and NVM
- `.gitconfig` - Git configuration with gh credential helper
- `.gitignore_global` - Global git ignores
- `.gitignore` - Dotfiles repository ignore rules
- `.dotfiles-install.sh` - Bootstrap installation script
- `README.md` - This documentation file

## Directory Management Guide

### 🔒 Protected Directories (Never Track)

These directories contain sensitive data and are blocked by `.gitignore` and pre-commit hook:

- **`.ssh/`** - SSH keys and authorized_keys
- **`.aws/`** - AWS credentials and configuration
- **`.docker/`** - Docker credentials and context
- **`.gnupg/`** - GPG keys
- Any files matching: `*.pem`, `*.key`, `*_rsa`, `*.p12`, `*.credentials`

### 🚫 System Directories (Excluded by Default)

These are framework files, caches, and system data - don't track:

- **`.oh-my-zsh/`** - Oh My Zsh framework (reinstall on new machines)
- **`.nvm/`** - Node Version Manager (reinstall on new machines)
- **`.npm/`** - npm cache
- **`.cache/`** - Application cache files
- **`.local/`** - Local application data
- **`.Trash/`** - System trash
- **`.DS_Store`** - macOS Finder metadata
- **`.zsh_sessions/`** - Zsh session data
- **`.zsh_history`** - Command history (may contain sensitive data)
- **`.viminfo`** - Vim session info
- **`.CFUserTextEncoding`** - System encoding file

### 📦 Separate Git Repositories

These directories maintain their own version control:

- **`.claude/`** - Claude Code configuration
  - Repository: https://github.com/andrew-tomago/.claude.git
  - Install separately: `git clone https://github.com/andrew-tomago/.claude.git ~/.claude`
  - Has independent git history and lifecycle

### ✅ Potentially Useful to Track

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

## Security

### Never Tracked

- `.ssh/` - SSH keys
- `.claude.json` - API credentials
- `*.pem`, `*.key` - Private keys
- `.aws/` - AWS credentials
- Password or secret files

Pre-commit hook prevents accidental commits of sensitive files.

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

### Important Configuration

The repository is configured to hide untracked files:

```bash
config config --local status.showUntrackedFiles no
```

Without this, `config status` would show every file in your home directory.

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

## Environment

- **OS**: macOS (Darwin 25.2.0)
- **Shell**: Zsh with Oh My Zsh
- **Theme**: robbyrussell
- **Node**: Managed with NVM
- **Git**: Using gh CLI for GitHub integration

## Repository

- **GitHub**: https://github.com/andrew-tomago/dotfiles
- **Method**: Bare git repository
- **Privacy**: Private repository

## References

- [Bare Git Repository Tutorial](https://www.atlassian.com/git/tutorials/dotfiles)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
