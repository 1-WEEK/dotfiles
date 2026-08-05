#!/usr/bin/env bash
# Fallback when linuxbrew is unavailable (Pi4 armv7).
# Approximates Brewfile.common via apt + a few official installers.

step_check() {
  command -v rg >/dev/null 2>&1 \
    && command -v fish >/dev/null 2>&1 \
    && command -v tmux >/dev/null 2>&1
}

step_run() {
  apt_install $(grep -vE '^\s*(#|$)' "$SETUP_ROOT/packages/apt.fallback.txt")

  # Tools not in apt or where apt versions lag too far behind.
  if ! command -v starship >/dev/null 2>&1; then
    log_info "Installing starship via official script"
    run sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
  fi
  if ! command -v dotter >/dev/null 2>&1; then
    log_warn "dotter not in apt; install via cargo or download release manually"
  fi
}
