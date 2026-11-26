#!/usr/bin/env python3
"""Render one supplied Trace snapshot; no Git, clock, network or subprocess work.

The shell collector owns observation. Caller-supplied provenance is not verified
here. Chat-owned HTML outputs are immutable deliverables, never rotated or pruned.
"""
import argparse
import html
import json
import os
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


def html_snapshot(snapshot, language="en"):
    # Values appear only in HTML text nodes. Never turn them into links, CSS,
    # attributes, script, raw Markdown or HTML, including the Dossier field.
    rows = "\n".join(f"<div><dt>{SPANISH_LABELS[label] if language == 'es' else label}</dt><dd>{html.escape(value)}</dd></div>"
                     for label, value in field_values(snapshot))
    return (f'<!DOCTYPE html>\n<html lang="{language}"><head><meta charset="utf-8">\n' + """
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<meta name="referrer" content="no-referrer">
<title>Trace</title><style>
*{box-sizing:border-box}
body{margin:0;padding:1rem;background:var(--background,#fff);color:var(--foreground,#171717);font:14px/1.5 var(--font-sans,system-ui,sans-serif)}
main{max-inline-size:72rem;margin-inline:auto;border:1px solid var(--border,#d4d4d4);border-radius:var(--radius,8px);padding:1rem 1.25rem;background:var(--card,#fff);color:var(--card-foreground,#171717)}
h1{font-size:1.1rem;font-weight:650;margin:0 0 .7rem}
dl{margin:0}dl>div{display:grid;grid-template-columns:9.5rem minmax(0,1fr);gap:.25rem 1rem;padding-block:.35rem;border-block-start:1px solid var(--border,#d4d4d4)}
dt{color:var(--muted-foreground,#525252);font-weight:550}
dd{margin:0;white-space:pre-wrap;overflow-wrap:anywhere;min-inline-size:0}
@media(max-width:32rem){body{padding:.5rem}main{padding:.8rem}dl>div{grid-template-columns:minmax(0,1fr);gap:0}}
</style></head><body><main><h1>Trace</h1><dl>
""" + rows + "\n</dl></main></body></html>\n").encode("utf-8")


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
