#!/usr/bin/env bash
# Write .dotter/local.toml from the active profile, back up any pre-existing
# real files at deploy targets, then run `dotter deploy`.

LOCAL_TOML="$DOTFILES_ROOT/.dotter/local.toml"

# Targets to check before deploy. Add new modules' target paths here.
# Keep in sync with .dotter/global.toml.
DEPLOY_TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.bashrc"
  "$HOME/.bash_profile"
  "$HOME/.vimrc"
  "$HOME/.tmux.conf"
  "$HOME/.config/fish/config.fish"
  "$HOME/.config/fish/fish_plugins"
  "$HOME/.config/mise/config.toml"
  "$HOME/.config/eza/theme.yml"
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
)

step_check() {
  [ -f "$LOCAL_TOML" ] || return 1
  grep -qF "$PROFILE_DOTTER_PACKAGES" "$LOCAL_TOML" 2>/dev/null
}

backup_real_file() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    log_info "Backing up real file → $target.bak"
    run mv "$target" "$target.bak"
  fi
}

step_run() {
  local desired="packages = $PROFILE_DOTTER_PACKAGES"

  # Rewrite local.toml when needed.
  if [ ! -f "$LOCAL_TOML" ] || ! grep -qxF "$desired" "$LOCAL_TOML"; then
    if [ -f "$LOCAL_TOML" ]; then
      log_info "Backing up existing local.toml → local.toml.bak"
      run cp "$LOCAL_TOML" "$LOCAL_TOML.bak"
    fi
    if [ "${DRY_RUN:-0}" = "1" ]; then
      printf '  $ write %s with: %s\n' "$LOCAL_TOML" "$desired"
    else
      printf '%s\n' "$desired" > "$LOCAL_TOML"
    fi
  fi

  # Convert conflicting real files into backups so dotter can symlink.
  for target in "${DEPLOY_TARGETS[@]}"; do
    backup_real_file "$target"
  done

  log_info "Running dotter deploy"
  ( cd "$DOTFILES_ROOT" && run dotter deploy )
}
