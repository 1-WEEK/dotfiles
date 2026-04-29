#!/usr/bin/env bash
# Clone TPM + install tmux plugins listed in tmux/.tmux.conf.

TPM_DIR="$HOME/.tmux/plugins/tpm"

step_check() {
  [ -d "$TPM_DIR" ]
}

step_run() {
  clone_or_pull https://github.com/tmux-plugins/tpm "$TPM_DIR"
  if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    log_info "Installing tmux plugins via TPM"
    run "$TPM_DIR/bin/install_plugins" || log_warn "TPM install failed; press prefix-I inside tmux to retry"
  fi
}
