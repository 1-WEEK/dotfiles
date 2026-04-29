#!/usr/bin/env bash
# Installation helpers (idempotent).

# Resolve brew path from current SETUP_OS so callers don't need to.
_brew() {
  if [ "$SETUP_OS" = "macos" ]; then
    /opt/homebrew/bin/brew "$@"
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    /home/linuxbrew/.linuxbrew/bin/brew "$@"
  elif command -v brew >/dev/null 2>&1; then
    brew "$@"
  else
    return 127
  fi
}

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1
}

apt_install() {
  if ! command -v apt-get >/dev/null 2>&1; then
    log_warn "apt-get unavailable; cannot install: $*"
    return 1
  fi
  run sudo apt-get update -qq
  run sudo apt-get install -y --no-install-recommends "$@"
}

brew_bundle() {
  local file="$1"
  if ! _brew --version >/dev/null 2>&1; then
    log_warn "Homebrew not available; skipping $(basename "$file")"
    return 1
  fi
  if [ "${DRY_RUN:-0}" = "1" ]; then
    _brew bundle check --file="$file" --verbose || true
  else
    _brew bundle install --file="$file"
  fi
}

clone_or_pull() {
  local url="$1" dest="$2" ref="${3:-}"
  if [ -d "$dest/.git" ]; then
    log_info "$(basename "$dest") already cloned — pulling latest"
    run git -C "$dest" pull --ff-only --quiet
  else
    run git clone --depth 1 ${ref:+--branch "$ref"} "$url" "$dest"
  fi
}
