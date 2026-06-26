# Bootstrap

One-shot setup for a fresh machine. The bootstrap script detects your platform (macOS, Raspberry Pi 4, or WSL2) and runs the correct sequence of steps.

## Quick start

```bash
./setup/bootstrap.sh           # interactive
./setup/bootstrap.sh --auto    # non-interactive
```

## Flags

| Flag | Effect |
|------|--------|
| `--auto` | Run all steps without prompting |
| `--check` / `-n` | Dry run; print actions without executing |
| `--list` | Show the steps for the active profile |
| `--profile=NAME` | Force profile (`macos`, `pi4`, `wsl2`) |
| `--only=A,B` | Run specific steps |
| `--skip=A,B` | Skip specific steps |
| `--help` | Show usage |

## Profiles

| Profile | Triggered when | What it installs |
|---------|-------------|------------------|
| `macos` | `uname -s = Darwin` | Brewfile.macos (taps + casks), Manico import |
| `pi4` | Linux + (raspbian/raspberrypi distro OR arm64) | Brewfile.common (or apt fallback on armv7) |
| `wsl2` | Linux + WSL kernel marker | Brewfile.common via linuxbrew |

## Steps

Each step is prefixed with a number and can be run individually with `--only=NN`.

| Step | Description |
|------|-------------|
| 00-install-prereqs | curl, git, build tools |
| 10-install-homebrew | brew (macOS) or linuxbrew (Linux x86_64/arm64) |
| 20-install-brew-common | packages/Brewfile.common |
| 21-install-brew-macos | packages/Brewfile.macos (mac only) |
| 22-install-apt-fallback | armv7 / no-brew Linux fallback via apt |
| 25-install-claude | curl https://claude.ai/install.sh |
| 30-setup-shells | oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting; chsh to fish |
| 40-install-mise-tools | mise install (per mise/config.toml) |
| 50-install-dotter | ensure dotter is on PATH |
| 60-deploy-dotfiles | write .dotter/local.toml from profile + dotter deploy |
| 61-setup-vim | vim-plug + :PlugInstall |
| 62-setup-tmux | TPM clone + plugin install + catppuccin PR #577 patch |
| 70-setup-manico | mac only - sync.sh import if Manico.app exists |

### tmux / catppuccin patch (step 62)

After tpm installs the pinned `catppuccin/tmux#v2.1.3`, the step runs `tmux/patch-catppuccin-577.py` to backport [PR #577](https://github.com/catppuccin/tmux/pull/577) onto the vendored `catppuccin_tmux.conf`.

The `rounded` window status style uses `#[fg=...,reverse]<glyph>` for separators. This forces terminal cell opacity to 1.0 and breaks `@catppuccin_status_background "none"`. Runtime overrides in `.tmux.conf` cannot fix this because the plugin bakes the separator variables into `window-status-format` via `set -agF` at load time. Patching the source file is the only clean fix until the pinned tag is bumped past a release containing PR #577.

The script is idempotent. Its `step_check` verifies the patch marker, so re-running `--only=62` after any plugin reinstall reapplies it.

## Idempotency

Every step has a `step_check` that returns 0 when the machine already satisfies it. Re-running `--auto` on a fully configured machine produces no changes.

## Adding a step

1. Create `setup/steps/NN-name.sh` with `step_check` and `step_run` functions.
2. Append `NN-name` to the relevant profiles in `setup/profiles/*.sh`.

## Adding a package

- Cross-platform brew: `setup/packages/Brewfile.common`
- macOS-only / tap / cask: `setup/packages/Brewfile.macos`
- apt (armv7 fallback only): `setup/packages/apt.fallback.txt`

## When to commit changes

Rule of thumb: **if you want it on another machine, commit it here.**

| You did | Where to add it |
|---------|----------------|
| `brew install X` (cross-platform) | `packages/Brewfile.common` |
| `brew install X` (mac-only / cask / tap) | `packages/Brewfile.macos` |
| `mise use -g X@v` | Edit `~/.config/mise/config.toml` (symlink) then commit `mise/config.toml` |
| `mise use -g uv` / `mise use -g python@x.xx` | Same as above |
| `mise use -g pipx:<python-cli>` | Same as above |
| `mise use -g --env local npm:<machine-cli>` | Keep it in `~/.config/mise/config.local.toml`; do not commit it |
| `uv tool install <name>` (standalone) | **Do not.** Convert to `mise use -g pipx:<name>` |
| `fisher install X` | `fish/fish_plugins` is auto-updated by fisher, then commit it |
| Edit `.zshrc` / `config.fish` / `.bashrc` / `.tmux.conf` / `.vimrc` / ghostty | Edit directly, then commit (they are symlinks) |
| New vim Plug / tmux @plugin line | Add to the rc file; steps 61 / 62 pick it up |
| New OMZ custom plugin | Add a `clone_or_pull` line to `steps/30-shells.sh` |
| `curl ... | sh` installer not covered by mise | New `steps/NN-name.sh` |
| New dotter module | Edit `.dotter/global.toml`, add to `PROFILE_DOTTER_PACKAGES` and `DEPLOY_TARGETS` in `steps/60-deploy-dotfiles.sh` |

Skip one-off project deps, throwaway experiments, and machine-specific secrets (use a local rc file outside the repo).

After committing, sanity check:

```sh
brew bundle check --file=setup/packages/Brewfile.common
brew bundle check --file=setup/packages/Brewfile.macos   # mac only
mise install
git status
```

## Verification

```sh
./setup/bootstrap.sh --check          # nothing should run on a satisfied host
./setup/bootstrap.sh --list           # confirm step set for the profile
brew bundle check --file=setup/packages/Brewfile.common
brew bundle check --file=setup/packages/Brewfile.macos   # mac only
dotter -d                             # should show empty diff
```
