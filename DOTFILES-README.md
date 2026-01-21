# Dotfiles

Personal dotfiles managed with bare git repository method.

## Fresh Installation

```bash
curl -Lks https://raw.githubusercontent.com/alvaldi-atom/dotfiles/main/.dotfiles-install.sh | bash
```

Or manually:

```bash
git clone --bare https://github.com/alvaldi-atom/dotfiles.git $HOME/.dotfiles.git
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

## Tracked Files

- `.zshrc` - Zsh configuration with Oh My Zsh and NVM
- `.gitconfig` - Git configuration with gh credential helper
- `.gitignore_global` - Global git ignores
- `.gitignore` - Dotfiles repository ignore rules
- `.dotfiles-install.sh` - Bootstrap installation script
- `DOTFILES-README.md` - This documentation file

## Security

### Never Tracked

- `.ssh/` - SSH keys
- `.claude.json` - API credentials
- `*.pem`, `*.key` - Private keys
- `.aws/` - AWS credentials
- Password or secret files

Pre-commit hook prevents accidental commits of sensitive files.

### Adding New Files

Always verify before committing:

```bash
config add <file>       # Add the file
config status           # Verify what's staged
config diff --cached    # See exact changes
config commit -m "msg"  # Commit if safe
```

## Separate Repositories

### .claude/

Claude configuration maintained separately:
- Repository: https://github.com/andrew-tomago/.claude.git
- Install: `git clone https://github.com/andrew-tomago/.claude.git ~/.claude`

The `.claude/` directory has its own git history and is excluded from dotfiles tracking.

## Bare Git Repository Method

### Why This Method?

- ✅ No `.git` folder cluttering home directory
- ✅ Files remain in natural locations (no symlinks)
- ✅ Native git workflow (all git commands work)
- ✅ Explicit file tracking (safe by default)
- ✅ Coexists with `.claude/` repo perfectly

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

## Adding New Dotfiles

To track a new dotfile:

1. Add it to `.gitignore` whitelist (with `!filename`)
2. Stage and commit:

```bash
vim ~/.gitignore        # Add: !.newconfig
config add .newconfig
config commit -m "Add new configuration"
config push
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

## Environment

- **OS**: macOS (Darwin 25.2.0)
- **Shell**: Zsh with Oh My Zsh
- **Theme**: robbyrussell
- **Node**: Managed with NVM
- **Git**: Using gh CLI for GitHub integration

## Repository

- **GitHub**: https://github.com/alvaldi-atom/dotfiles
- **Method**: Bare git repository
- **Privacy**: Private repository
