"""Command-level deployment tests using real mise and an isolated machine home.

Run with python3 -m unittest discover -s setup/tests -v. Set TEST_MISE to a
native mise binary when the executable is not on PATH. Only release lookup,
installation and self-update are simulated; dotfile operations use real mise.
"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
MISE = os.environ.get("TEST_MISE") or shutil.which("mise")

MISE_STUB = '''#!/bin/sh
if [ "$1" = --version ]; then
  cat "$HOME/current-version"
elif [ "$1" = self-update ]; then
  [ "${TEST_UPGRADE_FAIL:-0}" = 0 ] || exit 42
  [ "${TEST_UPGRADE_NOOP:-0}" = 0 ] || exit 0
  printf '%s\\n' "$TEST_RELEASE" > "$HOME/current-version"
else
  exec "$TEST_REAL_MISE" "$@"
fi
'''

CURL_STUB = '''#!/bin/sh
case "$*" in
  *https://mise.jdx.dev/VERSION*)
    [ "${TEST_RELEASE_FAIL:-0}" = 0 ] || exit 22
    printf '%s\\n' "$TEST_RELEASE"
    ;;
  *https://mise.run*)
    [ "${TEST_UPGRADE_FAIL:-0}" = 0 ] || exit 22
    while [ "$1" != -o ]; do shift; done
    cp "$HOME/installer" "$2"
    ;;
  *) echo "Unexpected network request: $*" >&2; exit 99 ;;
esac
'''


@unittest.skipUnless(MISE, "native mise is required (set TEST_MISE)")
class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.checkout = self.home / ".dotfiles"
        self.checkout.mkdir()
        for name in ("setup", "mise", "bash", "zsh", "fish", "vim", "tmux", "eza", "ghostty"):
            shutil.copytree(ROOT / name, self.checkout / name, ignore=shutil.ignore_patterns("__pycache__"))
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        # No inherited HOME, trust, configuration, tool shims or credentials.
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "SHELL": "/bin/sh", "TEST_REAL_MISE": str(Path(MISE).resolve()),
            "MISE_DATA_DIR": str(self.home / "data"),
            "MISE_STATE_DIR": str(self.home / "state"),
            "MISE_CACHE_DIR": str(self.home / "cache"),
            "MISE_CONFIG_DIR": str(self.home / ".config/mise"),
            "MISE_SYSTEM_CONFIG_FILE": str(self.home / "system.toml"),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / "data"),
            "XDG_STATE_HOME": str(self.home / "state"),
            "XDG_CACHE_HOME": str(self.home / "cache"),
            "MISE_AUTO_UPDATE": "false",
        }
        self.write("system.toml", "")
        version = subprocess.check_output([MISE, "--version"], cwd=self.home, env=self.env, text=True).split()[0]
        self.env["TEST_RELEASE"] = version
        self.write("current-version", version + "\n")
        self.write("mise-stub", MISE_STUB, executable=True)
        self.write(".local/bin/mise", MISE_STUB, executable=True)
        self.write(".local/bin/curl", CURL_STUB, executable=True)
        self.write("installer", 'mkdir -p "$HOME/.local/bin"\ncp "$HOME/mise-stub" "$HOME/.local/bin/mise"\nprintf "%s\\n" "$MISE_VERSION" > "$HOME/current-version"\n')

    def write(self, relative, content, executable=False):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        if executable:
            path.chmod(0o755)
        return path

    def run_command(self, command, **environment):
        return subprocess.run(command, cwd=self.home, env={**self.env, **environment},
                              text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)

    def setup(self, *flags, profile="macos"):
        return self.run_command(["bash", str(self.checkout / "setup/bootstrap.sh"),
                                 "--auto", f"--profile={profile}", *flags])

    def native(self, *flags, **environment):
        return self.run_command([str(self.bin / "mise"), "-C", str(self.home),
                                 "bootstrap", "dotfiles", *flags],
                                MISE_AUTO_ENV="true", **environment)

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_empty_home_deploys_and_repeated_apply_preserves_links(self):
        self.assert_success(self.setup("--only=60"))
        target = self.home / ".zshrc"
        self.assertEqual(target.resolve(), self.checkout / "zsh/.zshrc")
        inode = target.lstat().st_ino
        self.assert_success(self.native("apply", "--yes"))
        self.assertEqual(target.lstat().st_ino, inode)
        target.unlink()
        self.assert_success(self.native("apply", "--yes"))
        self.assertEqual(target.resolve(), self.checkout / "zsh/.zshrc")

    def test_linux_profiles_exclude_macos_targets(self):
        for profile in ("pi4", "wsl2"):
            with self.subTest(profile=profile):
                self.assert_success(self.setup("--only=60", profile=profile))
                self.assertTrue((self.home / ".bashrc").is_symlink())
                self.assertFalse((self.home / "Library/Application Support/com.mitchellh.ghostty").exists())
                self.assertFalse((self.home / ".config/mise/config.macos.toml").exists())

    def test_conflicts_are_all_reported_before_any_target_is_changed(self):
        regular = self.write(".zshrc", "local settings\n")
        foreign = self.write("foreign", "foreign content\n")
        (self.home / ".bashrc").symlink_to(foreign)
        result = self.setup("--only=60")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(str(regular), result.stdout)
        self.assertIn(str(self.home / ".bashrc"), result.stdout)
        self.assertEqual(regular.read_text(), "local settings\n")
        self.assertEqual((self.home / ".bashrc").resolve(), foreign)
        self.assertFalse((self.home / ".vimrc").exists())
        self.assertEqual(list(self.home.glob("*.backup-*")), [])

    def test_explicit_adoption_preserves_prior_backups_files_directories_and_links(self):
        self.write(".zshrc", "local settings\n")
        self.write(".zshrc.backup-earlier/.zshrc", "earlier\n")
        self.write(".vimrc/custom", "directory content\n")
        foreign = self.write("foreign", "foreign content\n")
        (self.home / ".bashrc").symlink_to(foreign)
        result = self.setup("--only=60", "--adopt")
        self.assert_success(result)
        self.assertIn("Backup:", result.stdout)
        self.assertEqual((self.home / ".zshrc.backup-earlier/.zshrc").read_text(), "earlier\n")
        backups = list(self.home.glob(".zshrc.backup-*/.zshrc"))
        self.assertEqual(sorted(p.read_text() for p in backups), ["earlier\n", "local settings\n"])
        self.assertEqual(next(self.home.glob(".vimrc.backup-*/.vimrc/custom")).read_text(), "directory content\n")
        self.assertEqual(next(self.home.glob(".bashrc.backup-*/.bashrc")).resolve(), foreign)
        self.assertEqual(foreign.read_text(), "foreign content\n")

    def test_correct_existing_links_and_host_owned_configuration_survive(self):
        target = self.home / ".zshrc"
        target.symlink_to(".dotfiles/zsh/.zshrc")
        inode = target.lstat().st_ino
        local = self.write(".config/mise/config.local.toml", '[tools]\n"example-host-tool" = "1.0.0"\n')
        plugin = self.write(".config/fish/functions/plugin.fish", "function plugin; end\n")
        manico = self.write("Library/Preferences/com.unknwon.Manico.plist", "device-private\n")
        self.assert_success(self.setup("--only=60"))
        self.assertEqual(target.lstat().st_ino, inode)
        self.assertIn('"example-host-tool"', local.read_text())
        self.assertEqual(plugin.read_text(), "function plugin; end\n")
        self.assertEqual(manico.read_text(), "device-private\n")
        tools = self.run_command([str(self.bin / "mise"), "-C", str(self.home), "config", "get", "tools"])
        self.assert_success(tools)
        self.assertIn("example-host-tool", tools.stdout)

    def test_fish_directory_link_migration_keeps_sources_and_plugin_neighbors(self):
        source = self.checkout / "fish/functions"
        plugin = source / "plugin.fish"
        plugin.write_text("function plugin; end\n")
        functions = self.home / ".config/fish/functions"
        functions.parent.mkdir(parents=True)
        functions.symlink_to(source, target_is_directory=True)
        result = self.setup("--only=60")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertTrue(functions.is_symlink())
        self.assert_success(self.setup("--only=60", "--adopt"))
        self.assertFalse(functions.is_symlink())
        self.assertTrue((functions / "chrome.fish").is_symlink())
        self.assertEqual(plugin.read_text(), "function plugin; end\n")
        self.assertEqual((functions / "plugin.fish").read_text(), plugin.read_text())
        saved = next(functions.parent.glob("functions.backup-*/contents/plugin.fish"))
        self.assertEqual(saved.read_text(), plugin.read_text())
        self.assertTrue((source / "chrome.fish").is_file())
        self.assertFalse((source / "chrome.fish").is_symlink())

    def test_previews_leave_targets_and_backups_unchanged(self):
        self.write(".zshrc", "local settings\n")
        self.assert_success(self.setup("--only=60", "--check", "--adopt"))
        self.assertEqual((self.home / ".zshrc").read_text(), "local settings\n")
        self.assertFalse((self.home / ".vimrc").exists())
        self.assertEqual(list(self.home.glob("*.backup-*")), [])
        self.assert_success(self.setup("--only=60", "--adopt"))
        target = self.home / ".zshrc"
        target.unlink()
        self.write(".zshrc", "new conflict\n")
        before = set(self.home.glob("*.backup-*"))
        self.assert_success(self.native("apply", "--dry-run", "--force", DOTFILES_ADOPT="1"))
        self.assertEqual(target.read_text(), "new conflict\n")
        self.assertEqual(set(self.home.glob("*.backup-*")), before)

    def test_backup_failure_leaves_conflicting_target_intact(self):
        if os.geteuid() == 0:
            self.skipTest("permission failure requires an unprivileged user")
        self.write(".config/fish/config.fish", "local fish\n")
        directory = self.home / ".config/fish"
        directory.chmod(0o555)
        try:
            result = self.setup("--only=60", "--adopt")
            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertEqual((directory / "config.fish").read_text(), "local fish\n")
            self.assertFalse((self.home / ".zshrc").exists())
        finally:
            directory.chmod(0o755)

    def test_absent_mise_is_installed_before_deployment(self):
        (self.bin / "mise").unlink()
        self.assert_success(self.setup("--only=60"))
        self.assertTrue((self.home / ".zshrc").is_symlink())
        self.assertTrue((self.bin / "mise").is_file())

    def test_outdated_mise_is_upgraded_before_deployment(self):
        self.write("current-version", "2020.1.1\n")
        self.assert_success(self.setup("--only=60"))
        self.assertEqual((self.home / "current-version").read_text().strip(), self.env["TEST_RELEASE"])
        self.assertTrue((self.home / ".zshrc").is_symlink())

    def test_release_or_upgrade_failure_blocks_selected_and_profile_deployment(self):
        for mode in ("TEST_RELEASE_FAIL", "TEST_UPGRADE_FAIL", "TEST_UPGRADE_NOOP"):
            for selection in ("--only=60", "--skip=00,10,20,21,22,25,30,40,61,62,70"):
                with self.subTest(mode=mode, selection=selection):
                    self.write("current-version", "2020.1.1\n")
                    self.env[mode] = "1"
                    try:
                        result = self.setup(selection)
                        self.assertNotEqual(result.returncode, 0, result.stdout)
                        self.assertFalse((self.home / ".zshrc").exists())
                        self.assertFalse((self.home / ".config/mise/config.toml").exists())
                    finally:
                        del self.env[mode]

    def test_native_apply_blocks_outdated_mise_and_release_failure(self):
        self.assert_success(self.setup("--only=60"))
        target = self.home / ".zshrc"
        target.unlink()
        self.write("current-version", "2020.1.1\n")
        result = self.native("apply", "--yes")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse(target.exists())
        self.write("current-version", self.env["TEST_RELEASE"] + "\n")
        result = self.native("apply", "--yes", TEST_RELEASE_FAIL="1")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertFalse(target.exists())

    def test_native_conflict_requires_adoption_even_with_force(self):
        self.assert_success(self.setup("--only=60"))
        target = self.home / ".zshrc"
        target.unlink()
        self.write(".zshrc", "native conflict\n")
        result = self.native("apply", "--force", "--yes")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(target.read_text(), "native conflict\n")
        self.assert_success(self.native("apply", "--yes", DOTFILES_ADOPT="1"))
        self.assertEqual(next(self.home.glob(".zshrc.backup-*/.zshrc")).read_text(), "native conflict\n")

    def test_occupied_standard_checkout_is_not_replaced(self):
        other = self.home / "development-checkout"
        self.checkout.rename(other)
        self.write(".dotfiles/keep", "other checkout\n")
        result = self.run_command(["bash", str(other / "setup/bootstrap.sh"), "--only=60", "--auto"])
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual((self.checkout / "keep").read_text(), "other checkout\n")
        self.assertFalse((self.home / ".zshrc").exists())


if __name__ == "__main__":
    unittest.main()
