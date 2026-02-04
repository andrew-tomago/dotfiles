# Linux-specific configuration
[[ ! "$OSTYPE" == linux-gnu* ]] && return

# fd-find / bat fallbacks (Ubuntu renames these packages)
command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && alias fd='fdfind'
command -v batcat &>/dev/null && ! command -v bat &>/dev/null && alias bat='batcat'

# Claude Code tool search
export ENABLE_TOOL_SEARCH=auto:5
