# Dotter to mise migration

The repository now declares configuration deployment alongside tools in `mise/config.toml`, with Ghostty in `mise/config.macos.toml`. The [migration specification](../.scratch/mise-dotfiles/spec.md) records the requirements.

## Prepare the checkout

Use `~/.dotfiles` as the deployment checkout. If it does not exist, clone this repository there. If it already contains this repository, update that checkout to the migration revision. If another directory or checkout occupies the location, resolve it manually first. Setup neither moves the development worktree nor overwrites that location.

Python 3 and curl must be available. Install Command Line Tools on macOS or `python3` on Linux if missing. Then, from `~/.dotfiles`:

```sh
./setup/bootstrap.sh --only=15 --auto
./setup/bootstrap.sh --only=60 --check --auto
./setup/bootstrap.sh --only=60 --auto
```

All detected conflicts are reported before target changes. Correct symlinks are reused, including links created by Dotter when they resolve to the current sources. Links to another checkout are conflicts. Missing links are repaired on every apply.

## Back up and adopt conflicts

Ordinary apply stops on conflicting files, directories, and foreign links. `--auto` does not imply adoption. To preserve those paths and replace them with repository links:

```sh
./setup/bootstrap.sh --only=60 --check --adopt --auto
./setup/bootstrap.sh --only=60 --adopt --auto
```

After initial setup the equivalent native entry point is:

```sh
DOTFILES_ADOPT=1 MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply
```

The preflight checks the complete configuration, so use these commands for a full configuration deployment. Backups go to unique sibling `<name>.backup-*` directories and each location is printed. Existing backups are never replaced. If a backup fails, deployment stops before replacing that target; earlier successful backups can remain. Resolve the error and rerun, or move the printed backup back after removing its managed link.

Native preview skips hooks. To preview conflicting targets as if they had been backed up, use `MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply --dry-run --force`. This only previews link changes; setup's `--check --adopt` also runs the read-only conflict preflight. Actual native apply still requires `DOTFILES_ADOPT=1` for backups, even with `--force`.

A legacy `~/.config/fish/functions` directory link requires explicit adoption. The migration saves an independent snapshot of its contents and the original link, then creates a real functions directory. Repository functions become individual links; plugin and local neighbors stay present, and the old source directory remains untouched. Other symlinked or obstructed parent directories require manual resolution because they can own unrelated configuration.

`~/.config/mise/config.local.toml` stays host-owned. Manico's preference file, including license-bearing content, is not part of deployment; its existing `manico/sync.sh import` workflow remains separate.

## Verify and retire Dotter manually

```sh
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles status --missing
MISE_AUTO_ENV=true mise -C ~ bootstrap dotfiles apply --dry-run
```

After checking the links and applications, uninstall Dotter with the manager that installed it, for example `brew uninstall dotter` or `cargo uninstall dotter`. Inspect the old checkout's `.dotter/local.toml`, `.dotter/cache.toml`, and `.dotter/cache/`; archive or remove those files manually when no longer needed. Keep migration backups until you have verified their contents. Setup leaves installed Dotter binaries and machine-local Dotter state untouched.
