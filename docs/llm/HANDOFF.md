<!-- doc-version: 4.26.1 -->
# LLM-DocKit handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-11-27 - Codex: worktree sync discovery correction (4.26.1).
- Current source version: 4.26.1
- Publication: candidate pending push to origin/main.
- Owner: Carlos
- Session focus: Carlos corrected the Executor recovery and TREK client access
  analysis and requested durable learning. DF-068, D-039,
  `docs/FAILURE_LEARNING.md` and the optional `failure-learning` check record
  and validate declared cases. Home Infra adopted the narrow guard and
  applied OCTA's scoped server policy; native client acceptance remains open.
  DF-069 records that DocKit sync mistook a managed worktree's `.git` file for
  a missing repository. Patch 4.26.1 recognizes it and protects Git discovery;
  a worktree still needs its own state and durable backup closeout.
- Previous state: 4.25.0 central update notices and collector-first Trace were
  published; their DEV hook trust and live notification gate remains open.
- Limits: instructions are central and current; project template files still
  change only through operator-gated `scripts/dockit-sync.sh` (49 adopters
  reported OUTDATED at the earlier count; refresh before quoting a new count).
  Codex runs the update-notice hooks only after /hooks trust. The learning
  checker sees declared cases only; it cannot discover missed chat corrections.

## Open work - next concrete step

For DF-069, finish review and publish the bounded 4.26.1 discovery correction.
Do not run a full sync in a disposable managed worktree until state and backup
custody through task retirement have a reviewed design. Home Infra's exact
published-file copy is recorded as selective adoption, with no full sync claim.
Fresh OCTA/Android client use and an authorized natural TREK write remain Home
Infra acceptance, separate from DocKit source. Other adopters receive no
automatic template replacement.

Update-notice rollout on DEV (commands in `docs/integrations/CODEX.md`):
(1) DONE 2026-11-27 02:24 UTC - installed into `~/.claude/settings.json` and both
Codex homes; a simulated open session in cortex got one notice, then silence.
Backups `*.bak.20261127T022402Z` beside each config are kept until step 2 is
verified (owner Carlos, review by 2026-12-04). (2) NEXT - Carlos trusts both new
hooks in Codex `/hooks`, once per Codex home (`~/.codex`, `~/.codex-lamanoriega`).
(3) agent observes one live notice per client after (2). Claude needs no trust
step. Home Infra registry records 4.25.0 at `5a24a184`. Fleet template
sync with `scripts/dockit-sync.sh` remains a separate operator-gated decision.

By 2026-12-03 the DocKit maintainer reviews the retained Windows candidate
`b6a369f` in `scripts/dockit-init-project.sh`, qualifies the Git Bash path
correction on native Windows before integration, or records an explicit discard.
Cobalto source publication and local Dossier L15 are complete. Existing projects
can adopt the renderer and template through their authorized sync as described
in `docs/integrations/ORCA.md`. Personal acceptance of the generated card
remains with Carlos.

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
- Cobalto is the default HTML layout in 4.24.0. Text remains available and is the no-capability fallback.
  Optional provenance has separate labeled fields and preserved line breaks.
- Leave-no-residue forbids repeated allocation per read/poll. It cannot replace
  actual producer adoption or host health checks. NAS2/Dossier runtime is owned
  by Home Infra/ForgeOS/Portal; no NAS deployment is part of this task.
- Publication checker has offline advisory and explicit live post-push modes.
  It never automatically publishes arbitrary dirty work or grants permission.
- Dossier: L15 local revision local:08fbb1e9dae90f15e2a66dadb5bbc05c9deb5871f983f5dbdff49c1a9f7d4559.
  The pinned 1.1.0 engine verified the export. The Portal reader passed 89
  visible assertions across Ahora, Hoja de ruta, Informes, Decisiones and
  Fuentes. Both new pins resolve to the published HANDOFF and DECISIONS blobs
  in ea02fb3. No external requests occurred. Permanent reader reachability and
  shared Portal recovery remain with their respective owners.

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
- Sent: 2026-11-27 03:23:43 Europe/Madrid (02:23:43 UTC)
- Subject: feat: central update notices and collector-first Trace onboarding (4.25.0)
- Resulting state: base HEAD=38e240f; version=4.25.0; gate=next-slice; source reviewed, DEV hook rollout pending
- Repo state: main matched origin/main at 38e240f before this commit; worktree carried only this task
- Validation: notice suite ALL PASS, 32 Trace tests OK, 140 smoke passed; independent Codex gpt-6.2-astra review GO after six rounds
- Next gate: agent installs hooks on DEV; Carlos trusts them in Codex /hooks per home
<!-- DOCKIT-STATE:END -->

## Historical evidence

The exact previous handoff is retained in
[HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md](../archive/HANDOFF_BEFORE_ORCA_CLOSEOUT_2026-11-26.md).
It is history, not the active next-step list. Stable decisions remain in
DECISIONS.md; source/reviewer provenance in REVIEWS.md; task custody in WORK_INDEX.md.
