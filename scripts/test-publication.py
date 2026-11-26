#!/usr/bin/env python3
"""Native Git publication boundary tests; all synthetic repositories retire."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location("publication", Path(__file__).with_name("dockit-publication.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dockit-publication-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "repo"
        self.remote = self.base / "remote.git"
        self.repo.mkdir()
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Synthetic Test")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "core.hooksPath", str(self.base / "no-hooks"))
        subprocess.run(["git", "init", "--bare", "--initial-branch=main", str(self.remote)], check=True, capture_output=True)
        (self.repo / "source").write_text("first\n")
        self.git("add", "source")
        self.git("-c", "commit.gpgsign=false", "commit", "-m", "Initial synthetic fixture")
        self.git("remote", "add", "origin", str(self.remote))
        self.git("push", "-u", "origin", "main")

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], check=True,
                              capture_output=True, env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})

    def test_published_is_live_and_no_fetch(self):
        before = sorted(str(p.relative_to(self.repo / ".git")) for p in (self.repo / ".git").rglob("*") if p.is_file())
        result = module.inspect(self.repo, True)
        self.assertEqual(result["state"], "published")
        self.assertTrue(result["remote_verified"])
        after = sorted(str(p.relative_to(self.repo / ".git")) for p in (self.repo / ".git").rglob("*") if p.is_file())
        self.assertEqual(before, after)

    def test_untracked_blocks_closeout(self):
        (self.repo / "not-committed").write_text("pending")
        self.assertEqual(module.inspect(self.repo, True)["state"], "pending")

    def test_staged_blocks_closeout(self):
        (self.repo / "source").write_text("changed")
        self.git("add", "source")
        self.assertTrue(module.inspect(self.repo, True)["dirty"])

    def test_unpublished_commit_blocks(self):
        (self.repo / "source").write_text("second")
        self.git("-c", "commit.gpgsign=false", "commit", "-am", "Unpublished synthetic work")
        self.assertEqual(module.inspect(self.repo, True)["state"], "pending")

    def test_side_branch_push_does_not_close_default(self):
        self.git("checkout", "-b", "task")
        (self.repo / "source").write_text("second")
        self.git("-c", "commit.gpgsign=false", "commit", "-am", "Synthetic task")
        self.git("push", "-u", "origin", "task")
        self.assertEqual(module.inspect(self.repo, True)["state"], "pending")

    def test_offline_cannot_claim_publication(self):
        result = module.inspect(self.repo)
        self.assertEqual(result["state"], "locally_synchronized")
        self.assertFalse(result["remote_verified"])

    def test_unavailable_remote_cannot_claim_publication(self):
        self.git("remote", "set-url", "origin", str(self.base / "absent"))
        with self.assertRaises(ValueError):
            module.inspect(self.repo, True)

    def test_distinct_push_destination_is_unverified(self):
        self.git("remote", "set-url", "--push", "origin", str(self.base / "different.git"))
        with self.assertRaisesRegex(ValueError, "destinations differ"):
            module.inspect(self.repo, True)


if __name__ == "__main__":
    unittest.main()
