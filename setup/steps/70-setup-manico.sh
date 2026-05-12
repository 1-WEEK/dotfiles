#!/usr/bin/env bash
# macOS-only: import Manico prefs if Manico.app is installed.

step_check() {
  [ "$SETUP_OS" = "macos" ] || return 0
  # Always returns 0 — this step is purely informational/idempotent and
  # determined at run-time.
  return 0
}

step_run() {
  if [ "$SETUP_OS" != "macos" ]; then
    log_skip "Manico is macOS-only"
    return 0
  fi
  if [ ! -d "/Applications/Manico.app" ]; then
    log_warn "Manico.app not found in /Applications. Install from https://manico.im/ then re-run --only=70-manico"
    return 0
  fi
  if [ -x "$DOTFILES_ROOT/manico/sync.sh" ]; then
    log_info "Importing Manico prefs from manico/settings.txt"
    run "$DOTFILES_ROOT/manico/sync.sh" import
  fi
}
