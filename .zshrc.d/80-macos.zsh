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
