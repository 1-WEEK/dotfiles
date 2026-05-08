#!/usr/bin/env bash
# Install Claude Code via the official installer script.

step_check() {
  command -v claude >/dev/null 2>&1
}

step_run() {
  if step_check; then
    log_skip "Claude Code already installed at $(command -v claude)"
    return 0
  fi
  log_info "Installing Claude Code via official script"
  if ! run sh -c 'curl -fsSL https://claude.ai/install.sh | bash'; then
    log_warn "Claude Code installer failed (network?). Re-run: setup/bootstrap.sh --only=25-claude-code"
    return 0
  fi
}
