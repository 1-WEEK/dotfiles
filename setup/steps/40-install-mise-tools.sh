#!/usr/bin/env bash
# Install mise tools per ~/.config/mise/config.toml (linked by dotter).
# This step runs after dotter-deploy on first run, so the symlink already exists.

step_check() {
  command -v mise >/dev/null 2>&1 \
    && mise current node >/dev/null 2>&1 \
    && mise current bun >/dev/null 2>&1
}

step_run() {
  if ! command -v mise >/dev/null 2>&1; then
    log_warn "mise not on PATH; re-run after step 20 (or 22)"
    return 1
  fi
  # If config not yet linked, link it temporarily so mise can read tools list.
  local cfg="$HOME/.config/mise/config.toml"
  if [ ! -e "$cfg" ]; then
    mkdir -p "$(dirname "$cfg")"
    log_info "Linking mise/config.toml → $cfg (dotter will replace later)"
    run ln -sf "$DOTFILES_ROOT/mise/config.toml" "$cfg"
  fi
  run mise install
}
