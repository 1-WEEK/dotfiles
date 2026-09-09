#!/usr/bin/env bash
step_check() { return 1; }

step_run() {
  local checkout="$HOME/.dotfiles"
  if [ ! -d "$checkout" ]; then
    log_error "Check out this repository at $checkout before deployment; setup never moves an existing checkout."
    return 1
  fi
  if [ ! "$checkout" -ef "$DOTFILES_ROOT" ]; then
    log_error "$checkout is occupied by another checkout or directory. Run setup from the intended checkout at that location."
    return 1
  fi
  command -v python3 >/dev/null 2>&1 || {
    log_error "python3 is required for conflict preflight (Command Line Tools on macOS or python3 on Linux)."
    return 1
  }
  # --only=60 and --skip=15 still enforce the deployment prerequisite.
  bash "$SETUP_ROOT/lib/mise-latest.sh" || return 1
  export PATH="$HOME/.local/bin:$PATH"
  export MISE_TRUSTED_CONFIG_PATHS="$checkout/mise${MISE_TRUSTED_CONFIG_PATHS:+:$MISE_TRUSTED_CONFIG_PATHS}"
  export MISE_AUTO_ENV=false
  case "$SETUP_PROFILE" in
    macos) export MISE_ENV=macos ;;
    pi4|wsl2) export MISE_ENV=linux ;;
  esac
  if [ "${DRY_RUN:-0}" = 1 ]; then
    if ! command -v mise >/dev/null 2>&1; then
      log_info "Deployment preview needs mise; install the prerequisite with --only=15 first."
      return 0
    fi
    (cd "$checkout" && python3 "$SETUP_ROOT/preflight-dotfiles.py" --dry-run) || return 1
    local preview_flags=(--dry-run)
    # Native preview skips hooks, so simulate the targets freed by adoption.
    if [ "${DOTFILES_ADOPT:-0}" = 1 ]; then preview_flags+=(--force); fi
    mise -C "$checkout" bootstrap dotfiles apply "${preview_flags[@]}"
  else
    mise -C "$checkout" bootstrap dotfiles apply --yes
  fi
}
