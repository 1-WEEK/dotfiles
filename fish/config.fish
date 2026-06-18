# ============================================================
# Cross-platform fish config (macOS + Linux/WSL2)
# ============================================================

# OS detection + Homebrew shellenv
switch (uname)
    case Darwin
        set -gx BREW_PREFIX /opt/homebrew
        set -gx SETUP_OS macos
    case Linux
        set -gx BREW_PREFIX /home/linuxbrew/.linuxbrew
        set -gx SETUP_OS linux
end
test -x $BREW_PREFIX/bin/brew; and $BREW_PREFIX/bin/brew shellenv fish | source

function __path_remove --argument-names dir
    while contains -- "$dir" $PATH
        set -l path_index (contains -i -- "$dir" $PATH)
        set -e PATH[$path_index]
    end
end

function __path_prepend --argument-names dir
    test -d "$dir"; or return
    __path_remove "$dir"
    set -gx PATH "$dir" $PATH
end

function __path_append --argument-names dir
    test -d "$dir"; or return
    __path_remove "$dir"
    set -gx PATH $PATH "$dir"
end

# --- env ---
set -gx TERM xterm-256color

# --- mise (always; sets up shell hooks) ---
if type -q mise
    mise activate fish | source
end

# Keep PATH order explicit in config.fish, not fish_user_paths:
# mise shims -> Homebrew -> user bins -> tool installs/system -> app-bundled tools.
__path_prepend $HOME/.antigravity/antigravity/bin
__path_prepend $HOME/.local/bin
__path_prepend $BREW_PREFIX/sbin
__path_prepend $BREW_PREFIX/bin
__path_prepend $HOME/.local/share/mise/shims

# macOS-only env
if test "$SETUP_OS" = macos
    set -gx SCRCPY_SERVER_PATH /Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
    __path_append /Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools
end

functions -e __path_remove __path_prepend __path_append

# macOS remote SSH sessions: Keychain agent socket isn't forwarded to SSH sessions
if test "$SETUP_OS" = macos; and set -q SSH_CONNECTION
    set -gx SSH_AUTH_SOCK $HOME/.ssh/ssh-agent.sock
    /usr/bin/ssh-add -l >/dev/null 2>&1
    if test $status -eq 2
        rm -f $SSH_AUTH_SOCK
        /usr/bin/ssh-agent -a $SSH_AUTH_SOCK >/dev/null 2>&1
    end
    set _fp (ssh-keygen -l -E sha256 -f ~/.ssh/id_ed25519.pub 2>/dev/null | string split ' ')[2]
    if test -n "$_fp"; and not /usr/bin/ssh-add -l 2>/dev/null | string match -q "*$_fp*"
        /usr/bin/ssh-add --apple-load-keychain ~/.ssh/id_ed25519 >/dev/null 2>&1
    end
    set -e _fp
end

# ============================================================
# Interactive-only
# ============================================================
if status is-interactive
    # SSH Agent Management (Linux only — macOS remote SSH sessions handled above)
    if test "$SETUP_OS" = linux; and type -q keychain
        keychain --quiet ~/.ssh/id_ed25519
        set -l kc_file ~/.keychain/(hostname -s)-fish
        test -f $kc_file; and source $kc_file
    end

   # gnome-keyring secrets
    if test "$SETUP_OS" = linux
        if type -q gnome-keyring-daemon
            if test -z "$GNOME_KEYRING_CONTROL"
                gnome-keyring-daemon --start --components=secrets --daemonize >/dev/null 2>&1
            end
        end
    end

    set -gx GPG_TTY (tty)

    # autojump (replaces the oh-my-zsh autojump plugin)
    if test -f $BREW_PREFIX/share/autojump/autojump.fish
        source $BREW_PREFIX/share/autojump/autojump.fish
    end

    # starship prompt (after mise activate so node/ruby/rust segments resolve)
    if type -q starship
        starship init fish | source
    end

    # --- generic env ---
    set -gx EZA_ICONS_AUTO 1

    # --- generic aliases (cross-platform) ---
    alias ls="eza"
    alias lc="eza --tree --level=1 --sort=size"
    alias nls="npm list --dep=0"
    alias gsb="git status -sb"
    alias gm="git merge --no-ff"
    alias tree="tree -N"
    alias mv_comit="find . -name '*.zip' -print0 | xargs -0 -I {} mv {} ."

    # --- macOS-only aliases / sources ---
    if test "$SETUP_OS" = macos
        alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
        alias chrome='"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'
        alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
        alias rm="trash"
        alias localip="ifconfig en0 | grep 'net ' | awk '{print \$2}'"

        # OpenClaw Completion (installed via `openclaw completion -s fish -i`)
        if test -f $HOME/.openclaw/completions/openclaw.fish
            source $HOME/.openclaw/completions/openclaw.fish
        end
    end
end

# ============================================================
# NOTE: zsh-only completions still pending fish equivalents:
#   - $HOME/.zsh/completions   (zsh fpath dir)
# When a tool ships fish completions, drop them in
# ~/.config/fish/completions/<cmd>.fish.
# ============================================================
