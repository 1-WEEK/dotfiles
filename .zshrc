(node ~/.loading/loading.js &)

# Stylizing Powerlevel9k Prompt
POWERLEVEL9K_MODE='awesome-fontconfig'
POWERLEVEL9K_APPLE_ICON=""
POWERLEVEL9K_HOME_ICON=""
POWERLEVEL9K_FOLDER_ICON=" "
POWERLEVEL9K_HOME_SUB_ICON=" "
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_DIR_HOME_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND="white"
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND="white"
POWERLEVEL9K_DIR_HOME_BACKGROUND="red"
POWERLEVEL9K_DIR_HOME_SUBFOLDER_BACKGROUND="red"
POWERLEVEL9K_OS_ICON_BACKGROUND="60"
# POWERLEVEL9K_OS_ICON_FOREGROUND="white"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(nvm)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{197}%F{75}%F{226} "
# POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{60}%F{103}%F{110} "

# ZSH-NVM
export NVM_DIR="/Users/bayes/.nvm"
export NVM_LAZY_LOAD=true
# export NVM_AUTO_USE=true

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/bayes/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="powerlevel9k/powerlevel9k"

#if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
#  export DEFAULT_USER="bayes"
#  MY_THEME="powerlevel9k/powerlevel9k"
#else
#  MY_THEME="refined"
#fi
MY_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME=$MY_THEME

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(zsh-autosuggestions git autojump zsh-syntax-highlighting tig zsh-nvm osx zsh-iterm-touchbar npm node git-open thefuck)
plugins=(git autojump zsh-nvm git-open zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export TERM="xterm-256color"

# my alias set
alias lc="colorls --sd --tree=1"
alias nls="npm list --dep=0"
alias gsb="git status -sb"
alias gm="git merge --no-ff"
alias oanki="launchctl load ~/Library/LaunchAgents/user.launchkeep.anki.plist"
alias qanki="launchctl remove user.launchkeep.anki"
alias tree="tree -N"
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias qtalk="printf 'p *(char*)(void(*)())AudioDeviceDuck=0xc3\nq' | lldb -n QQ"
alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
alias rm="trash"

alias ali="ssh bayes@139.196.143.151"

# where proxy
proxy () {
  export https_proxy=http://127.0.0.1:8888
  export http_proxy=http://127.0.0.1:8888
  export all_proxy=socks5://127.0.0.1:8889
  echo "Proxy on"
}

# where noproxy
noproxy () {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo "Proxy off"
}

export ANDROID_SDK_ROOT="/Users/bayes/Library/Android/sdk"
export ANDROID_HOME="/Users/bayes/Library/Android/sdk"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="/usr/local/sbin:$PATH:$HOME/.rvm/bin:${ANDROID_SDK_ROOT}/tools:${ANDROID_SDK_ROOT}/build-tools/28.0.2:${ANDROID_SDK_ROOT}/platform-tools:$HOME/.build/bin"

export RPC_HOST=192.168.1.22
export USDT_RPC_HOST=192.168.1.22
export WEB3_PROVIDER=http://192.168.1.22:8545
curl "wttr.in/hangzhou?m"
