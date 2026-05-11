# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal cross-platform dotfiles (macOS / Pi4 64-bit Linux / WSL2 Ubuntu 24) managed by [Dotter](https://github.com/SuperCuber/dotter). Each top-level dir is a module; `.dotter/global.toml` declares which file in the module is symlinked where. Shell rc files (`zsh/.zshrc`, `fish/config.fish`, `bash/.bashrc`) detect OS at startup and gate platform-specific blocks behind `$SETUP_OS` checks.

## Common commands

- `dotter deploy` — apply symlinks to `$HOME`
- `dotter -d` — dry-run / show what would change
- `setup/bootstrap.sh --auto` — bootstrap a fresh machine (see `setup/README.md`)
- Manico sync (special, see below):
  - `./manico/sync.sh export` — capture current Manico prefs into `manico/settings.txt` (run before commit)
  - `./manico/sync.sh import` — apply `manico/settings.txt` via `defaults write` and restart Manico

To add a new managed file: edit `.dotter/global.toml`, then `dotter deploy`.

## Bootstrapping a new machine

`setup/bootstrap.sh` is the entry point. It auto-detects OS / arch / WSL / Pi distro and selects a profile (`macos` / `pi4` / `wsl2`). Each step is in `setup/steps/NN-*.sh` and is independently runnable via `--only=NN`. Package lists live in `setup/packages/` (Brewfile.common is cross-platform, Brewfile.macos adds taps + casks, apt.fallback.txt is for Pi4 armv7 where linuxbrew isn't supported). See `setup/README.md`.

## Architectural rules these configs encode

- **mise shims must beat Homebrew on PATH.** Every shell rc redundantly prepends `~/.local/share/mise/shims` after tool init. Reason (from a comment in `.zprofile` not in this repo): a previous incident had OpenClaw running under Homebrew Node 25 while its plugins were built for Node 24. If you refactor PATH logic, preserve this ordering.
- **Manico is *not* symlinked.** Other apps' configs are linked via Dotter; Manico is plist-based and contains device-specific IDs/licenses, so `sync.sh` round-trips only a non-sensitive subset through `defaults read`/`defaults write`. License must be re-entered on each new machine.
- **Interactive-only vs always-loaded.** `fish/config.fish` puts PATH/env in the always-loaded section and gates prompt/aliases/autojump behind `if status is-interactive`. Match this convention when editing.
- **Completion files for CLI tools live outside this repo** (`~/.zsh/completions/`, `~/.config/fish/completions/`, `~/.openclaw/completions/`). They are regenerated per-machine (e.g. `bun completions > ~/.zsh/completions/_bun`, `openclaw completion -s fish -i`) and intentionally not under Dotter.

## Environment management philosophy

This dotfiles repo encodes a single principle: **mise is the canonical source of truth for all language runtimes and global CLI tools.** Everything else is either a system dependency or a temporary workaround.

### The hierarchy

| Layer | Role | Examples | How it's added |
|-------|------|----------|----------------|
| **mise** | Version manager of managers. Locks runtime & tool versions in `mise/config.toml`. | node, python, uv, ruby, rust, bun, cargo tools, npm packages, pipx tools | `mise use -g <tool>` |
| **Homebrew** | System-level dependencies and GUI apps only. Never installs language runtimes that mise can handle. | git, ripgrep, ffmpeg, Ghostty, Manico | `brew install` / Brewfile |
| **uv** | Python-internal workflow tool. Managed *by* mise, not alongside it. | Python venvs, package resolution, `uv tool install` (called by mise pipx backend) | `mise use -g uv` |
| **curl \| sh** | Last resort for things neither mise nor brew cover. | claude-code installer | New `setup/steps/NN-*.sh` |

### Rules derived from this

1. **No language runtime goes through Homebrew if mise has it.** Python, Node, Ruby, Rust, Bun, uv — all via mise. Brew may still *pull in* a Python as a transitive dependency (e.g. `git-filter-repo` needs `python@3.13`), but that Python is not for human use.

2. **No standalone `uv tool install` or `pip install --user`.** If a Python CLI tool needs to be global and version-locked, it goes through `mise use -g pipx:<name>` so it appears in `mise/config.toml` and `mise list`. The pipx backend happens to invoke `uv tool install` under the hood, but the *ownership* is mise's.

3. **No `python3` or `pip3` aliases that bypass mise.** After `mise activate`, `python3` and `pip3` resolve through `~/.local/share/mise/shims`. Brew's `python@3.14` and the system Python in `/usr/bin/python3` are still present but are not on the interactive PATH ahead of mise.

4. **Every new machine should reach the same state from `mise/config.toml` alone.** If you install something via `uv tool install`, `npm install -g`, `cargo install`, or `gem install` *outside* of mise, it's invisible to other machines. Convert it to a `mise use -g` declaration.

## Gotchas

- **Per-host packages are gated by `.dotter/local.toml`.** `global.toml` only declares mappings; only packages listed in `local.toml`'s `packages = [...]` actually get deployed. After adding a new module to `global.toml`, also append it to `local.toml`, otherwise `dotter deploy` will silently skip it.
- **`zsh/.zshrc`, `fish/config.fish`, and `bash/.bashrc` are kept in sync.** Login shell is fish; zsh and bash remain as working fallbacks. Changes to one shell's env/PATH should be mirrored to the others unless intentionally shell-specific.
- **Cross-platform shell rc.** Each rc file sets `$SETUP_OS` (`macos`/`linux`) and `$BREW_PREFIX` (`/opt/homebrew` vs `/home/linuxbrew/.linuxbrew`) at the top, then sources brew shellenv conditionally. macOS-only aliases / PATH / completions are wrapped in `if [[ "$SETUP_OS" == "macos" ]]` blocks. Don't undo this — the same file must work on all three platforms.
- **mise activate must precede starship init.** Otherwise starship prompt segments (node/ruby/rust) won't see mise versions.
- **bun is provisioned by mise, not Homebrew.** If bun ever gets reinstalled via `brew install bun`, expect duplicate completion definitions and a PATH that no longer routes through mise — investigate before trusting `which bun`.
- **catppuccin/tmux v2.1.3 is patched in-place by `setup/steps/72-setup-tmux.sh`.** The vendored plugin file `~/.tmux/plugins/tmux/catppuccin_tmux.conf` gets a backport of [PR #577](https://github.com/catppuccin/tmux/pull/577) applied via `tmux/patch-catppuccin-577.py`, because the plugin bakes `@catppuccin_window_*_separator` into `window-status-format` at load time (`set -agF`) so runtime overrides in `.tmux.conf` don't propagate. The patch is required for the `rounded` window status style to render correctly with `@catppuccin_status_background "none"`. Idempotent; re-run `./setup/bootstrap.sh --only=72` after any plugin reinstall. Remove both the script and the setup hook once the pinned tag (`catppuccin/tmux#v2.1.3` in `.tmux.conf`) is bumped past a release containing PR #577.
