# Dotfiles

Personal cross-platform dotfiles for macOS, Raspberry Pi 4 (64-bit Linux), and WSL2 Ubuntu 24.

## What's included

| Tool | Files |
|------|-------|
| Bash | `.bashrc`, `.bash_profile` |
| Zsh | `.zshrc` |
| Fish | `config.fish` |
| Vim | `.vimrc` |
| Tmux | `.tmux.conf` |
| Ghostty | Terminal config |
| Manico | App switcher settings |

Everything is symlinked to `$HOME` via [Dotter](https://github.com/SuperCuber/dotter). Each top-level directory is one module; `.dotter/global.toml` maps files to their target paths.

## Quick start on a new machine

```bash
git clone git@github.com:1-WEEK/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup/bootstrap.sh
```

The bootstrap script detects your platform and installs dependencies. It is idempotent: running it twice does nothing. See [`docs/bootstrap.md`](docs/bootstrap.md) for flags, step details, and how to add a new step.

## Project layout

```
.
├── .dotter/          # symlink mappings (global.toml)
├── setup/            # bootstrap scripts
│   ├── bootstrap.sh  # entry point
│   ├── steps/        # numbered deploy steps
│   ├── packages/     # Brewfiles + apt lists
│   └── profiles/     # macos / pi4 / wsl2
├── bash/ fish/ zsh/  # shell configs
├── ghostty/          # terminal config
├── tmux/             # tmux + catppuccin patch
├── mise/             # runtime versions
└── manico/           # sync script + settings
```

## Managed by

- **Dotter** for file symlinks (`dotter deploy`)
- **mise** for language runtimes and global CLI tools ([philosophy](docs/philosophy.md))
- **Homebrew** for system-level dependencies and GUI apps

## Platform conventions

- Shell rc files set `$SETUP_OS` (`macos` or `linux`) and `$BREW_PREFIX` at the top.
- macOS-only blocks are wrapped in `if [[ "$SETUP_OS" == "macos" ]]`.
- Login shell is Fish; Zsh and Bash are maintained as fallbacks.

## Manico sync

Manico is not symlinked because its plist contains device-specific IDs and licenses. Use the sync script instead:

```bash
./manico/sync.sh export   # capture current prefs into manico/settings.txt
./manico/sync.sh import   # apply settings on a new machine
```

You will still need to activate your license manually.

## Tmux plugins

After first deploy, install [TPM](https://github.com/tmux-plugins/tpm):

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then open tmux and press `prefix + I` to install plugins.

## Common commands

| Command | Purpose |
|---------|---------|
| `dotter deploy` | Apply symlinks to `$HOME` |
| `dotter -d` | Dry-run: show what would change |
| `./setup/bootstrap.sh --auto` | Non-interactive bootstrap |
| `./setup/bootstrap.sh --list` | Show steps for the active profile |
| `./setup/bootstrap.sh --only=62` | Run a single step |
