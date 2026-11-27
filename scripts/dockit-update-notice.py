#!/usr/bin/env python3
"""dockit-update-notice.py -- Tell running agent sessions that LLM-DocKit changed.

Central-only operator tool (like dockit-sync-check.sh): it runs from the
canonical LLM-DocKit checkout and is NOT copied to downstream projects.

Hook mode (called by Claude Code / Codex CLI hooks; JSON event on stdin):

  dockit-update-notice.py hook --event start    record a baseline for an unseen session
  dockit-update-notice.py hook --event prompt   compare and notify once per change

On every prompt the hook compares this checkout's VERSION with the version
recorded for the session. Unchanged: no output and no write (beyond a refresh
of the session's timestamp at most once a day). Changed: one short notice tells
the agent to reload the central onboarding, and the baseline advances only when
that notice is delivered inside a DocKit project. Recurring SessionStart events
(resume, compaction) never move an existing baseline.

Sessions that began before notices were installed have no baseline. Within the
first INSTALL_GRACE_DAYS after `install`, their first prompt gets one notice
worded as "may be newer" (the session's loaded version is unknown); afterwards
a missing baseline is recorded silently.

It never contacts the network, never edits a project, and never runs dockit-sync:
project template files stay operator-gated.

State: one bounded JSON file plus one persistent lock under
$XDG_STATE_HOME/LLM-DocKit/ (absolute XDG value only; default ~/.local/state).
Entries unused for 30 days are pruned. No per-request files are created.

Install mode (idempotent; unique backups; atomic replace; aborts on a
concurrent change):

  dockit-update-notice.py install   [--claude-settings PATH]... [--codex-config PATH]...
  dockit-update-notice.py uninstall [--claude-settings PATH]... [--codex-config PATH]...

Codex skips new or changed hooks until they are trusted in /hooks; installation
cannot and does not bypass that review.
"""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import shlex
import subprocess
import sys
import time
import tomllib
from pathlib import Path

SCRIPT = Path(__file__).resolve()
DOCKIT_ROOT = SCRIPT.parent.parent
DAY = 24 * 3600
MAX_AGE_SECONDS = 30 * DAY
INSTALL_GRACE_DAYS = 7
BEGIN = "# --- LLM-DocKit Codex update-notice hooks: BEGIN ---"
END = "# --- LLM-DocKit Codex update-notice hooks: END ---"
EVENTS = (("start", "SessionStart"), ("prompt", "UserPromptSubmit"))
META = "__meta__"


def hook_command(event: str) -> str:
    return f"python3 -I {shlex.quote(str(SCRIPT))} hook --event {event}"


OWNED = {hook_command(e) for e, _ in EVENTS}


# -- hook ---------------------------------------------------------------------

def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME", "")
    root = Path(base) if base and os.path.isabs(base) else Path.home() / ".local" / "state"
    return root / "LLM-DocKit"


class State:
    """Exclusive lock around the session-baseline file."""

    def __init__(self) -> None:
        self.dir = state_dir()
        self.path = self.dir / "update-notice.json"

    def __enter__(self) -> "State":
        self.dir.mkdir(parents=True, exist_ok=True)
        self.lock = open(self.dir / "update-notice.lock", "a+", encoding="utf-8")
        fcntl.flock(self.lock, fcntl.LOCK_EX)
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
            self.data = data if isinstance(data, dict) else {}
        except (OSError, ValueError):
            self.data = {}
        return self

    def save(self) -> None:
        now = int(time.time())
        self.data = {
            k: v for k, v in self.data.items()
            if k == META or (isinstance(v, dict) and now - int(v.get("t", 0)) < MAX_AGE_SECONDS)
        }
        tmp = self.path.with_name(self.path.name + ".tmp")
        tmp.write_text(json.dumps(self.data, sort_keys=True), encoding="utf-8")
        os.replace(tmp, self.path)

    def __exit__(self, *exc: object) -> None:
        self.lock.close()


def central_version() -> str:
    try:
        return (DOCKIT_ROOT / "VERSION").read_text(encoding="utf-8").splitlines()[0].strip()
    except (OSError, IndexError):
        return ""


def dockit_project(cwd: str) -> Path | None:
    root: Path | None = None
    try:
        out = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=3, check=False)
        if out.returncode == 0 and out.stdout.strip():
            root = Path(out.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        pass
    root = root or (Path(cwd) if cwd else None)
    return root if root is not None and (root / "LLM_START_HERE.md").is_file() else None


def template_version(root: Path) -> str:
    try:
        for line in (root / ".git" / ".dockit" / "state.yml").read_text(encoding="utf-8").splitlines():
            if line.startswith("template_version:"):
                return line.split(":", 1)[1].strip().strip("\"'")
    except (OSError, ValueError):  # unreadable or non-UTF-8 optional metadata
        pass
    return ""


def notice(root: Path, old: str | None, new: str) -> str:
    bootstrap = shlex.quote(str(DOCKIT_ROOT / "scripts" / "dockit-bootstrap-context.sh"))
    if old:
        head = f"LLM-DocKit update notice: the central DocKit instructions changed from {old} to {new} during this session."
    else:
        head = (f"LLM-DocKit update notice: central DocKit is now {new}; this session began before update "
                "notices were installed, so its loaded instructions may be older.")
    lines = [
        head,
        f"Reload them once now: {bootstrap} --human --project {shlex.quote(str(root))}",
        "Follow the reloaded rules from this turn on (for example, generate Trace with the collector it names).",
    ]
    tv = template_version(root)
    if (root / ".dockit-enabled").exists() and tv and tv != new:
        sync = shlex.quote(str(DOCKIT_ROOT / "scripts" / "dockit-sync.sh"))
        lines.append(
            f"This project's synced template files are at {tv}, not {new}. Do not sync them on your own: "
            f"template sync is operator-gated (dry run: {sync} --dry-run --project {shlex.quote(str(root))})."
        )
    return "\n".join(lines)


def run_hook(event: str) -> int:
    try:
        payload = json.load(sys.stdin)
    except (OSError, ValueError):
        return 0
    if not isinstance(payload, dict) or not payload.get("session_id"):
        return 0
    session = str(payload["session_id"])
    cwd = str(payload.get("cwd") or os.getcwd())
    # SessionStart source: startup/clear begin with current instructions;
    # resume/compact continue an older session. Missing means startup.
    fresh_start = str(payload.get("source") or "startup") in ("startup", "clear")
    now = int(time.time())

    # Phase 1 (locked, cheap): is anything due?
    with State() as st:
        version = central_version()
        if not version:
            return 0
        entry = st.data.get(session)
        if isinstance(entry, dict):
            seen = entry.get("v")
            if seen == version or event == "start":
                if now - int(entry.get("t", 0)) > DAY:
                    entry["t"] = now
                    st.save()
                return 0  # unchanged, or a recurring SessionStart: never move the baseline
        else:
            seen = None
            meta = st.data.get(META) if isinstance(st.data.get(META), dict) else {}
            in_grace = now - int(meta.get("installed_at", 0)) < INSTALL_GRACE_DAYS * DAY
            if (event == "start" and fresh_start) or not in_grace:
                st.data[session] = {"v": version, "t": now}
                st.save()
                return 0
            if event == "start":
                return 0  # pre-install session resumed/compacted: stay eligible for one notice

    # Phase 2 (unlocked, may be slow): is this a DocKit project?
    root = dockit_project(cwd)
    if root is None:
        return 0  # nothing recorded: the notice arrives once back in a DocKit project

    # Phase 3 (locked): build first, then commit delivery once.
    with State() as st:
        version = central_version()
        current = st.data.get(session)
        current_seen = current.get("v") if isinstance(current, dict) else None
        if not version or current_seen == version or current_seen != seen:
            return 0
        message = notice(root, seen, version)
        sys.stdout.write(message + "\n")
        sys.stdout.flush()  # raises if the client did not accept it: baseline stays, retry later
        st.data[session] = {"v": version, "t": now}
        st.save()
    return 0


# -- install / uninstall ------------------------------------------------------
#
# Cooperating installers from this checkout serialize on one lock. An external editor that does
# not take it can still race in the short window between the final comparison
# and the atomic rename; every write keeps a unique backup for that case.

class ConfigChanged(RuntimeError):
    pass


def install_lock():
    # Lock this script file itself: shared by every installer run from this
    # checkout regardless of XDG_STATE_HOME, and creates no extra file.
    fh = open(SCRIPT, "rb")
    fcntl.flock(fh, fcntl.LOCK_EX)
    return fh


def target_of(path: Path) -> Path:
    return path.resolve() if path.is_symlink() else path  # edit the backing file, keep the link


def write_atomic(path: Path, original: bytes | None, text: str) -> str:
    """Back up and atomically replace; abort if the file changed under us."""
    if (path.read_bytes() if path.exists() else None) != original:
        raise ConfigChanged("changed while editing; nothing written")
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    note = ""
    if original is not None:
        stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
        n = 0
        while True:
            dest = path.with_name(f"{path.name}.bak.{stamp}" + (f".{n}" if n else ""))
            try:
                fd = os.open(dest, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                break
            except FileExistsError:
                n += 1
        with os.fdopen(fd, "wb") as fh:
            os.fchmod(fh.fileno(), mode)  # created 0600, then exactly the original mode
            fh.write(original)
        note = f" (backup {dest})"
    tmp = path.with_name(f".{path.name}.dockit-tmp.{os.getpid()}")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        os.fchmod(fh.fileno(), mode)
        fh.write(text)
    if (path.read_bytes() if path.exists() else None) != original:
        tmp.unlink()
        raise ConfigChanged("changed while editing; nothing written")
    os.replace(tmp, path)
    return note


def tagged(value: object) -> object:
    """Type-sensitive, JSON-free comparable form (bool vs int, TOML datetimes)."""
    if isinstance(value, dict):
        return ("dict", tuple(sorted((k, tagged(v)) for k, v in value.items())))
    if isinstance(value, list):
        return ("list", tuple(tagged(v) for v in value))
    return (type(value).__name__, repr(value))


def owned_view(data: object) -> object:
    """Config with owned handlers removed, compared type-sensitively.

    Empty hook containers are equivalent to absent ones, so installing into a
    pre-existing empty `hooks`/event container verifies, and uninstall may drop
    a container its own removal emptied without counting as a foreign change.
    """
    if not isinstance(data, dict):
        return tagged(data)
    data = dict(data)
    hooks = data.get("hooks")
    if isinstance(hooks, dict):
        hooks = dict(hooks)
        for _, key in EVENTS:
            groups = hooks.get(key)
            if not isinstance(groups, list):
                continue
            kept_groups = []
            for g in groups:
                if isinstance(g, dict) and isinstance(g.get("hooks"), list):
                    kept = [h for h in g["hooks"] if not (isinstance(h, dict) and h.get("command") in OWNED)]
                    if len(kept) != len(g["hooks"]):
                        if not kept:
                            continue
                        g = {**g, "hooks": kept}
                kept_groups.append(g)
            if kept_groups:
                hooks[key] = kept_groups
            else:
                del hooks[key]
        if hooks:
            data["hooks"] = hooks
        else:
            del data["hooks"]
    return tagged(data)


def owned_count(data: object) -> dict[str, int]:
    hooks = data.get("hooks", {}) if isinstance(data, dict) else {}
    out = {}
    for _, key in EVENTS:
        groups = hooks.get(key, []) if isinstance(hooks, dict) else []
        out[key] = sum(1 for g in groups if isinstance(g, dict) and isinstance(g.get("hooks"), list)
                       for h in g["hooks"] if isinstance(h, dict) and h.get("command") in OWNED)
    return out


def verify(before: object, after: object, install: bool) -> None:
    """Refuse any edit that changes something other than the owned handlers."""
    if owned_view(before) != owned_view(after):
        raise ValueError("edit would change hooks or settings this tool does not own; nothing written")
    want = 1 if install else 0
    if any(n != want for n in owned_count(after).values()):
        raise ValueError(f"expected {want} owned handler per event after edit; nothing written")


def edit_claude(path: Path, install: bool) -> str:
    target = target_of(path)
    if not target.exists() and not install:
        return f"absent, skipped: {path}"
    original = target.read_bytes() if target.exists() else None
    data = json.loads(original) if original else {}
    if not install and not any(owned_count(data).values()):
        return f"unchanged: {path}"
    had_hooks = isinstance(data.get("hooks"), dict)
    hooks = data.get("hooks", {}) if had_hooks else {}
    removed_any = False
    for event, key in EVENTS:
        groups, removed = [], False
        for group in hooks.get(key, []):
            if isinstance(group, dict) and isinstance(group.get("hooks"), list):
                kept = [h for h in group["hooks"] if not (isinstance(h, dict) and h.get("command") in OWNED)]
                if len(kept) != len(group["hooks"]):
                    removed = True
                    if not kept:
                        continue
                    group = {**group, "hooks": kept}
            groups.append(group)
        if install:
            groups.append({"hooks": [{"type": "command", "command": hook_command(event), "timeout": 5}]})
        if groups or (key in hooks and not removed):
            hooks[key] = groups
        elif key in hooks:
            del hooks[key]
        removed_any = removed_any or removed
    if hooks or (had_hooks and not removed_any):
        data["hooks"] = hooks
    else:
        data.pop("hooks", None)
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    if original is not None and original.decode("utf-8") == text:
        return f"unchanged: {path}"
    verify(json.loads(original) if original else {}, json.loads(text), install)
    note = write_atomic(target, original, text)
    return f"{'installed' if install else 'removed'}: {path}{note}"


HEADER_RE = re.compile(r"^\s*(\[\[?)\s*([^\]#]+?)\s*(\]\]?)\s*(?:#.*)?$")


def header_of(line: str) -> str:
    m = HEADER_RE.match(line)
    if not m:
        return ""
    key = ".".join(part.strip().strip('"').strip("'") for part in m.group(2).split("."))
    return f"{m.group(1)}{key}{m.group(3)}"


def toml_chunks(lines: list[str]) -> list[list[str]]:
    """Split into [preamble, table1, ...]; each chunk starts at its header line."""
    chunks: list[list[str]] = [[]]
    for line in lines:
        if header_of(line):
            chunks.append([line])
        else:
            chunks[-1].append(line)
    return chunks


def is_owned_handler(chunk: list[str]) -> bool:
    if not chunk or header_of(chunk[0]) not in {f"[[hooks.{k}.hooks]]" for _, k in EVENTS}:
        return False
    try:
        body = tomllib.loads("\n".join(["[[h]]", *chunk[1:]]))
        return body["h"][0].get("command") in OWNED
    except (tomllib.TOMLDecodeError, KeyError, IndexError):
        return False


def blank(lines: list[str]) -> bool:
    return all(not l.strip() or l.strip().startswith("#") for l in lines)


def strip_codex(text: str) -> str:
    lines = [l for l in text.splitlines()
             if l.strip() not in (BEGIN, END, "# Managed by LLM-DocKit scripts/dockit-update-notice.py (central-only).")]
    chunks = toml_chunks(lines)
    out = [chunks[0]]
    i = 1
    while i < len(chunks):
        ch = chunks[i]
        if is_owned_handler(ch):
            i += 1
            continue
        header = header_of(ch[0])
        parent = next((k for _, k in EVENTS if header == f"[[hooks.{k}]]"), None)
        if parent and blank(ch[1:]) and i + 1 < len(chunks) and is_owned_handler(chunks[i + 1]):
            nxt = header_of(chunks[i + 2][0]) if i + 2 < len(chunks) else ""
            if nxt != f"[[hooks.{parent}.hooks]]":  # no foreign sibling handler under this parent
                i += 2
                continue
        out.append(ch)
        i += 1
    flat = [l for ch in out for l in ch]
    while flat and not flat[-1].strip():
        flat.pop()
    return "\n".join(flat) + ("\n" if flat else "")


INLINE_EMPTY_RE = re.compile(r"^\s*[\"']?(SessionStart|UserPromptSubmit)[\"']?\s*=\s*\[\s*\]\s*(?:#.*)?$")


def drop_inline_empty_events(text: str) -> str:
    """Remove `Event = []` under [hooks] so [[hooks.Event]] can be appended (empty == absent)."""
    chunks = toml_chunks(text.splitlines())
    for ch in chunks[1:]:
        if header_of(ch[0]) == "[hooks]":
            ch[1:] = [l for l in ch[1:] if not INLINE_EMPTY_RE.match(l)]
    flat = [l for ch in chunks for l in ch]
    return "\n".join(flat) + ("\n" if flat else "")


def edit_codex(path: Path, install: bool) -> str:
    target = target_of(path)
    if not target.exists() and not install:
        return f"absent, skipped: {path}"
    original = target.read_bytes() if target.exists() else None
    text = original.decode("utf-8") if original else ""
    before = tomllib.loads(text)
    if not install and BEGIN not in text and not any(owned_count(before).values()):
        return f"unchanged: {path}"
    new = strip_codex(text)
    if install:
        new = drop_inline_empty_events(new)
        block = ["", BEGIN, "# Managed by LLM-DocKit scripts/dockit-update-notice.py (central-only)."]
        for event, key in EVENTS:
            block += [f"[[hooks.{key}]]", "", f"[[hooks.{key}.hooks]]", 'type = "command"',
                      f"command = {json.dumps(hook_command(event))}", "timeout = 5", ""]
        block[-1] = END
        new = new.rstrip("\n") + "\n" + "\n".join(block) + "\n"
    if new == text:
        if not install and any(owned_count(before).values()):
            raise ValueError("owned hook is in a TOML form this tool did not write; remove it by hand")
        if install:
            verify(before, before, True)
        return f"unchanged: {path}"
    verify(before, tomllib.loads(new), install)  # parses, and only owned handlers differ
    note = write_atomic(target, original, new)
    suffix = "; trust both hooks in Codex /hooks before they run" if install else ""
    return f"{'installed' if install else 'removed'}: {path}{note}{suffix}"


def record_install() -> None:
    with State() as st:
        meta = st.data.get(META) if isinstance(st.data.get(META), dict) else {}
        if "installed_at" not in meta:  # a repeated install never restarts the grace window
            st.data[META] = {"installed_at": int(time.time())}
            st.save()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    hook = sub.add_parser("hook")
    hook.add_argument("--event", choices=[e for e, _ in EVENTS], required=True)
    for name in ("install", "uninstall"):
        p = sub.add_parser(name)
        p.add_argument("--claude-settings", action="append", default=[], type=Path)
        p.add_argument("--codex-config", action="append", default=[], type=Path)
    args = parser.parse_args(argv)
    if args.cmd == "hook":
        try:
            return run_hook(args.event)
        except Exception:  # a notice must never break the user's prompt
            return 0
    install = args.cmd == "install"
    if not args.claude_settings and not args.codex_config:
        parser.error("give at least one --claude-settings or --codex-config")
    status = 0
    if install:
        record_install()  # before any hook can activate, so a partial failure keeps the grace window
    with install_lock():
        for fn, paths in ((edit_claude, args.claude_settings), (edit_codex, args.codex_config)):
            for path in paths:
                try:
                    print(fn(path, install))
                except (ConfigChanged, ValueError, UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
                    print(f"ERROR: {path}: {exc}", file=sys.stderr)
                    status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
