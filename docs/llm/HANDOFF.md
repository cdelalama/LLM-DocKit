<!-- doc-version: 4.23.0 -->
# LLM-DocKit handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-11-26 - Codex
- Current source version: 4.23.0
- Owner: Carlos
- State: source validated and independently reviewed; publication and retirement next.
- Session focus: complete inherited source, publish instead of abandoning edits,
  deliver static Orca Trace, and retire legacy task workspaces without losing history.
- Authority: Carlos explicitly approved the analysis and instructed implementation,
  agent delegation, cleanup and publication of inherited pending work on November26.
- Source details: docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md.

## Open work - next concrete step

The executing agent publishes the validated, independently reviewed candidate
and runs `scripts/dockit-publication.py --require-published`.
It reconciles published `docs/llm/work/` records with the installed ForgeOS
ledger and retires the exact eligible workspaces. The missing historical entry
needs the bounded ForgeOS retirement repair; do not broad-prune or discard it.
Update the receipt in `docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md`
after observed retirement. Existing author edits are explicitly adopted by this
session; unrelated ForgeOS/Home Infra Dossier implementation remains with its owner.

## Current capability and acceptance limits

- Roles remain executor/auditor/advisor; docs/AGENT_ROLES.md separates model,
  client, account and task. ForgeOS owns routing; project owners define scope.
- Trace renders static HTML for an advertised Orca capability, text otherwise;
  `scripts/dockit-trace-status.sh --language es` is the Spanish operator route.
  Native Orca readback and terminal tests are separate from source publication.
- Leave-no-residue forbids repeated allocation per read/poll. It cannot replace
  actual producer adoption or host health checks. NAS2/Dossier runtime is owned
  by Home Infra/ForgeOS/Portal; no NAS deployment is part of this task.
- Publication checker has offline advisory and explicit live post-push modes.
  It never automatically publishes arbitrary dirty work or grants permission.
- Dossier: refresh required for this accepted source state. The pinned local
  offline1.1.0 engine is separate from current ForgeOS1.2.0; preserve history.
  Shared Portal was paused by its owner; do not invoke the old container-per-read
  route. Complete feasible local capture and report shared-reader delivery blocked.

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
- Sent: 2026-11-26 22:50:32 CET (21:50:32 UTC)
- Subject: authorized inherited-source publication, Orca Trace and workspace closure
- Resulting state: version=4.23.0; source candidate; review/publication pending
- Repo state: published baseline f7b469a; inherited candidate adopted without reset
- Validation: smoke138/138, Trace13/13, publication8/8; exact Opus R2 SOURCE_GO
- Next gate: executor completes publication, guarded retirement and Dossier upkeep
<!-- DOCKIT-STATE:END -->

## Historical evidence

The exact previous handoff is retained in
[HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md](../archive/HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md).
It is history, not the active next-step list. Stable decisions remain in
DECISIONS.md; source/reviewer provenance in REVIEWS.md; task custody in WORK_INDEX.md.
