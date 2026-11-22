"""Regressions for batched Trace metadata and remote ancestry validation."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import types
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parent
checker = types.ModuleType("dockit_trace_check")
exec(compile((ROOT / "dockit-trace-check.py").read_bytes(),
             str(ROOT / "dockit-trace-check.py"), "exec"), checker.__dict__)


class TraceCheck(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="dockit-trace-check-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
                        GIT_AUTHOR_DATE="2000-01-02T08:43:29+0200",
                        GIT_COMMITTER_DATE="2000-01-02T08:43:29+0200")
        self.git("init", "-q")
        self.git("config", "user.name", "Trace fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "core.hooksPath", ".git/disabled-fixture-hooks")
        self.git("commit", "--allow-empty", "--no-gpg-sign", "-qm", "Initial subject")
        self.initial = self.git("rev-parse", "HEAD")
        self.git("update-ref", "refs/remotes/origin/main", self.initial)
        self.git("commit", "--allow-empty", "--no-gpg-sign", "-qm", "Remote feature")
        self.feature = self.git("rev-parse", "HEAD")
        self.git("update-ref", "refs/remotes/origin/feature", self.feature)
        self.git("commit", "--allow-empty", "--no-gpg-sign", "-qm", "Local only")
        self.local = self.git("rev-parse", "HEAD")
        docs = self.root / "docs/llm"
        docs.mkdir(parents=True)
        self.handoff = docs / "HANDOFF.md"
        self.history = docs / "HISTORY.md"
        self.handoff.write_text(f"## Trace Anchor\nRole: executor\nSubject: `{self.initial}` Initial subject\n2000-01-02 06:43:29 UTC\nRepo state: fixture\nValidation: fixture\nNext: fixture\n")
        self.args = argparse.Namespace(project=self.root, since="2000-01-01", upstream="main", reject_current=False)

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], env=self.env,
                                       stderr=subprocess.DEVNULL).decode().strip()

    def entry(self, value, external=None):
        extra = " external=" + external + ";" if external is not None else ""
        return f"- 2000-01-02 - Checked `{value}`. Trace: role=auditor; commits={value};{extra} state=fixture; validation=fixture; next=fixture\n"

    def test_many_rows_use_bounded_git_batches(self):
        self.history.write_text(self.entry(self.initial) * 1000)
        with mock.patch.object(checker, "git", wraps=checker.git) as calls:
            status, message = checker.check(self.args)
        self.assertEqual(status, "PASS", message)
        self.assertLessEqual(calls.call_count, 8)

    def test_remote_branch_warning_and_local_commit_failure(self):
        self.history.write_text(self.entry(self.feature))
        status, message = checker.check(self.args)
        self.assertEqual(status, "WARN")
        self.assertIn("refs/remotes/origin/feature", message)
        self.history.write_text(self.entry(self.local))
        status, message = checker.check(self.args)
        self.assertEqual(status, "FAIL")
        self.assertIn("not an ancestor", message)

    def test_failed_remote_listing_cannot_accept_local_commit(self):
        self.history.write_text(self.entry(self.local))
        original = checker.git
        def fail_listing(project, *args, **kwargs):
            if args[0] == "for-each-ref":
                return 1, ""
            return original(project, *args, **kwargs)
        with mock.patch.object(checker, "git", side_effect=fail_listing):
            with self.assertRaisesRegex(ValueError, "remote reference listing failed"):
                checker.check(self.args)

    def test_signature_display_cannot_spawn_verifiers(self):
        verifier = self.root / "signature-observer.sh"
        verifier.write_text('#!/bin/sh\nprintf called > "$0.called"\nexit 1\n')
        verifier.chmod(0o755)
        self.git("config", "log.showSignature", "true")
        self.git("config", "gpg.program", str(verifier))
        tree = self.git("rev-parse", self.initial + "^{tree}")
        raw = (f"tree {tree}\nparent {self.initial}\n"
               "author Fixture <fixture@example.invalid> 946800000 +0000\n"
               "committer Fixture <fixture@example.invalid> 946800000 +0000\n"
               "gpgsig -----BEGIN PGP SIGNATURE-----\n"
               " invalid-synthetic-signature\n -----END PGP SIGNATURE-----\n"
               "\nSynthetic signed commit\n")
        signed = subprocess.check_output(
            ["git", "-C", str(self.root), "hash-object", "-t", "commit", "-w", "--stdin"],
            input=raw.encode(), env=self.env).decode().strip()
        self.git("update-ref", "refs/remotes/origin/main", signed)
        self.history.write_text(self.entry(signed))
        status, message = checker.check(self.args)
        self.assertEqual(status, "PASS", message)
        self.git("tag", "-a", "-m", "Tag", "signed-target", signed)
        self.history.write_text(self.entry(self.git("rev-parse", "signed-target")))
        self.assertEqual(checker.check(self.args)[0], "PASS")
        self.assertFalse(Path(str(verifier) + ".called").exists())

    def test_external_empty_fields_keep_shell_semantics(self):
        entry = self.entry("deadbee", "other@deadbee,").replace("commits=deadbee", "commits=none")
        self.history.write_text(entry)
        self.assertEqual(checker.check(self.args)[0], "PASS")
        self.history.write_text(entry.replace("other@deadbee,", ",other@deadbee"))
        status, message = checker.check(self.args)
        self.assertEqual(status, "FAIL")
        self.assertIn("invalid external= reference", message)

    def test_annotated_tag_retains_quoted_object_identity(self):
        self.git("tag", "-a", "-m", "Tag subject", "fixture-tag", self.initial)
        tag = self.git("rev-parse", "fixture-tag")
        self.history.write_text(self.entry(tag))
        status, message = checker.check(self.args)
        self.assertEqual(status, "PASS", message)


if __name__ == "__main__":
    unittest.main()
