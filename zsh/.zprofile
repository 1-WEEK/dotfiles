# Login-shell PATH bootstrap. Runs for non-interactive logins (cron, ssh -c)
# that skip .zshrc — without mise activate here, jobs can pick up Homebrew
# Node instead of mise's, breaking plugins built against the mise version.

case "$OSTYPE" in
  darwin*) BREW_PREFIX="/opt/homebrew"; SETUP_OS="macos" ;;
  linux*)  BREW_PREFIX="/home/linuxbrew/.linuxbrew"; SETUP_OS="linux" ;;
esac
[ -x "$BREW_PREFIX/bin/brew" ] && eval "$($BREW_PREFIX/bin/brew shellenv)"

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

[ -f "$HOME/.orbstack/shell/init.zsh" ] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

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
