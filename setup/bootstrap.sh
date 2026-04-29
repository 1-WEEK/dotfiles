#!/usr/bin/env bash
# Bootstrap a new machine (macOS / Pi4 / WSL2 Ubuntu24).
# Usage:
#   setup/bootstrap.sh                  interactive: detect + per-step y/N
#   setup/bootstrap.sh --auto           non-interactive: apply profile defaults
#   setup/bootstrap.sh --profile=pi4    force a profile
#   setup/bootstrap.sh --only=20,40     run only listed steps (numbers or names)
#   setup/bootstrap.sh --skip=80        skip listed steps
#   setup/bootstrap.sh --check          dry-run
#   setup/bootstrap.sh --list           list steps for the active profile
#   setup/bootstrap.sh --help           show this help

set -euo pipefail

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SETUP_ROOT/.." && pwd)"
export SETUP_ROOT DOTFILES_ROOT

# shellcheck disable=SC1091
. "$SETUP_ROOT/lib/log.sh"
# shellcheck disable=SC1091
. "$SETUP_ROOT/lib/install.sh"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

AUTO=0
DRY_RUN=0
LIST=0
SETUP_PROFILE_OVERRIDE=""
ONLY=""
SKIP=""

for arg in "$@"; do
  case "$arg" in
    --auto)            AUTO=1 ;;
    --check|-n)        DRY_RUN=1 ;;
    --list)            LIST=1 ;;
    --profile=*)       SETUP_PROFILE_OVERRIDE="${arg#*=}" ;;
    --only=*)          ONLY="${arg#*=}" ;;
    --skip=*)          SKIP="${arg#*=}" ;;
    -h|--help)         usage; exit 0 ;;
    *)                 log_error "Unknown flag: $arg"; usage; exit 2 ;;
  esac
done
export DRY_RUN

# shellcheck disable=SC1091
. "$SETUP_ROOT/lib/detect.sh"

PROFILE_FILE="$SETUP_ROOT/profiles/$SETUP_PROFILE.sh"
if [ ! -f "$PROFILE_FILE" ]; then
  log_error "Unknown profile: $SETUP_PROFILE (looked at $PROFILE_FILE)"
  exit 2
fi
# shellcheck disable=SC1090
. "$PROFILE_FILE"

log_step "Detected: os=$SETUP_OS arch=$SETUP_ARCH distro=$SETUP_DISTRO wsl=$SETUP_WSL → profile=$SETUP_PROFILE"

# Resolve a step token (number or full name) to a step file path.
resolve_step() {
  local token="$1" file
  for file in "$SETUP_ROOT"/steps/${token}-*.sh "$SETUP_ROOT"/steps/${token}.sh; do
    [ -f "$file" ] && { echo "$file"; return 0; }
  done
  return 1
}

# Build list of steps to consider.
declare -a STEPS_TO_RUN=()
if [ -n "$ONLY" ]; then
  IFS=',' read -ra parts <<<"$ONLY"
  for p in "${parts[@]}"; do STEPS_TO_RUN+=("$p"); done
else
  STEPS_TO_RUN=("${PROFILE_STEPS[@]}")
fi

# Apply --skip filter.
if [ -n "$SKIP" ]; then
  IFS=',' read -ra skips <<<"$SKIP"
  declare -a filtered=()
  for s in "${STEPS_TO_RUN[@]}"; do
    keep=1
    for sk in "${skips[@]}"; do
      case "$s" in "$sk"*) keep=0 ;; esac
    done
    [ "$keep" = "1" ] && filtered+=("$s")
  done
  STEPS_TO_RUN=("${filtered[@]}")
fi

if [ "$LIST" = "1" ]; then
  log_step "Steps for profile $SETUP_PROFILE:"
  for s in "${STEPS_TO_RUN[@]}"; do
    file="$(resolve_step "$s" || true)"
    if [ -n "$file" ]; then
      printf '  %s  → %s\n' "$s" "$(basename "$file")"
    else
      printf '  %s  (NOT FOUND)\n' "$s"
    fi
  done
  exit 0
fi

ask_yes_no() {
  local prompt="$1" reply
  if [ "$AUTO" = "1" ]; then return 0; fi
  read -r -p "$prompt [Y/n] " reply || return 0
  case "$reply" in n|N|no|NO) return 1 ;; *) return 0 ;; esac
}

run_step() {
  local token="$1" file
  file="$(resolve_step "$token")" || { log_error "Step not found: $token"; return 1; }
  local name; name="$(basename "$file" .sh)"

  # Source step in subshell so step_check/step_run definitions don't leak.
  (
    # shellcheck disable=SC1090
    . "$file"
    if declare -f step_check >/dev/null && step_check >/dev/null 2>&1; then
      log_skip "$name (already satisfied)"
      exit 0
    fi
    if ! ask_yes_no "Run step $name?"; then
      log_skip "$name (declined)"
      exit 0
    fi
    log_step "$name"
    step_run
  )
}

FAILED=()
for s in "${STEPS_TO_RUN[@]}"; do
  if ! run_step "$s"; then
    FAILED+=("$s")
    log_warn "Step $s failed; continuing"
  fi
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  log_warn "Completed with failures: ${FAILED[*]}"
  exit 1
fi
log_ok "All requested steps completed."
