#!/usr/bin/env bash
# Raspberry Pi 4 profile.
# 64-bit (arm64): linuxbrew supported → use Brewfile.common.
# 32-bit (armv7): linuxbrew unsupported → fall back to apt.

if [ "$SETUP_HAS_BREW_TARGET" = "1" ]; then
  PROFILE_STEPS=(
    00-prereqs
    10-homebrew
    20-brew-common
    25-claude-code
    30-shells
    40-mise-tools
    60-dotter
    70-dotter-deploy
    71-vim-plug
    72-tmux-tpm
  )
else
  PROFILE_STEPS=(
    00-prereqs
    22-apt-fallback
    25-claude-code
    30-shells
    40-mise-tools
    60-dotter
    70-dotter-deploy
    71-vim-plug
    72-tmux-tpm
  )
fi

PROFILE_DOTTER_PACKAGES='["zsh", "fish", "vim", "bash", "tmux", "mise"]'
