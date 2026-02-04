# Dotfiles management via bare git repository
alias config="/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME"
alias cs='config status'
alias ca='config add'
alias ccom='config commit'
alias cpush='config push'
alias clist='config ls-tree -r main --name-only'

# Enable git completions for config alias
compdef config=git
