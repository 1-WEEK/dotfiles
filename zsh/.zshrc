export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git autojump zsh-autosuggestions zsh-syntax-highlighting)

# zsh completions fpath (must be set before oh-my-zsh sources compinit)
fpath=($HOME/.zsh/completions $fpath)
source $ZSH/oh-my-zsh.sh

# OS detection + Homebrew shellenv
case "$OSTYPE" in
  darwin*) BREW_PREFIX="/opt/homebrew";          SETUP_OS="macos" ;;
  linux*)  BREW_PREFIX="/home/linuxbrew/.linuxbrew"; SETUP_OS="linux" ;;
esac
[[ -x "$BREW_PREFIX/bin/brew" ]] && eval "$($BREW_PREFIX/bin/brew shellenv)"

path_remove() {
  local dir="$1"
  [[ -n "$dir" ]] || return 0
  PATH=":$PATH:"
  PATH="${PATH//:$dir:/:}"
  PATH="${PATH#:}"
  PATH="${PATH%:}"
}

path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path_remove "$dir"
  PATH="$dir${PATH:+:$PATH}"
}

path_append() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path_remove "$dir"
  PATH="${PATH:+$PATH:}$dir"
}

# true color
export TERM="xterm-256color"

# gpg
export GPG_TTY=$(tty)

# SSH Agent Management (Linux only — macOS remote SSH sessions handled above)
if [[ "$SETUP_OS" == "linux" ]] && command -v keychain >/dev/null 2>&1; then
  keychain --quiet ~/.ssh/id_ed25519
  kc_file="$HOME/.keychain/$(hostname -s)-zsh"
  [[ -f "$kc_file" ]] && source "$kc_file"
fi

# macOS remote SSH sessions: Keychain agent socket isn't forwarded to SSH sessions
if [[ "$SETUP_OS" == "macos" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
  /usr/bin/ssh-add -l >/dev/null 2>&1
  if [[ $? -eq 2 ]]; then
    rm -f "$SSH_AUTH_SOCK"
    /usr/bin/ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null 2>&1
  fi
  _fp=$(ssh-keygen -l -E sha256 -f ~/.ssh/id_ed25519.pub 2>/dev/null | awk '{print $2}')
  if [[ -n "$_fp" ]] && ! /usr/bin/ssh-add -l 2>/dev/null | grep -qF "$_fp"; then
    /usr/bin/ssh-add --apple-load-keychain ~/.ssh/id_ed25519 >/dev/null 2>&1
  fi
  unset _fp
fi

# gnome-keyring secrets
if [[ "$SETUP_OS" == "linux" ]]; then
  if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    if [[ -z "$GNOME_KEYRING_CONTROL" ]]; then
      gnome-keyring-daemon --start --components=secrets --daemonize >/dev/null 2>&1
    fi
  fi
fi

# generic env
export EZA_ICONS_AUTO=1

# generic aliases (cross-platform)
alias ls="eza"
alias lc="eza --tree --level=1 --sort=size"
alias nls="npm list --dep=0"
alias gsb="git status -sb"
alias gm="git merge --no-ff"
alias tree="tree -N"
alias mv_comit="find . -name \"*\.zip\" -print0 |  xargs -0 -I {} mv {} ."

# macOS-only aliases / sources
if [[ "$SETUP_OS" == "macos" ]]; then
  alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
  alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
  alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
  alias rm="trash"
  alias localip="ifconfig en0 | grep 'net[ ]' | awk '{print \$2}'"

  # OpenClaw completion
  if [ -f "$HOME/.openclaw/completions/openclaw.zsh" ]; then
    source "$HOME/.openclaw/completions/openclaw.zsh"
  fi
fi

# mise (must run before starship so prompt sees mise versions)
eval "$(mise activate zsh)"

# Keep PATH order explicit and synced with fish/bash:
# mise shims -> Homebrew -> user bins -> tool installs/system -> app-bundled tools.
path_prepend "$HOME/.antigravity/antigravity/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$BREW_PREFIX/sbin"
path_prepend "$BREW_PREFIX/bin"
path_prepend "$HOME/.local/share/mise/shims"
if [[ "$SETUP_OS" == "macos" ]]; then
  export SCRCPY_SERVER_PATH=/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
  path_append "/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools"
fi
export PATH
unset -f path_remove path_prepend path_append

# starship
eval "$(starship init zsh)"
