# Environment management philosophy

This dotfiles repo encodes one principle: **mise is the canonical source of truth for all language runtimes and global CLI tools.** Everything else is either a system dependency or a temporary workaround.

## The hierarchy

| Layer | Role | Examples | How it's added |
|-------|------|----------|----------------|
| **mise** | Version manager of managers. Locks runtime and tool versions in `mise/config.toml`. | node, python, uv, ruby, rust, bun, cargo tools, npm packages, pipx tools | `mise use -g <tool>` |
| **Homebrew** | System-level dependencies and GUI apps only. Never installs language runtimes that mise can handle. | git, ripgrep, ffmpeg, Ghostty, Manico | `brew install` / Brewfile |
| **uv** | Python-internal workflow tool. Managed *by* mise, not alongside it. | Python venvs, package resolution, `uv tool install` (called by mise pipx backend) | `mise use -g uv` |
| **curl \| sh** | Last resort for things neither mise nor brew cover. | claude-code installer | New `setup/steps/NN-*.sh` |

## Rules derived from this

1. **No language runtime goes through Homebrew if mise has it.** Python, Node, Ruby, Rust, Bun, uv — all via mise. Brew may still *pull in* a Python as a transitive dependency, but that Python is not for human use.

2. **No standalone `uv tool install` or `pip install --user`.** If a Python CLI tool needs to be global and version-locked, it goes through `mise use -g pipx:<name>` so it appears in `mise/config.toml` and `mise list`. The pipx backend happens to invoke `uv tool install` under the hood, but the *ownership* is mise's.

3. **No `python3` or `pip3` aliases that bypass mise.** After `mise activate`, `python3` and `pip3` resolve through `~/.local/share/mise/shims`. Brew's `python@3.14` and the system Python in `/usr/bin/python3` are still present but are not on the interactive PATH ahead of mise.

4. **Every new machine should reach the same synced state from `mise/config.toml` alone.** If you install something via `uv tool install`, `npm install -g`, `cargo install`, or `gem install` *outside* of mise, it's invisible to other machines. Convert synced tools to a `mise use -g` declaration.

5. **Machine-local global tools still belong to mise, but not to the repo.** If a CLI should be installed only on one host, declare it in `~/.config/mise/config.local.toml` instead of `mise/config.toml`. This keeps ownership with mise without forcing every synced device to install the tool.

## Architectural rules these configs encode

- **mise shims must beat Homebrew on PATH.** Every shell rc prepends `~/.local/share/mise/shims` after tool init. A previous incident had an app running under Homebrew Node 25 while its plugins were built for Node 24. If you refactor PATH logic, preserve this ordering.

- **Manico is *not* symlinked.** Other apps' configs are linked via Dotter; Manico is plist-based and contains device-specific IDs and licenses, so `sync.sh` round-trips only a non-sensitive subset through `defaults read`/`defaults write`. License must be re-entered on each new machine.

- **Interactive-only vs always-loaded.** `fish/config.fish` puts PATH/env in the always-loaded section and gates prompt/aliases/autojump behind `if status is-interactive`. Match this convention when editing.

- **Completion files live outside this repo.** They are regenerated per-machine (`bun completions`, `openclaw completion`) and intentionally not under Dotter.
