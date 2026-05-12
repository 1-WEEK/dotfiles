# setup/

One-shot bootstrap for a fresh machine (macOS / Pi4 64-bit Linux / WSL2 Ubuntu 24).
Detects the platform, installs the dependencies actually used in this dotfiles
repo, then hands off to `dotter deploy`.

## Quick start

```sh
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./setup/bootstrap.sh           # interactive
./setup/bootstrap.sh --auto    # use detected profile defaults
```

## Flags

| Flag | Effect |
|------|--------|
| `--auto` | Non-interactive; run all profile steps |
| `--check` / `-n` | Dry run; print actions without executing |
| `--list` | List the steps for the active profile |
| `--profile=NAME` | Force profile (`macos`, `pi4`, `wsl2`) |
| `--only=A,B` | Run only matching steps (numbers or names) |
| `--skip=A,B` | Skip matching steps |
| `--help` | Show usage |

## Profiles

| Profile | Triggered when | Notable inclusions |
|---------|---------------|-------------------|
| `macos` | `uname -s = Darwin` | Brewfile.macos (taps + casks), Manico import |
| `pi4` | Linux + (raspbian/raspberrypi distro OR arm64) | Brewfile.common (or apt fallback on armv7) |
| `wsl2` | Linux + WSL kernel marker | Brewfile.common via linuxbrew |

## Steps

Each numeric prefix is a discrete component. Run a single one with `--only=NN`.

```
00-install-prereqs   curl / git / build tools
10-install-homebrew  brew (mac) or linuxbrew (linux x86_64/arm64)
20-install-brew-common  packages/Brewfile.common
21-install-brew-macos   packages/Brewfile.macos (mac only)
22-install-apt-fallback armv7 / no-brew Linux fallback via apt
25-install-claude    curl https://claude.ai/install.sh | bash
30-setup-shells      oh-my-zsh + zsh-autosuggestions / -syntax-highlighting; chsh fish
40-install-mise-tools  mise install (per mise/config.toml)
50-install-dotter    ensure dotter on PATH
60-deploy-dotfiles   write .dotter/local.toml from profile + dotter deploy
61-setup-vim         vim-plug + :PlugInstall
62-setup-tmux        TPM clone + plugin install + catppuccin PR #577 patch
70-setup-manico      mac only — sync.sh import if Manico.app present
```

### tmux / catppuccin patch (step 72)

After tpm installs the pinned `catppuccin/tmux#v2.1.3`, the step runs
`tmux/patch-catppuccin-577.py` to backport
[PR #577](https://github.com/catppuccin/tmux/pull/577) onto the vendored
`catppuccin_tmux.conf`. The patch is needed because the plugin's `rounded`
window status style uses `#[fg=...,reverse]<glyph>` for separators, which
forces terminal cell opacity to 1.0 and breaks `@catppuccin_status_background
"none"`. Runtime overrides in `.tmux.conf` can't fix this (the plugin bakes
the separator vars into `window-status-format` via `set -agF` at load time),
so patching the source file is the only clean path until the pin can be
bumped past a release containing PR #577. The script is idempotent and
`step_check` verifies the patch marker, so re-running `--only=62` after any
plugin reinstall reapplies it.

## Idempotency

Every step has a `step_check` that returns 0 when already satisfied; the
step is skipped silently. Re-running `--auto` on a fully-set-up machine
produces no changes.

## Adding a step

1. Drop a new file `setup/steps/NN-name.sh` defining `step_check` and
   `step_run`.
2. Append `NN-name` to the relevant profiles in `setup/profiles/*.sh`.

## Adding a package

- Cross-platform brew: `setup/packages/Brewfile.common`.
- macOS-only / tap / cask: `setup/packages/Brewfile.macos`.
- apt (only used for armv7 fallback): `setup/packages/apt.fallback.txt`.

## When to update this repo after installing something

Rule of thumb: **if you want it on another machine too, commit it here.**

| You did | Update |
|---------|--------|
| `brew install X` (cross-platform) | `packages/Brewfile.common` |
| `brew install X` mac-only / cask / tap | `packages/Brewfile.macos` |
| `mise use -g X@v` | edit `~/.config/mise/config.toml` (it's a symlink) → commit `mise/config.toml` |
| `mise use -g uv` / `mise use -g python@x.xx` | same as above — uv and python are runtime versions, belong in mise |
| `mise use -g pipx:<python-cli>` | same as above — Python CLI tools must go through mise so they're locked |
| `uv tool install <name>` (standalone) | **Don't.** Convert to `mise use -g pipx:<name>` so the tool is tracked in `mise/config.toml` |
| `fisher install X` | `fish/fish_plugins` is auto-updated by fisher → commit it |
| Edit `.zshrc` / `config.fish` / `.bashrc` / `.tmux.conf` / `.vimrc` / ghostty | They're symlinks — edit directly, then commit |
| New vim Plug / tmux @plugin line | Just add it to the rc; step 61 / 62 picks it up |
| New OMZ custom plugin | Add a `clone_or_pull` line to `steps/30-shells.sh` |
| `curl … | sh` installer not coverable by mise | New `steps/NN-name.sh` |
| New dotter module | Edit `.dotter/global.toml`, add to all `profiles/*.sh` `PROFILE_DOTTER_PACKAGES`, append target path to `DEPLOY_TARGETS` in `steps/60-deploy-dotfiles.sh` |

Skip for: one-off project deps, throwaway experiments, machine-specific secrets/keys (use a local rc file outside the repo).

After committing, sanity check: `brew bundle check --file=…`, `mise install`, and `git status` to catch indirect symlink writes you might miss.

## Verification

```sh
./setup/bootstrap.sh --check          # nothing should run on a satisfied host
./setup/bootstrap.sh --list           # confirm step set for the profile
brew bundle check --file=setup/packages/Brewfile.common
brew bundle check --file=setup/packages/Brewfile.macos   # mac only
dotter -d                             # should show empty diff
```
