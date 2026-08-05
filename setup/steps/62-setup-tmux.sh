#!/usr/bin/env bash
# Clone TPM + install tmux plugins listed in tmux/.tmux.conf.
#
# The catppuccin/tmux plugin is pinned to a tag (see tmux/.tmux.conf). TPM
# skips reinstall when the plugin dir already exists, so an existing checkout
# can silently stay on an older tag. Align the checkout to the pinned tag
# before patching: the backport script is written against the pinned source
# and must not run on a drifted version.

TPM_DIR="$HOME/.tmux/plugins/tpm"
CATPPUCCIN_REPO="$HOME/.tmux/plugins/tmux"
CATPPUCCIN_CONF="$CATPPUCCIN_REPO/catppuccin_tmux.conf"
# Pin must match the @plugin line in tmux/.tmux.conf. Keep in sync manually;
# the backport script's anchors are written against this release.
CATPPUCCIN_PIN="v2.1.3"
# Unique marker added by tmux/patch-catppuccin-577.py.
PATCH_MARKER='@catppuccin_window_current_left_separator "#\[fg=#{@catppuccin_window_current_number_color},bg=#{@_ctp_status_bg}\]'

step_check() {
  [ -d "$TPM_DIR" ] && \
    [ -f "$CATPPUCCIN_CONF" ] && \
    grep -q "$PATCH_MARKER" "$CATPPUCCIN_CONF" && \
    [ "$(git -C "$CATPPUCCIN_REPO" rev-parse HEAD 2>/dev/null)" = \
      "$(git -C "$CATPPUCCIN_REPO" rev-parse "$CATPPUCCIN_PIN^{commit}" 2>/dev/null)" ]
}

step_run() {
  clone_or_pull https://github.com/tmux-plugins/tpm "$TPM_DIR"
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    log_info "Installing tmux plugins via TPM"
    run "$TPM_DIR/bin/install_plugins" || log_warn "TPM install failed; press prefix-I inside tmux to retry"
  fi

  # Align the catppuccin checkout to the tag pinned in tmux/.tmux.conf; TPM
  # will not update an existing dir by itself.
  if [ -d "$CATPPUCCIN_REPO/.git" ]; then
    log_info "Aligning catppuccin/tmux to $CATPPUCCIN_PIN"
    run git -C "$CATPPUCCIN_REPO" fetch --depth 1 origin tag "$CATPPUCCIN_PIN"
    run git -C "$CATPPUCCIN_REPO" checkout -q "$CATPPUCCIN_PIN"
  else
    run git clone --depth 1 --branch "$CATPPUCCIN_PIN" \
      https://github.com/catppuccin/tmux "$CATPPUCCIN_REPO"
  fi

  # Backport catppuccin/tmux PR #577 onto the pinned release so the
  # "rounded" window status style works with a transparent status background.
  # Idempotent; safe to re-run. Drop once the pin is bumped past v2.1.3.
  local patch_script
  patch_script="$(cd "$(dirname "$0")/../.." && pwd)/tmux/patch-catppuccin-577.py"
  if [ -x "$patch_script" ]; then
    log_info "Applying catppuccin PR #577 patch"
    run "$patch_script" || log_warn "catppuccin patch failed; check $patch_script"
  fi
}
