#!/usr/bin/env bash
# macOS profile: full set including casks, taps, and Manico.

PROFILE_STEPS=(
  00-prereqs
  10-homebrew
  20-brew-common
  21-brew-macos
  25-claude-code
  30-shells
  40-mise-tools
  50-vim-plug
  55-tmux-tpm
  60-dotter
  70-dotter-deploy
  80-manico
)

PROFILE_DOTTER_PACKAGES='["ghostty", "zsh", "fish", "vim", "bash", "tmux", "mise"]'
