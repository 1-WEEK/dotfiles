#!/usr/bin/env bash
# WSL2 Ubuntu 24 profile (assumes amd64 or arm64; both supported by linuxbrew).

PROFILE_STEPS=(
  00-prereqs
  10-homebrew
  20-brew-common
  25-claude-code
  30-shells
  40-mise-tools
  50-vim-plug
  55-tmux-tpm
  60-dotter
  70-dotter-deploy
)

PROFILE_DOTTER_PACKAGES='["zsh", "fish", "vim", "bash", "tmux", "mise"]'
