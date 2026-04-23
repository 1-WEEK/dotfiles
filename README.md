# Dotfiles

My personal configuration files managed by Dotter.

## Manico Sync

To avoid sync issues with device-specific IDs and licenses, Manico configuration is managed via a sync script instead of direct plist linking.

### How to Sync

#### 1. On Source Machine (Export)
When you change your Manico settings, run:
```bash
./manico/sync.sh export
```
This will update `manico/settings.txt` with your current non-sensitive preferences (UI, behavior, etc.). Commit and push this file.

#### 2. On Destination Machine (Import)
After pulling the changes and deploying with Dotter:
```bash
./manico/sync.sh import
```
This script will:
- Write preferences using `defaults write`.
- Restart Manico to apply the changes.
- **Note**: You will still need to enter your license/activation once on new machines, as this data is intentionally excluded for security and compatibility.

## Managed Modules
- **Bash**: `.bashrc`, `.bash_profile`
- **Zsh**: `.zshrc`
- **Vim**: `.vimrc`
- **Ghostty**: Terminal configuration
- **Manico**: App switcher configuration (via `sync.sh`)
