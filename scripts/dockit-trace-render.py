#!/usr/bin/env python3
"""Render one supplied Trace snapshot; no Git, clock, network or subprocess work.

The shell collector owns observation. Caller-supplied provenance is not verified
here. Chat-owned HTML outputs are immutable deliverables, never rotated or pruned.
"""
import argparse
import hashlib
import html
import json
import os
import re
from pathlib import Path
import sys
import uuid

sys.dont_write_bytecode = True
MAX_HTML_BYTES = 512 * 1024
FIELDS = (
    ("role", "Role"), ("sent", "Sent"), ("subject", "Subject"),
    ("resulting_state", "Resulting state"), ("repo_state", "Repo state"),
    ("validation", "Validation"), ("next", "Next gate"),
)
OPTIONAL_FIELDS = (
    ("client", "Client"), ("model", "Model"), ("model_family", "Model family"),
    ("account", "Account"), ("session", "Session"), ("task", "Task"),
    ("dossier", "Dossier"),
)
SPANISH_LABELS = {
    "Role": "Rol", "Sent": "Fecha", "Subject": "Asunto",
    "Resulting state": "Estado resultante", "Repo state": "Repositorio",
    "Validation": "Validación", "Next gate": "Siguiente paso",
    "Client": "Cliente", "Model": "Modelo", "Model family": "Familia",
    "Account": "Alias de cuenta", "Session": "Sesión", "Task": "Tarea",
    "Dossier": "Dossier",
}


def field_values(snapshot):
    return [(label, snapshot[key]) for key, label in FIELDS + OPTIONAL_FIELDS
            if key in snapshot]


def text_snapshot(snapshot):
    return "Trace\n" + "".join(f"{label}: {value}\n" for label, value in field_values(snapshot))


TEMPLATE_PATH = Path(__file__).with_name("dockit-trace-cobalt.html")
SLOT = re.compile(r"@@DOCKIT_([A-Z_]+)@@")
# The renderer and its reviewed template ship as one managed pair.
# Pin LF-normalized bytes so a partial sync or corrupt asset takes the text path.
TEMPLATE_SHA256 = "ec7918b6dc53edeeac26f87d09eddd77a2f5dc09c0aab18189369c7b8a2fcff1"


def read_template():
    with TEMPLATE_PATH.open("rb") as source:
        raw = source.read(MAX_HTML_BYTES)
    if len(raw) >= MAX_HTML_BYTES:
        raise ValueError("Template exceeds size limit")
    raw = raw.replace(b"\r\n", b"\n")
    if hashlib.sha256(raw).hexdigest() != TEMPLATE_SHA256:
        raise ValueError("Unexpected Cobalto template")
    return raw.decode("utf-8")


def html_snapshot(snapshot, language="en"):
    if language not in ("en", "es"):
        raise ValueError("Unsupported Trace language")
    # The packaged asset is loaded only for HTML. Values are escaped text;
    # ROWS is generated markup with fixed tags/labels and individually escaped
    # values. No caller data can become attributes, CSS, links or raw HTML.
    template = read_template()
    rows = []
    for label, value in field_values(snapshot):
        title = SPANISH_LABELS[label] if language == "es" else label
        rows.append(
            f'<div class="kv"><dt class="k">{title}</dt>'
            f'<dd class="v">{html.escape(value)}</dd></div>'
        )
    values = {
        "LANG": language, "ROWS": "\n".join(rows),
        "NEXT_LABEL": "Siguiente paso" if language == "es" else "Next gate",
        "DISCLOSURE_LABEL": "Evidencia y Trace" if language == "es" else "Evidence and Trace",
        "TEXT_LABEL": "Trace completo" if language == "es" else "Full Trace",
        "FULL_TEXT": html.escape(text_snapshot(snapshot)),
    }
    values.update({key: html.escape(snapshot[key.lower()]) for key in ("SUBJECT", "ROLE", "SENT", "NEXT")})
    # One substitution pass only: template-looking caller text is never parsed
    # again, including strings inserted into ROWS or the canonical text block.
    return SLOT.sub(lambda match: values[match.group(1)], template).encode("utf-8")


def write_visual(snapshot, directory, language="en"):
    """Write one fresh file, or fail without deleting/replacing existing files."""
    if not directory:
        raise ValueError("Orca capability is not declared")
    root = Path(directory)
    if not root.is_absolute() or root.is_symlink() or not root.is_dir():
        raise ValueError("Orca directory must be an existing absolute non-symlink directory")
    document = html_snapshot(snapshot, language)
    if len(document) >= MAX_HTML_BYTES:
        raise ValueError("HTML exceeds the Orca size limit")
    name = f"trace-{uuid.uuid4().hex}.html"
    target = root / name
    created = False
    fd = None
    try:
        # Exclusive creation protects historical output even in the unlikely
        # event of an identifier collision. No directories are created.
        fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        created = True
        with os.fdopen(fd, "wb") as stream:
            stream.write(document)
    except OSError:
        if fd is not None:
            try:
                os.close(fd)
            except OSError:
                pass  # fdopen may already have closed the owned descriptor.
        if created:
            target.unlink(missing_ok=True)
        raise
    return name


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("auto", "text", "html", "json"), default="auto")
    parser.add_argument("--language", choices=("en", "es"), default="en")
    for key, _ in FIELDS:
        parser.add_argument("--" + key.replace("_", "-"), required=True)
    for key, _ in OPTIONAL_FIELDS:
        parser.add_argument("--" + key.replace("_", "-"), default="")
    args = parser.parse_args()
    snapshot = {key: getattr(args, key) for key, _ in FIELDS}
    snapshot.update({key: getattr(args, key) for key, _ in OPTIONAL_FIELDS if getattr(args, key)})
    if args.format == "json":
        print(json.dumps({"schema_version": 1, "fields": snapshot}, ensure_ascii=False))
        return 0
    directory = os.environ.get("ORCA_CHAT_SCRATCH_DIR", "")
    if args.format == "text" or (args.format == "auto" and not directory):
        print(text_snapshot(snapshot), end="")
        return 0
    try:
        name = write_visual(snapshot, directory, args.language)
    except (OSError, ValueError) as error:
        # Error details may contain private paths. Emit only the category.
        print(f"Trace HTML unavailable ({type(error).__name__}); using text.", file=sys.stderr)
        print(text_snapshot(snapshot), end="")
        return 0
    print(f'::orca-visual{{file="{name}" title="Trace"}}')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
