#!/usr/bin/env bash
# oh-my-zsh + custom plugins, fisher + fish plugins, optional chsh to fish.

ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
FISHER_FN="$HOME/.config/fish/functions/fisher.fish"

step_check() {
  [ -d "$HOME/.oh-my-zsh" ] \
    && [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ] \
    && [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ] \
    && { ! command -v fish >/dev/null 2>&1 || [ -f "$FISHER_FN" ]; }
}

step_run() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing oh-my-zsh (unattended)"
    run sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  else
    log_skip "oh-my-zsh present"
  fi

  clone_or_pull https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

  # fisher + fish plugins (reads fish/fish_plugins manifest)
  if command -v fish >/dev/null 2>&1; then
    if [ ! -f "$FISHER_FN" ]; then
      log_info "Installing fisher"
      run fish -c '
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
        fisher install jorgebucaran/fisher
      '
    else
      log_skip "fisher present"
    fi
    log_info "Installing fish plugins from fish_plugins manifest"
    run fish -c 'fisher update'
  fi

  # chsh to fish if installed and not already the login shell
  if command -v fish >/dev/null 2>&1; then
    local fish_path; fish_path="$(command -v fish)"
    if [ "$SHELL" != "$fish_path" ]; then
      if ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
        log_info "Adding $fish_path to /etc/shells (sudo)"
        run sh -c "echo $fish_path | sudo tee -a /etc/shells >/dev/null"
      fi
      log_info "Changing login shell to fish (you may need to log out/in)"
      run chsh -s "$fish_path" || log_warn "chsh failed; set manually later"
    fi
  fi
}
