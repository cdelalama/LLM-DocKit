# Changelog

All notable changes to this scaffold are documented in this file.

This project follows Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

## [4.7.1] - 2026-05-03

### Fixed

- `scripts/dockit-bootstrap-context.sh`: awk regex for extracting the
  "Recommended reading order:" section no longer exits early when there
  is a blank line between the header and the first numbered item.
  Repos that customise the LLM-DocKit template with a blank-line gap
  (e.g. `home-infra-protocol`'s `LLM_START_HERE.md`) were falling back
  to a generic 2-item list instead of extracting the full per-repo
  reading order. Surfaced during the 2026-05-03 smoke test of the v4.7.0
  primitive against the originally-failing repo. Fix: track a `started`
  flag in awk so the blank-line-exit only fires after the first numbered
  item has been captured. Verified post-fix: home-infra-protocol now
  emits its 7 real items (SPEC.md, PROJECT_CONTEXT.md, ARCHITECTURE.md,
  COMPLETION_RULE.md, HANDOFF.md, DECISIONS.md, this file); tomatic
  still emits 9 items; LLM-DocKit still emits 7 items (regression-clean).

## [4.7.0] - 2026-05-03

### Added

- `scripts/dockit-bootstrap-context.sh`: new POSIX shell script that emits the
  project's mandatory onboarding context as a Claude Code SessionStart
  `additionalContext` JSON payload (`--json`, default) or as plain text for
  pasting into non-Claude LLM sessions (`--human`). Reads
  `LLM_START_HERE.md` dynamically to extract the "Recommended reading order:"
  list, so updates to that section flow through without changing the script.
  Output is short (~1.5 KB at default project) — points the LLM at the docs
  to read rather than concatenating them, staying well under the 10 KB
  SessionStart hook limit. Closes `docs/DOWNSTREAM_FEEDBACK.md` DF-033.
- `.claude/settings.json` `SessionStart` hook entry calling
  `scripts/dockit-bootstrap-context.sh --json`. Wrapped in
  `sh -c 'if [ -x ... ]; then ... ; fi'` so downstream copies of
  `settings.json` that arrive before the script gracefully degrade to a
  no-op rather than break sessions. Inverse counterpart of the existing
  `Stop` hook (which guards session end via
  `dockit-validate-session.sh`); together they bracket the session.
- `dockit-sync-manifest.yml`: new entry registering
  `scripts/dockit-bootstrap-context.sh` with `strategy: copy` so downstream
  projects pick it up on the next `dockit-sync` pass.
- `docs/DOWNSTREAM_FEEDBACK.md` DF-033: "Passive onboarding instructions in
  repo docs do not enforce session-start context loading." Captures the
  failure mode observed in a 2026-05-03 Codex CLI session inside
  `home-infra-protocol`, where the agent gave a partial ecosystem opinion
  because it had not read `LLM_START_HERE.md` despite the rule being
  declared at lines 9 and 87. Status: implemented (this release ships
  the cure for Claude Code; non-Claude LLMs use `--human` mode manually
  until they grow equivalent hooks).

### Changed

- `docs/llm/DECISIONS.md`: D-007 added — "Session-start onboarding is
  enforced mechanically, not by prose." Records the precedent that future
  rules of the form "always read X before doing Y" should ship as a hook
  + script, not as another prose paragraph.


## [4.6.1] - 2026-05-01

### Fixed

- `scripts/dockit-init-project.sh`: new projects were being created
  on the `master` branch instead of `main` (depended on the host
  system's `init.defaultBranch`). The orchestrator and skill in
  `home-infra-protocol` document `git push origin main` and the
  whole ecosystem standardises on `main`. Fixed by adding
  `git symbolic-ref HEAD refs/heads/main` immediately after
  `git init -q`. Portable to Git < 2.28 (no dependency on the
  `-b main` flag). Found by GPT-5 review during smoke testing of
  the orchestrator.

## [4.6.0] - 2026-05-01

### Added

- `scripts/dockit-init-project.sh`: from-scratch project initializer.
  Closes the gap between `/adopt-dockit` (which bolts the scaffold
  onto an existing repo) and the manual instructions in `HOW_TO_USE.md`
  (clone + strip + sed + git init). One command produces a clean,
  validator-green project at `0.1.0`. Behavior:
  - Copies tracked files only via `git archive HEAD` (drafts and
    untracked notes in the source LLM-DocKit checkout never leak
    into the new project — addresses the same risk class as DF-027).
  - Strips DocKit-internal meta files: `HOW_TO_USE.md`,
    `docs/DOWNSTREAM_FEEDBACK.md`, `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`,
    `dockit-sync-manifest.yml`, `scripts/dockit-sync.sh`,
    `scripts/dockit-sync-check.sh`, and `scripts/dockit-init-project.sh`
    itself (template-only utilities).
  - Resets live operational docs (`CHANGELOG.md`,
    `docs/llm/HANDOFF.md`, `docs/llm/HISTORY.md`,
    `docs/llm/DECISIONS.md`) to fresh stubs so DocKit's own DF-027 /
    plaud-mirror / D-001..D-006 content does not leak.
  - Substitutes `<PROJECT_NAME>`, `<CONVERSATION_LANGUAGE>`,
    `<YYYY-MM-DD>` placeholders in remaining `*.md`/`*.yml`/`*.json`.
  - Runs `scripts/bump-version.sh 0.1.0` to set VERSION and sync
    doc-version markers atomically.
  - Initializes a fresh git repo with a single
    "chore: initial scaffold from LLM-DocKit X.Y.Z" commit.
  - Refuses to overwrite an existing target directory; exits with a
    clear error if the source is not a git repository (no working-
    tree fallback — that path was the source of leaks during early
    smoke-testing).
- Strict scope: no GitHub remote creation, no push, no
  ecosystem-specific profile application, no `~/.claude/` edits.
  Those concerns belong to higher layers (orchestrator scripts in
  consumer repositories such as `home-infra-protocol`).
- `HOW_TO_USE.md` rewritten so the new "Quick Start (one command,
  recommended)" section ships above the existing manual flow, which
  is preserved as "Quick Start (manual)" for Windows / CI cases.

### Changed

- `docs/llm/HANDOFF.md`: Current Status, Session Focus, and
  Patch 4.6.0 Outcome blocks reflect the new feature. The previously
  speculated "next 4.6.0 = pre-commit checks for DF-027(b) +
  DF-002 + DF-008" plan is acknowledged and explicitly deferred to a
  future v4.7.0 — that work is unrelated to from-scratch
  initialization and is not bundled here.

### Fixed

## [4.5.5] - 2026-04-25

### Added
- DF-027 in `docs/DOWNSTREAM_FEEDBACK.md`: "`git add -u` silently skips new untracked files; commit succeeds, workspace stays green, origin is broken." A specialisation of DF-024 ("documenting without verifying") at the git-mechanics layer, distinct enough from DF-014 ("commit accumulation across version bumps") to deserve its own entry. The plaud-mirror v0.4.17 commit (`d1bc317`) was published broken to `origin/main`: the LLM created two new source files with the Write tool, used `git add -u && git commit`, and the new files stayed `??`-untracked while the commit succeeded with the modified-only changes. Local workspace stayed green because tsc/node read from filesystem; a fresh clone would have failed `npm install && npm run build` at import-resolution. Closed in plaud-mirror v0.4.18 (commit `d2f17f2`) by re-staging the missing files explicitly + version bump + CHANGELOG entry naming the broken release. DF-027 ships as `partially implemented (plaud-mirror v0.4.18)` on the adopter-symptom axis; the protocol-level pre-commit hook check is `open` and proposed in detail (grep the staged tree for relative-path imports that resolve to files NOT present in the staged set, error if any are missing).

### Notes
- Adopter count: 27 entries, 5 `implemented`, 2 `partially implemented` (DF-026, DF-027), 20 `open`. The `partially implemented` count is now plural — exactly the case the v4.5.4 legend extension was anticipating.
- The most actionable next bump is the pre-commit hook proposed by DF-027(b). It's mechanical, false-positive risk is low (skip dynamic imports / module aliases), and it would have prevented the v0.4.17 → v0.4.18 cycle entirely. Pair it naturally with DF-002 (orphan-marker scan) and DF-008 (empty-CHANGELOG guard) — three pre-commit checks that target concrete failure modes already observed in the field. That would be a meaningful v4.6.0 (minor: new validator capabilities) rather than another DF entry release.

## [4.5.4] - 2026-04-24

### Changed
- DF-026 Status updated from `open` to `partially implemented (plaud-mirror v0.4.17)`. The adopter (plaud-mirror v0.4.17) extracted the previously local-to-App.tsx pure UI helpers (`formatDuration`, `formatBytes`, `formatRecordingsMetric`, `computeMissing`, `formatDeviceLabel`, `formatDeviceShortName`, `coerceNonNegativeInteger`, `summarizeRun`, `describeBusy`) into `packages/shared/src/formatting.ts` and added 12 dedicated `node:test` tests hooked into the root suite. That closes the helper-level half of DF-026 — a regression in any of those would now actually fail the suite. Component-level rendering tests (tabs persistence + switch, collapsible card ARIA + mount/unmount of BackfillPreview, debounced fetch behaviour) remain `open` because they would require introducing vitest+jsdom+@testing-library/react as new dependencies, which is a non-trivial scope addition deferred for a later patch. Protocol-level template change (split DocKit's "every new runtime case must come with tests" rule by layer, with explicit waiver path in HISTORY for UI cases) also still `open`.

### Notes
- Adopter count: 26 entries, 5 `implemented`, 1 `partially implemented` (DF-026), 20 `open`.
- The partial-implementation pattern is itself worth tracking. DF-024's convention requires every entry citing `<file>:<line>` to ship with a fix-commit OR a `TODO:` block. Adding `partially implemented (<adopter-version>)` as a third valid Status value extends that convention naturally — the adopter half of the work is closed in a concrete release while the protocol half stays visible as ongoing. If this pattern recurs (likely; many DF entries have an adopter-symptom axis and a protocol-level axis), the file's "Status legend" header should grow this value formally. Watch for it on the next pass.

## [4.5.3] - 2026-04-24

### Added
- DF-025 in `docs/DOWNSTREAM_FEEDBACK.md`: "Runbook promises a configuration the codebase doesn't actually support." Specialisation of DF-024: the drift is code-vs-docs, not doc-vs-doc. The plaud-mirror instance is textbook — v0.4.15 rewrote DEPLOY_PLAYBOOK with `node:20-alpine` as an acceptable Docker fallback example, but the committed Dockerfile forced `SHELL ["/bin/bash", "-lc"]` and Alpine ships no bash. An operator would have hit a build error. Closed in plaud-mirror v0.4.16 by dropping both SHELL directives and verifying an Alpine build end-to-end. Proposed mitigations: template rule adding a `Verified:` annotation convention to concrete runbook examples; session-end addendum to DF-024(c) requiring the LLM to attempt any new runbook example before declaring the session done.
- DF-026: "Backend tests go green while UI-state features (tabs, localStorage, collapse) ship with only a build-shell smoke test." Observed in plaud-mirror v0.4.14 — the tabs + collapsible-backfill + localStorage-persistence feature set shipped with 53/53 passing, but the only web-side test is a build-shell smoke check. A regression flipping any of those to broken would still report PASS. Not a validator concern (test coverage is adopter-owned), but DocKit's template LLM_START_HERE rule "every new runtime case must come with explicit tests" is not layer-differentiated; adopter LLMs interpret it as "backend tests count" and ship UI changes without asserting the new state. Proposed: template rule distinguishing backend-runtime vs UI-state cases, with an explicit waiver path in HISTORY for UI cases left untested (so the gap is acknowledged, not silently skipped).

### Changed
- DF-025 Status: `implemented (plaud-mirror v0.4.16)` on the concrete symptom (Alpine build now works), but the protocol-level `Verified:` annotation convention is `open`. Same pattern as DF-001/002/003: adopter symptom fixed, systemic cure pending.

### Notes
- Adopter count: 26 entries now, 4 implemented (DF-005, 001, 002, 003 — the last three from v0.4.15 adopter fixes, noted in v4.5.2 — and now DF-025 joins as 5 `implemented` on the adopter-symptom axis). 21 open. DF-024 and DF-026 remain `open` — those are protocol-level not adopter-level and the fix is template/validator work, not just a downstream patch.

## [4.5.2] - 2026-04-24

### Added
- DF-024 in `docs/DOWNSTREAM_FEEDBACK.md`: "Documenting drift is not fixing drift." Distinct failure mode from DF-010: the LLM HAS noticed the content problem and turned the noticing into a polished DF entry — then declared the work complete while the underlying instance stays broken. Observed directly on 2026-04-24: DF-001/002/003 were written at v4.5.0 with precise file:line citations in plaud-mirror, and the plaud-mirror instances remained broken until a second GPT-5 review at v4.5.2/plaud-mirror v0.4.15 forced the actual fix. Proposed mitigations: (a) convention that every DF citing `<file>:<line>` in an adopter must either ship with a fix-commit OR carry explicit `TODO:` remediation block, (b) stretch validator check that cross-references DF entries against adopter git log, (c) session-end ritual requiring review of every DF written in session for "fix vs Status truthfulness".

### Changed
- DF-001, DF-002, DF-003 Status lines updated from `open` to `implemented (plaud-mirror v0.4.15)` with a pointer to the concrete fix that closed each instance. The protocol-level checks proposed in each entry's body remain `open` — the adopter-specific symptom is gone but the systemic cure is still ahead.
- Meta-observation at the bottom of the file unchanged in wording; DF-024 is the new through-line of this release, threaded in below the last entry.

### Notes
- This release's value is primarily epistemic: it names a failure mode the LLM had been performing without realising it. No validator or template change ships. The three concrete adopter symptoms (DEPLOY_PLAYBOOK Kali, HOW_TO_USE orphan, HANDOFF stale "Next:") were fixed in plaud-mirror v0.4.15 and carry `Fixed-in:` pointers in their Status lines so future readers of DOWNSTREAM_FEEDBACK see the full audit trail — entry, fix, residual protocol work.

## [4.5.1] - 2026-04-24

### Added
- Seven more seed entries in `docs/DOWNSTREAM_FEEDBACK.md` (DF-017..DF-023) after a second pass over the plaud-mirror adoption experience focused on LLM-native workflow patterns the first 16 entries missed. Categories: context compaction checkpoint discipline (DF-017), parallel persistence stores with no bridge — LLM personal auto-memory vs `docs/llm/*` (DF-018), cross-LLM review metadata (DF-019), graduated validator execution modes — fast/normal/strict/paranoid (DF-020), external-context version correlation not just edit-trigger (DF-021), HISTORY entry quality lint (DF-022), DocKit self-application without external reviewer (DF-023).
- Extended meta-observation at the bottom of `DOWNSTREAM_FEEDBACK.md` now names two distinct patterns instead of one: "structural vs semantic" (DF-001, DF-006, DF-008, DF-011, DF-016, DF-019) and "single-fact-in-multiple-places-with-no-sync-contract" (DF-015, DF-018, DF-021) — the latter is a generalization of what `version-sync-manifest.yml` already solves for version strings.

### Changed
- `docs/llm/HANDOFF.md`: Current Status refreshed to point at all 23 entries (not just the first 16) and flags DF-023 as DocKit's own blind spot. Also corrects a pre-existing drift: the "Project Summary" block still said `Current version: 4.4.0` at v4.5.0 — now cites `VERSION` file as the single source of truth instead of carrying a prose version string.

### Notes
- Still no validator or template change. The content of the log is the deliverable. The three most actionable next steps implied by the 23 entries are: (a) implement DF-002 (orphan marker scan) and DF-008 (empty CHANGELOG guard) first — they are low-cost and high-signal; (b) adopt the graduated-mode framing from DF-020 as the surface on which DF-001/006/013/018/021 attach; (c) codify DF-018 by publishing a small `/export-memory` skill so adopters stop losing auto-memory lessons to the protocol.

## [4.5.0] - 2026-04-24

### Added
- `docs/DOWNSTREAM_FEEDBACK.md`: living log of drift, gap, usability and process issues observed when DocKit is adopted by real projects. Each entry (`DF-NNN`) records source project + version, category, observation with file:line references, and the protocol-level implication (what DocKit should change to address it). The doc opens with 16 seed entries collected from `plaud-mirror`'s v0.1.0 → v0.4.13 experience — four flagged explicitly by a GPT-5 review (DEPLOY_PLAYBOOK Kali drift, orphan HOW_TO_USE, stale "Next:" snapshots, asymmetric enforcement) and the rest distilled from personal-memory feedback the downstream LLM assistant had saved to itself.
- `dockit-sync-manifest.yml`: explicit `skip` entry for `docs/DOWNSTREAM_FEEDBACK.md` so the feedback log stays DocKit-only and is never propagated to adopters.

### Changed
- `docs/llm/HANDOFF.md`: Current Status updated to reference the new feedback-intake workflow and points at the 16 seeded entries for anyone picking up protocol work next.

### Notes
- No code or validator change ships in this minor. The feedback log is intentionally a preparatory artifact — the entries in it are the prioritised backlog for the next round of validator / template work (semantic-content checks, orphan-marker detection, prose-version lag, CHANGELOG emptiness guard, deploy-verify playbook snippet, decision supersession syntax).
- Follow-up items DF-001..DF-004 correspond directly to the four concrete drifts a sibling LLM found in the plaud-mirror repo on 2026-04-24; DF-005 is an already-implemented check documented here for audit trail; DF-006..DF-016 extend the log into adjacent problem classes observed across the same project over the preceding week.

## [4.4.0] - 2026-03-01

### Added
- `.claude/skills/adopt-dockit/SKILL.md`: `/adopt-dockit` skill for adding LLM-DocKit scaffold to existing repositories (7-step guided process: analyze project, copy templates, replace placeholders, personalize with intelligence, technical setup, validate, optional external context)

## [4.3.0] - 2026-03-01

### Added
- `check_external_triggers` check in `dockit-validate-session.sh`: detects local file changes matching `update_triggers` globs and produces WARN (non-blocking)
- WARN status support in validator (non-blocking, shown in output, does not affect exit code)
- `--claude-rules` flag in `dockit-generate-external-context.sh`: generates `.claude/rules/external-context-triggers.md` with glob frontmatter (no absolute paths)
- `warnings` field in validator JSON output

## [4.2.0] - 2026-03-01

### Added
- `scripts/dockit-generate-external-context.sh`: generates External Context section in LLM_START_HERE.md from `.dockit-config.yml` configuration (--dry-run/--apply, idempotent)
- `check_external_context` check in `dockit-validate-session.sh`: validates external doc path and read files exist (opt-in, skippable via `DOCKIT_SKIP_EXTERNAL=1`)
- `DOCKIT-EXTERNAL-CONTEXT:START/END` markers in `LLM_START_HERE.md` template
- D-006: External context uses separate markers to avoid sync interference

## [4.1.0] - 2026-03-01

### Added
- Pre-commit hook Check 2: BLOCKS commits when code/config files are staged without VERSION (enforcement, not just warning)
- `.ps1` added to code file extensions pattern in pre-commit hook

### Changed
- `LLM_START_HERE.md`: version management section now requires per-commit versioning (not per-session)
- Pre-commit hook checks renumbered (5 checks total, was 4)

## [4.0.0] - 2026-02-22

### Added
- `dockit-sync-manifest.yml`: sync strategy manifest (copy/skip/section-merge/yaml-merge per file)
- `scripts/dockit-sync.sh`: template sync tool with dry-run, apply, backup/rollback, conflict detection, lock, JSON output, git-branch support (~1200 lines, POSIX sh)
- `scripts/dockit-sync-check.sh`: downstream project status checker (CURRENT/OUTDATED/NO_STATE)
- `<!-- DOCKIT-TEMPLATE:START/END -->` section markers in `LLM_START_HERE.md` for 9 syncable sections
- `.dockit-enabled` opt-in marker file concept for downstream projects
- `.dockit-config.yml` human-managed config (adoption_mode, exclude_sections) for downstream projects
- `.git/.dockit/` runtime directory (state, lock, backups) -- auto-ignored by git

### Changed
- `LLM_START_HERE.md`: 9 sections now wrapped in DOCKIT-TEMPLATE markers for automated sync

### Breaking
- Downstream projects must add DOCKIT-TEMPLATE markers to their `LLM_START_HERE.md` for section-merge to work
- Downstream projects must create `.dockit-enabled` to opt in to sync
- Downstream projects must run `--init-state` to establish baseline before first sync

## [3.0.0] - 2026-02-20

### Added
- `docs/version-sync-manifest.yml`: single source of truth for version-synced files
- `scripts/bump-version.sh`: automated version bump across all tracked files (POSIX sh)
- `scripts/check-version-sync.sh`: drift validator with `--staged` mode (POSIX sh)
- `scripts/pre-commit-hook.sh`: git hook template enforcing version sync and HISTORY updates
- `<!-- doc-version: X.Y.Z -->` HTML comment markers in all tracked documentation files
- Documentation sync rules in `LLM_START_HERE.md` (snapshot <-> HANDOFF, STRUCTURE <-> filesystem)
- Pre-commit hook installation step in Getting Started Checklist

### Changed
- `LLM_START_HERE.md`: version management now references bump script instead of manual edits
- `docs/VERSIONING_RULES.md`: rewritten with manifest-based workflow, concrete 6-step process
- `README.md`: converted from scaffold description to downstream project template with placeholders
- `docs/STRUCTURE.md`: updated tree and table with new scripts and manifest
- `HOW_TO_USE.md`: version management, doc maintenance, and troubleshooting sections updated

### Breaking
- Version markers (`<!-- doc-version: X.Y.Z -->`) are now required on line 1 of all tracked docs
- `README.md` is no longer a scaffold description (that content lives in `HOW_TO_USE.md`)
- Manual version editing is replaced by `scripts/bump-version.sh`

## [2.0.0] - 2025-12-17

### Added
- LLM working-memory index: `docs/llm/README.md`
- Decision log template: `docs/llm/DECISIONS.md`
- Optional reviews template: `docs/llm/REVIEWS.md`
- Optional architecture template: `docs/ARCHITECTURE.md`
- Optional operations runbooks: `docs/operations/API_CONTRACT.md`, `docs/operations/DEPLOY_PLAYBOOK.md`
- Operations index in `docs/operations/README.md`
- Generated/runtime dirs section in `docs/STRUCTURE.md`

### Changed
- `docs/llm/HANDOFF.md` emphasizes brevity and linking to DECISIONS
- `LLM_START_HERE.md`, `README.md`, and `HOW_TO_USE.md` updated to reference the new docs

