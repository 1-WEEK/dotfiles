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

# --- PATH additions (fish_add_path is idempotent; skips missing dirs) ---
fish_add_path $HOME/.antigravity/antigravity/bin
fish_add_path $HOME/.local/bin

# --- env ---
set -gx TERM xterm-256color

# --- mise (always; sets up shell hooks) ---
if type -q mise
    mise activate fish | source
end

# Keep mise shims ahead of Homebrew (CLAUDE.md invariant).
# --move relocates the path if it's already in PATH; plain fish_add_path
# would silently leave it after /opt/homebrew/bin.
fish_add_path --prepend --move $HOME/.local/share/mise/shims

# macOS-only env
if test "$SETUP_OS" = macos
    set -gx SCRCPY_SERVER_PATH /Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools/scrcpy-server
    fish_add_path /Applications/极空间.app/Contents/Resources/app.asar.unpacked/bin/platform-tools
end

# ============================================================
# Interactive-only
# ============================================================
if status is-interactive
    # SSH Agent Management
    # macOS uses system Keychain automatically. Linux/WSL2 uses keychain to persist across sessions.
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

    # --- generic aliases (cross-platform) ---
    alias lc="colorls --sd --tree=1"
    alias nls="npm list --dep=0"
    alias gsb="git status -sb"
    alias gm="git merge --no-ff"
    alias tree="tree -N"

    # --- macOS-only aliases / sources ---
    if test "$SETUP_OS" = macos
        alias tmm="/Applications/tinyMediaManager.app/Contents/MacOS/tinyMediaManager"
        alias gitbk_serve="gitbook --lrport 9999 --port 31231 serve"
        alias rm="trash"

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
