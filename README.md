# (Config) Dotfiles Repo

THIS README ONLY APPLIES TO OUR DOTFILES REPO AT ~/.dotfiles.git
It's a bare git repository method managing all our local configs.

## Onboarding a New Machine

### 1. Run the platform setup script

| Platform | Command | Notes |
|----------|---------|-------|
| MacBook (Intel or Apple Silicon) | `./setup-new-macbook.sh` | Auto-detects architecture via `uname -m` |
| MacBook + music production | `./setup-new-macbook.sh --music` | Adds DAWs, audio plugins |
| Ubuntu | `./setup-new-ubuntu.sh` | apt + snap based |

Intel Macs automatically skip Rosetta 2 and use the `/usr/local` Homebrew prefix. No flags needed.

### 2. Install dotfiles

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

### 3. Install Claude config

```bash
git clone https://github.com/andrew-tomago/.claude.git ~/.claude
```

### 4. Verify

```bash
cs   # config status — should show clean working tree
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

### Agent Skill Usage (Reliable Invocation)

Name the skill ID directly in the first line of your prompt. This avoids ambiguous routing.

| Goal | Use this exact skill name | Prompt template |
| --- | --- | --- |
| End-to-end WIN flow | `win-committee` | `Use win-committee. Run committee flow with targets at <path> and content at <path>.` |
| Build target profiles only | `win-profile` | `Use win-profile. Generate profiles from <targets-path>.` |
| Score drafts only | `win-evaluate` | `Use win-evaluate. Evaluate <content-path> using <profiles-path> and <committee-path>.` |
| Generate markdown summary only | `win-summary` | `Use win-summary. Synthesize summary from <committee-matrix-path>.` |

Rules:
- Put `Use <skill-id>.` first.
- Repeat the skill ID each turn; skill use is turn-scoped.
- Prefer exact IDs (`win-committee`, `win-profile`, `win-evaluate`, `win-summary`) over descriptive aliases.

### Convenience Aliases

These are defined in `.zshrc.d/40-dotfiles.zsh` (loaded via modular `.zshrc`):

```bash
cs       # config status
ca       # config add
ccom     # config commit
cpush    # config push
clist    # config ls-tree -r main --name-only
```

## Currently Tracked Files

- `.zshrc` - Modular shell loader (sources `.zshrc.d/*.zsh`)
- `.zshrc.d/*.zsh` - Modular shell configuration modules
- `.gitconfig` - Git settings, gh auth
- `.gitignore` - Dotfiles whitelist rules
- `.gitignore_global` - Global ignores
- `.dotfiles-install.sh` - Bootstrap script
- `setup-new-macbook.sh` - macOS dev environment setup (Intel + Apple Silicon)
- `setup-new-ubuntu.sh` - Ubuntu dev environment setup
- `README.md` - Documentation
- `CLAUDE.md` - Symlink to `~/.claude/CLAUDE.md` (relative path for portability)

### MacBook Setup

`setup-new-macbook.sh` supports both **Intel and Apple Silicon** Macs. Architecture is auto-detected — the same script works on either. Its companion [MacBook Setup Checklist Gist](https://gist.github.com/andrew-tomago/35d217aa12f387c529ed188facc3d212) is the source of truth for this machine's dev environment. The script is self-documenting — refer to it directly for package lists and installation order.

**Managing software:** Use the `install-software` and `uninstall-software` skills from the `unique@skill-tree` plugin as the primary way to add or remove tools from the setup script. They handle script edits and gist synchronization.

### Ubuntu Setup

`setup-new-ubuntu.sh` and its companion [Ubuntu Setup Checklist Gist](https://gist.github.com/andrew-tomago/b13a3bdace6261c747f9124fcbdcee70) are the sources of truth for Ubuntu dev environments. The script installs build essentials, modern CLI tools (ripgrep, fd, bat, fzf, zoxide, lsd), Docker, NVM, GitHub CLI, and Claude Code.

**Shell configuration:** Uses modular `~/.zshrc.d/*.zsh` files for organized, OS-aware shell setup.

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
  - **`CLAUDE.md` symlink** - This dotfiles repo tracks a symlink at `~/CLAUDE.md` pointing to `.claude/CLAUDE.md` (relative path). This lets Claude Code find project instructions at the home level while the actual file lives in the `.claude` repo. The relative path ensures portability across machines with different usernames.

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

- No `.git` folder cluttering home directory
- Files remain in natural locations (no symlinks)
- Native git workflow (all git commands work)
- Explicit file tracking (safe by default)
- Coexists with other git repos perfectly

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

### Platform Comparison

| Feature | MacBook (Apple Silicon) | MacBook (Intel) | Ubuntu |
|---------|------------------------|-----------------|--------|
| Setup script | `setup-new-macbook.sh` | `setup-new-macbook.sh` | `setup-new-ubuntu.sh` |
| Companion checklist | [MacBook Gist](https://gist.github.com/andrew-tomago/35d217aa12f387c529ed188facc3d212) | [MacBook Gist](https://gist.github.com/andrew-tomago/35d217aa12f387c529ed188facc3d212) | [Ubuntu Gist](https://gist.github.com/andrew-tomago/b13a3bdace6261c747f9124fcbdcee70) |
| Package manager | Homebrew (`/opt/homebrew`) | Homebrew (`/usr/local`) | apt + snap |
| Shell | Zsh + Oh My Zsh | Zsh + Oh My Zsh | Zsh + Oh My Zsh |
| Node | NVM | NVM | NVM |
| Go | Homebrew (go-grip for Markdown) | Homebrew (go-grip for Markdown) | — |
| Python | uv | uv | — |
| Databases | DuckDB, SQLite | DuckDB, SQLite | — |
| Docker | Docker Desktop (cask) | Docker Desktop (cask) | Docker Engine (apt) |
| Music software | `--music` flag | `--music` flag | — |
| Git auth | GitHub CLI (`gh`) | GitHub CLI (`gh`) | GitHub CLI (`gh`) |
| AI | Claude Code | Claude Code | Claude Code |

### Common (All Platforms)

- **Shell**: Zsh with Oh My Zsh (robbyrussell theme)
- **Node**: Managed with NVM
- **Git**: GitHub CLI (`gh`) for authentication
- **AI**: Claude Code
- **CLI Tools**: ripgrep, fd, bat, fzf, zoxide, lsd

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
