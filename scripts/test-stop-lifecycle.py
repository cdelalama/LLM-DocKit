"""Exercise the configured Stop entrypoint with two concurrent, disposable sessions."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parent.parent
# Both workers hold a live resource. Each exits independently after 18 seconds
# even if the supervisor regresses. Ports avoid inspecting or killing by PID.
WORKER = """
import json, os, pathlib, socket, subprocess, sys, time
root = pathlib.Path(os.environ["TEST_SLOT"])
with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    listener.listen()
    if sys.argv[1] == "child":
        subprocess.Popen([sys.executable, __file__, "grandchild"])
    (root / sys.argv[1]).write_text(str(listener.getsockname()[1]))
    end = time.monotonic() + 18
    while time.monotonic() < end and not (root / "finish").exists():
        time.sleep(.03)
"""


def wait_until(predicate, seconds=4):
    deadline = time.monotonic() + seconds
    while not predicate():
        if time.monotonic() >= deadline:
            raise AssertionError("fixture did not reach the expected state")
        time.sleep(.025)


def port_released(port):
    with socket.socket() as probe:
        try:
            probe.bind(("127.0.0.1", port))
        except OSError:
            return False
        return True


class StopLifecycle(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="dockit-stop-test-")
        def retire_temp():
            # The independent fixture deadline also bounds a broken supervisor.
            deadline = time.monotonic() + 20
            while True:
                try:
                    temp.cleanup()
                    return
                except PermissionError:
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(.05)
        self.addCleanup(retire_temp)
        self.root = Path(temp.name)
        scripts = self.root / "scripts"
        scripts.mkdir()
        for name in ("dockit-stop.py", "dockit-session-gate.sh"):
            shutil.copy2(ROOT / "scripts" / name, scripts / name)
        self.validator = scripts / "dockit-validate-session.sh"
        self.validator.write_bytes(b'#!/bin/sh\nexec "$TEST_PY" "$TEST_SLOT/worker.py" child\n')
        self.validator.chmod(0o755)
        self.config = json.loads((ROOT / ".claude/settings.json").read_text())["hooks"]
        entry = self.config["Stop"][0]["hooks"][0]
        self.assertEqual(entry["shell"], "bash")
        if os.name == "nt":
            bash = Path(shutil.which("git")).parent.parent / "bin" / "bash.exe"
        else:
            bash = shutil.which("bash")
        self.command = [str(bash), "-c", entry["command"]]
        self.env = dict(os.environ, CLAUDE_PROJECT_DIR=str(self.root))

    def start(self, name, caller=False):
        slot = self.root / name
        slot.mkdir()
        (slot / "worker.py").write_text(WORKER)
        env = dict(self.env, TEST_PY=sys.executable, TEST_SLOT=str(slot))
        cmd = self.command
        if caller:
            cmd = [sys.executable, "-c", "import subprocess,sys; sys.exit(subprocess.call(sys.argv[1:]))", *cmd]
        proc = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, env=env, cwd=self.root)
        def cleanup():
            (slot / "finish").touch()
            if proc.poll() is None:
                proc.kill()
            proc.wait(timeout=3)
        self.addCleanup(cleanup)
        names = [slot / "child", slot / "grandchild"]
        wait_until(lambda: all(p.exists() and p.stat().st_size for p in names))
        return proc, [int(p.read_text()) for p in names]

    def test_cancel_preserves_other_session(self):
        first, ports = self.start("cancel")
        second, peers = self.start("peer")
        first.kill()
        first.wait(timeout=3)
        wait_until(lambda: all(map(port_released, ports)))
        self.assertTrue(all(not port_released(port) for port in peers))
        (self.root / "peer" / "finish").touch()
        self.assertEqual(second.wait(timeout=4), 0)

    def test_loss_of_client(self):
        caller, ports = self.start("client", caller=True)
        caller.kill()
        caller.wait(timeout=3)
        wait_until(lambda: all(map(port_released, ports)))

    def test_deadline(self):
        proc, ports = self.start("timeout")
        self.assertEqual(proc.wait(timeout=10), 2)
        wait_until(lambda: all(map(port_released, ports)))

    def test_block_and_no_per_edit_validation(self):
        hooks = self.config.get("PostToolUse", [])
        self.assertNotIn("dockit-validate-session", json.dumps(hooks))
        self.validator.write_bytes(b"#!/bin/sh\necho deliberate-document-error\nexit 1\n")
        result = subprocess.run(self.command, input="{}", capture_output=True, text=True, timeout=5, env=self.env, cwd=self.root)
        output = json.loads(result.stdout)
        self.assertEqual(output["decision"], "block")
        self.assertIn("deliberate-document-error", output["reason"])


if __name__ == "__main__":
    unittest.main()
