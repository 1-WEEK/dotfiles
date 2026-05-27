# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## What this is

Personal cross-platform dotfiles (macOS / Pi4 64-bit Linux / WSL2 Ubuntu 24) managed by [Dotter](https://github.com/SuperCuber/dotter). Each top-level dir is a module; `.dotter/global.toml` declares which file is symlinked where.

## Common commands

- `dotter deploy` — apply symlinks to `$HOME`
- `dotter -d` — dry-run
- `setup/bootstrap.sh --auto` — bootstrap a fresh machine ([details](docs/bootstrap.md))
- Manico sync (special):
  - `./manico/sync.sh export` — capture current prefs into `manico/settings.txt`
  - `./manico/sync.sh import` — apply prefs via `defaults write` and restart Manico

To add a new managed file: edit `.dotter/global.toml`, then `dotter deploy`.

## Project structure

```
.
├── .dotter/          # symlink mappings (global.toml + local.toml)
├── setup/            # bootstrap scripts
│   ├── bootstrap.sh  # entry point
│   ├── steps/        # numbered deploy steps
│   ├── packages/     # Brewfiles + apt lists
│   └── profiles/     # macos / pi4 / wsl2
├── bash/ fish/ zsh/  # shell configs
├── ghostty/          # terminal config
├── tmux/             # tmux + catppuccin patch
├── mise/             # runtime versions (mise is canonical source of truth)
└── manico/           # sync script + settings
```

## Environment hierarchy

| Layer | Role | Examples |
|-------|------|----------|
| mise | Version manager of managers | node, python, uv, rust, bun |
| Homebrew | System deps and GUI apps | git, ripgrep, Ghostty, Manico |
| curl \| sh | Last resort | claude-code installer |

Details: [docs/philosophy.md](docs/philosophy.md)

## Platform conventions

- Shell rc files set `$SETUP_OS` (`macos`/`linux`) and `$BREW_PREFIX` at the top.
- macOS-only blocks use `if [[ "$SETUP_OS" == "macos" ]]`.
- Login shell is Fish; Zsh and Bash are fallbacks. Keep them in sync.
- mise shims must precede Homebrew on PATH.
- mise activate must precede starship init.

## Three gotchas

1. **Per-host packages are gated by `.dotter/local.toml`.** After adding a module to `global.toml`, also append it to `local.toml` or `dotter deploy` will silently skip it.

2. **`zsh/.zshrc`, `fish/config.fish`, and `bash/.bashrc` are kept in sync.** Changes to one shell's env/PATH should be mirrored to the others unless intentionally shell-specific.

3. **catppuccin/tmux v2.1.3 is patched in-place.** `~/.tmux/plugins/tmux/catppuccin_tmux.conf` gets a backport of [PR #577](https://github.com/catppuccin/tmux/pull/577) via `tmux/patch-catppuccin-577.py`. Required because the plugin bakes separator vars into `window-status-format` at load time, so `.tmux.conf` overrides don't propagate. Re-run `./setup/bootstrap.sh --only=62` after any plugin reinstall. Remove both the script and setup hook once the pinned tag is bumped past a release containing PR #577.
