# Claude/AI CLI functions

# cyolo - Run Claude Code in YOLO mode (auto-accept all prompts)
cyolo() {
    claude --dangerously-skip-permissions "$@"
}

# xyolo - Run Codex in full-auto mode
alias xyolo='codex --approval-mode full-auto'

# cplan - Run Claude Code in plan mode
cplan() {
    claude --plan "$@"
}
