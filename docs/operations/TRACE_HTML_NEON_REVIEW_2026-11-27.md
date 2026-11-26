# Trace: Barcience input, Neon design and verified clock

Status: source candidate 4.23.1; design proposals are not operator acceptance.
Owner: LLM-DocKit. Authority: Carlos requested integration of the published
Barcience note and asked Neon to author the design, following his authorization
to implement, test, delegate, clean up and publish this work.

## Historical input and disposition

The note `TRACE_HTML_DOWNSTREAM_BARCIENCE_2026-11-16.md` and both files under
`trace-html-barcience-2026-11-16/` remain byte-identical to published 18251ba.
The first prototype rendered but Carlos disliked its appearance. The second
rendered; its appearance was not accepted and its buttons were not qualified.
Do not infer approval from rendering or from the absence of a reply.

Use visible subject, role, exact local/UTC time and who acts next. Preserve all
Trace fields, with secondary evidence available through native disclosure.
Neon was asked to author three distinct static HTML compositions from one fixed
observed snapshot. The earlier three Codex previews remain historical options;
the active design comparison now follows Carlos's request for Neon.

The downstream note is historical evidence, not an exact description of every
4.23.0 behavior. In HTML mode the collector emits an Orca visual directive,
not a duplicate plain Trace alongside it. Explicit `--format text` remains
available. Exported transcript portability is not established by Orca rendering.
A selectable text disclosure is a design proposal; it does not by itself prove
that an external transcript exporter includes the text.

Clipboard actions, accent switching and a checklist progress bar are deferred.
The shipped renderer has no JavaScript and a restrictive CSP; the current
request is static HTML. Native details/summary can expose text without script.
A future clipboard enhancement needs an explicit bounded Orca capability test,
a usable fallback and a reviewed policy change; this release adds no fake copy
button and makes no claim that browser testing proves Orca clipboard support.
The Pixel Fold sidebar report belongs upstream and creates no DocKit task.

## Clock correction

4.23.0 used two date reads and trusted `TZ=Europe/Madrid date`. OCTA evidence
shows Git Bash can silently ignore that zone. 4.23.1 captures one UTC epoch and
converts it using Python zoneinfo, Windows TimeZoneInfo, or system TZif files
with a nonzero sentinel capability check for date. The PowerShell fallback
resolves native IDs first and explicitly maps Europe/Madrid and UTC when needed.
Unsupported zones fail closed. If no conversion can be verified, Sent states
`unverified client time`; UTC is never merely labelled Madrid.

Local time equalling UTC is not a failure heuristic: London in winter and UTC
zones are legitimate. Tests cover both DST boundaries, midnight, zero offsets,
missing zone databases, a date implementation ignoring TZ, source absence and
text/JSON/HTML consistency. Native SPITFIRE-2 qualification passed six cases using the exact collector SHA
`f09e21f6379cc3228d1d2cbb25838c1e95aff1e6df85a5bed7d8f4f381048ca9`.
Git Bash reproduced the original GMT/UTC result and Python lacked tzdata, so
this exercised the real Windows TimeZoneInfo fallback. Windows PowerShell
5.1.26100.9818, Bash 5.3.15, Git 2.56.0.windows.4, Python 3.12.10. One epoch
read per case; temporary fixture absent on a second SSH readback. No packages,
services, credentials, access policy or existing checkouts changed. OCTA SSH
was inaccessible and no connected Orca Windows destination was available;
SPITFIRE-2 evidence is not OCTA adoption.

## Distribution and acceptance boundaries

Source-only Barcience and Neon notes/prototypes must not be installed into a
new project's scaffold. The initializer removes only these exact owner paths
from the newly generated target, preserving source originals. The existing
Windows initializer path-normalization branch b6a369f remains a separate retained
candidate; this clock fix does not integrate or retire that branch.

No runtime installation, NAS operation, service, container or image is part of
this change. The renderer's production layout remains unchanged until Carlos
selects a design. The release corrects clock collection and scaffold isolation.

## Design provenance and validation

The two `gemini-4-neon-xhigh` design calls reached their print deadlines (300s
and 480s); the first returned incomplete HTML and the second no complete design.
Neither is presented as a usable design. A fresh, smaller template-only request
uses `gemini-4-neon-medium`; this changes the requested reasoning level, not the
designer family. Actual returned model metadata remains a separate check.

Exact `claude-opus-5-5` at high effort R1 accepted the code and tests, but withheld
SOURCE_GO/CURATION_GO for unfinished documentation: premature Neon wording,
stale Trace Anchor, diagnostic/test-count distinction and curation source wording.
R2 accepted these corrections with SOURCE_GO and bounded CURATION_GO, using
verified canonical `claude-opus-5-5` at high effort. Publication, source pin
substitution and actual local reader readback remain explicit closure steps.
Full frozen-source smoke passed
138/138 with no failures, stable source hashes and all disposable fixtures gone.
Trace passed 25/25 and version synchronization passed all ten targets.
Raw prompts/results and native review evidence are private at
`~/.local/state/LLM-DocKit/neon-trace-20261127`, owner DocKit/Carlos, custody
review 2026-12-04. This is a review date, not automatic deletion authority.
Published HTML examples are intentional source evidence; chat copies are
intentional deliverables retained for the chat lifetime. Disposable validation
fixtures must be removed and their absence verified.

## Received Neon designs

The fresh `gemini-4-neon-medium` route returned SUCCESS in 75.216 seconds,
conversation `da36dfe9-a7d4-4ef1-9292-7b27794558f1`. Neon authored all three HTML/CSS
templates. Codex only replaced declared placeholders with HTML-escaped values
from one fixed observed snapshot and added a final newline; no layout/CSS was
changed. Original response, templates, prompt, invocation and hashes are retained
privately. The CLI response does not expose canonical model identity: the
requested Neon route is evidenced, actual identity remains unverified. Never
mislabel these as independently verified model metadata.

The example values are a historical snapshot at 2026-11-27 00:19:46 CET
(23:19:46 UTC), HEAD18251ba, version4.23.0. They are deliberately identical in
all variants, not a live report of the subsequent 4.23.1 source. The model/client
fields describe the sample Codex executor, not the external designer.

| Proposal | Composition | Disposition |
| --- | --- | --- |
| `ledger-sheet.html` | Compact register; state evidence and full text in native disclosures | Neon's recommendation; operator choice pending |
| `split-rail.html` | Asymmetric typography; next actor alongside the subject | Alternative; operator choice pending |
| `command-strip.html` | Full-width next-action band; evidence always visible | Alternative; operator choice pending |

All three are in `trace-html-neon-2026-11-27/`. They are static, script-free and
use native details/summary. No browser result asserts clipboard capability,
actual Orca readback or operator acceptance. The production renderer is unchanged.

Rendered example SHA-256 values:
- `ledger-sheet.html`: `b7edd0f70e7d0cc5fcccfdd3876f6c7eb66ecdc4cf4bfa75c750069966c16940`.
- `split-rail.html`: `547369dcb2a4693b1b6d1256bc94479b167c5c62ae5cef26f42e3da39efb6731`.
- `command-strip.html`: `4b6265e42f4e20043d4803da1e6408f37a8ad5082a3c2cc849227b79d65c8ad8`.

## Observed visual qualification

All three examples passed native Chromium inspection at 390 and 1280 pixels:
12 exact snapshot values each, no horizontal overflow, no scripts/event handlers
or external requests, and all 16 native disclosure openings via keyboard.
Light and simulated Orca dark tokens were inspected without modifying source
files. Root inspected all three desktop views plus mobile views; the disposable
browser profile was removed and source hashes stayed unchanged. An initial
keyboard-harness attempt omitted the Enter character event; it was corrected
in the test harness, with no HTML changes and the failed receipt preserved.

The three files were presented inline in this Orca conversation. Carlos's
selection remains pending. Neon recommends ledger-sheet; Codex's visual
preference is split-rail for its compact subject/next-actor arrangement. Neither
recommendation is an operator decision or production-layout change.
