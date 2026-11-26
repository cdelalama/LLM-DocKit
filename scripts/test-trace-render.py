#!/usr/bin/env python3
"""Exercise Trace rendering and fallback without services or persistent fixtures."""
import importlib.util
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("trace_render", ROOT / "scripts/dockit-trace-render.py")
RENDER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RENDER)
SNAPSHOT = {
    "role": "advisor", "sent": "2026-11-26 22:00:00 CET (21:00:00 UTC)",
    "subject": "Revisión de estado", "resulting_state": "HEAD=123abcd; version=4.23.0; gate=next-slice",
    "repo_state": "local main=123abcd, origin/main=123abcd, clean",
    "validation": "PASS", "next": "Revisar la publicación",
    "client": "Orca", "model": "unknown", "account": "openai-2",
}


class Document(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.tags = []
        self.values = []
        self.in_dd = False
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))
        if tag == "dd":
            self.in_dd = True
            self.values.append("")

    def handle_endtag(self, tag):
        if tag == "dd":
            self.in_dd = False

    def handle_data(self, data):
        if self.in_dd:
            self.values[-1] += data


class TraceRendering(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dockit-trace-test-")
        self.root = Path(self.temp.name)
        self.addCleanup(self.retire)

    def retire(self):
        self.temp.cleanup()
        self.assertFalse(self.root.exists())

    def cli(self, format="auto", directory=None, **fields):
        args = [sys.executable, "-B", str(ROOT / "scripts/dockit-trace-render.py"), "--format", format]
        for key, value in (SNAPSHOT | fields).items():
            args.append("--" + key.replace("_", "-") + "=" + value)
        env = dict(os.environ)
        env.pop("ORCA_CHAT_SCRATCH_DIR", None)
        if directory is not None:
            env["ORCA_CHAT_SCRATCH_DIR"] = str(directory)
        return subprocess.run(args, env=env, capture_output=True, text=True, check=True)

    def test_same_values_in_text_json_html(self):
        raw = self.cli("json").stdout
        snapshot = json.loads(raw)["fields"]
        self.assertEqual(snapshot, SNAPSHOT)
        doc = Document(RENDER.html_snapshot(snapshot).decode())
        self.assertEqual(doc.values, [v for _, v in RENDER.field_values(snapshot)])
        for label, value in RENDER.field_values(snapshot):
            self.assertIn(f"{label}: {value}\n", RENDER.text_snapshot(snapshot))

    def test_untrusted_values_are_only_text(self):
        value = '<script>alert(1)</script><img src="https://example.invalid" onerror="x"> javascript:alert(1) & "'
        doc = Document(RENDER.html_snapshot(SNAPSHOT | {"subject": value}).decode())
        self.assertIn(value, doc.values)
        self.assertFalse(any(tag in ("script", "img", "a", "iframe", "link") for tag, _ in doc.tags))
        self.assertFalse(any(k.startswith("on") or k in ("href", "src") for _, attrs in doc.tags for k in attrs))

    def test_absent_capability_and_missing_directory_fall_back(self):
        for directory in (None, self.root / "missing"):
            result = self.cli(directory=directory)
            self.assertEqual(result.stdout, RENDER.text_snapshot(SNAPSHOT))
        self.assertEqual(list(self.root.iterdir()), [])

    def test_explicit_html_without_capability_also_falls_back(self):
        result = self.cli("html")
        self.assertEqual(result.stdout, RENDER.text_snapshot(SNAPSHOT))
        self.assertIn("using text", result.stderr)

    def test_immutable_visual_and_safe_directive(self):
        first = self.cli(directory=self.root).stdout
        second = self.cli(directory=self.root).stdout
        pattern = r'^::orca-visual\{file="(trace-[0-9a-f]{32}\.html)" title="Trace"\}\n$'
        one = re.fullmatch(pattern, first).group(1)
        two = re.fullmatch(pattern, second).group(1)
        self.assertNotEqual(one, two)
        self.assertEqual((self.root / one).read_bytes(), (self.root / two).read_bytes())
        self.assertLess((self.root / one).stat().st_size, RENDER.MAX_HTML_BYTES)

    def test_size_limit_leaves_no_file(self):
        with self.assertRaises(ValueError):
            RENDER.write_visual(SNAPSHOT | {"subject": "<" * RENDER.MAX_HTML_BYTES}, str(self.root))
        self.assertEqual(list(self.root.iterdir()), [])

    def test_write_failure_falls_back_and_leaves_no_file(self):
        with patch.object(RENDER.os, "open", side_effect=PermissionError("private path")):
            with self.assertRaises(PermissionError):
                RENDER.write_visual(SNAPSHOT, str(self.root))
        self.assertEqual(list(self.root.iterdir()), [])
        # A regular file is also a real invalid output directory.
        target = self.root / "not-a-directory"
        target.write_text("preserve")
        result = self.cli(directory=target)
        self.assertEqual(result.stdout, RENDER.text_snapshot(SNAPSHOT))
        self.assertEqual(target.read_text(), "preserve")

    def test_collision_preserves_previous_artifact(self):
        name = "trace-" + "a" * 32 + ".html"
        previous = self.root / name
        previous.write_text("previous")
        with patch.object(RENDER.uuid, "uuid4") as mock:
            mock.return_value.hex = "a" * 32
            with self.assertRaises(FileExistsError):
                RENDER.write_visual(SNAPSHOT, str(self.root))
        self.assertEqual(previous.read_text(), "previous")

    def test_partial_write_failure_removes_only_owned_output(self):
        previous = self.root / "previous.html"
        previous.write_text("keep")
        with patch.object(RENDER.os, "fdopen", side_effect=OSError("write failed")):
            with self.assertRaises(OSError):
                RENDER.write_visual(SNAPSHOT, str(self.root))
        self.assertEqual(list(self.root.iterdir()), [previous])
        self.assertEqual(previous.read_text(), "keep")

    def test_spanish_labels_preserve_values(self):
        source = RENDER.html_snapshot(SNAPSHOT, "es").decode()
        self.assertIn('<html lang="es">', source)
        self.assertIn("Siguiente paso", source)
        self.assertEqual(Document(source).values, [v for _, v in RENDER.field_values(SNAPSHOT)])

    def test_shell_text_and_json_agree_except_observation_time(self):
        env = dict(os.environ)
        env.pop("ORCA_CHAT_SCRATCH_DIR", None)
        command = ["sh", str(ROOT / "scripts/dockit-trace-status.sh"), "--project", str(self.root),
                   "--role", "advisor", "--subject", "Example", "--validation", "PASS", "--next", "Review"]
        text = subprocess.check_output(command + ["--format", "text"], env=env, text=True)
        snapshot = json.loads(subprocess.check_output(command + ["--format", "json"], env=env, text=True))["fields"]
        actual = [x for x in text.splitlines() if not x.startswith("Sent:")]
        expected = [x for x in RENDER.text_snapshot(snapshot).splitlines() if not x.startswith("Sent:")]
        self.assertEqual(actual, expected)
        self.assertTrue(text.startswith("Trace\nRole: advisor\nSent: "))
        self.assertEqual(len(text.splitlines()), 8)
        self.assertEqual(actual, ["Trace", "Role: advisor", "Subject: Example",
            "Resulting state: HEAD=none; version=none; gate=next-slice",
            "Repo state: local detached=none, no upstream, clean",
            "Validation: PASS", "Next gate: Review"])

    def test_shell_missing_renderer_falls_back_without_artifact(self):
        script = self.root / "dockit-trace-status.sh"
        shutil.copyfile(ROOT / "scripts/dockit-trace-status.sh", script)
        env = dict(os.environ, ORCA_CHAT_SCRATCH_DIR=str(self.root))
        result = subprocess.run(["sh", str(script), "--project", str(self.root)],
                                env=env, capture_output=True, text=True, check=True)
        self.assertTrue(result.stdout.startswith("Trace\n"))
        self.assertIn("missing Python 3 or renderer", result.stderr)
        self.assertEqual(list(self.root.glob("*.html")), [])

    def test_shell_auto_capability_and_explicit_text(self):
        env = dict(os.environ, ORCA_CHAT_SCRATCH_DIR=str(self.root))
        command = ["sh", str(ROOT / "scripts/dockit-trace-status.sh"), "--project", str(self.root),
                   "--language", "es", "--model", "unknown", "--dossier", "unavailable"]
        visual = subprocess.check_output(command, env=env, text=True)
        self.assertTrue(visual.startswith('::orca-visual{file="trace-'))
        doc = next(self.root.glob("trace-*.html")).read_text()
        self.assertIn("Siguiente paso", doc)
        text = subprocess.check_output(command + ["--format", "text"], env=env, text=True)
        self.assertTrue(text.startswith("Trace\n"))
        self.assertIn("Model: unknown\n", text)
        self.assertEqual(len(list(self.root.glob("trace-*.html"))), 1)


if __name__ == "__main__":
    unittest.main()
