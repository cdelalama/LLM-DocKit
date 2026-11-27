#!/usr/bin/env python3
"""Exercise Trace rendering and fallback without services or persistent fixtures."""
import importlib.util
import base64
import hashlib
from datetime import datetime, timezone
import shlex
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
        self.in_pre = False
        self.pre = ""
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        self.tags.append((tag, dict(attrs)))
        if tag == "dd":
            self.in_dd = True
            self.values.append("")
        if tag == "pre":
            self.in_pre = True

    def handle_endtag(self, tag):
        if tag == "dd":
            self.in_dd = False
        if tag == "pre":
            self.in_pre = False

    def handle_data(self, data):
        if self.in_dd:
            self.values[-1] += data
        if self.in_pre:
            self.pre += data


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

    def copied_helper(self, format="html"):
        helper = self.root / "helper"
        helper.mkdir(exist_ok=True)
        shutil.copyfile(ROOT / "scripts/dockit-trace-render.py", helper / "dockit-trace-render.py")
        command = [sys.executable, "-B", str(helper / "dockit-trace-render.py"), "--format", format]
        command.extend("--" + key.replace("_", "-") + "=" + value for key, value in SNAPSHOT.items())
        return subprocess.run(command, env=dict(os.environ, ORCA_CHAT_SCRATCH_DIR=str(self.root)),
                              capture_output=True, text=True, check=True)

    def test_copied_helper_without_template_falls_back_without_artifact(self):
        result = self.copied_helper()
        self.assertEqual(result.stdout, RENDER.text_snapshot(SNAPSHOT))
        self.assertIn("using text", result.stderr)
        self.assertEqual(list(self.root.glob("trace-*.html")), [])

    def test_copied_helper_with_packaged_template_renders(self):
        helper = self.root / "helper"
        helper.mkdir()
        shutil.copyfile(RENDER.TEMPLATE_PATH, helper / RENDER.TEMPLATE_PATH.name)
        result = self.copied_helper()
        artifact = re.search(r'file="([^"]+)"', result.stdout).group(1)
        document = Document((self.root / artifact).read_text())
        self.assertEqual(document.values, list(SNAPSHOT.values()))
        self.assertEqual(document.pre, RENDER.text_snapshot(SNAPSHOT))

    def test_malformed_template_falls_back_without_artifact(self):
        helper = self.root / "helper"
        helper.mkdir()
        original = RENDER.TEMPLATE_PATH.read_bytes()
        malformed = [b"not HTML", b"\xff", b"x" * RENDER.MAX_HTML_BYTES,
                     original.replace(b"@@DOCKIT_SUBJECT@@", b"@@DOCKIT_UNKNOWN@@"),
                     original.replace(b"@@DOCKIT_SUBJECT@@", b"@@DOCKIT_SUBJECT@@" * 2),
                     original.replace(b"</body>", b""),
                     original.replace(b"<h1>@@DOCKIT_SUBJECT@@</h1>", b'<h1 title="@@DOCKIT_SUBJECT@@">invalid context</h1>'),
                     original.replace(b"</head>", b"<script>invalid()</script></head>")]
        for index, candidate in enumerate(malformed):
            with self.subTest(case=index):
                (helper / RENDER.TEMPLATE_PATH.name).write_bytes(candidate)
                result = self.copied_helper()
                self.assertEqual(result.stdout, RENDER.text_snapshot(SNAPSHOT))
                self.assertIn("using text", result.stderr)
                self.assertEqual(list(self.root.glob("trace-*.html")), [])

    def test_crlf_checkout_of_packaged_template_renders(self):
        helper = self.root / "helper"
        helper.mkdir()
        template = RENDER.TEMPLATE_PATH.read_bytes().replace(b"\r\n", b"\n")
        (helper / RENDER.TEMPLATE_PATH.name).write_bytes(template.replace(b"\n", b"\r\n"))
        self.assertTrue(self.copied_helper().stdout.startswith("::orca-visual{"))

    def test_text_and_json_do_not_read_template(self):
        helper = self.root / "helper"
        helper.mkdir()
        (helper / RENDER.TEMPLATE_PATH.name).write_bytes(b"\xff")
        self.assertEqual(self.copied_helper("text").stdout, RENDER.text_snapshot(SNAPSHOT))
        self.assertEqual(json.loads(self.copied_helper("json").stdout)["fields"], SNAPSHOT)

    def test_one_pass_placeholders_and_all_optional_rows(self):
        values = {key: f'{key}: @@DOCKIT_ROWS@@ @@DOCKIT_SUBJECT@@ <script>bad</script> & "\nsecond line'
                  for key, _ in RENDER.FIELDS + RENDER.OPTIONAL_FIELDS}
        for language in ("en", "es"):
            with self.subTest(language=language):
                document = Document(RENDER.html_snapshot(values, language).decode())
                self.assertEqual(document.values, list(values.values()))
                self.assertEqual(document.pre, RENDER.text_snapshot(values))
                self.assertEqual(sum(tag == "dt" for tag, _ in document.tags), 14)
                self.assertFalse(any(tag == "script" for tag, _ in document.tags))
        with self.assertRaises(ValueError):
            RENDER.html_snapshot(values, 'en" onload="bad')

    def test_selected_fonts_and_full_licenses_preserved(self):
        # Source-only prototypes are deliberately omitted from new scaffolds.
        template = RENDER.TEMPLATE_PATH.read_text(encoding="utf-8")
        fonts = re.findall(r'data:font/woff2;base64,([A-Za-z0-9+/=]+)', template)
        self.assertEqual([hashlib.sha256(base64.b64decode(font)).hexdigest() for font in fonts], [
            "7a19a7027e125257d310c6dbd78ae3a30b5ea1e3794d60b12bb28227a003bfda",
            "7478e1920209e51dcc235d151d2056a0a6e3c54b4436f7030d256f231fe09b58"])
        notices = re.findall(r'<!-- Bundled unmodified font:.*?-->', template, re.DOTALL)
        self.assertEqual([hashlib.sha256(note.encode()).hexdigest() for note in notices], [
            "16ebe6d2178122559f2ab6199ca7d54bd2fcb9faafdff80e67f373d4c92d6340",
            "1eb4acb361338476c239b8773a70722114402c795c79f13f5fdbf1f2546e1e94",
        ])
        self.assertIn("font-src data:", template)
        self.assertLess(len(RENDER.html_snapshot(SNAPSHOT)), RENDER.MAX_HTML_BYTES)


class TraceClock(unittest.TestCase):
    """Isolated PATH simulations; these are not native Windows qualification."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dockit-trace-clock-")
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.project = self.root / "project"
        self.project.mkdir()
        self.clock_log = self.root / "clock-calls"
        self.ps_log = self.root / "powershell-calls"
        self.addCleanup(self.retire)
        for name in ("awk", "sed", "dirname", "tr", "dd", "cat"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.date = shutil.which("date")
        self.env = dict(os.environ, PATH=str(self.bin))
        self.env.pop("ORCA_CHAT_SCRATCH_DIR", None)
        self.env.pop("OS", None)
        self.zone("Europe/Madrid")

    def retire(self):
        self.temp.cleanup()
        self.assertFalse(self.root.exists())

    def executable(self, name, source):
        target = self.bin / name
        target.write_text(source)
        target.chmod(0o755)

    def zone(self, name):
        (self.project / ".dockit-config.yml").write_text(
            "trace_protocol:\n  local_timezone: " + name + "\n")

    def clock(self, utc, *, ignore_tz=False, bsd=False):
        epoch = int(datetime.fromisoformat(utc).replace(tzinfo=timezone.utc).timestamp())
        conversion = "exec " + shlex.quote(self.date) + ' "$@"'
        if ignore_tz:
            conversion = "TZ=UTC " + conversion
        if bsd:
            conversion = '''if [ "$1" = -u ]; then shift; utc=-u; else utc=; fi
if [ "$1" != -r ]; then exit 1; fi
shift
instant=$1
shift
exec ''' + shlex.quote(self.date) + ' $utc -d "@$instant" "$@"'
        self.executable("date", "#!/bin/sh\n" +
            'if [ "$*" = "-u +%s" ]; then\n' +
            " printf 'clock\\n' >> " + shlex.quote(str(self.clock_log)) + "\n" +
            f" printf '%s\\n' '{epoch}'\n exit 0\nfi\n" + conversion + "\n")
        return epoch

    def python(self, *, missing_zoneinfo=False):
        if missing_zoneinfo:
            # Disable both system TZPATH and optional site-packaged tzdata so
            # the real converter raises ZoneInfoNotFoundError on Madrid.
            self.executable("python3", '#!/bin/sh\nif [ "$1" = - ]; then\n' +
                            ' PYTHONTZPATH=' + shlex.quote(str(self.root / "absent-zoneinfo")) +
                            ' exec ' + shlex.quote(sys.executable) + ' -S "$@"\nfi\nexec ' +
                            shlex.quote(sys.executable) + ' "$@"\n')
        else:
            (self.bin / "python3").symlink_to(sys.executable)

    def powershell(self, *, available=True, epoch=None):
        self.env["OS"] = "Windows_NT"
        self.executable("powershell.exe", f"#!{sys.executable}\n" +
            "import os,sys\nfrom datetime import datetime, timezone\nfrom zoneinfo import ZoneInfo\n" +
            f"with open({str(self.ps_log)!r}, 'a') as f: f.write('call\\n')\n" +
            ("sys.exit(1)\n" if not available else "") +
            "command=sys.argv[-1]\n" +
            f"if 'UtcNow' in command:\n print({epoch!r})\n sys.exit(0)\n" +
            "assert 'FindSystemTimeZoneById' in command\n" +
            "assert 'Romance Standard Time' in command\n" +
            "assert 'ConvertTimeFromUtc' in command\n" +
            "instant=datetime.fromtimestamp(int(os.environ['DOCKIT_TRACE_EPOCH']), timezone.utc)\n" +
            "local=instant.astimezone(ZoneInfo(os.environ['DOCKIT_TRACE_ZONE']))\n" +
            "print(local.strftime('%Y-%m-%d %H:%M:%S')+'|'+instant.strftime('%H:%M:%S UTC'))\n")

    def run_trace(self, format="text"):
        result = subprocess.run(["/bin/sh", str(ROOT / "scripts/dockit-trace-status.sh"),
            "--project", str(self.project), "--format", format], env=self.env,
            capture_output=True, text=True, check=True)
        return result.stdout

    def sent(self):
        output = self.run_trace()
        self.assertEqual(len(output.splitlines()), 8)
        return output.splitlines()[2].removeprefix("Sent: ")

    def test_python_ignores_broken_date_timezone_and_preserves_midnight(self):
        self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.python()
        self.assertEqual(self.sent(), "2026-11-27 00:02:32 Europe/Madrid (23:02:32 UTC)")
        self.assertEqual(self.clock_log.read_text().splitlines(), ["clock"])

    def test_python_dst_transition_from_same_utc_instant(self):
        self.python()
        cases = [("2026-03-29T00:59:59", "2026-03-29 01:59:59", "00:59:59"),
                 ("2026-03-29T01:00:00", "2026-03-29 03:00:00", "01:00:00"),
                 ("2026-10-25T00:59:59", "2026-10-25 02:59:59", "00:59:59"),
                 ("2026-10-25T01:00:00", "2026-10-25 02:00:00", "01:00:00")]
        for instant, local, utc in cases:
            with self.subTest(instant=instant):
                self.clock(instant, ignore_tz=True)
                self.assertEqual(self.sent(), f"{local} Europe/Madrid ({utc} UTC)")

    def test_python_accepts_legitimate_zero_offset_zones(self):
        self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.python()
        for zone in ("Europe/London", "UTC", "Africa/Abidjan"):
            with self.subTest(zone=zone):
                self.zone(zone)
                self.assertEqual(self.sent(), f"2026-11-26 23:02:32 {zone} (23:02:32 UTC)")

    def test_no_python_date_ignoring_tz_is_unverified(self):
        epoch = self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.assertEqual(self.sent(), f"unverified client time (UTC epoch {epoch}; requested zone Europe/Madrid)")

    def test_no_python_real_tzif_conversion_and_zero_offset(self):
        self.clock("2026-11-26T23:02:32")
        self.assertEqual(self.sent(), "2026-11-27 00:02:32 Europe/Madrid (23:02:32 UTC)")
        self.zone("Europe/London")
        self.assertEqual(self.sent(), "2026-11-26 23:02:32 Europe/London (23:02:32 UTC)")

    def test_bsd_date_interface_requires_same_tzif_probe(self):
        self.clock("2026-07-01T23:02:32", bsd=True)
        self.assertEqual(self.sent(), "2026-07-02 01:02:32 Europe/Madrid (23:02:32 UTC)")

    def test_missing_zone_database_uses_powershell_simulation(self):
        self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.python(missing_zoneinfo=True)
        self.powershell()
        self.assertEqual(self.sent(), "2026-11-27 00:02:32 Europe/Madrid (23:02:32 UTC)")
        self.assertEqual(self.ps_log.read_text().splitlines(), ["call"])

    def test_powershell_failure_is_unverified_with_broken_date(self):
        self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.python(missing_zoneinfo=True)
        self.powershell(available=False)
        self.assertTrue(self.sent().startswith("unverified client time"))

    def test_powershell_can_supply_clock_without_python_or_date(self):
        epoch = int(datetime(2026, 11, 26, 23, 2, 32, tzinfo=timezone.utc).timestamp())
        self.powershell(epoch=epoch)
        self.assertEqual(self.sent(), "2026-11-27 00:02:32 Europe/Madrid (23:02:32 UTC)")
        self.assertEqual(self.ps_log.read_text().splitlines(), ["call", "call"])

    def test_all_clock_sources_absent_are_explicit(self):
        self.assertEqual(self.sent(), "unverified client time (clock unavailable; requested zone Europe/Madrid)")

    def test_unknown_zone_never_gets_an_invented_offset(self):
        self.clock("2026-11-26T23:02:32")
        self.python()
        self.zone("Example/Unknown")
        self.assertTrue(self.sent().startswith("unverified client time"))

    def test_text_json_html_share_one_snapshot_and_one_clock_read(self):
        self.clock("2026-11-26T23:02:32", ignore_tz=True)
        self.python()
        text = self.run_trace()
        snapshot = json.loads(self.run_trace("json"))["fields"]
        self.env["ORCA_CHAT_SCRATCH_DIR"] = str(self.project)
        directive = self.run_trace("html")
        artifact = re.search(r'file="([^"]+)"', directive).group(1)
        document = Document((self.project / artifact).read_text())
        sent = "2026-11-27 00:02:32 Europe/Madrid (23:02:32 UTC)"
        self.assertIn("Sent: " + sent + "\n", text)
        self.assertEqual(snapshot["sent"], sent)
        self.assertIn(sent, document.values)
        self.assertEqual(self.clock_log.read_text().splitlines(), ["clock"] * 3)


if __name__ == "__main__":
    unittest.main()
