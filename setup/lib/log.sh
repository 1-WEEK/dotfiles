#!/usr/bin/env bash
# Logging helpers.

if [ -t 1 ]; then
  _C_RESET=$'\033[0m'; _C_DIM=$'\033[2m'; _C_BOLD=$'\033[1m'
  _C_BLUE=$'\033[34m'; _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_RED=$'\033[31m'
else
  _C_RESET=""; _C_DIM=""; _C_BOLD=""
  _C_BLUE=""; _C_GREEN=""; _C_YELLOW=""; _C_RED=""
fi

log_step()  { printf '%s==>%s %s%s%s\n'   "$_C_BLUE"  "$_C_RESET" "$_C_BOLD" "$*" "$_C_RESET"; }
log_info()  { printf '%s    %s%s\n'       "$_C_DIM"   "$*" "$_C_RESET"; }
log_ok()    { printf '%s  ✓ %s%s\n'       "$_C_GREEN" "$*" "$_C_RESET"; }
log_skip()  { printf '%s  · %s (skip)%s\n' "$_C_DIM"  "$*" "$_C_RESET"; }
log_warn()  { printf '%s  ! %s%s\n'       "$_C_YELLOW" "$*" "$_C_RESET" >&2; }
log_error() { printf '%s  ✗ %s%s\n'       "$_C_RED"   "$*" "$_C_RESET" >&2; }

# Run a command, but print + skip when DRY_RUN=1
run() {
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '%s  $ %s%s\n' "$_C_DIM" "$*" "$_C_RESET"
  else
    "$@"
  fi
}
