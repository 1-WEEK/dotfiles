#!/usr/bin/env bash
# oh-my-zsh + custom plugins, fisher + fish plugins, optional chsh to fish.

ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
FISHER_FN="$HOME/.config/fish/functions/fisher.fish"
OMZ_MAIN="$HOME/.oh-my-zsh/oh-my-zsh.sh"

step_check() {
  [ -f "$OMZ_MAIN" ] \
    && [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ] \
    && [ -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ] \
    && { ! command -v fish >/dev/null 2>&1 || [ -f "$FISHER_FN" ]; }
}

step_run() {
  if [ ! -f "$OMZ_MAIN" ]; then
    log_info "Installing oh-my-zsh (unattended)"
    if [ -d "$HOME/.oh-my-zsh" ]; then
      # Partial checkout (e.g. core files wiped but custom/ left behind):
      # move aside so the installer can bootstrap a fresh copy. Plugins are
      # re-cloned below, so nothing is lost.
      log_info "Moving incomplete ~/.oh-my-zsh aside"
      run mv "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh.bak.$(date +%s)"
    fi
    run bash -c '
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    '
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
  # (best-effort: skip cleanly when we lack sudo)
  if command -v fish >/dev/null 2>&1 && command -v chsh >/dev/null 2>&1; then
    local fish_path; fish_path="$(command -v fish)"
    if [ "$SHELL" != "$fish_path" ]; then
      if ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
        if ! sudo -n sh -c "echo $fish_path >> /etc/shells" 2>/dev/null; then
          log_warn "Cannot add $fish_path to /etc/shells without sudo; skipping chsh"
          return 0
        fi
      fi
      log_info "Changing login shell to fish (you may need to log out/in)"
      run chsh -s "$fish_path" || log_warn "chsh failed; set manually later"
    fi
  fi
}
