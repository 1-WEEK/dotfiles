#!/usr/bin/env bash
# WSL2 Ubuntu 24 profile (assumes amd64 or arm64; both supported by linuxbrew).

PROFILE_STEPS=(
  00-install-prereqs
  10-install-homebrew
  20-install-brew-common
  15-install-mise
  25-install-claude
  60-deploy-dotfiles
  40-install-mise-tools
  30-setup-shells
  61-setup-vim
  62-setup-tmux
)
