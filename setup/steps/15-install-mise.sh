#!/usr/bin/env bash
# Install mise via the official script (https://mise.run).
# Preferred over `brew install mise` so version tracks upstream releases
# immediately and avoids Homebrew's slower formula cadence.
# Cross-platform: macOS (x86_64/arm64), Linux (linuxbrew + apt fallback).

step_check() {
  command -v mise >/dev/null 2>&1
}

step_run() {
  if command -v mise >/dev/null 2>&1; then
    log_skip "mise already installed at $(command -v mise)"
    return 0
  fi
  log_info "Installing mise via official script"
  run sh -c 'curl https://mise.run | sh'
}
