#!/usr/bin/env python3
"""Regress configuration reader semantics and per-line process creation."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
NAMES = (
    "_read_top_level_value", "_read_ext_path", "_read_ext_read_files",
    "_read_ext_triggers", "_read_orientation_drift_value", "_read_orientation_drift_docs",
)
SOURCE = (ROOT / "scripts/dockit-validate-session.sh").read_text()
FUNCTIONS = "\n".join(
    re.search(r"^" + name + r"\(\) \{.*?^\}", SOURCE, re.M | re.S).group()
    for name in NAMES
)
SHELL = shutil.which("sh")


class ConfigReaders(unittest.TestCase):
    def run_reader(self, text, call, env=None):
        with tempfile.TemporaryDirectory(prefix="dockit-config-reader-") as temp:
            path = Path(temp) / "config.yml"
            path.write_bytes(text.encode())
            result = subprocess.run(
                [SHELL, "-c", FUNCTIONS + '\nCONFIG_FILE=$1\n' + call,
                 "reader", str(path)], capture_output=True, text=True,
                env=env, timeout=10,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_reader_values_and_indentation(self):
        config = '''# comment
history_format: "dash"
  history_format: nested
external_context:
  path: ~/project
  read:
    - docs/a.md
    raw-entry.md
  update_triggers:
    - local: src/* target: docs/b.md
orientation_drift:
  enabled: 'true'
  docs:
    - "README.md"
    - 'docs/ROADMAP.md'
\tinvalid: tab
'''
        cases = (
            ("_read_top_level_value history_format", "dash\n"),
            ("_read_top_level_value absent", ""),
            ("_read_ext_path", "~/project\n"),
            ("_read_ext_read_files", "docs/a.md\nraw-entry.md\n"),
            ("_read_ext_triggers", "src/*|docs/b.md\n"),
            ("_read_orientation_drift_value enabled", "true\n"),
            ("_read_orientation_drift_docs", "README.md\ndocs/ROADMAP.md\n"),
        )
        for call, expected in cases:
            with self.subTest(call=call):
                self.assertEqual(self.run_reader(config, call), expected)
        self.assertEqual(self.run_reader("history_format: dash", cases[0][0]), "dash\n")

    def test_legacy_echo_sensitive_lines(self):
        # These lines affected section state through echo's shell-dependent
        # interpretation. Preserve the actual host shell's prior behavior.
        for line in ("-n", "-e", "\\c"):
            echoed = subprocess.run(
                [SHELL, "-c", 'echo "$1"', "echo-probe", line],
                capture_output=True, text=True, check=True, timeout=3,
            ).stdout.rstrip("\n")
            expected = "retained\n" if echoed == "" else ""
            config = "external_context:\n" + line + "\n  path: retained\n"
            with self.subTest(line=line):
                self.assertEqual(self.run_reader(config, "_read_ext_path"), expected)

    def test_normal_lines_do_not_spawn_sed(self):
        real_sed = shutil.which("sed")
        with tempfile.TemporaryDirectory(prefix="dockit-reader-counter-") as temp:
            root = Path(temp)
            counter = root / "calls"
            wrapper = root / "sed"
            wrapper.write_text('#!/bin/sh\nprintf x >> "$READER_COUNTER"\nexec "$READER_REAL_SED" "$@"\n')
            wrapper.chmod(0o755)
            env = dict(os.environ, PATH=temp + os.pathsep + os.environ["PATH"],
                       READER_COUNTER=str(counter), READER_REAL_SED=real_sed)
            config = "".join(f"unused_{i}: value\n" for i in range(200))
            config += 'history_format: "dash"\n'
            self.assertEqual(self.run_reader(config, "_read_top_level_value history_format", env), "dash\n")
            self.assertEqual(counter.read_text(), "x")


if __name__ == "__main__":
    unittest.main()
