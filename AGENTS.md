# AGENTS.md

This file provides guidance to coding agents when working with this repository.

## What this is

Personal cross-platform dotfiles (macOS / Pi4 64-bit Linux / WSL2 Ubuntu 24) managed by native mise dotfiles. `mise/config.toml` declares shared tools and configuration links; `mise/config.macos.toml` adds Ghostty on macOS. Deployment sources live at `~/.dotfiles`.

## Common commands

- `MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply` — deploy configuration
- `MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply --dry-run` — preview
- `setup/bootstrap.sh --auto` — bootstrap a fresh machine ([details](docs/bootstrap.md))
- Manico sync (special):
  - `./manico/sync.sh export` — capture current prefs into `manico/settings.txt`
  - `./manico/sync.sh import` — apply prefs via `defaults write` and restart Manico

To add a managed file, add a `[dotfiles]` entry with a source under `~/.dotfiles`. For migration, conflicts, and backup adoption, read [docs/dotfiles-migration.md](docs/dotfiles-migration.md).

## Project structure

```
.
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

1. **Native deployment uses platform environments.** Include `MISE_AUTO_ENV=true` for host platform selection. Keep `~/.config/mise/config.local.toml` host-owned. The pre-dotfiles hook requires the latest stable mise and explicit adoption for conflicts; `--auto` does not authorize backups.

2. **`zsh/.zshrc`, `fish/config.fish`, and `bash/.bashrc` are kept in sync.** Changes to one shell's env/PATH should be mirrored to the others unless intentionally shell-specific.

3. **catppuccin/tmux v2.1.3 is patched in-place.** `~/.tmux/plugins/tmux/catppuccin_tmux.conf` gets a backport of [PR #577](https://github.com/catppuccin/tmux/pull/577) via `tmux/patch-catppuccin-577.py`. Required because the plugin bakes separator vars into `window-status-format` at load time, so `.tmux.conf` overrides don't propagate. Re-run `./setup/bootstrap.sh --only=62` after any plugin reinstall. Remove both the script and setup hook once the pinned tag is bumped past a release containing PR #577.

## Agent skills

### Issue tracker

Issues live as Markdown files under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The default canonical triage labels are used: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

The repository uses a single-context layout. See `docs/agents/domain.md`.
