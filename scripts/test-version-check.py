"""Version-marker contracts; optional DOCKIT_VERSION_BASELINE checks old/new parity."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

CHECKER = Path(__file__).resolve().with_name("check-version-sync.sh")
BASELINE = os.environ.get("DOCKIT_VERSION_BASELINE")


class VersionCheck(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="dockit-version-check-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        (self.root / "docs").mkdir()
        (self.root / "VERSION").write_text("1.2.3\n")
        self.manifest = self.root / "docs/version-sync-manifest.yml"
        self.manifest.write_text("targets:\n- path: doc.md marker: html-comment\n")
        self.doc = self.root / "doc.md"
        self.doc.write_text("<!-- doc-version: 1.2.3 -->\n")
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.shell = shutil.which("sh")
        if not self.shell and os.name == "nt":
            self.shell = str(Path(shutil.which("git")).parent.parent / "bin/sh.exe")

    def check(self, *args, compare=True):
        result = subprocess.run([self.shell, str(CHECKER), *args], cwd=self.root,
                                env=self.env, capture_output=True, text=True, timeout=15)
        if BASELINE and compare:
            old = subprocess.run([self.shell, BASELINE, *args], cwd=self.root,
                                 env=self.env, capture_output=True, text=True, timeout=15)
            self.assertEqual((result.returncode, result.stdout, result.stderr),
                             (old.returncode, old.stdout, old.stderr))
        return result

    def test_first_marker_wins_on_same_line_and_later_lines(self):
        for separator in (" prefix ", "\n"):
            with self.subTest(separator=separator):
                self.doc.write_text("prefix <!-- doc-version: 1.2.3 -->" + separator + "<!-- doc-version: 9.9.9 -->\n")
                result = self.check()
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout, "OK: 1 target(s) in sync with VERSION (1.2.3)\n")

    def test_missing_and_non_semver_markers_fail(self):
        for contents in ("no marker", "<!-- doc-version: 1.2 -->", "<!-- doc-version: 1.2.3-rc.1 -->", "<!-- doc-version: x.y.z -->"):
            with self.subTest(contents=contents):
                self.doc.write_text(contents)
                result = self.check()
                self.assertEqual(result.returncode, 1)
                self.assertIn("doc.md missing <!-- doc-version: --> marker", result.stdout)

    def test_invalid_marker_before_valid_marker_is_ignored(self):
        self.doc.write_text("<!-- doc-version: 1.2 --> <!-- doc-version: 1.2.3 -->\n")
        self.assertEqual(self.check().returncode, 0)

    def test_first_valid_marker_drift_fails(self):
        self.doc.write_text("<!-- doc-version: 9.9.9 -->\n<!-- doc-version: 1.2.3 -->\n")
        result = self.check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("doc.md has '9.9.9', expected '1.2.3'", result.stdout)

    def test_empty_manifest_has_zero_targets(self):
        self.manifest.write_text("targets:\n# No targets yet\n")
        result = self.check()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "OK: 0 target(s) in sync with VERSION (1.2.3)\n")

    def test_missing_target_remains_warning(self):
        self.doc.unlink()
        result = self.check()
        self.assertEqual(result.returncode, 0)
        self.assertIn("WARN: doc.md not found, skipping", result.stdout)

    @unittest.skipIf(os.name == "nt" or getattr(os, "geteuid", lambda: 0)() == 0,
                     "POSIX unprivileged file readability contract")
    def test_unreadable_html_marker_is_reported_as_drift(self):
        self.doc.chmod(0)
        try:
            result = self.check()
            self.assertEqual(result.returncode, 1)
            self.assertIn("doc.md missing <!-- doc-version: --> marker", result.stdout)
        finally:
            self.doc.chmod(0o600)

    def test_unknown_and_missing_marker_types_fail(self):
        for marker in ("unknown-marker", ""):
            with self.subTest(marker=marker):
                self.manifest.write_text("targets:\n- path: doc.md marker: " + marker + "\n")
                result = self.check()
                self.assertEqual(result.returncode, 1)
                self.assertIn("uses unknown marker type", result.stdout)

    def test_staged_selection_keeps_worktree_reading(self):
        subprocess.run(["git", "init", "-q"], cwd=self.root, env=self.env, check=True)
        self.doc.write_text("<!-- doc-version: 9.9.9 -->\n")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0)
        self.assertIn("OK: 0 target(s)", result.stdout)
        subprocess.run(["git", "add", "doc.md"], cwd=self.root, env=self.env, check=True)
        self.assertEqual(self.check("--staged").returncode, 1)
        self.doc.write_text("<!-- doc-version: 1.2.3 -->\n")
        result = self.check("--staged")
        self.assertEqual(result.returncode, 0)
        self.assertIn("OK: 1 target(s)", result.stdout)

    def write_structured_versions(self, changed=None):
        self.manifest.write_text("targets:\n- path: VERSION marker: version-file\n- path: package.json marker: json-version\n- path: openapi.yml marker: yaml-info-version\n- path: package-lock.json marker: package-lock-version\n")
        versions = {key: "1.2.3" for key in ("json", "yaml", "lock-top", "lock-root")}
        if changed:
            versions[changed] = "9.9.9"
        (self.root / "package.json").write_text(json.dumps({"version": versions["json"]}))
        (self.root / "openapi.yml").write_text('info:\n  title: fixture\n  version: "' + versions["yaml"] + '"\n')
        (self.root / "package-lock.json").write_text(json.dumps({"version": versions["lock-top"], "packages": {"": {"version": versions["lock-root"]}}}))

    def test_structured_versions_pass_and_detect_each_drift(self):
        self.write_structured_versions()
        result = self.check()
        self.assertEqual(result.returncode, 0)
        self.assertIn("OK: 4 target(s)", result.stdout)
        for changed in ("json", "yaml", "lock-top", "lock-root"):
            with self.subTest(changed=changed):
                self.write_structured_versions(changed)
                result = self.check()
                self.assertEqual(result.returncode, 1)
                self.assertIn("FAILED: 1 file(s)", result.stdout)

    def test_unreadable_structured_versions_fail(self):
        for file, contents in (("package.json", "{bad"), ("openapi.yml", "info:\n  title: missing version\n"), ("package-lock.json", '{"version":"1.2.3","packages":{}}')):
            with self.subTest(file=file):
                self.write_structured_versions()
                (self.root / file).write_text(contents)
                self.assertEqual(self.check().returncode, 1)

    @unittest.skipIf(os.name == "nt", "POSIX PATH shim verifies the removed mktemp dependency")
    def test_no_manifest_scratch_file_when_mktemp_unavailable(self):
        commands = self.root / "commands"
        commands.mkdir()
        mktemp = commands / "mktemp"
        mktemp.write_text('#!/bin/sh\nprintf called > mktemp-called\nexit 97\n')
        mktemp.chmod(0o755)
        self.env["PATH"] = str(commands) + os.pathsep + self.env["PATH"]
        result = self.check(compare=False)
        self.assertEqual(result.returncode, 0)
        self.assertFalse((self.root / "mktemp-called").exists())
        if BASELINE:
            old = subprocess.run([self.shell, BASELINE], cwd=self.root, env=self.env,
                                 capture_output=True, text=True, timeout=15)
            self.assertEqual(old.returncode, 97)
            self.assertTrue((self.root / "mktemp-called").is_file())


if __name__ == "__main__":
    unittest.main()
