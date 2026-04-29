#!/usr/bin/env bash
# Ensure dotter is on PATH. On linuxbrew/macos this is satisfied by step 20.
# On apt fallback (armv7), fall back to cargo install.

step_check() {
  command -v dotter >/dev/null 2>&1
}

step_run() {
  if step_check; then
    log_skip "dotter already on PATH"
    return 0
  fi
  if command -v cargo >/dev/null 2>&1; then
    log_info "Installing dotter via cargo"
    run cargo install dotter
  else
    log_error "dotter not installed and no cargo available; install Rust then re-run --only=60-dotter"
    return 1
  fi
}
