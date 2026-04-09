curl "wttr.in/hangzhou?m"

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git autojump zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# true color
export TERM="xterm-256color"

# aliases
alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
alias lc="colorls --sd --tree=1"
alias nls="npm list --dep=0"
alias gsb="git status -sb"
alias gm="git merge --no-ff"
alias tree="tree -N"
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
alias rm="trash"
alias mv_comit="find . -name \"*\.zip\" -print0 |  xargs -0 -I {} mv {} ."
alias localip="ifconfig en0 | grep 'net[ ]' | awk '{print $2}'"

# gpg
export GPG_TTY=$(tty)

# 极空间
export SCRCPY_SERVER_PATH=/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
export PATH=$PATH:/Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools

# OpenClaw Completion
if [ -f "$HOME/.openclaw/completions/openclaw.zsh" ]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi

# opencli completion
fpath=($HOME/.zsh/completions $fpath)

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# claude code
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# startship
eval "$(starship init zsh)"

# mise
eval "$(mise activate zsh)"
