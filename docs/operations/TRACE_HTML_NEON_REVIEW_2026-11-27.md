# Trace: Barcience input, Neon design and verified clock

Status: 4.23.1 is published; the first Neon designs were rejected. A second
source-only visual comparison is received and visually qualified; independent
review, publication, Dossier refresh and operator acceptance remain separate.
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

## First-round Neon designs: rejected appearance, preserved evidence

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
| `ledger-sheet.html` | Compact register; state evidence and full text in native disclosures | Rejected by Carlos; retained history |
| `split-rail.html` | Asymmetric typography; next actor alongside the subject | Rejected by Carlos; retained history |
| `command-strip.html` | Full-width next-action band; evidence always visible | Rejected by Carlos; retained history |

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

The three files were presented inline in this Orca conversation. Carlos then
rejected all three as visually unattractive and requested a much more attractive
result. The earlier Neon recommendation of ledger-sheet and Codex preference
for split-rail are historical opinions, not current choices or operator
acceptance. Rendering checks did not establish aesthetic acceptance.

## Publication and local closure

4.23.1 source commit `850aeda49cc9fa00643969511bc96cc96f5138a2` was pushed
normally to main and verified clean against the live remote. Exact independent
review R2 strict capture manifest: `bd9bb430b8fd2aa45a0418ec25a0730d0f0794e7928dd8e6c73e512b4ee432f5`.
Local Dossier L13 `local:6c99af3dedf5b5292f0b18e0a4b3568731c88c41460f8ec92fd197eb01cbea13` was captured/exported
with all12 earlier records and17 historical sources intact. Actual five-section
Portal component readback passed81 visible assertions; the browser exited and
its fixture/profile/bundle were removed. This is local delivery; shared Portal,
permanent reader availability and OCTA adoption are not established.

Retained: published source examples, immutable chat previews, original advisor
and review evidence, native Windows receipts and browser screenshots. Owner:
DocKit/Carlos; private evidence custody review2026-12-04, no automatic deletion.
Removed: owned local test directories, browser/build staging and the temporary
Windows qualification fixture (absence checked through a second connection).
No worktree, branch, service, container or image was created for this follow-up.
The19 earlier secondary worktrees remain retired; only the primary is registered.
This publication/readback receipt requires no new version or recursive Dossier.


## Second round after explicit operator rejection

Carlos rejected the first trio in this conversation on 2026-11-27: "Joder, puede
ser mucho más atractivo!" This is a request for a new visual direction, not a
selection among the rejected files. All earlier source and chat artifacts remain
preserved. The production renderer and source version 4.23.1 remain unchanged.

The fresh requested `gemini-4-neon-medium` call returned SUCCESS in 95.241 seconds,
conversation `99ea28ef-ac4e-4465-ad6c-cda46975b5a3`. The returned CLI data still
has no canonical model identity: actual model metadata is unverified. Neon
supplied the HTML/CSS/SVG geometry; Codex substituted HTML-escaped values from
one fixed snapshot, mechanically embedded unchanged Source Sans 3 and Literata
font bytes from Portal 2f913 with full OFL notices, translated labels and the
document language to Spanish, and corrected outer Orca theme-token names.
The inner palettes and layout geometry remain Neon-authored; the final files
are not claimed to be byte-identical to the original Neon templates.
No network font dependency or new production renderer behavior is introduced.

All three new examples use the same observed snapshot: 2026-11-27 01:12:50 CET
(00:12:50 UTC), HEAD5be30a6, version4.23.1. Their model/client values describe
the sample executor and do not verify the external designer. The fixed values
are evidence for comparison, not a live status feed.

| Second-round file | Visual direction | Current disposition |
| --- | --- | --- |
| `r2-cobalt-folio.html` | Warm porcelain, serif display type and a cobalt next-actor panel | Neon recommendation; operator evaluation pending |
| `r2-verdigris-dispatch.html` | Dark slate and verdigris with a separate desktop action column | Alternative; operator evaluation pending |
| `r2-plum-atelier.html` | Cream and sand editorial framing with a plum action panel | Alternative; operator evaluation pending |

The files are in the existing `trace-html-neon-2026-11-27/` source-only directory.
They add no initializer path or installation change. After inspecting all three
desktop views, the executing agent prefers cobalt-folio as the most balanced.
This agrees with Neon's recommendation but is not Carlos's selection. Final
localized Chromium qualification passed all six views (390 and 1280 pixels for
each file), retaining all 12 exact snapshot fields and all six keyboard-operated
native disclosures. No horizontal overflow or external request was observed.
Source Sans 3 loaded in all three; Literata loaded in Cobalt/Plum, where used.
Verdigris uses sans only, so its embedded unused serif remained unloaded.
Contrast checks reported zero warnings and zero excluded background-image cases;
gradients used conservative composited color-stop endpoints. These are bounded
checks, not a claim of universal accessibility certification.

The visual agent inspected all three mobile/desktop localized closed views and
all three dark expanded mobile views. Root inspected the desktop views and
presented the three localized files inline in this Orca turn. Presentation is
not Carlos's acceptance. Source hashes stayed unchanged; the disposable browser
profile is absent. Final evidence is `browser-inspection/inspection-receipt.json`
in the private custody directory below. Exact Opus5.5/high independent review accepted the new examples and bounded
curation, including the later license-comment whitespace normalization;
no operator selection or production-layout change is claimed.

SHA-256 values of the localized rendered examples (pre-localization hashes
remain in the private artifact receipt):
- `r2-cobalt-folio.html`: `1d7a467c888e7077c6d83b3d2b94b37f3a520adfe7ef57c1e996699b2c428711`.
- `r2-verdigris-dispatch.html`: `8704103f388e45039b39d316bd352c942c8849be6cd9ab3d7b618a019ded5bdb`.
- `r2-plum-atelier.html`: `b469cdeff14e13a9935451adc4f09747702d03d304b82c27e449a0ca33e83d5c`.

Dossier assessment: refresh required. L13 still describes the now-rejected trio
as the available choice set. L14 must record the rejection, the three new names,
Neon's recommendation, unchanged default and the current evaluation/next-step
state. Preserve all 13 earlier revisions and 20 historical sources; pin the new
allowlisted HANDOFF source only after reviewed publication. Capture/export and
actual reader readback remain pending. The eventual receipt does not itself
require another recursive capture.

Original advisor inputs/results, font provenance, hashes and review/qualification
evidence are retained privately under
`~/.local/state/LLM-DocKit/neon-trace-visual-r2-20261127`, owner DocKit/Carlos,
custody review 2026-12-04; no automatic deletion authority. New source HTML and
immutable chat copies are intentional deliverables. Remove only owned disposable
browser/validation staging and verify its absence. No new worktree, branch,
server, container or image is needed. This visual/documentary iteration requires
focused content, continuity and browser checks, not a rerun of unchanged runtime
smoke tests.

After browser inspection, trailing whitespace in embedded OFL license comment
lines was normalized for the repository whitespace check. Full license wording
and font bytes are unchanged; an HTML-parser comparison verified identical
rendered tags, attributes, CSS and text before/after. Private
`license-comment-normalization.json` maps inspected hashes to published hashes;
chat copies retain the visually identical pre-normalization comments.
