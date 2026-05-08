#!/usr/bin/env bash
# Raspberry Pi 4 profile.
# 64-bit (arm64): linuxbrew supported → use Brewfile.common.
# 32-bit (armv7): linuxbrew unsupported → fall back to apt.

if [ "$SETUP_HAS_BREW_TARGET" = "1" ]; then
  PROFILE_STEPS=(
    00-install-prereqs
    10-install-homebrew
    20-install-brew-common
    25-install-claude
    30-setup-shells
    40-install-mise-tools
    60-install-dotter
    70-deploy-dotfiles
    71-setup-vim
    72-setup-tmux
  )
else
  PROFILE_STEPS=(
    00-install-prereqs
    22-install-apt-fallback
    25-install-claude
    30-setup-shells
    40-install-mise-tools
    60-install-dotter
    70-deploy-dotfiles
    71-setup-vim
    72-setup-tmux
  )
fi

PROFILE_DOTTER_PACKAGES='["zsh", "fish", "vim", "bash", "tmux", "mise"]'
