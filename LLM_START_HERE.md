## DocKit source maintainer context - 2026-11-27

Source version: 4.24.0. Current owner state and next action are in
`docs/llm/HANDOFF.md`; source architecture is in `HOW_TO_USE.md` under
"Source maintainer context". README, PROJECT_CONTEXT and ARCHITECTURE below
are distributable starter templates, not an inventory of DocKit runtime.
This preface is source-only and is removed by the initializer.

### Open work - next concrete step

Cobalto is implemented and browser-qualified in the 4.24.0 candidate.
Follow `docs/llm/HANDOFF.md` for independent review, source publication and
local Dossier L15. Orca Trace uses `scripts/dockit-trace-status.sh --language es`.
Terminal clients retain the text format.
Previous source observations are preserved in
`docs/archive/ONBOARDING_OWNER_STATUS_BEFORE_2026-11-26.md`; they are historical,
not today's next actions. Existing fleet, DF-058 and recovery obligations remain
in the current handoff with their owners.

<!-- doc-version: 4.24.0 -->

# LLM Start Guide - <PROJECT_NAME>

## Read This First (Mandatory)

Welcome to <PROJECT_NAME>. Before you contribute, review and adapt the sections below to match the project requirements. Replace angle-bracket placeholders (<...>) with real values and share this file with every LLM agent.

Recommended reading order:
1. This file (rules, workflows, and current expectations)
2. docs/PROJECT_CONTEXT.md (vision, architecture, current state)
3. docs/ARCHITECTURE.md if present; otherwise docs/ARCHITECTURE.md.example as the optional starter template
4. docs/VERSIONING_RULES.md (version management policy)
5. docs/llm/README.md (LLM docs index)
6. docs/llm/HANDOFF.md — current work state. Read the **Open work — next concrete step** section near the top first; it is the canonical declaration of "what to do next" and must name concrete file paths inside the repo. The static check `scripts/dockit-validate-session.sh --check orientation` enforces that contract.
7. docs/llm/DECISIONS.md (stable rationale; link from HANDOFF)

Session-start scope:
- This reading order is mandatory once at session start, not on every turn.
- If you already loaded it in this same conversation and no relevant onboarding file changed, do not re-read the full list on later turns.
- For later turns, follow the stale-read re-verification rule: re-check the current clock before writing Trace, `git status`, current HEAD, and any files directly relevant to the new request.
- Re-read the full onboarding only when the operator explicitly widens scope or when repo state/doc changes make the prior onboarding stale. In that case begin with `Onboarding loaded (mid-session).`

## Critical Rules (Non-Negotiable)

<!-- DOCKIT-TEMPLATE:START leave-no-residue -->
### Leave no residue

A task is not done while something it created only in order to do the work
still exists. Authority: Carlos, 2026-11-26; `docs/LEAVE_NO_RESIDUE.md`.

1. Residue is what a task makes on the way and nobody will use afterwards: test
   and qualification containers, images built or pulled for a test, scratch and
   staging folders, temporary files, restore rehearsals, the task's own copies
   taken before a change, task branches and worktrees, superseded drafts, raw
   logs and transport archives.
2. Know what removes a disposable thing before creating it. Prefer forms that
   remove themselves (`--rm`, a self-deleting temporary directory, a stream).
3. Nothing that runs repeatedly may create and destroy a resource per request,
   poll or read. Use a long-lived process, a native tool or a cache.
4. Remove only what this task created and is authorized to remove, and verify
   that it is gone. A copy the task took before a change goes when the change is
   verified, unless the project's rollback or retention rule keeps it.
5. Anything kept is written down: what, why, who owns it and until when.
6. Custody, backup, rollback and history obligations prevail over this rule.
   Never delete or shrink evidence, backups, data volumes, other sessions' work,
   user data or objects of unknown origin in order to tidy up: report them. An
   unreferenced volume may hold data.
7. Closeout states what the task created, what it removed and what it kept under
   point 5. "Created nothing disposable" is a valid statement.

Applied by `docs/RUNTIME_LIFECYCLE.md` (runtime) and the `workspace-ownership`
section (workspaces). `workspace-leftovers` warns on backup/temporary files.
<!-- DOCKIT-TEMPLATE:END leave-no-residue -->

### Language Policy
- Canonical engineering documentation, code identifiers, comments and file names: English.
- Conversation with the user: <CONVERSATION_LANGUAGE>.
- All operator-facing prose uses the configured conversation language unless
  the user explicitly selects a different product language.
- Product copy includes UI labels, dialogs, accessibility text, dashboards,
  reports and every human-readable field in a Dossier projection. This rule
  also applies when that content is stored in JSON or generated from English
  technical documents. Translate its meaning before capture/publication.
- Keep product names, exact commands, code literals, paths, schema keys, IDs,
  enum values, hashes and source bytes unchanged. Source titles and explanatory
  summaries shown to the operator use that product language; technical source files remain English.
- A language correction creates a newly dated revision. Preserve original
  observations, immutable historical revisions, status, evidence and permissions.
- Before delivery, review every visible field and inspect the real reader in
  the selected product language. Schema validation alone does not prove language or translation quality.

<!-- DOCKIT-TEMPLATE:START operator-clarity -->
### Operator clarity and roadmap continuity

- Write all operator-facing status, roadmaps, Dossiers, reports and questions
  for someone returning without the chat. Use the configured product language.
- Explain the useful outcome, what works today, what remains, and one immediate
  next step: who acts, where, what they do, and the result they should see.
  Read recorded operator/device preferences before asking for missing details.
- Define completion with an observable user example. Unexplained phrases such
  as "private transfer", "acceptance verified", "gate" or "canary" are not
  actionable instructions. Keep technical evidence available separately.
- Explain priority changes with previous/new order, date, reason and authority;
  show what happens to the earlier unfinished work. Separate work lines and
  real dependencies. Array order does not establish progress or prerequisites.
- Preserve IDs, historical evidence, pending obligations and proposed/accepted
  boundaries. Prepared, published, deployed and personally tried remain distinct.
- Before delivery, author and independent reviewer read the actual operator
  view: what is usable, who does what next, what finishes it, and why the route
  changed. Correct ambiguity before claiming delivery. Schema PASS is not proof
  of comprehension. Follow LLM-DocKit docs/OPERATOR_CLARITY.md for examples.
- When meaningful operator state changes in a Dossier-enabled project, the
  executing agent must assess refresh versus no_change before task closeout.
  Milestone acceptance, decisions, priorities and next actions require refresh.
  Complete already-authorized capture, sharing review, publication and real
  reader readback without another reminder. No new project admission or wider
  source disclosure is implied. Report an actual blocker and retain the draft;
  do not call the Dossier current while it is stale. Receipt-only commits do
  not trigger another capture. See the closeout section in OPERATOR_CLARITY.md.
<!-- DOCKIT-TEMPLATE:END operator-clarity -->

<!-- DOCKIT-TEMPLATE:START idea-continuity -->
### Preserve and recall project ideas

Before brainstorming or resuming work, read `docs/llm/IDEA_INDEX.json` when
adopted, its relevant owner registers, and retained work. Follow
`docs/IDEA_CONTINUITY.md`. Preserve material requests, suggestions, constraints
and unresolved questions with attribution, stable identity, owner and recall
trigger. Reuse existing D/ADR/UP authority; the recall index never sets priority.
Before closing, compare the session's ideas with recorded dispositions and
reconcile newly closed tasks. Documented does not mean implemented. Author and
reviewer check semantic coverage; the validator only checks the declared corpus.
Run the idea check against the explicit reviewed start revision before publishing.
Retain unknown coverage and the historical-backfill cursor; never claim all chats
were captured. Complete the existing Dossier refresh/no_change assessment.
<!-- DOCKIT-TEMPLATE:END idea-continuity -->

<!-- DOCKIT-TEMPLATE:START runtime-lifecycle -->
### Retire disposable test runtime

Follow docs/RUNTIME_LIFECYCLE.md whenever a task creates disposable runtime.
Preserve durable evidence outside the container, then retire its exact ID and
verify disappearance before declaring success. Persist creation intent and run ID;
reconcile interrupted attempts before retrying. A failed cleanup stops that
producer. Respect host creation holds and allocation checks before engine writes.
Debug holds require an owner, reason, finite lease and next action. Record one
sanitized receipt per run in docs/llm/runtime; none is task-specific with a reason,
never inferred from missing records. Use scripts/dockit-runtime.py --strict for
runtime closeout. Do not delete unknown objects, data volumes, images or historical
snapshots by age. DocKit checks declarations; host reconciliation finds undeclared
objects. Installing this rule does not install a garbage collector.
Validation commands also own their children and scratch files. Avoid per-edit
history scans. Verify retirement on success, failure and cancellation and
reconcile an interrupted run before retrying. Follow docs/RUNTIME_LIFECYCLE.md.
<!-- DOCKIT-TEMPLATE:END runtime-lifecycle -->

<!-- DOCKIT-TEMPLATE:START doc-update-rules -->
### Documentation Update Rules
- Update docs/llm/HANDOFF.md every time you make a change.
- Append an entry to docs/llm/HISTORY.md in every session.
- HISTORY format defaults to `any`: either `- YYYY-MM-DD - <LLM_NAME> - ...` or `YYYY-MM-DD - <LLM_NAME> - ...` is accepted. Set top-level `history_format: dash` or `history_format: no-dash` in `.dockit-config.yml` when a project wants strict enforcement.
- Projects with a phase-based roadmap can opt into semantic phase drift checks with `.dockit-config.yml` `orientation_drift.enabled: true`; this fails when entry docs describe a completed roadmap phase as "next".
- Put long-form rationale in docs/llm/DECISIONS.md and link to it from HANDOFF.
- Prefer ASCII-only in docs/llm/* to avoid Windows encoding issues.
<!-- DOCKIT-TEMPLATE:END doc-update-rules -->

<!-- DOCKIT-TEMPLATE:START doc-sync-rules -->
### Documentation Sync Rules
- Keep this file's "Current Focus" section synchronized with docs/llm/HANDOFF.md "Current Status".
- Keep docs/STRUCTURE.md synchronized with the actual repository file tree.
- Keep docs/PROJECT_CONTEXT.md synchronized with architectural reality.
- Version markers (`<!-- doc-version: X.Y.Z -->`) in documentation files are managed by `scripts/bump-version.sh`. See `docs/version-sync-manifest.yml` for the full list of tracked files.
<!-- DOCKIT-TEMPLATE:END doc-sync-rules -->

<!-- DOCKIT-TEMPLATE:START commit-policy -->
### Publish work before declaring completion

Follow `docs/PUBLICATION_CLOSEOUT.md`. Finished authorized source changes are
validated, reviewed, committed and published in the same session through the
owner's ordinary workflow. Do not stop at a suggested commit message or leave
work uncommitted/unpushed without a concrete blocker and retained handoff.
A local commit or a task-branch push is not default-branch completion. Preserve
concurrent work, secrets, signing/review safeguards and history; never force-push
or publish outside existing authority. Reconcile a refused ordinary push and
retry. After publication, run `scripts/dockit-publication.py --require-published`
once, then retire task resources through the owner tool and verify absence.
Offline `publication-state` warns during work; the live final gate must pass
before declaring publication complete. Report actual commit and publication,
checks and retained exceptions rather than only suggesting what to commit.
<!-- DOCKIT-TEMPLATE:END commit-policy -->

<!-- DOCKIT-TEMPLATE:START version-management -->
### Version Management
- Every commit that changes code/config files MUST include a version bump. The pre-commit hook enforces this.
- For version bumps, run `scripts/bump-version.sh <new_version>`; do not edit version strings manually.
- The bump script reads `docs/version-sync-manifest.yml` to update all tracked files atomically.
- Supported manifest marker types are `version-file`, `changelog`, `html-comment`, `json-version`, `yaml-info-version`, and `package-lock-version`.
- Validate sync with `scripts/check-version-sync.sh` (also available as pre-commit hook).
- Do not bump versions without consulting docs/VERSIONING_RULES.md for impact level (patch/minor/major).
- Do NOT batch multiple code commits without versioning. No exceptions.
<!-- DOCKIT-TEMPLATE:END version-management -->

<!-- DOCKIT-TEMPLATE:START independent-review-policy -->
### Independent Review Policy

The operator-wide Claude default is Opus 5.5, exact model
`claude-opus-5-5`, with high effort. This applies to Claude advisory/coauthor
work and independent source review unless the operator explicitly selects a
different model for the task. The operator's 2026-09-23 decision supersedes the
previous inherited Fable-first / quota-only Opus fallback preference.

1. Select the exact model explicitly for non-interactive review; do not use a
   floating `opus`, `best` or `default` alias as audit provenance.
2. Record effective model, effort, command, candidate revision/tree and validation
   packet in `docs/llm/REVIEWS.md` when present, otherwise the audited revision's
   HISTORY entry. Verify returned model metadata; a self-reported model name in
   the answer is not evidence. Do not silently substitute Fable, older Opus,
   Sonnet, Haiku or another model. If the selected model is unavailable or the
   provider changes it, preserve the packet and keep the required review gate
   open; continue only authorized work that does not depend on that verdict.
3. When durable Trace is enabled, keep non-commit object IDs such as tree hashes
   as plain text in HISTORY and HANDOFF Trace Anchors. Backtick-quoted hashes are
   reserved for commit provenance and must resolve as commits. Never remove
   backticks from a commit to bypass validation; classify a cross-repository
   commit with the Trace `external=repo@hash` field instead.

The auditor is independent and read-only: it reads primary files and evidence,
does not edit the candidate, and returns evidence-backed findings. The executor
must verify each finding, reconcile disagreements with the same auditor session
where practical, and preserve explicit unresolved disagreement for the operator.
A review verdict does not authorize build, deployment, runtime, secrets,
infrastructure, lifecycle or acceptance changes.

This synchronized section changes the model preference, not other project review
requirements. Explicit task-specific operator choices remain authoritative. A documented
operator-approved project model exception remains an exception until explicitly
superseded; exclusion alone is not approval of a different model. Other project
review constraints remain in force. Projects that exclude this section through
`.dockit-config.yml` must keep the exception and its authority visible.
The source policy belongs to LLM-DocKit; Claude Code's user `model` setting is a
separate runtime default and does not prove that project copies were synchronized.

Roles are model-independent: see `docs/AGENT_ROLES.md`. Separate role, family,
actual/requested model, client, account alias, session and task. Two accounts of
the same family do not satisfy a required cross-family independent review.
ForgeOS owns runtime assignment/routing; projects own scope and acceptance.
Unknown effective model metadata remains unknown, never inferred from an alias.

<!-- DOCKIT-TEMPLATE:END independent-review-policy -->

<!-- DOCKIT-TEMPLATE:START env-policy -->
### Environment Files (If Applicable)
- Do not edit generated .env.example files directly.
- Never change or remove existing credentials in .env or equivalent secret stores.
- If a new variable is needed, document it in the relevant README and ask the user to add it manually.
<!-- DOCKIT-TEMPLATE:END env-policy -->

## Current Focus (Snapshot)

Source of truth: docs/llm/HANDOFF.md.
- Last Updated: <YYYY-MM-DD - Author>
- Working on: <Feature or task>
- Status: <Short status summary>

Keep this section synchronized with the "Current Status" block in docs/llm/HANDOFF.md.

<!-- DOCKIT-TEMPLATE:START checklist -->
## Getting Started Checklist
- [ ] Read this entire file and update placeholders
- [ ] Review docs/PROJECT_CONTEXT.md
- [ ] Review docs/VERSIONING_RULES.md
- [ ] Read the current docs/llm/HANDOFF.md
- [ ] Install pre-commit hook: `cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
- [ ] Run `scripts/check-version-sync.sh` to verify version markers
- [ ] Confirm scope with the user
- [ ] Complete the work
- [ ] Update docs/llm/HANDOFF.md
- [ ] Add an entry to docs/llm/HISTORY.md
<!-- DOCKIT-TEMPLATE:END checklist -->

## Customization Notes for Maintainers
- Replace <PROJECT_NAME> with the actual project name.
- Define the conversation language (or remove the rule if not applicable).
- Remove or adapt any sections that do not align with your workflow (e.g., environment file policy).
- Populate docs/STRUCTURE.md with details about your repository layout.

## Quick Navigation
- Project Overview: docs/PROJECT_CONTEXT.md
- Architecture: docs/ARCHITECTURE.md if present; otherwise docs/ARCHITECTURE.md.example
- Version Rules: docs/VERSIONING_RULES.md
- Version Sync Manifest: docs/version-sync-manifest.yml
- Codex CLI Integration: docs/integrations/CODEX.md
- LLM Docs Index: docs/llm/README.md
- Current Work State: docs/llm/HANDOFF.md
- Change History: docs/llm/HISTORY.md
- Decision Rationale: docs/llm/DECISIONS.md
- Reviews (optional): docs/llm/REVIEWS.md
- Runbooks: docs/operations/

<!-- DOCKIT-TEMPLATE:START llm-communication -->
## LLM-to-LLM Communication
When handing off to another LLM:
1. Update docs/llm/HANDOFF.md with the current state and next steps.
2. Append an entry to docs/llm/HISTORY.md following the required format.
3. Ensure the snapshot in this file matches the latest status.
<!-- DOCKIT-TEMPLATE:END llm-communication -->

<!-- DOCKIT-TEMPLATE:START trace-protocol -->
## Trace Protocol

Every substantive assistant turn in a DocKit-governed session must begin with
a compact `Trace` header, then continue with the normal explanation in prose.
This includes execution, audit, design opinions, recommendations,
brainstorming, clarifying questions, status reports, and go/no-go calls.

A turn is substantive if the operator might need to find it when returning to
a multi-window workflow: it contains a decision, opinion, recommendation,
status, audit, action, or clarifying question. Non-substantive turns such as a
pure acknowledgement under 50 characters do not require Trace, but emitting
Trace is always safe. The header is for orientation; it does not replace the
message.

Required chat header fields:
- `Role`: `executor`, `auditor`, or `advisor`
- `Sent`: `YYYY-MM-DD HH:MM:SS <local-tz> (HH:MM:SS UTC)`. The order and
  precision are mandatory: local time first, UTC second in parentheses, seconds
  included on both sides.
- `Subject`: current task, question, recommendation, or commit hash/title being implemented or audited
- `Resulting state`: what this message leaves true after it is sent
- `Repo state`: local branch vs origin and worktree status verified now
- `Validation`: checks run and result
- `Next gate`: who/what should act next

Time verification:
- Verify `Sent` before writing it; do not infer or mentally convert the time.
- If shell access is available, run both:
  ```sh
  date -u '+%Y-%m-%d %H:%M:%S UTC'
  TZ=Europe/Madrid date '+%Y-%m-%d %H:%M:%S %Z'
  ```
- Replace `Europe/Madrid` with `trace_protocol.local_timezone` from
  `.dockit-config.yml` when the project sets one.
- If the agent cannot verify the clock, write:
  `Sent: unverified client time YYYY-MM-DD HH:MM:SS <claimed-tz>`.
- Prefer generating the close-out scaffold immediately before sending it:
  ```sh
  scripts/dockit-trace-status.sh --format text --role executor --subject "<commit/task>" \
    --validation "<checks>" --next "<next gate>"
  ```
  This prints current HEAD, local/upstream state, worktree cleanliness, version,
  and verified local/UTC time from git/date instead of relying on memory.

Recommended `Resulting state` shape:

```text
Resulting state: HEAD=<hash|unchanged (hash)>; version=<version|none>; gate=<opened|cleared|blocked|superseded|next-slice>; <short note>
```

Examples:

```text
Resulting state: HEAD=01f90bb; version=4.9.1; gate=cleared; supersedes audit of d6fc816
Resulting state: HEAD=unchanged (01f90bb); version=none; gate=cleared; ready for next slice
Resulting state: HEAD=unchanged (d6fc816); version=none; gate=blocked; requires executor patch v4.9.1
```

Use clear prose after the header. Explain what changed, why it matters, what
was verified, and what risk remains.

When reading an older Trace block, do not treat its `Repo state` as current
without checking the tree again. If the `Sent` time is more than a few minutes
old, or another LLM/operator may have acted since it was written, verify
`git status`, `git log -1`, and the current clock before acting on the report.

When `trace_protocol.enabled: true` is set in `.dockit-config.yml`, the durable
half is enforced by `scripts/dockit-validate-session.sh --check trace-protocol`:
- `docs/llm/HANDOFF.md` must contain a `## Trace Anchor` section.
- HANDOFF Trace Anchor commit times may use `YYYY-MM-DD HH:MM:SS UTC` or
  `YYYY-MM-DD HH:MM UTC`.
- A committed HANDOFF Trace Anchor is a durable repo-side anchor, not a
  guaranteed live HEAD pointer. Prefer neutral labels such as `Subject:` or
  `Trace target:`. Projects can set
  `trace_protocol.reject_current_anchor_label: true` to fail anchors labelled
  `Current target:` or `Current audit target:`.
- `docs/llm/HISTORY.md` entries dated on or after `trace_protocol.since` that
  reference backtick-quoted commit hashes must end with an inline footer:
  `Trace: role=executor|auditor|advisor; commits=hash1,hash2; state=...; validation=...; next=...`
- `commits=` contains only commits from the current repository. When the same
  HISTORY entry names a backtick-quoted commit from another repository, insert
  `external=repo@hash[,repo@hash];` immediately after `commits=...;`. The exact
  external hash must also appear in backticks in the entry. Example:
  `Trace: role=executor; commits=abc1234; external=forgeos@def5678; state=...; validation=...; next=...`

Projects can set the local timezone used in `Sent` with:

```yaml
trace_protocol:
  local_timezone: Europe/Madrid
```

Projects that do not use Trace-oriented LLM windows can disable the chat-side
convention with:

```yaml
trace_protocol:
  enabled: false
```

### Capability-based presentation

Use `scripts/dockit-trace-status.sh` to collect one snapshot. `--format auto`
(the default) emits a static HTML card when the client provides the writable
`ORCA_CHAT_SCRATCH_DIR` capability; show the returned `orca-visual` directive.
Use `--language es` for Spanish operator views. Without the capability, or if
rendering fails, it returns text; `--format text` explicitly selects the
compatible terminal form. `docs/integrations/ORCA.md` defines the adapter.
No container, polling or network is needed. Delivered HTML is retained chat
history with a fresh filename, not disposable scratch. HANDOFF/HISTORY stay
textual; neither presentation replaces review provenance or freshness checks.

<!-- DOCKIT-TEMPLATE:END trace-protocol -->

<!-- DOCKIT-TEMPLATE:START delivery-evidence -->
## Optional Delivery Controls

For repeated delivery/infrastructure attempts, adopt `docs/DELIVERY_CONTRACT.md`
in the actual project mutation command. The project runs the real prerequisite
probe, records its observation, and calls `scripts/dockit-delivery-record.sh begin`
immediately before mutation; it records outcome and recovery afterward.

Copying scripts or a passing session validator is not integration. Require the
project's rerunnable negative test to demonstrate zero mutation calls for a failed
prerequisite, plus a current candidate-bound integration receipt. The journal
preserves attempt/review counts across sessions and versions. Repeating a failed
causal state or exhausting a budget requires bounded reassessment, never automatic
approval. Existing independent review and operational authority still apply.
Recovery must remain available independently of ordinary delivery checks.

Keep source publication, deployment and actual user acceptance separate. A short
HANDOFF names the observed result, current blocker and next concrete step.
<!-- DOCKIT-TEMPLATE:END delivery-evidence -->

<!-- DOCKIT-TEMPLATE:START do-not-touch -->
## Do Not Touch Zones
Use the Do Not Touch section in docs/llm/HANDOFF.md to flag any files or areas that must remain unchanged without explicit approval from the user.
<!-- DOCKIT-TEMPLATE:END do-not-touch -->

<!-- DOCKIT-EXTERNAL-CONTEXT:START -->
<!-- DOCKIT-EXTERNAL-CONTEXT:END -->

<!-- DOCKIT-TEMPLATE:START footer -->
---

Every change must be documented. If you are unsure about a rule, ask the user before proceeding.
<!-- DOCKIT-TEMPLATE:END footer -->

<!-- DOCKIT-TEMPLATE:START workspace-ownership -->
### Parent-owned task workspaces that clean up behind themselves

The source root contains admitted primary projects. Tasks, experiments, reviews,
disk investigations and delivery branches belong to an existing project; their
folder names never make them independent projects. A new top-level project needs
an explicit operator purpose and `devenv admission add PROJECT` after validating
its canonical repository. Visibility is independent from lifecycle and sessions.

Work directly on the default branch in the project's primary checkout. Create a
task workspace only when another session or its uncommitted state occupies that
checkout: `task-workspace create --project OWNER --task ID --purpose "Specific
result" --reason "Why the primary cannot be used"` (add `--detach` where the
project publishes directly to main, such as Home Infra). Worktrees live under the
host's hidden worktree root; host-local locations stay out of portable records.
Read `docs/llm/WORK_INDEX.md` when present and `task-workspace status --project .`.

Closing a task workspace happens in the same session: publish to the default
branch, record the closed disposition (export/verify records where the project
keeps them), then run `task-workspace retire --project OWNER --task ID`. It
removes the checkout, its local branch and its merged origin branch only after
verifying a clean, published, unlocked and unused checkout whose ignored files
are regenerable caches. `task-workspace retire-branches` removes merged branches
left without a checkout. A task is not finished while a workspace, branch,
container, temporary directory or test service it created still exists, unless
its record names an owner, reason and deadline for keeping it. The
`workspace-leftovers` validator check fails on closed, unretired workspaces.

Retirement never covers unpublished, dirty, active, locked or custody-ambiguous
work: archive ignored evidence first and preserve unknown objects. Disposable
runtimes follow `docs/RUNTIME_LIFECYCLE.md`. Do not create task-named siblings
under the source root or auto-admit directories. The PATH guard protects
supported CLI workflows; direct Git binaries and other clients can bypass it.
<!-- DOCKIT-TEMPLATE:END workspace-ownership -->

## GitHub validation cost discipline

Before changing `.github/workflows`, read `docs/CI_EFFICIENCY.md`. Retain useful
checks, batch final reviewed publication, avoid duplicate branch/PR runs, and
stop unchanged quota retries. Paid usage and additional access require their
own authority. Existing adopters need explicit reviewed rollout.
