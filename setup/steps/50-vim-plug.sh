#!/usr/bin/env bash
# Install vim-plug + run :PlugInstall. .vimrc declares 22 plugins.

PLUG_VIM="$HOME/.vim/autoload/plug.vim"

step_check() {
  [ -f "$PLUG_VIM" ]
}

step_run() {
  if [ ! -f "$PLUG_VIM" ]; then
    log_info "Installing vim-plug"
    run curl -fsSL --create-dirs -o "$PLUG_VIM" \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    log_skip "vim-plug present"
  fi
  if command -v vim >/dev/null 2>&1; then
    log_info "Running :PlugInstall (headless)"
    run vim +PlugInstall +qall
  else
    log_warn "vim not on PATH; install vim then re-run --only=50-vim-plug"
  fi
}
