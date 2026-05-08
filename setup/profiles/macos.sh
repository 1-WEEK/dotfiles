#!/usr/bin/env bash
# macOS profile: full set including casks, taps, and Manico.

PROFILE_STEPS=(
  00-install-prereqs
  10-install-homebrew
  20-install-brew-common
  21-install-brew-macos
  25-install-claude
  30-setup-shells
  40-install-mise-tools
  60-install-dotter
  70-deploy-dotfiles
  71-setup-vim
  72-setup-tmux
  80-setup-manico
)

PROFILE_DOTTER_PACKAGES='["ghostty", "zsh", "fish", "vim", "bash", "tmux", "mise"]'
