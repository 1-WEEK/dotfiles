#!/usr/bin/env bash
# Cross-platform Homebrew formulae from packages/Brewfile.common.

step_check() {
  _brew bundle check --file="$SETUP_ROOT/packages/Brewfile.common" >/dev/null 2>&1
}

step_run() {
  if [ "$SETUP_HAS_BREW_TARGET" != "1" ]; then
    log_skip "No brew target on $SETUP_ARCH; use 22-apt-fallback"
    return 0
  fi
  brew_bundle "$SETUP_ROOT/packages/Brewfile.common"
}
