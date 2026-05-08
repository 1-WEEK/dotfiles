#!/usr/bin/env bash
# Prereqs: minimum tools needed before anything else (curl, git, build tools).

step_check() {
  command -v curl >/dev/null 2>&1 \
    && command -v git >/dev/null 2>&1
}

step_run() {
  if [ "$SETUP_OS" = "macos" ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
      log_info "Triggering Command Line Tools install — accept the prompt"
      run xcode-select --install || true
    else
      log_skip "xcode-select already installed"
    fi
  else
    apt_install $(grep -vE '^\s*(#|$)' "$SETUP_ROOT/packages/apt.common.txt")
  fi
}
