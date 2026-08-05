#!/usr/bin/env bash
# WSL2 Ubuntu 24 profile (assumes amd64 or arm64; both supported by linuxbrew).

PROFILE_STEPS=(
  00-install-prereqs
  10-install-homebrew
  20-install-brew-common
  15-install-mise
  25-install-claude
  30-setup-shells
  40-install-mise-tools
  50-install-dotter
  60-deploy-dotfiles
  61-setup-vim
  62-setup-tmux
)

PROFILE_DOTTER_PACKAGES='["zsh", "fish", "vim", "bash", "tmux", "mise", "eza"]'
