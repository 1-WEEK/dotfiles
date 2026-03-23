export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git autojump zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# aliases
alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
alias lc="colorls -1"

export SCRCPY_SERVER_PATH=/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
export PATH=$PATH:/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools

# OpenClaw Completion
source "/Users/1-week/.openclaw/completions/openclaw.zsh"

# bun completions
[ -s "/Users/1-week/.bun/_bun" ] && source "/Users/1-week/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# mise
eval "$(mise activate zsh)"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# startship
eval "$(starship init zsh)"

# claude code
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
