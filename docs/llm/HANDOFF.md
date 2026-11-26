<!-- doc-version: 4.23.1 -->
# LLM-DocKit handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-11-27 - Codex: integrate Barcience input, compare received Neon designs and verify the clock
- Current source version: 4.23.1
- Owner: Carlos
- State: 4.23.1 clock/distribution correction verified; exact Opus R2 review accepted.
  All 19 secondary worktrees remain retired.
- Local Dossier: L12 captured/exported and all five reader sections verified.
- Release evidence: smoke138/138, Trace25/25, native Windows6/6, visual6/6;
  exact Opus5.5/high R2 SOURCE_GO and bounded CURATION_GO accepted.
  Publication and final hosted checks require exact commit readback.
- Operator presentation: Carlos requested three static HTML Trace layouts to choose;
  previews do not change the published default until he selects one.
- Session focus: complete inherited source, publish instead of abandoning edits,
  deliver static Orca Trace, and retire legacy task workspaces without losing history.
- Authority: Carlos explicitly approved the analysis and instructed implementation,
  agent delegation, cleanup and publication of inherited pending work on November26.
- Source details: docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md.

## Open work - next concrete step

Carlos requested Neon to author the design after supplying the Barcience note.
Three static proposals returned through the requested Neon route: ledger-sheet
(Neon recommendation), split-rail and command-strip. Canonical model identity
is not present in the CLI response; operator selection is still pending. The
agent compares these actual proposals in
`docs/operations/TRACE_HTML_NEON_REVIEW_2026-11-27.md`; Carlos can then select
a layout before it is applied to `scripts/dockit-trace-render.py`. The earlier
Codex options are retained history, not the active default choice.
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
documentation, actual visual comparison and bounded post-publication curation.

## Current capability and acceptance limits

- Roles remain executor/auditor/advisor; docs/AGENT_ROLES.md separates model,
  client, account and task. ForgeOS owns routing; project owners define scope.
- Trace renders static HTML for an advertised Orca capability, text otherwise;
  `scripts/dockit-trace-status.sh --language es` is the Spanish operator route.
  Static HTML has been emitted in this Orca chat; terminal tests pass.
  Three Neon-route proposals were received; selection and final client acceptance remain separate.
- Leave-no-residue forbids repeated allocation per read/poll. It cannot replace
  actual producer adoption or host health checks. NAS2/Dossier runtime is owned
  by Home Infra/ForgeOS/Portal; no NAS deployment is part of this task.
- Publication checker has offline advisory and explicit live post-push modes.
  It never automatically publishes arbitrary dirty work or grants permission.
- Dossier: L12 local capture/export/readback completed with the pinned1.1.0
  engine; all11 earlier snapshots preserved. Three new sources pin11e94e0.
  Revision: local:b01f3d2661f08d7fb729923da3b46e3b73f9ea612f063bbba019de7a627f1299.
  The actual local export was read through all five Portal reader sections.
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
- Sent: 2026-11-27 00:42:38 Europe/Madrid (23:42:38 UTC)
- Subject: Barcience input, requested Neon designs and verified Trace clock
- Resulting state: version=4.23.1; source candidate; production layout unchanged
- Repo state: main18251ba equals fetched origin; scoped source/docs edits pending publication
- Validation: Trace25/25 and native SPITFIRE-2 Windows6/6; smoke138/138; exact Opus R2 SOURCE_GO and bounded CURATION_GO accepted
- Next gate: agent publishes verified source and captures local L13; Carlos selects a layout independently
<!-- DOCKIT-STATE:END -->

## Historical evidence

The exact previous handoff is retained in
[HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md](../archive/HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md).
It is history, not the active next-step list. Stable decisions remain in
DECISIONS.md; source/reviewer provenance in REVIEWS.md; task custody in WORK_INDEX.md.
