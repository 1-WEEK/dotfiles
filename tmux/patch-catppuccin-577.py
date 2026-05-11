#!/usr/bin/env python3
# Backport of https://github.com/catppuccin/tmux/pull/577 onto the v2.1.3
# release of catppuccin/tmux. Idempotent: safe to re-run.
#
# Why patch the plugin file instead of overriding at runtime?
# catppuccin bakes `@catppuccin_window_*_separator` into `window-status-format`
# via `set -agF` at plugin load time, so changing the variables afterward has
# no effect. Patching the source is the only clean fix until v2.1.4 ships
# with PR #577 merged.

import os
import sys
from pathlib import Path

PLUGIN = Path(os.path.expanduser("~/.tmux/plugins/tmux/catppuccin_tmux.conf"))

# Powerline-Extra glyphs (Nerd Font Symbols Extra range)
L = bytes([0xEE, 0x82, 0xB6])  # U+E0B6 left half-circle
R = bytes([0xEE, 0x82, 0xB4])  # U+E0B4 right half-circle

# Fix 1: @_ctp_status_bg "none" is not a valid tmux color; use "default".
FIX1_OLD = b'  set -g @_ctp_status_bg "none"\n'
FIX1_NEW = b'  set -g @_ctp_status_bg "default"\n'

# Fix 2: rounded window separators use `reverse`, which forces terminal cell
# opacity to 1.0 in most emulators and breaks transparent status background.
# Replace with explicit bg=... per number_position branch.
FIX2_OLD = (
    b'%elif "#{==:#{@catppuccin_window_status_style},rounded}"\n'
    b'\n'
    b'  set -gq @catppuccin_window_left_separator "#[fg=#{@_ctp_status_bg},reverse]' + L + b'#[none]"\n'
    b'  set -gq @catppuccin_window_middle_separator " "\n'
    b'  set -gq @catppuccin_window_right_separator "#[fg=#{@_ctp_status_bg},reverse]' + R + b'#[none]"\n'
)
FIX2_NEW = (
    b'%elif "#{==:#{@catppuccin_window_status_style},rounded}"\n'
    b'\n'
    b'  set -gq @catppuccin_window_middle_separator " "\n'
    b'  %if "#{==:#{@catppuccin_window_number_position},left}"\n'
    b'    set -gq @catppuccin_window_left_separator "#[fg=#{@catppuccin_window_number_color},bg=#{@_ctp_status_bg}]' + L + b'#[fg=#{@catppuccin_window_text_color},bg=#{@catppuccin_window_number_color}]"\n'
    b'    set -gq @catppuccin_window_current_left_separator "#[fg=#{@catppuccin_window_current_number_color},bg=#{@_ctp_status_bg}]' + L + b'#[fg=#{@catppuccin_window_current_text_color},bg=#{@catppuccin_window_current_number_color}]"\n'
    b'    set -gq @catppuccin_window_right_separator "#[fg=#{@catppuccin_window_text_color},bg=#{@_ctp_status_bg}]' + R + b'#[none]"\n'
    b'    set -gq @catppuccin_window_current_right_separator "#[fg=#{@catppuccin_window_current_text_color},bg=#{@_ctp_status_bg}]' + R + b'#[none]"\n'
    b'  %else\n'
    b'    set -gq @catppuccin_window_left_separator "#[fg=#{@catppuccin_window_text_color},bg=#{@_ctp_status_bg}]' + L + b'#[fg=#{@catppuccin_window_text_color},bg=#{@catppuccin_window_number_color}]"\n'
    b'    set -gq @catppuccin_window_current_left_separator "#[fg=#{@catppuccin_window_current_text_color},bg=#{@_ctp_status_bg}]' + L + b'#[fg=#{@catppuccin_window_current_text_color},bg=#{@catppuccin_window_current_number_color}]"\n'
    b'    set -gq @catppuccin_window_right_separator "#[fg=#{@catppuccin_window_number_color},bg=#{@_ctp_status_bg}]' + R + b'#[none]"\n'
    b'    set -gq @catppuccin_window_current_right_separator "#[fg=#{@catppuccin_window_current_number_color},bg=#{@_ctp_status_bg}]' + R + b'#[none]"\n'
    b'  %endif\n'
)

# Marker used to detect already-patched state. Unique to the new layout.
MARKER = b'set -gq @catppuccin_window_current_left_separator "#[fg=#{@catppuccin_window_current_number_color},bg=#{@_ctp_status_bg}]'


def main() -> int:
    if not PLUGIN.exists():
        print(f"skip: {PLUGIN} not installed yet", file=sys.stderr)
        return 0

    data = PLUGIN.read_bytes()

    if MARKER in data:
        print(f"already patched: {PLUGIN}")
        return 0

    if FIX1_OLD not in data:
        print(f"fix1: anchor not found, plugin version may have changed", file=sys.stderr)
        return 1
    if FIX2_OLD not in data:
        print(f"fix2: anchor not found, plugin version may have changed", file=sys.stderr)
        return 1

    data = data.replace(FIX1_OLD, FIX1_NEW, 1)
    data = data.replace(FIX2_OLD, FIX2_NEW, 1)
    PLUGIN.write_bytes(data)
    print(f"patched: {PLUGIN}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
