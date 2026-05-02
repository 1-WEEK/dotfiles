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
00-prereqs           curl / git / build tools
10-homebrew          brew (mac) or linuxbrew (linux x86_64/arm64)
20-brew-common       packages/Brewfile.common
21-brew-macos        packages/Brewfile.macos (mac only)
22-apt-fallback      armv7 / no-brew Linux fallback via apt
25-claude-code       curl https://claude.ai/install.sh | bash
30-shells            oh-my-zsh + zsh-autosuggestions / -syntax-highlighting; chsh fish
40-mise-tools        mise install (per mise/config.toml)
50-vim-plug          vim-plug + :PlugInstall
55-tmux-tpm          TPM clone + plugin install
60-dotter            ensure dotter on PATH
70-dotter-deploy     write .dotter/local.toml from profile + dotter deploy
80-manico            mac only — sync.sh import if Manico.app present
```

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
| `fisher install X` | `fish/fish_plugins` is auto-updated by fisher → commit it |
| Edit `.zshrc` / `config.fish` / `.bashrc` / `.tmux.conf` / `.vimrc` / ghostty | They're symlinks — edit directly, then commit |
| New vim Plug / tmux @plugin line | Just add it to the rc; step 50 / 55 picks it up |
| New OMZ custom plugin | Add a `clone_or_pull` line to `steps/30-shells.sh` |
| `curl … | sh` installer not coverable by mise | New `steps/NN-name.sh` |
| New dotter module | Edit `.dotter/global.toml`, add to all `profiles/*.sh` `PROFILE_DOTTER_PACKAGES`, append target path to `DEPLOY_TARGETS` in `steps/70-dotter-deploy.sh` |

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
