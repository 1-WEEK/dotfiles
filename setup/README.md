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

## Verification

```sh
./setup/bootstrap.sh --check          # nothing should run on a satisfied host
./setup/bootstrap.sh --list           # confirm step set for the profile
brew bundle check --file=setup/packages/Brewfile.common
brew bundle check --file=setup/packages/Brewfile.macos   # mac only
dotter -d                             # should show empty diff
```
