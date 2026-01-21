# Dotfiles Repository Configuration

## Repository Context
- Bare git repository at ~/.dotfiles.git
- Work tree: $HOME
- Access via `config` alias (NOT `git`)
- Whitelist strategy: everything ignored, explicit opt-in

## Critical Commands
- `config status` / `cs` - Check changes
- `config add <file>` / `ca` - Stage file
- `config commit -m "msg"` / `ccom` - Commit
- `config push` / `cpush` - Push to remote
- `config ls-tree -r main --name-only` / `clist` - List tracked files

## Security Rules (MANDATORY)
NEVER commit or stage:
- .ssh/, .aws/, .docker/, .gnupg/
- .claude.json, *.credentials
- *.pem, *.key, *_rsa, *.p12
- Files containing secrets, passwords, tokens

Pre-commit hook enforces this. If hook blocks commit, DO NOT bypass.

## Adding New Files Workflow
1. Inspect file for secrets: `cat ~/.newfile`
2. Whitelist in .gitignore: Add `!.newfile`
3. Stage: `config add .newfile`
4. Verify: `config diff --cached` and `config status`
5. Commit: `config commit -m "Add newfile"`

## Tracked Files Reference
| File | Purpose |
|------|---------|
| .zshrc | Shell config, aliases, NVM |
| .gitconfig | Git settings, gh auth |
| .gitignore | Dotfiles whitelist rules |
| .gitignore_global | Global ignores |
| .dotfiles-install.sh | Bootstrap script |
| README.md | Documentation |
| CLAUDE.md | This file |

## Excluded Directories (Separate Concerns)
- .claude/ - Separate git repository (SuperClaude framework)
- .oh-my-zsh/ - Reinstall on new machines
- .nvm/ - Reinstall on new machines

## Environment
- macOS Darwin 25.2.0
- Zsh with Oh My Zsh (robbyrussell theme)
- Node via NVM
- GitHub CLI (gh) for authentication
