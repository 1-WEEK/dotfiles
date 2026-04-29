#!/usr/bin/env bash
# Install Homebrew (macOS) or linuxbrew (Linux x86_64/arm64). Skip on armv7.

step_check() {
  if [ "$SETUP_HAS_BREW_TARGET" != "1" ]; then return 0; fi
  command -v brew >/dev/null 2>&1 \
    || [ -x /opt/homebrew/bin/brew ] \
    || [ -x /home/linuxbrew/.linuxbrew/bin/brew ]
}

step_run() {
  if [ "$SETUP_HAS_BREW_TARGET" != "1" ]; then
    log_skip "Homebrew not supported on $SETUP_ARCH; skipping"
    return 0
  fi
  if step_check; then
    log_skip "Homebrew already installed"
    return 0
  fi
  log_info "Installing Homebrew via official script"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}
