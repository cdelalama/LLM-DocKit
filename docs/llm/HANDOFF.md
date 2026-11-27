<!-- doc-version: 4.24.0 -->
# LLM-DocKit handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-11-27 - Codex qualified the generated Cobalto card.
- Current source version: 4.24.0
- Owner: Carlos
- State: Cobalto is implemented on the 4.24.0 candidate based on 8bc8437.
  Carlos selected the second-round design with "Implementa cobalto".
- Qualification: 32 Trace tests passed. Chromium checked the actual Orca chat
  artifact and long multiline data at 390 and 1280 px. Native selection includes
  the final newline. No external request or horizontal overflow was observed.
- Local Dossier: L14 remains current until reviewed source publication. L15
  will retain all 14 revisions and 21 sources and add HANDOFF and D-037 pins.

## Open work - next concrete step

The DocKit maintainer obtains independent source and Spanish L15 curation review
for the candidate in `scripts/dockit-trace-render.py` and
`scripts/dockit-trace-cobalt.html`. After the ordinary push to main, verify the
live remote with `scripts/dockit-publication.py --require-published`, pin both
reviewed sources, capture/export L15 and inspect its five local reader sections.
Follow `docs/operations/DOSSIER.md` and `docs/integrations/ORCA.md`.
Existing downstream projects can adopt the pair through their usual authorized
sync. Personal acceptance of the generated card remains with Carlos.

The selected reference is
`docs/operations/trace-html-neon-2026-11-27/r2-cobalt-folio.html`.
All previous examples remain immutable history. Neon authored the selected
layout; the renderer implements current values, fixed Spanish/English labels,
separate optional provenance rows and full selectable canonical text. The
embedded Source Sans 3/Literata font bytes retain complete OFL notices. The HTML
uses native disclosure and no JavaScript/network request. Do not reuse the
prototype's historical clock/Git values as live state. No clipboard behavior is
introduced. Source-only prototype notes remain excluded from new scaffolds.

Preserve the published Windows candidate `b6a369f` on
`origin/fix/windows-documentary-validation`: it still contains an unintegrated
Git Bash path-normalization fix in `scripts/dockit-init-project.sh`. Owner: DocKit
maintainer. Review by 2026-12-03, with independent review and native Windows
qualification before integration or an explicit discard. Other portions were
absorbed by 18d64a3/925fa2a; partial supersession is not full integration. This is
published retained work, not an uncommitted change or a remaining worktree.
Unrelated ForgeOS/Home Infra Dossier implementation remains with its owner.

The Barcience source note and two prototypes are preserved unchanged in
`docs/operations/TRACE_HTML_DOWNSTREAM_BARCIENCE_2026-11-16.md` and its linked
HTML directory. 4.23.1 corrects the reported Git Bash timezone failure in
`scripts/dockit-trace-status.sh`: one UTC instant, verified conversion, explicit
unverified fallback. Trace tests pass 25/25; native SPITFIRE-2 Windows tests pass
6/6. A separate diagnostic reproduced the old defect. OCTA adoption is not verified.
The initializer excludes these source-only notes/prototypes from new project
scaffolds while preserving the source originals. Full smoke passed 138/138 with no failures and
removed all disposable fixtures. Exact Opus 5.5/high R2 accepted the source, corrected
documentation, first-round visual comparison and bounded post-publication curation.

## Current capability and acceptance limits

- Roles remain executor/auditor/advisor; docs/AGENT_ROLES.md separates model,
  client, account and task. ForgeOS owns routing; project owners define scope.
- Cobalto is the default HTML layout in the 4.24.0 candidate. Text remains available and is the no-capability fallback.
  Optional provenance has separate labeled fields and preserved line breaks.
- Leave-no-residue forbids repeated allocation per read/poll. It cannot replace
  actual producer adoption or host health checks. NAS2/Dossier runtime is owned
  by Home Infra/ForgeOS/Portal; no NAS deployment is part of this task.
- Publication checker has offline advisory and explicit live post-push modes.
  It never automatically publishes arbitrary dirty work or grants permission.
- Dossier: L14 local capture/export/readback completed with pinned 1.1.0 engine;
  all 13 earlier snapshots and 20 historical sources preserved. One new HANDOFF
  source pins 64cc5a6; 21 sources total. Revision: local:042af7e9e66436cc7df37ada98da680612be5e2a2df38a8f3f085cd6143417c1.
  All five Portal reader sections passed 84 visible assertions; root and agent
  inspected Ahora. New pin/hash checked against the published Git blob.
  No external requests; browser and fixture/profile removed. Permanent port 4319 and
  shared Portal remain unavailable/unproven; shared recovery stays owner-held.

## Retained work and separate owners

- DF-058: source mechanics and local packaging are published; actual intended-user
  acceptance and wider mutation-entrypoint adoption remain adopter-owned.
- Validation lifecycle: DEV/selected OCTA observations remain dated evidence;
  66 held OCTA configurations still need qualification. See
  docs/llm/work/validation-lifecycle-20261122.json and docs/RUNTIME_LIFECYCLE.md.
- DF-064/065/066/067 and other feedback remain in docs/DOWNSTREAM_FEEDBACK.md;
  source review must not erase them or imply all clients have equivalent hooks.
- Project authentication is per owner policy. Historical Authelia next steps in
  archived handoffs are superseded by Home Infra's October 16 per-application
  Better Auth decision; this source task performs no authentication migration.
- Historical portfolio consensus is preserved verbatim in
  docs/archive/DOCKIT_ECOSYSTEM_CONSENSUS_2026-09-29.md, not new runtime authority.

## Do Not Touch

Preserve original history, raw advisor transcripts, backups, user data and
unrelated concurrent work. No NAS writes, production changes, forced pushes,
blanket pruning, hidden review bypass or automatic evidence expiry. Closeout
records preserve separately unfinished product work when a checkout is retired.

## Trace Anchor

- Role: executor
- Sent: 2026-11-27 02:09:54 Europe/Madrid (01:09:54 UTC)
- Subject: Qualify generated Cobalto for DocKit 4.24.0
- Resulting state: HEAD=8bc8437; version=4.24.0; reviewed publication pending
- Repo state: main and origin/main at 8bc8437 before the candidate commit
- Validation: 32 Trace tests and four generated browser cases passed
- Next gate: independent source/curation review, publication and local L15 readback
<!-- DOCKIT-STATE:END -->

## Historical evidence

The exact previous handoff is retained in
[HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md](../archive/HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md).
It is history, not the active next-step list. Stable decisions remain in
DECISIONS.md; source/reviewer provenance in REVIEWS.md; task custody in WORK_INDEX.md.
