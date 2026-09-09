#!/usr/bin/env bash
# mise's automatic update check is cached and continues after failure.
# Deployment instead requires a fresh successful release check.
set -euo pipefail

latest="$(curl --fail --silent --show-error --location --max-time 30 https://mise.jdx.dev/VERSION)"
if [[ ! "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Cannot verify latest stable mise: invalid release response\n' >&2
  exit 1
fi
current="$(mise --version 2>/dev/null || true)"
if [ "${current%% *}" = "$latest" ]; then
  exit 0
fi
if [ "${1:-}" = --verify ]; then
  printf 'Deployment requires mise %s (found %s). Run setup/bootstrap.sh --only=15 --auto, then retry.\n' "$latest" "${current:-absent}" >&2
  exit 1
fi
if [ "${DRY_RUN:-0}" = 1 ]; then
  printf 'Would install/upgrade mise to %s before deployment\n' "$latest"
  exit 0
fi
if command -v mise >/dev/null 2>&1; then
  mise self-update --yes --no-plugins "$latest"
else
  installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-mise-install.XXXXXX")"
  trap 'rm -f "$installer"' EXIT
  curl --fail --silent --show-error --location --max-time 60 https://mise.run -o "$installer"
  MISE_VERSION="$latest" sh "$installer"
  export PATH="$HOME/.local/bin:$PATH"
fi
current="$(mise --version)"
if [ "${current%% *}" != "$latest" ]; then
  printf 'mise upgrade verification failed: expected %s, found %s\n' "$latest" "$current" >&2
  exit 1
fi
