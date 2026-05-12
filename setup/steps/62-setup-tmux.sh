#!/usr/bin/env bash
# Clone TPM + install tmux plugins listed in tmux/.tmux.conf.

TPM_DIR="$HOME/.tmux/plugins/tpm"
CATPPUCCIN_CONF="$HOME/.tmux/plugins/tmux/catppuccin_tmux.conf"
# Unique marker added by tmux/patch-catppuccin-577.py.
PATCH_MARKER='@catppuccin_window_current_left_separator "#\[fg=#{@catppuccin_window_current_number_color},bg=#{@_ctp_status_bg}\]'

step_check() {
  [ -d "$TPM_DIR" ] && \
    [ -f "$CATPPUCCIN_CONF" ] && \
    grep -q "$PATCH_MARKER" "$CATPPUCCIN_CONF"
}

step_run() {
  clone_or_pull https://github.com/tmux-plugins/tpm "$TPM_DIR"
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    log_info "Installing tmux plugins via TPM"
    run "$TPM_DIR/bin/install_plugins" || log_warn "TPM install failed; press prefix-I inside tmux to retry"
  fi

  # Backport catppuccin/tmux PR #577 onto the pinned v2.1.3 release so the
  # "rounded" window status style works with a transparent status background.
  # Idempotent; safe to re-run. Drop once the pin is bumped past v2.1.3.
  local patch_script
  patch_script="$(cd "$(dirname "$0")/../.." && pwd)/tmux/patch-catppuccin-577.py"
  if [ -x "$patch_script" ]; then
    log_info "Applying catppuccin PR #577 patch"
    run "$patch_script" || log_warn "catppuccin patch failed; check $patch_script"
  fi
}
