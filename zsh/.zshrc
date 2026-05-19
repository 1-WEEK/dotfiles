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

# true color
export TERM="xterm-256color"

# gpg
export GPG_TTY=$(tty)

# SSH Agent Management
# macOS uses system Keychain automatically. Linux/WSL2 uses keychain to persist across sessions.
if [[ "$SETUP_OS" == "linux" ]] && command -v keychain >/dev/null 2>&1; then
  keychain --quiet ~/.ssh/id_ed25519
  kc_file="$HOME/.keychain/$(hostname -s)-zsh"
  [[ -f "$kc_file" ]] && source "$kc_file"
fi

# gnome-keyring secrets
if [[ "$SETUP_OS" == "linux" ]]; then
  if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    if [[ -z "$GNOME_KEYRING_CONTROL" ]]; then
      gnome-keyring-daemon --start --components=secrets --daemonize >/dev/null 2>&1
    fi
  fi
fi

# generic aliases (cross-platform)
alias lc="colorls --sd --tree=1"
alias nls="npm list --dep=0"
alias gsb="git status -sb"
alias gm="git merge --no-ff"
alias tree="tree -N"
alias mv_comit="find . -name \"*\.zip\" -print0 |  xargs -0 -I {} mv {} ."

# macOS-only aliases / PATH / sources
if [[ "$SETUP_OS" == "macos" ]]; then
  alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
  alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
  alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
  alias rm="trash"
  alias localip="ifconfig en0 | grep 'net[ ]' | awk '{print \$2}'"

  # 极空间
  export SCRCPY_SERVER_PATH=/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
  export PATH=$PATH:/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools

  # OpenClaw completion
  if [ -f "$HOME/.openclaw/completions/openclaw.zsh" ]; then
    source "$HOME/.openclaw/completions/openclaw.zsh"
  fi
fi

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# claude code
export PATH="$HOME/.local/bin:$PATH"

# mise (must run before starship so prompt sees mise versions)
eval "$(mise activate zsh)"

# Keep mise shims ahead of Homebrew (CLAUDE.md invariant)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# starship
eval "$(starship init zsh)"
