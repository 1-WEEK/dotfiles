#!/usr/bin/env bash
# Detects OS / arch / WSL / distro and exports SETUP_OS, SETUP_ARCH, SETUP_DISTRO,
# SETUP_WSL, SETUP_PROFILE. Sourced by bootstrap.sh.

case "$(uname -s)" in
  Darwin) SETUP_OS="macos" ;;
  Linux)  SETUP_OS="linux" ;;
  *)      SETUP_OS="unknown" ;;
esac

case "$(uname -m)" in
  arm64|aarch64) SETUP_ARCH="arm64" ;;
  x86_64|amd64)  SETUP_ARCH="amd64" ;;
  armv7l|armv6l) SETUP_ARCH="armv7" ;;
  *)             SETUP_ARCH="$(uname -m)" ;;
esac

SETUP_DISTRO="darwin"
SETUP_WSL="0"
if [ "$SETUP_OS" = "linux" ]; then
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    SETUP_DISTRO="${ID:-linux}"
  fi
  if [ -r /proc/sys/kernel/osrelease ] \
     && grep -qi 'microsoft\|wsl' /proc/sys/kernel/osrelease; then
    SETUP_WSL="1"
  fi
fi

# Profile inference
if [ -n "$SETUP_PROFILE_OVERRIDE" ]; then
  SETUP_PROFILE="$SETUP_PROFILE_OVERRIDE"
elif [ "$SETUP_OS" = "macos" ]; then
  SETUP_PROFILE="macos"
elif [ "$SETUP_WSL" = "1" ]; then
  SETUP_PROFILE="wsl2"
elif [ "$SETUP_DISTRO" = "raspbian" ] || [ "$SETUP_DISTRO" = "raspberrypi" ]; then
  SETUP_PROFILE="pi4"
elif [ "$SETUP_ARCH" = "arm64" ] && [ "$SETUP_OS" = "linux" ]; then
  SETUP_PROFILE="pi4"
else
  SETUP_PROFILE="wsl2"
fi

# Linuxbrew is supported on linux/amd64 and linux/arm64; not on armv7
if [ "$SETUP_OS" = "linux" ] && [ "$SETUP_ARCH" = "armv7" ]; then
  SETUP_HAS_BREW_TARGET="0"
else
  SETUP_HAS_BREW_TARGET="1"
fi

export SETUP_OS SETUP_ARCH SETUP_DISTRO SETUP_WSL SETUP_PROFILE SETUP_HAS_BREW_TARGET
