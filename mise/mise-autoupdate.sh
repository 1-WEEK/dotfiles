#!/usr/bin/env bash
# mise self-update + global tool upgrade, run by launchd
# (dev.mise.mise-autoupdate). launchd starts jobs with a minimal
# environment, so PATH is set here instead of relying on the shell.
set -uo pipefail

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

log() { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"; }

log "mise-autoupdate start"
mise self-update --yes || log "self-update failed: exit $?"
mise upgrade --global --yes || log "upgrade failed: exit $?"
log "mise-autoupdate done"
