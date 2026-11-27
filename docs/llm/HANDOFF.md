<!-- doc-version: 4.23.1 -->
# LLM-DocKit handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-11-27 - Codex: replace the rejected first Neon comparison with three new round-2 proposals
- Current source version: 4.23.1
- Owner: Carlos
- State: 4.23.1 remains published; current main baseline is 5be30a6.
  Its source release passed exact Opus R2 review; the new visual comparison passed its separate exact Opus5.5/high review.
  All 19 secondary worktrees remain retired.
- Local Dossier: L13 is the last completed capture/export/readback;
  refresh L14 is required because Carlos rejected the choices it presents.
  Preserve all 13 existing revisions and 20 historical sources.
- Published-release evidence: smoke138/138, Trace25/25, native Windows6/6,
  first-round visual6/6 (technical rendering passed; Carlos rejected the appearance);
  exact Opus5.5/high R2 SOURCE_GO and bounded CURATION_GO accepted.
  Live publication verified at850aeda; final hosted check receipts live in GitHub Actions.
- Operator presentation: Carlos rejected ledger-sheet, split-rail and command-strip
  as visually unattractive and requested a much more attractive second round.
  New proposals are received, not accepted; the production layout stays unchanged.
- Session focus: complete inherited source, publish instead of abandoning edits,
  deliver static Orca Trace, and retire legacy task workspaces without losing history.
- Authority: Carlos explicitly approved the analysis and instructed implementation,
  agent delegation, cleanup and publication of inherited pending work on November26.
- Source details: docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md.

## Open work - next concrete step

Carlos rejected all three first-round Neon proposals: ledger-sheet, split-rail
and command-strip. Their original files remain unchanged as history; they are
no longer the current choice set. The requested Neon route returned three new
static proposals in `docs/operations/trace-html-neon-2026-11-27/`:
`r2-cobalt-folio.html`, `r2-verdigris-dispatch.html` and `r2-plum-atelier.html`.
Neon recommends cobalt-folio; the executing agent also prefers it after inspecting
all three desktop views. Neither preference is Carlos's selection.
The CLI does not return canonical model metadata;
the requested `gemini-4-neon-medium` route is evidenced, actual identity is unverified.

Final localized browser qualification passed all six mobile/desktop views,
preserving all 12 exact fields and six keyboard-operated native disclosures.
The agent presented all three proposals inline in Orca; this is not acceptance.
The independent source/curation review is accepted. The agent must publish the
reviewed documents and complete local Dossier L14 capture/export/readback. Carlos
then evaluates the actual designs; none is selected or accepted. Applying a
chosen layout to `scripts/dockit-trace-render.py` remains a later step. The
production renderer and version 4.23.1 are unchanged by these source examples.
See `docs/operations/TRACE_HTML_NEON_REVIEW_2026-11-27.md` for provenance and
qualification. The new files share one observed 2026-11-27 01:12:50 CET snapshot
(00:12:50 UTC), not live status. Source Sans 3 and Literata bytes from Portal
2f913 are embedded unchanged, with full OFL notices; Neon authored the layout,
while Codex escaped snapshot values, embedded those fonts and full OFL notices,
translated labels and the document language to Spanish, and corrected outer Orca
theme-token names. The inner palettes and layout geometry remain Neon-authored.
Completed source, cleanup and local Dossier evidence are recorded in
`docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md`. The 19 historical
secondary registrations are retired; only the primary checkout remains. The
17 associated local branches and 9 remote branches were removed through reviewed
plans. Two original commits are archived remotely and six administrative files
remain under verified private custody. The task's ForgeOS checkout is also gone.

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
scaffolds while preserving the source originals. Full smoke passed138/138 with no failures and
removed all disposable fixtures. Exact Opus5.5/high R2 accepted the source, corrected
documentation, first-round visual comparison and bounded post-publication curation.

## Current capability and acceptance limits

- Roles remain executor/auditor/advisor; docs/AGENT_ROLES.md separates model,
  client, account and task. ForgeOS owns routing; project owners define scope.
- Trace renders static HTML for an advertised Orca capability, text otherwise;
  `scripts/dockit-trace-status.sh --language es` is the Spanish operator route.
  Static HTML has been emitted in this Orca chat; terminal tests pass.
  First-round Neon appearance was rejected; three second-round proposals are
  qualified in six browser views and presented inline; Carlos's evaluation
  remains pending. No default was selected.
- Leave-no-residue forbids repeated allocation per read/poll. It cannot replace
  actual producer adoption or host health checks. NAS2/Dossier runtime is owned
  by Home Infra/ForgeOS/Portal; no NAS deployment is part of this task.
- Publication checker has offline advisory and explicit live post-push modes.
  It never automatically publishes arbitrary dirty work or grants permission.
- Dossier: L13 local capture/export/readback completed with the pinned1.1.0
  engine; all12 earlier snapshots and17 historical sources preserved. Three new
  sources pin850aeda;20 sources total. Revision: local:6c99af3dedf5b5292f0b18e0a4b3568731c88c41460f8ec92fd197eb01cbea13.
  L13 still describes the old comparison; L14 refresh is pending.
  Its five Portal reader sections passed81 visible assertions; root inspected
  Ahora/Fuentes and agent inspected the real view. No external requests.
  Permanent4319 and shared Portal remain unavailable/unproven; do not invoke
  the old container-per-read route. Shared recovery stays with its owner.

## Retained work and separate owners

- DF-058: source mechanics and local packaging are published; actual intended-user
  acceptance and wider mutation-entrypoint adoption remain adopter-owned.
- Validation lifecycle: DEV/selected OCTA observations remain dated evidence;
  66 held OCTA configurations still need qualification. See
  docs/llm/work/validation-lifecycle-20261122.json and docs/RUNTIME_LIFECYCLE.md.
- DF-064/065/066/067 and other feedback remain in docs/DOWNSTREAM_FEEDBACK.md;
  source review must not erase them or imply all clients have equivalent hooks.
- Project authentication is per owner policy. Historical Authelia next steps in
  archived handoffs are superseded by Home Infra's October16 per-application
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
- Sent: 2026-11-27 01:24:17 Europe/Madrid (00:24:17 UTC)
- Subject: Second Neon visual comparison after Carlos rejected the first round
- Resulting state: HEAD=5be30a6; version=4.23.1; comparison candidate received; default unchanged; L14 refresh pending
- Repo state: main=origin/main=5be30a6 at observation; new proposals and owner documentation are uncommitted
- Validation: second-round localized browser6/6 and inline presentation completed; prior release checks remain historical evidence; exact Opus5.5/high SOURCE_GO and CURATION_GO accepted
- Next gate: agent publishes and refreshes L14; Carlos evaluates the three new designs before any production layout change
<!-- DOCKIT-STATE:END -->

## Historical evidence

The exact previous handoff is retained in
[HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md](../archive/HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md).
It is history, not the active next-step list. Stable decisions remain in
DECISIONS.md; source/reviewer provenance in REVIEWS.md; task custody in WORK_INDEX.md.
