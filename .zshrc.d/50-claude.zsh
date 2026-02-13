# Claude/AI CLI functions

# cyolo - Run Claude Code in YOLO mode (auto-accept all prompts)
cyolo() {
    claude --dangerously-skip-permissions "$@"
}

# xyolo - Run Codex in full-auto mode (default, overridable)
xyolo() {
    if [[ "$*" == *"--approval-mode"* ]]; then
        codex "$@"
    else
        codex --approval-mode full-auto "$@"
    fi
}

# cplan - Run Claude Code in plan mode
cplan() {
    claude --dangerously-skip-permissions --permission-mode plan "$@"
}
