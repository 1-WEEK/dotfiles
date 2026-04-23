# Prefer mise-managed shims over Homebrew binaries for Node/OpenClaw.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Load .bashrc when present.
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
