# Bootstrap

One-shot setup for a fresh machine. The bootstrap script detects your platform (macOS, Raspberry Pi 4, or WSL2) and runs the correct sequence of steps.

Run from the standard checkout at `~/.dotfiles`. Setup reports a missing or occupied location and never moves another checkout there. Configuration deployment needs curl, Git, Python 3 (Command Line Tools on macOS, `python3` on Linux), and the latest stable mise. Step 15 installs or upgrades mise; selecting step 60 alone also enforces this prerequisite. Network, upgrade, or verification failures block deployment. A failure of step 15 or 60 stops the remaining setup steps.

## Quick start

```bash
./setup/bootstrap.sh           # interactive
./setup/bootstrap.sh --auto    # non-interactive
```

## Flags

| Flag | Effect |
|------|--------|
| `--auto` | Run all steps without prompting |
| `--adopt` | Explicitly back up conflicting dotfiles before adopting them; `--auto` alone does not authorize this |
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
| 00-install-prereqs | curl, git, Python 3, build tools |
| 10-install-homebrew | brew (macOS) or linuxbrew (Linux x86_64/arm64) |
| 15-install-mise | verify the latest stable release and install/upgrade mise |
| 20-install-brew-common | packages/Brewfile.common |
| 21-install-brew-macos | packages/Brewfile.macos (mac only) |
| 22-install-apt-fallback | armv7 / no-brew Linux fallback via apt |
| 25-install-claude | curl https://claude.ai/install.sh |
| 30-setup-shells | oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting; chsh to fish |
| 40-install-mise-tools | mise install (per mise/config.toml) |
| 60-deploy-dotfiles | verify mise, preflight conflicts, then apply native dotfiles |
| 61-setup-vim | vim-plug + :PlugInstall |
| 62-setup-tmux | TPM clone + plugin install + catppuccin PR #577 patch |
| 70-setup-manico | mac only - sync.sh import if Manico.app exists |

### tmux / catppuccin patch (step 62)

After tpm installs the pinned `catppuccin/tmux#v2.1.3`, the step aligns the vendored checkout to that tag (TPM skips reinstall when the plugin dir exists, so an older checkout would otherwise stay put), then runs `tmux/patch-catppuccin-577.py` to backport [PR #577](https://github.com/catppuccin/tmux/pull/577) onto the vendored `catppuccin_tmux.conf`. The backport anchors are written against the pinned release, so step 62 also verifies the checkout is exactly on the pin.

The `rounded` window status style uses `#[fg=...,reverse]<glyph>` for separators. This forces terminal cell opacity to 1.0 and breaks `@catppuccin_status_background "none"`. Runtime overrides in `.tmux.conf` cannot fix this because the plugin bakes the separator variables into `window-status-format` via `set -agF` at load time. Patching the source file is the only clean fix until the pinned tag is bumped past a release containing PR #577.

The script is idempotent. Its `step_check` verifies the patch marker, so re-running `--only=62` after any plugin reinstall reapplies it.

## Idempotency

Most steps use `step_check` to skip satisfied work. Mise version checks and configuration preflight always run. Native apply preserves correct links and repairs missing links based on actual targets. Profiles deploy configuration before installing mise tools and shell plugins. Preview checks the release service but does not install mise or change deployment targets or backups; if mise is absent, install step 15 before requesting a detailed native preview.

For routine configuration updates, use the native command without installing tools:

```sh
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply --dry-run
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles status --missing
```

`MISE_AUTO_ENV=true` selects the host platform, including Ghostty on macOS. The setup profile interface explicitly selects macOS or Linux instead, so `--profile=pi4` and `--profile=wsl2` exclude Ghostty even during a simulated run on macOS. Native apply runs the same latest-version and conflict hooks. An outdated mise stops native apply; run `~/.dotfiles/setup/bootstrap.sh --only=15 --auto`, then retry. Do not use `--force` to bypass adoption: use the [explicit backup workflow](dotfiles-migration.md).

## Deployment tests

```sh
python3 -m unittest discover -s setup/tests -v
```

Tests use native mise from PATH (or `TEST_MISE=/path/to/mise`) with a temporary HOME, checkout, configuration, state, and cache. Release lookup, installation, and self-update are simulated, so the suite does not download tools or modify the real machine. Run with an unprivileged account to exercise backup permission failures. Profile tests cover macOS, pi4, and wsl2 selection; simulated Linux profiles on macOS are not native Linux execution.

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
| Host-only tool (e.g. `npm:node-gyp`) | Add it to `~/.config/mise/config.local.toml` directly; do not commit it. (`mise use -g --env local` does *not* write here — despite `-g`, `--env` makes it write `mise.local.toml` in the cwd instead. Create/edit `config.local.toml` by hand, mise picks it up automatically alongside `config.toml`.) |
| `uv tool install <name>` (standalone) | **Do not.** Convert to `mise use -g pipx:<name>` |
| `fisher install X` | `fish/fish_plugins` is auto-updated by fisher, then commit it |
| Edit `.zshrc` / `config.fish` / `.bashrc` / `.tmux.conf` / `.vimrc` / ghostty | Edit directly, then commit (they are symlinks) |
| New vim Plug / tmux @plugin line | Add to the rc file; steps 61 / 62 pick it up |
| New OMZ custom plugin | Add a `clone_or_pull` line to `steps/30-shells.sh` |
| `curl ... | sh` installer not covered by mise | New `steps/NN-name.sh` |
| New managed file | Add a `[dotfiles]` entry to `mise/config.toml` (or `mise/config.macos.toml` for macOS), using a source under `~/.dotfiles` |

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
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles status --missing
```
