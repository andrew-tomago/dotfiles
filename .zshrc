# ~/.zshrc - Modular shell configuration loader
# Individual modules are in ~/.zshrc.d/*.zsh

ZSHRC_D="${HOME}/.zshrc.d"

if [[ -d "$ZSHRC_D" ]]; then
    for f in "$ZSHRC_D"/*.zsh(N); do
        [[ -r "$f" ]] && source "$f"
    done
fi
