#!/usr/bin/env python3
"""Protect conflicts mise natively replaces; leave link creation to mise."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def backup(target):
    directory = Path(tempfile.mkdtemp(prefix=target.name + ".backup-", dir=target.parent))
    destination = directory / target.name
    target.rename(destination)
    print(f"Backup: {target} -> {destination}", flush=True)


def main():
    dry_run = "--dry-run" in sys.argv[1:]
    adopt = os.environ.get("DOTFILES_ADOPT") == "1"
    result = subprocess.run(
        ["mise", "bootstrap", "dotfiles", "status", "--json"],
        check=True, text=True, stdout=subprocess.PIPE,
    )
    entries = json.loads(result.stdout)["files"]
    conflicts = set()
    blocked_parents = set()
    missing_sources = []
    for entry in entries:
        if entry["mode"] != "symlink":
            continue
        target = Path(entry["target"]).expanduser()
        source = Path(entry["source"]).expanduser()
        if not source.exists():
            missing_sources.append(source)
        for parent in reversed(target.parents):
            # Inspect only parents inside HOME; macOS itself aliases /tmp.
            if Path.home() not in parent.parents:
                continue
            if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                blocked_parents.add(parent)
                break
        if os.path.lexists(target) and not (target.is_symlink() and target.resolve() == source.resolve()):
            conflicts.add(target)

    for source in missing_sources:
        print(f"Missing source: {source}", file=sys.stderr)
    conflicts |= blocked_parents
    for target in sorted(conflicts):
        print(f"Conflict: {target}", file=sys.stderr)
    if missing_sources:
        return 1
    if conflicts and not adopt:
        print("No targets changed. Use --adopt with setup, or DOTFILES_ADOPT=1 with native apply, to back up and adopt.", file=sys.stderr)
        return 1
    if dry_run:
        return 0

    # Only Fish's former directory link has a defined migration. Other parent
    # aliases may own unrelated configuration and need manual resolution.
    functions = Path.home() / ".config/fish/functions"
    for parent in blocked_parents:
        if parent != functions or not parent.is_dir():
            print(f"Resolve parent path manually before deployment: {parent}", file=sys.stderr)
            return 1
    if functions in blocked_parents:
        staging = Path(tempfile.mkdtemp(prefix="functions.backup-", dir=functions.parent))
        saved = staging / "contents"
        shutil.copytree(functions, saved, symlinks=True)
        print(f"Backup: {functions} contents -> {saved}", flush=True)
        functions.rename(staging / "original-link")
        shutil.copytree(saved, functions, symlinks=True)
        conflicts.discard(functions)
        for entry in entries:
            target = Path(entry["target"]).expanduser()
            if target.parent == functions and os.path.lexists(target):
                conflicts.add(target)
    for target in sorted(conflicts):
        backup(target)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Deployment preflight failed: {error}", file=sys.stderr)
        sys.exit(1)
