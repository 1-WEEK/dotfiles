#!/usr/bin/env bash
# Install tools only after successful configuration deployment.

step_check() {
  command -v mise >/dev/null 2>&1 \
    && mise current node >/dev/null 2>&1 \
    && mise current bun >/dev/null 2>&1
}

step_run() {
  if ! command -v mise >/dev/null 2>&1; then
    log_warn "mise not on PATH; re-run after step 20 (or 22)"
    return 1
  fi
  local cfg="$HOME/.config/mise/config.toml"
  if [ ! "$cfg" -ef "$HOME/.dotfiles/mise/config.toml" ]; then
    log_error "Deploy configuration successfully before installing tools (--only=60)."
    return 1
  fi
  run mise install
}
