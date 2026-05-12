# Login-shell PATH bootstrap. Runs for non-interactive logins (cron, ssh -c)
# that skip .zshrc — without mise activate here, jobs can pick up Homebrew
# Node instead of mise's, breaking plugins built against the mise version.

case "$OSTYPE" in
  darwin*) BREW_PREFIX="/opt/homebrew" ;;
  linux*)  BREW_PREFIX="/home/linuxbrew/.linuxbrew" ;;
esac
[ -x "$BREW_PREFIX/bin/brew" ] && eval "$($BREW_PREFIX/bin/brew shellenv)"

[ -f "$HOME/.orbstack/shell/init.zsh" ] && source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
# >>> Nowledge Mem PATH >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Nowledge Mem PATH <<<
