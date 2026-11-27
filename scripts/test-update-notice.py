#!/usr/bin/env python3
"""Tests for dockit-update-notice.py. Fixtures live in one self-removing temp dir."""

from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / "dockit-update-notice.py"
FAILS = 0


def check(name: str, cond: bool, detail: str = "") -> None:
    global FAILS
    print(f"{'PASS' if cond else 'FAIL'}: {name}{'' if cond else ' -- ' + detail[:400]}")
    FAILS += 0 if cond else 1


def main() -> int:
    tmp = Path(tempfile.mkdtemp(prefix="dockit-notice-test-"))
    try:
        root = tmp / "dock it"  # space: commands must be quoted
        (root / "scripts").mkdir(parents=True)
        script = root / "scripts" / "dockit-update-notice.py"
        shutil.copy2(SOURCE, script)
        version = root / "VERSION"
        version.write_text("1.0.0\n")
        proj = tmp / "proj"
        (proj / ".git" / ".dockit").mkdir(parents=True)
        (proj / "LLM_START_HERE.md").write_text("x\n")
        (proj / ".dockit-enabled").write_text("")
        (proj / ".git" / ".dockit" / "state.yml").write_text("template_version: 0.9.0\n")
        plain = tmp / "plain"
        plain.mkdir()
        env = dict(os.environ, XDG_STATE_HOME=str(tmp / "state"), GIT_CEILING_DIRECTORIES=str(tmp))
        state = tmp / "state" / "LLM-DocKit" / "update-notice.json"

        def run(*args: str, data: str = "", extra: dict | None = None, cwd: Path = tmp) -> subprocess.CompletedProcess:
            return subprocess.run([sys.executable, "-I", str(script), *args], input=data,
                                  capture_output=True, text=True, env={**env, **(extra or {})}, cwd=cwd)

        def hook(event: str, session: str, cwd: Path, raw: str | None = None, run_cwd: Path = tmp, **kw) -> str:
            data = raw if raw is not None else json.dumps({"session_id": session, "cwd": str(cwd)})
            r = run("hook", "--event", event, data=data, cwd=run_cwd, **kw)
            check(f"hook {event} exits 0", r.returncode == 0, r.stderr)
            return r.stdout

        # Baseline and silence.
        check("start is silent", hook("start", "s1", proj) == "")
        check("same version prompt silent", hook("prompt", "s1", proj) == "")
        mtime = state.stat().st_mtime_ns
        hook("prompt", "s1", proj)
        check("unchanged prompt does not rewrite state", state.stat().st_mtime_ns == mtime)

        # Missing baseline without an install record: silent (no false notice).
        check("unseen session outside grace silent", hook("prompt", "nobase", proj) == "")

        # Change, then recurring SessionStart (resume/compact) must not consume it.
        version.write_text("1.1.0\n")
        check("resume start silent", hook("start", "s1", proj) == "")
        out = hook("prompt", "s1", proj)
        check("notice survives recurring SessionStart", "from 1.0.0 to 1.1.0" in out, out)
        check("reload command quoted", "'" in out and "dockit-bootstrap-context.sh' --human --project" in out, out)
        check("template lag reported without syncing", "at 0.9.0" in out and "operator-gated" in out, out)
        check("notice fires once", hook("prompt", "s1", proj) == "")

        # Non-DocKit prompt must not consume the change.
        hook("start", "s2", proj)
        version.write_text("1.2.0\n")
        check("non-DocKit prompt silent", hook("prompt", "s2", plain) == "")
        out = hook("prompt", "s2", proj)
        check("notice delivered back in DocKit project", "from 1.1.0 to 1.2.0" in out, out)

        # Install grace: pre-install sessions get one honestly worded notice.
        claude = tmp / "settings.json"
        claude.write_text(json.dumps({"model": "x", "hooks": {
            "SessionStart": [{"hooks": [{"type": "command", "command": "other"}]}]}}, indent=2) + "\n")
        os.chmod(claude, 0o640)
        r = run("install", "--claude-settings", str(claude))
        check("install exits 0", r.returncode == 0, r.stderr)
        out = hook("prompt", "pre-install", proj)
        check("pre-install session notified as may-be-older", "may be older" in out and "changed from" not in out, out)
        check("pre-install session then silent", hook("prompt", "pre-install", proj) == "")
        check("malformed input silent", hook("prompt", "", proj, raw="not json") == "")

        # Relative XDG_STATE_HOME is ignored (no state inside the project).
        fake_home = tmp / "home"
        fake_home.mkdir()
        hook("start", "rel", proj, extra={"XDG_STATE_HOME": "relative-state", "HOME": str(fake_home)}, run_cwd=proj)
        check("relative XDG ignored", not (proj / "relative-state").exists()
              and (fake_home / ".local" / "state" / "LLM-DocKit" / "update-notice.json").exists())

        # Claude: keep foreign siblings, mode, idempotency, exact removal.
        cdata = json.loads(claude.read_text())
        check("claude keeps foreign hook", cdata["hooks"]["SessionStart"][0]["hooks"][0]["command"] == "other")
        check("claude mode preserved", (claude.stat().st_mode & 0o777) == 0o640)
        before = claude.read_text()
        r = run("install", "--claude-settings", str(claude))
        check("claude install idempotent", claude.read_text() == before and "unchanged" in r.stdout, r.stdout)
        cdata = json.loads(claude.read_text())
        cdata["hooks"]["UserPromptSubmit"][0]["hooks"].append({"type": "command", "command": "sibling"})
        claude.write_text(json.dumps(cdata, indent=2) + "\n")
        run("uninstall", "--claude-settings", str(claude))
        cdata = json.loads(claude.read_text())
        check("claude uninstall keeps sibling handler",
              cdata["hooks"]["UserPromptSubmit"] == [{"hooks": [{"type": "command", "command": "sibling"}]}], json.dumps(cdata))
        check("claude uninstall removes owned", "dockit-update-notice" not in claude.read_text())
        backups = list(tmp.glob("settings.json.bak.*"))
        check("unique backups per write", len(backups) == 2 and len({b.name for b in backups}) == 2, str(backups))

        # Codex: round trip, foreign tables inside the block, trust table between events.
        codex = tmp / "config.toml"
        original = '[features]\nhooks = true\n\n[hooks.state]\n\n[hooks.state."a:session_start:0:0"]\nenabled = true\n'
        codex.write_text(original)
        run("install", "--codex-config", str(codex))
        tomllib.loads(codex.read_text())
        check("codex block appended", "UserPromptSubmit.hooks" in codex.read_text())
        before = codex.read_text()
        r = run("install", "--codex-config", str(codex))
        check("codex install idempotent", codex.read_text() == before and "unchanged" in r.stdout, r.stdout)
        run("uninstall", "--codex-config", str(codex))
        check("codex round trip byte-identical", codex.read_text() == original, codex.read_text())

        run("install", "--codex-config", str(codex))
        text = codex.read_text()
        text = text.replace("[[hooks.UserPromptSubmit]]",
                            '[hooks.state."b:user_prompt_submit:0:0"]\nenabled = true\n\n[[hooks.UserPromptSubmit]]', 1)
        text = text.replace("# --- LLM-DocKit Codex update-notice hooks: END ---",
                            '[[hooks.UserPromptSubmit]]\n\n[[hooks.UserPromptSubmit.hooks]]\ntype = "command"\ncommand = "foreign"\n'
                            "# --- LLM-DocKit Codex update-notice hooks: END ---")
        codex.write_text(text)
        run("install", "--codex-config", str(codex))
        parsed = tomllib.loads(codex.read_text())
        cmds = [h["command"] for g in parsed["hooks"]["UserPromptSubmit"] for h in g["hooks"]]
        check("codex reinstall does not duplicate", sum("dockit-update-notice" in c for c in cmds) == 1, str(cmds))
        run("uninstall", "--codex-config", str(codex))
        parsed = tomllib.loads(codex.read_text())
        cmds = [h["command"] for g in parsed.get("hooks", {}).get("UserPromptSubmit", []) for h in g["hooks"]]
        check("codex uninstall keeps foreign handler", cmds == ["foreign"], str(cmds))
        check("codex uninstall keeps trust table between events",
              "b:user_prompt_submit:0:0" in parsed["hooks"]["state"], codex.read_text())
        check("codex uninstall leaves no markers", "update-notice hooks" not in codex.read_text())
        check("no temp files left", not list(tmp.glob(".*dockit-tmp*")))

        # Uninstall never creates absent targets.
        r = run("uninstall", "--claude-settings", str(tmp / "absent.json"), "--codex-config", str(tmp / "absent.toml"))
        check("uninstall skips absent targets", not (tmp / "absent.json").exists() and not (tmp / "absent.toml").exists(), r.stdout)


        # Round-2 cases. Grace: a no-op reinstall keeps installed_at; resume/outside stay eligible.
        meta_before = json.loads(state.read_text())["__meta__"]
        run("install", "--claude-settings", str(claude))
        check("reinstall keeps install time", json.loads(state.read_text())["__meta__"] == meta_before)
        data = json.dumps({"session_id": "pre-resume", "cwd": str(proj), "source": "resume"})
        check("pre-install resume silent", hook("start", "pre-resume", proj, raw=data) == "")
        check("pre-install outside DocKit silent", hook("prompt", "pre-resume", plain) == "")
        out = hook("prompt", "pre-resume", proj)
        check("pre-install resume still notified later", "may be older" in out, out)
        data = json.dumps({"session_id": "fresh", "cwd": str(proj), "source": "startup"})
        hook("start", "fresh", proj, raw=data)
        check("fresh session after install silent", hook("prompt", "fresh", proj) == "")

        # A notice that fails to build stays eligible: unreadable optional metadata must not block it.
        hook("start", "utf", proj)
        (proj / ".git" / ".dockit" / "state.yml").write_bytes(b"template_version: \xff\xfe\n")
        version.write_text("1.3.0\n")
        out = hook("prompt", "utf", proj)
        check("notice delivered despite bad template metadata", "to 1.3.0" in out, out)
        (proj / ".git" / ".dockit" / "state.yml").write_text("template_version: 0.9.0\n")

        # Codex formatting variants: inline comments, compact '=', commented headers.
        codex2 = tmp / "fmt.toml"
        codex2.write_text("[features]\nhooks = true\n")
        run("install", "--codex-config", str(codex2))
        t = codex2.read_text().replace("command = ", "command=").replace("timeout = 5", "timeout = 5 # mine")
        t = t.replace("[[hooks.UserPromptSubmit.hooks]]", "[[hooks.UserPromptSubmit.hooks]] # handler")
        t += '\n[[hooks.UserPromptSubmit]] # foreign parent\n\n[[ hooks.UserPromptSubmit.hooks ]] # foreign\ntype = "command"\ncommand = "foreign2"\n'
        codex2.write_text(t)
        r = run("install", "--codex-config", str(codex2))
        parsed = tomllib.loads(codex2.read_text())
        cmds = [h["command"] for g in parsed["hooks"]["UserPromptSubmit"] for h in g["hooks"]]
        check("reformatted owned handler not duplicated", sum("dockit-update-notice" in c for c in cmds) == 1, r.stderr + str(cmds))
        run("uninstall", "--codex-config", str(codex2))
        parsed = tomllib.loads(codex2.read_text())
        ups = parsed["hooks"]["UserPromptSubmit"]
        check("foreign handler keeps array structure", isinstance(ups, list) and [h["command"] for g in ups for h in g["hooks"]] == ["foreign2"], str(ups))
        check("no owned handler left", "dockit-update-notice" not in codex2.read_text())

        # Permissions under restrictive and permissive umasks, and symlinked settings.
        for umask, mode in ((0o022, 0o600), (0o077, 0o640)):
            f = tmp / f"perm-{mode:o}.json"
            f.write_text("{}\n")
            os.chmod(f, mode)
            subprocess.run(["sh", "-c", f"umask {umask:o}; exec \"$@\"", "sh", sys.executable, "-I", str(script),
                            "install", "--claude-settings", str(f)], env=env, capture_output=True)
            bak = next(tmp.glob(f"perm-{mode:o}.json.bak.*"))
            check(f"mode {mode:o} kept under umask {umask:o}", (f.stat().st_mode & 0o777) == mode
                  and (bak.stat().st_mode & 0o777) == mode, f"{f.stat().st_mode:o} {bak.stat().st_mode:o}")
        real_target = tmp / "backing.json"
        real_target.write_text("{}\n")
        link = tmp / "link.json"
        link.symlink_to(real_target)
        run("install", "--claude-settings", str(link))
        check("symlink preserved and target edited", link.is_symlink() and "dockit-update-notice" in real_target.read_text())


        # Round-3 cases.
        q = tmp / "quoted.toml"
        q.write_text('[features]\nhooks = true\nwhen = 2026-11-27T00:00:00Z\n\n[hooks.state."t"]\nenabled = true\n')
        r1 = run("install", "--codex-config", str(q))
        t = q.read_text().replace("[[hooks.SessionStart.hooks]]", '[[hooks."SessionStart".hooks]]')
        q.write_text(t)
        r2 = run("install", "--codex-config", str(q))
        r3 = run("uninstall", "--codex-config", str(q))
        check("quoted keys and TOML datetimes handled", r1.returncode == r2.returncode == r3.returncode == 0
              and "dockit-update-notice" not in q.read_text(), r1.stderr + r2.stderr + r3.stderr)
        inline = tmp / "inline.toml"
        cmd = json.dumps(f"python3 -I {shlex.quote(str(script))} hook --event prompt")
        inline.write_text(f'[hooks]\nUserPromptSubmit = [{{hooks = [{{type = "command", command = {cmd}}}]}}]\n')
        r = run("uninstall", "--codex-config", str(inline))
        check("inline owned hook refused, not silently kept", r.returncode == 1 and "by hand" in r.stderr, r.stdout + r.stderr)
        def counts(data: dict) -> list[int]:
            hooks = data.get("hooks", {})
            return [sum("dockit-update-notice" in h.get("command", "") for g in hooks.get(k, []) for h in g["hooks"])
                    for k in ("SessionStart", "UserPromptSubmit")]

        def strip_empty(data: dict) -> dict:
            hooks = {k: v for k, v in data.get("hooks", {}).items() if v}
            return {**{k: v for k, v in data.items() if k != "hooks"}, **({"hooks": hooks} if hooks else {})}

        for i, case in enumerate(({"hooks": {}}, {"hooks": {"SessionStart": []}}, {"hooks": {"UserPromptSubmit": []}})):
            empty = tmp / f"empty{i}.json"
            empty.write_text(json.dumps(case) + "\n")
            r1 = run("install", "--claude-settings", str(empty))
            after = json.loads(empty.read_text())
            r2 = run("uninstall", "--claude-settings", str(empty))
            check(f"claude empty container case {i}", r1.returncode == 0 and counts(after) == [1, 1] and r2.returncode == 0
                  and strip_empty(json.loads(empty.read_text())) == strip_empty(case), r1.stderr + r2.stderr + empty.read_text())
        for i, body in enumerate(("[hooks]\n", "[hooks]\nSessionStart = []\n", "[hooks]\nUserPromptSubmit = [] # x\nSessionStart = []\n")):
            etoml = tmp / f"empty{i}.toml"
            etoml.write_text(body)
            r1 = run("install", "--codex-config", str(etoml))
            after = tomllib.loads(etoml.read_text())
            r2 = run("uninstall", "--codex-config", str(etoml))
            check(f"codex empty container case {i}", r1.returncode == 0 and counts(after) == [1, 1] and r2.returncode == 0
                  and "dockit-update-notice" not in etoml.read_text(), r1.stderr + r2.stderr + etoml.read_text())
        sys.path.insert(0, str(script.parent))
        import importlib.util
        spec = importlib.util.spec_from_file_location("notice_mod", script)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        try:
            mod.verify({"hooks": {"state": {"x": {"enabled": True}}}}, {"hooks": {"state": {"x": {"enabled": 1}}}}, False)
            check("verify is type-sensitive", False)
        except ValueError:
            check("verify is type-sensitive", True)

        # Partial multi-target failure keeps the grace record.
        st_home = tmp / "state2"
        good = tmp / "good.json"
        good.write_text("{}\n")
        bad = tmp / "bad.toml"
        bad.write_text("not = = toml\n")
        r = run("install", "--claude-settings", str(good), "--codex-config", str(bad), extra={"XDG_STATE_HOME": str(st_home)})
        meta = json.loads((st_home / "LLM-DocKit" / "update-notice.json").read_text()).get("__meta__", {})
        check("partial install keeps grace record", r.returncode == 1 and "installed_at" in meta, r.stderr)

        # Closed stdout must not consume the notice.
        hook("start", "pipe", proj)
        version.write_text("1.4.0\n")
        proc = subprocess.Popen([sys.executable, "-I", str(script), "hook", "--event", "prompt"], stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env=env, cwd=tmp, text=True)
        proc.stdout.close()
        proc.communicate(json.dumps({"session_id": "pipe", "cwd": str(proj)}))
        out = hook("prompt", "pipe", proj)
        check("notice retried after closed stdout", "to 1.4.0" in out, out)

        # Real configs (read-only): simulate on copies, require byte-identical round trip.
        for real in (Path.home() / ".claude" / "settings.json", Path.home() / ".codex" / "config.toml",
                     Path.home() / ".codex-lamanoriega" / "config.toml"):
            if not real.exists():
                continue
            copy = tmp / f"real-{real.parent.name}-{real.name}"
            shutil.copy2(real, copy)
            flag = "--claude-settings" if real.suffix == ".json" else "--codex-config"
            orig = copy.read_bytes()
            r1 = run("install", flag, str(copy))
            r2 = run("uninstall", flag, str(copy))
            check(f"real {real} round trip", r1.returncode == r2.returncode == 0
                  and (copy.read_bytes() == orig or json.loads(copy.read_bytes() or b"{}") == json.loads(orig or b"{}")
                       if real.suffix == ".json" else copy.read_bytes() == orig), r1.stderr + r2.stderr)
    finally:
        shutil.rmtree(tmp)
    check("fixtures removed", not tmp.exists())
    print(f"{'ALL PASS' if FAILS == 0 else f'{FAILS} FAILED'}")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
