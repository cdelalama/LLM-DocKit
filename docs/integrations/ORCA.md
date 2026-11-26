# Trace in Orca

DocKit collects one current Git/time snapshot and presents it as text, JSON or a
small static HTML document. HTML is presentation only: durable HANDOFF and HISTORY
contracts remain unchanged. Model choice does not determine rendering support.

## Use

```sh
scripts/dockit-trace-status.sh --role executor --language es \
  --subject "Publicación comprobada" --validation "Pruebas y versión correctas" \
  --next "Continuar con la tarea registrada" --client Orca \
  --model unknown --dossier "Estado del último Dossier comprobado"
```

The default `--format auto` uses HTML when `ORCA_CHAT_SCRATCH_DIR` points to an
existing absolute directory supplied by Orca. It emits an `::orca-visual`
directive on stdout. The agent places that directive on its own line in the
substantive reply, outside a code fence. The directory is a client capability,
not a model capability. Do not invent it in a plain terminal.

Use `--format text` to force the existing eight-field textual header, or
`--format json` for the same snapshot as a versioned field object. Optional
provenance adds fields only when explicitly supplied. JSON requires Python 3;
plain terminal text does not. `--format html` requires the same Orca directory
and falls back to text if it is unavailable. HTML uses English labels by default;
`--language es` selects Spanish labels without changing the durable text format.
Supply operator-facing values in the project's conversation language.

Optional `--client`, `--model`, `--model-family`, `--account`, `--session` and
`--task` values are supplied by the caller. The renderer does not discover or
verify them. An unverified actual model should be `unknown`, never the requested
model asserted as observed. Account means an opaque non-secret alias, not an
email, credential or model family. Two accounts of one model family do not make
an independent cross-family review. `--dossier` carries the last checked status;
the renderer never contacts a reader or captures a Dossier.

## Verified clock

Since 4.23.1, the collector reads one UTC epoch and converts that same instant
for both timestamps. Python zoneinfo is preferred; Windows TimeZoneInfo and
verified system TZif/date are fallbacks. A missing or ignored timezone produces
an explicit `unverified client time`, never UTC relabelled as local time.
Local and UTC equality is legitimate for zero-offset zones. Windows fallback
supports native zone resolution plus explicit Madrid/UTC mappings; unsupported
zones remain unverified. No dependency is installed to obtain a clock.

HTML mode emits a visual directive only. Use `--format text` when the receiving
client needs plain text; do not claim that an exported transcript embeds the
HTML contents without checking that exporter. Design experiments and their
acceptance limits are in
`docs/operations/TRACE_HTML_NEON_REVIEW_2026-11-27.md` in the source repository.

## Boundaries and retention

The helper renders only when invoked for a substantive turn; there is no timer,
polling loop, service, container, external font, script or network request. Values
are escaped text, including URLs. It does not turn supplied content into links,
HTML, CSS or JavaScript. A restrictive CSP is defense in depth. Do not pass
secrets: HTML escaping is not secret detection or redaction.

Each successful invocation writes one fresh `trace-<uuid>.html`, strictly under
512 KiB, with exclusive creation. It never creates the parent directory,
overwrites an older visual or deletes chat history. These are intentional chat
deliverables, retained for the chat lifetime under Orca's policy. Test fixtures
are separate and removed by their tests. Missing Python/renderer, invalid or
unwritable directory, or excessive HTML size returns the original text on stdout
and a warning on stderr. No partial artifact is retained after a caught write
failure. Abrupt process/host death remains the client's recovery boundary.

## Qualification

Run `python3 -B scripts/test-trace-render.py`. It checks content equivalence,
injection treated as text, immutable names, size and write failures, no-capability
fallback, Spanish labels, and actual shell integration. Tests use self-removing
temporary directories and no containers. Before claiming client delivery,
inspect a real Orca visual and a plain-terminal invocation separately.
