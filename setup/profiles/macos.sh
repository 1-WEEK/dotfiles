#!/usr/bin/env bash
# macOS profile: full set including casks, taps, and Manico.

PROFILE_STEPS=(
  00-install-prereqs
  10-install-homebrew
  20-install-brew-common
  15-install-mise
  21-install-brew-macos
  25-install-claude
  60-deploy-dotfiles
  40-install-mise-tools
  30-setup-shells
  61-setup-vim
  62-setup-tmux
  70-setup-manico
)
