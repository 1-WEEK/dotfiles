# Cross-platform bash config (macOS + Linux/WSL2)

# OS detection + Homebrew shellenv
case "$OSTYPE" in
  darwin*) BREW_PREFIX="/opt/homebrew";              SETUP_OS="macos" ;;
  linux*)  BREW_PREFIX="/home/linuxbrew/.linuxbrew"; SETUP_OS="linux" ;;
esac
[[ -x "$BREW_PREFIX/bin/brew" ]] && eval "$($BREW_PREFIX/bin/brew shellenv)"

# ~/.local/bin (Claude Code etc.)
export PATH="$HOME/.local/bin:$PATH"

# mise (always; matches zsh/fish)
command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

# Keep mise shims ahead of Homebrew (CLAUDE.md invariant)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# SSH Agent Management + gnome-keyring (interactive only)
# macOS uses system Keychain automatically. Linux/WSL2 uses keychain to persist across sessions.
case $- in
  *i*)
    if [[ "$SETUP_OS" == "linux" ]] && command -v keychain >/dev/null 2>&1; then
      keychain --quiet ~/.ssh/id_ed25519
      kc_file="$HOME/.keychain/$(hostname -s)-bash"
      [[ -f "$kc_file" ]] && source "$kc_file"
    fi

    if [[ "$SETUP_OS" == "linux" ]] && command -v gnome-keyring-daemon >/dev/null 2>&1; then
      if [[ -z "$GNOME_KEYRING_CONTROL" ]]; then
        gnome-keyring-daemon --start --components=secrets --daemonize >/dev/null 2>&1
      fi
    fi
    ;;
esac

# starship (interactive only)
case $- in
  *i*) command -v starship >/dev/null 2>&1 && eval "$(starship init bash)" ;;
esac
