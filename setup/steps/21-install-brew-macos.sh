#!/usr/bin/env bash
# macOS-only formulae, taps, and casks from packages/Brewfile.macos.

step_check() {
  [ "$SETUP_OS" = "macos" ] || return 0
  _brew bundle check --file="$SETUP_ROOT/packages/Brewfile.macos" >/dev/null 2>&1
}

step_run() {
  if [ "$SETUP_OS" != "macos" ]; then
    log_skip "macOS-only step on $SETUP_OS"
    return 0
  fi
  brew_bundle "$SETUP_ROOT/packages/Brewfile.macos"
}
