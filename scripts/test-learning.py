#!/usr/bin/env python3
"""Regression tests for adopted failure-learning closure and deletion gates."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/dockit-learning.py"
VALIDATOR = ROOT / "scripts/dockit-validate-session.sh"


def run(*argv, cwd):
    env = os.environ.copy()
    for name in ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_COMMON_DIR"):
        env.pop(name, None)
    return subprocess.run(argv, cwd=cwd, env=env, text=True, capture_output=True, check=False)


class LearningGate(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "project"
        self.root.mkdir()
        self.outside = Path(self.temp.name) / "outside.md"
        self.outside.write_text("outside\n")
        (self.root / "docs/llm").mkdir(parents=True)
        (self.root / "scripts").mkdir()
        shutil.copy2(CHECKER, self.root / "scripts/dockit-learning.py")
        (self.root / "prevention.md").write_text("guard\n")
        (self.root / "source.md").write_text("owner\n")
        self.path = self.root / "docs/llm/FAILURE_LEARNING.json"
        run("git", "init", "-q", cwd=self.root)
        run("git", "add", "source.md", "prevention.md", cwd=self.root)
        committed = run("git", "-c", "user.name=Test", "-c",
                        "user.email=test@example.invalid", "-c", "commit.gpgsign=false",
                        "commit", "-qm", "fixture", cwd=self.root)
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.revision = run("git", "rev-parse", "HEAD", cwd=self.root).stdout.strip()

    def case(self, **changes):
        item = {
            "id": "FL-001", "observed": "agent used stale source",
            "consequence": "operator asked for unnecessary action",
            "cause_status": "known", "cause": "old source precedence",
            "status": "closed", "corrective_action": "publish guard",
            "owner": "owner", "verification": "actual readback",
            "source_refs": ["source.md"], "prevention_refs": ["prevention.md"],
            "adoption_revision": self.revision,
            "coverage_limit": "declared case only",
        }
        item.update(changes)
        self.path.write_text(json.dumps({"schema": 1, "cases": [item]}))

    def check(self):
        return run(sys.executable, str(CHECKER), "--project", str(self.root), cwd=self.root)

    def validate(self):
        return run("sh", str(VALIDATOR), "--project", str(self.root),
                   "--check", "failure-learning", "--human", cwd=self.root)

    def test_unadopted_skips_and_tracked_deletion_fails(self):
        self.assertIn("SKIP", self.validate().stdout)
        self.case(status="open", adoption_revision=None)
        run("git", "add", "docs/llm/FAILURE_LEARNING.json", cwd=self.root)
        committed = run("git", "-c", "user.name=Test", "-c",
                        "user.email=test@example.invalid", "-c", "commit.gpgsign=false",
                        "commit", "-qm", "adopt", cwd=self.root)
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.path.unlink()
        checked = self.validate()
        self.assertEqual(checked.returncode, 1, checked.stdout + checked.stderr)
        self.assertIn("Tracked failure-learning register is missing", checked.stdout)
        run("git", "add", "-u", cwd=self.root)
        committed = run("git", "-c", "user.name=Test", "-c",
                        "user.email=test@example.invalid", "-c", "commit.gpgsign=false",
                        "commit", "-qm", "delete", cwd=self.root)
        self.assertEqual(committed.returncode, 0, committed.stderr)
        self.assertIn("Tracked failure-learning register is missing", self.validate().stdout)

    def test_valid_close_passes_with_coverage_limit(self):
        self.case()
        checked = self.validate()
        self.assertEqual(checked.returncode, 0, checked.stdout + checked.stderr)
        self.assertIn("conversation coverage is not inferred", checked.stdout)

    def test_malformed_and_duplicate_cases_fail(self):
        for body in ("{", "[]", "42", '{"schema":true,"cases":[]}'):
            self.path.write_text(body)
            self.assertNotEqual(self.check().returncode, 0, body)
        self.case()
        data = json.loads(self.path.read_text())
        data["cases"].append(dict(data["cases"][0]))
        self.path.write_text(json.dumps(data))
        self.assertIn("unique FL-nnn", self.check().stderr)

    def test_unsupported_close_fails(self):
        for changes, expected in (
            ({"cause_status": "unknown"}, "established cause"),
            ({"source_refs": []}, "requires source_refs"),
            ({"prevention_refs": []}, "requires prevention_refs"),
            ({"adoption_revision": None}, "requires an adoption revision"),
            ({"prevention_refs": ["new-guard.md"]}, "absent at adoption revision"),
            ({"source_refs": ["../outside.md"]}, "outside project"),
            ({"source_refs": [str(self.outside)]}, "outside project"),
        ):
            self.case(**changes)
            if changes.get("prevention_refs") == ["new-guard.md"]:
                (self.root / "new-guard.md").write_text("unpublished\n")
            result = self.check()
            self.assertNotEqual(result.returncode, 0, changes)
            self.assertIn(expected, result.stderr, changes)


if __name__ == "__main__":
    unittest.main()
