<!-- doc-version: 4.7.0 -->
# LLM Work Handoff

This file is the current operational snapshot. Long-form rationale lives in `docs/llm/DECISIONS.md`.

## Pending session — Ecosystem Reconciliation

A multi-day deliberation on 2026-05-02→04 produced two cross-repo proposals AND surfaced a significant prior-art gap: `~/src/llm-council` (created 2026-03-01) substantially predates the `CONSENSUS_PROTOCOL_PROPOSAL.md` written this week. The reconciliation work is gated to a follow-up session.

**Master roadmap**: `~/src/home-infra/docs/SESSION_HANDOFF_2026-05-04_ECOSYSTEM_RECONCILIATION.md`

**For LLM-DocKit specifically**: do NOT implement `docs/CONSENSUS_PROTOCOL_PROPOSAL.md` until Session 4 of the roadmap closes its merge plan. The proposal in this repo conflicts with `~/src/llm-council/docs/PROTOCOL_PROPOSAL.md` and Session 4 reconciles them.

DFs whose ownership and full expansion are pending Session 4: DF-031, DF-032 in `docs/DOWNSTREAM_FEEDBACK.md` (both have content; what Session 4 decides is which repo owns the cure and how it ships).

## Current Status
- Last Updated: 2026-05-03 - Claude Opus 4.7 (1M context) + GPT-5 (concur) + Carlos (arbiter)
- Session Focus: Cut **v4.7.0** (minor) shipping the SessionStart-side enforcement primitive — `scripts/dockit-bootstrap-context.sh` + `.claude/settings.json` SessionStart hook + `dockit-sync-manifest.yml` entry — closing **DF-033** (passive onboarding instructions in repo docs do not enforce session-start context loading). New decision **D-007** records the precedent that future "always read X at session start" rules ship as a hook + script, not as more prose. Counterpart of D-005 (session-end enforcement); together they bracket the session.
- Status: **Mechanical cure shipped on the Claude Code axis.** The new POSIX script reads `LLM_START_HERE.md` dynamically to extract the recommended reading order and emits a Claude Code `additionalContext` JSON payload (~1.5–2.4 KB; under the 10 KB SessionStart limit) with a small protocol the LLM must follow (`Onboarding loaded.` or `Onboarding skipped: <reason>` as the first line of the first substantive reply). `--human` mode of the same script is the manual workaround for non-Claude LLMs (Codex CLI, Cursor, web ChatGPT) until those tools grow equivalent hooks. Smoke-tested in both LLM-DocKit (1905 bytes JSON) and tomatic (9-item reading order, ~2.4 KB JSON), `python3 -m json.tool` validates output. Tomatic adopted directly in this same session (script + settings.json copied without waiting for `dockit-sync`); other downstream projects close on next sync pass. Adopter count of DF entries: 30 (DF-033 marked `implemented` on the Claude axis; rollout to other LLMs remains advisory). Previous session focus (CONSENSUS_PROTOCOL_PROPOSAL) carried forward — gated on Session 4 of the ecosystem reconciliation roadmap above.
- Pending Proposals: `docs/CONSENSUS_PROTOCOL_PROPOSAL.md` (carried forward; Session 4 gated); `docs/HOOKS_ENFORCEMENT_PROPOSAL.md` (untracked, pre-existing); `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md` (untracked, pre-existing).

## Patch 4.7.0 Outcome
- `scripts/dockit-bootstrap-context.sh` (new, ~7 KB, POSIX sh, zero deps): SessionStart-side counterpart of `dockit-validate-session.sh`. Reads `LLM_START_HERE.md` "Recommended reading order:" section and emits an `additionalContext` JSON payload (`--json`, default) or plain text (`--human`) for the operator to paste into non-Claude LLM sessions. Includes `--quiet` and `--project PATH` options; project root resolution via `git rev-parse --show-toplevel` with script-dir fallback. JSON escaping done with awk (POSIX, no jq dependency). Graceful degradation: emits nothing if `LLM_START_HERE.md` is missing (does not break sessions in non-LLM-DocKit repos).
- `.claude/settings.json`: new SessionStart hook block calling the script with `--json`. Wrapped in `sh -c 'if [ -x scripts/dockit-bootstrap-context.sh ]; then ...; fi'` so downstream copies that arrive before the script no-op gracefully. Stop / PostToolUse / PreCompact hooks unchanged.
- `dockit-sync-manifest.yml`: new entry `- path: scripts/dockit-bootstrap-context.sh strategy: copy` registered immediately after `dockit-validate-session.sh`, so downstream projects pick the script up on next `dockit-sync` pass alongside the matching `.claude/settings.json` (also `copy`).
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-033 added at `Status: implemented` (Claude axis) with full Observation / Protocol implication / Cross-protocol relationship / Mitigation sections. Related: DF-005, DF-015, DF-024, DF-031. Inverse counterpart of `docs/HOOKS_ENFORCEMENT_PROPOSAL.md`.
- `docs/llm/DECISIONS.md`: D-007 added — "Session-start onboarding is enforced mechanically, not by prose." Records the precedent for future "always read X at session start" rules.
- Cross-repo: tomatic gets `scripts/dockit-bootstrap-context.sh` + the matching SessionStart entry in `.claude/settings.json` applied directly in this session (not via `dockit-sync`) so the failure mode is closed for the project under active work; tomatic HANDOFF/HISTORY updated. Other downstream projects (`plaud-mirror`, `home-infra-protocol`, `infra-portal`, `llm-council`) close the scaffold side on next operator-driven `dockit-sync` pass — but the Codex CLI hook covers them all today via the global user-level config (see below).
- Codex CLI axis closed (post-4.7.0, doc-only follow-up). Operator-side wiring in `~/.codex/config.toml` (`[features] codex_hooks = true` + `[[hooks.SessionStart]]` calling the central LLM-DocKit script with `--project "$(git rev-parse --show-toplevel)"`) — Codex's SessionStart hook accepts the exact same `hookSpecificOutput.additionalContext` JSON shape as Claude Code, so the same script drives both LLMs without modification. Smoke-tested 2026-05-03 in `home-infra-protocol` (the originally-failing repo): Codex's first substantive reply began with `Onboarding loaded.` followed by ecosystem-aware content (cited version 0.3.0, deployment evidence contract, intent-vs-telemetry rule). DF-033 status updated to "implemented (Claude Code + Codex CLI axes)"; D-007 follow-ups updated. Cursor / Aider remain pending until they grow SessionStart equivalents. CHANGELOG 4.7.0 not amended — the user-level Codex wiring is operator-side workflow, not a scaffold artefact (the scaffold ships the script + Claude wiring + Codex JSON-shape compatibility; the wiring is operator-owned).
- Minor refinement filed as candidate 4.7.1 patch (see DECISIONS D-007 follow-ups): awk regex in the bootstrap script exits early on a blank line between "Recommended reading order:" and the numbered list. Affects repos that customise the LLM-DocKit template with a blank-line gap (e.g. home-infra-protocol). Hook still fires and protocol still works; only the per-repo reading-order extraction is degraded to a generic 2-item fallback. Not blocking. Operator-decided whether to ship 4.7.1 now or fold into a later patch.

## Patch 2026-05-03 Outcome
- `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`: new self-contained proposal formalising the deliberation primitive that has been in informal use across recent sessions. Roles (proposer / critic / arbiter), invocation thresholds (contract changes / multi-repo / security / multi-week reversibility / precedent-setting), mechanics (N rounds, classify outcome, terminate), recording format (structured `REVIEWS.md` entry preserving causality, not transcript), failure modes (non-convergence, arbiter unavailable, supersession, critic capture), and explicit relationship with `DOWNSTREAM_FEEDBACK.md` + `*_PROPOSAL.md`. Acceptance criteria included for the future implementing session that wires the protocol into LLM_START_HERE / docs/llm/README templates.
- `docs/llm/REVIEWS.md`: rewritten from the legacy stub into a structured audit trail. First entry (2026-05-03) records the consensus run that produced this very proposal — the protocol applied to itself. Six load-bearing decisions documented with causal reasoning; four explicit rejections. Legacy informal format kept as backward-compatibility appendix.
- `docs/DOWNSTREAM_FEEDBACK.md` DF-029 status → `accepted` with cross-reference to the proposal (per the file's legend: `accepted` = listed in a `*_PROPOSAL.md` and committed to the roadmap, which is exactly the current state). The DF moves to `partially implemented` only when the template-side changes (LLM_START_HERE block, REVIEWS template, README pointer) actually ship in a release. Validator-side cure (`--check deployed-version`) remains a separate open follow-up.

## Do Not Touch (for parallel sessions)

These files are present in the working tree but deliberately untracked, owned by the operator, and **must not be staged or committed by parallel sessions**:

- `docs/DEFERRED_NEXT_VERSION.md` — operator's planning notes for v4.7.0+, ongoing.
- `docs/HOOKS_ENFORCEMENT_PROPOSAL.md` — operator's draft proposal, not yet ready to land.
- `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md` — operator's draft proposal, not yet ready to land.
- `documento.md` — operator's scratch notes.

Sessions that need to stage changes should use explicit paths (`git add <path>`), never `git add -A` or `git add .`. The `dockit-init-project.sh` script in this repo is robust against these (uses `git archive HEAD` so untracked files never leak); manual sessions need the same discipline.

## Patch 4.6.1 Outcome (previous session)
- `scripts/dockit-init-project.sh`: added `git symbolic-ref HEAD refs/heads/main` immediately after `git init -q`. Portable to any Git version (no dependency on `git init -b main` from 2.28+). Smoke test confirms `main` from the first commit.
- `CHANGELOG.md`: 4.6.1 section explains the bug and the fix; references the GPT-5 review that surfaced it.

## Patch 4.6.0 Outcome (carried forward from previous session)
- `scripts/dockit-init-project.sh`: new POSIX `sh` script. Inputs: `<project-name>` plus optional `--target-dir`, `--language`, `--source` flags. Outputs a self-contained new project ready for first session. The script:
  1. Validates inputs (slug pattern, target absent, source is a git repo with VERSION).
  2. `git archive HEAD | tar -x` from the source DocKit checkout into the target directory (tracked files only — drafts in the source working tree never leak).
  3. Removes DocKit-internal meta files: `HOW_TO_USE.md`, `docs/DOWNSTREAM_FEEDBACK.md`, `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`, `dockit-sync-manifest.yml`, `scripts/dockit-sync.sh`, `scripts/dockit-sync-check.sh`, `scripts/dockit-init-project.sh` itself.
  4. Resets live operational docs (`CHANGELOG.md`, `docs/llm/HANDOFF.md`, `docs/llm/HISTORY.md`, `docs/llm/DECISIONS.md`) to fresh stubs — so DocKit's own DF entries / D-001..D-006 / session history don't leak into the new project.
  5. Substitutes `<PROJECT_NAME>`, `<CONVERSATION_LANGUAGE>`, `<YYYY-MM-DD>` and similar placeholders in remaining `*.md`/`*.yml`/`*.json`.
  6. Runs `scripts/bump-version.sh 0.1.0` to set VERSION and sync doc-version markers atomically.
  7. Initializes a fresh git repository with a single "chore: initial scaffold from LLM-DocKit X.Y.Z" commit.
- Strict scope respected: no GitHub remote, no push, no ecosystem-profile application, no global config edits. Higher-layer orchestrators (such as a future `home-infra-protocol/integrations/dockit/new-homelab-project.sh`) call this script as their first step and add their own concerns on top.
- `HOW_TO_USE.md` reorganized: the new "Quick Start (one command, recommended)" section is now the canonical path; the previous manual flow remains available as "Quick Start (manual)" for Windows / CI environments without the helper script.
- Smoke test: ran the script three times against `/tmp/smoke-init` while iterating. Two real bugs caught and fixed before commit — (a) `tar` from the working tree leaked five untracked DocKit drafts (`documento.md`, `LLM_DOCKIT_CE_V2_PROPOSAL.md`, `HOOKS_ENFORCEMENT_PROPOSAL.md`, `DEFERRED_NEXT_VERSION.md`, `EXTERNAL_CONTEXT_PLUGIN_PLAN.md`) into the new project; switched to `git archive HEAD` and added a hard-fail when source has no `.git`. (b) The fresh `CHANGELOG.md` had no `## [` anchor for `bump-version.sh` to insert before, leaving the new project's `[0.1.0]` section empty; fixed by emitting the section directly in the stub. Final smoke run: validator 6/6 PASS, 8 doc-version targets in sync at 0.1.0.

### Pre-existing v4.5.x backlog (still relevant, deferred to v4.7.0)

### Feedback intake workflow
- Downstream adopter observes a problem → summarises it into a DF-NNN entry in `docs/DOWNSTREAM_FEEDBACK.md` of this repo (fields: Source, Date, Category, Status, Observation, Protocol implication).
- DocKit maintainer reviews the log when planning a bump; open entries become candidate work.
- When a fix lands, the entry is updated to `Status: implemented` with a pointer to the commit/doc change, NOT deleted.
- Rejected entries also stay in place with rationale.

### Prior session context (v4.4.0, 2026-03-23 - Claude Opus 4.6)
Read-only session — reviewed full project state, summarized completed Phase 1 work, identified pending items (git tags, uncommitted changes, pilot sessions remaining), outlined short/medium/long-term roadmap. Left in place here as the last technical snapshot before v4.5.0.

## Project Summary

**LLM-DocKit** is a documentation scaffold for LLM-assisted projects. It solves the problem of memory loss between LLM sessions by providing:
- `docs/llm/HANDOFF.md` — operational snapshot (this file)
- `docs/llm/HISTORY.md` — append-only change log per session
- `docs/llm/DECISIONS.md` — durable architectural decisions with rationale
- `LLM_START_HERE.md` — mandatory rules for any LLM working on the project
- Version sync tooling (bump-version.sh, check-version-sync.sh, pre-commit hook)
- Downstream template sync (dockit-sync.sh, 1192 lines POSIX sh, 4 strategies)

**Repository:** https://github.com/cdelalama/LLM-DocKit
**Current version:** see `VERSION` (single source of truth — prose strings here drift; the file does not)
**Tech stack:** POSIX shell scripts only, zero external dependencies

## The Core Problem

LLM_START_HERE.md says "update HANDOFF and HISTORY every session" but this is purely advisory. LLMs forget. On 2026-02-28, HANDOFF.md was modified but its own `Last Updated` field was not changed, and HISTORY.md received no entry. The rules existed; they were not followed.

**Root cause:** compliance depends on LLM discipline, not on system enforcement.

---

## Decision Lock (2026-03-01)

Confirmed by human owner after 4 rounds of cross-LLM review (Claude Opus 4.6 + ChatGPT Codex GPT-5). Full review history in `docs/llm/HISTORY.md`.

### Execution Order: A -> B -> C

Three initiatives exist for evolving LLM-DocKit. They are **layers, not alternatives**:

```
Layer 3: Code Factory recs (C) .... improves quality of rules and contracts
Layer 2: CE V2 (B) ................ defines workflows, modes, session structure
Layer 1: Hook Enforcement (A) ..... guarantees rules are followed
Layer 0: LLM-DocKit v4.0.0 ........ the current scaffold base
```

Without Layer 1 (enforcement), Layers 2 and 3 are advisory — the same problem we have today. A is the foundation that makes B and C enforceable.

### Phase 1 Scope (Initiative A — locked)

Implement now, pilot 10 sessions, then decide B/C with real data.

**Components:**
1. `scripts/dockit-validate-session.sh` — portable POSIX validator (checks: handoff-date, history-entry, decisions-referenced, version-sync, external-context, external-triggers)
2. `.claude/settings.json` — Stop hook (blocking), PostToolUse nudge (non-blocking), PreCompact reminder
3. `.claude/rules/require-docs-on-code-change.md` — path-triggered rule
4. `.claude/skills/update-docs/SKILL.md` — convenience `/update-docs` command
5. Extend `scripts/pre-commit-hook.sh` — call validator at commit time
6. `.github/workflows/doc-validation.yml` — CI safety net for PRs

**Enforcement cascade:**
```
Stop hook (Claude Code)     <- Catches drift in real-time (best)
  |
  v  (if LLM tool has no hooks)
Pre-commit hook             <- Catches drift at commit time (good)
  |
  v  (if commit bypasses hooks)
CI validation               <- Catches drift at PR time (safety net)
  |
  v  (if CI skipped)
Manual: run validate script <- Human runs it (last resort)
```

**Blocking semantics:**
- Stop/SubagentStop: block via exit code 2 or JSON `{"decision": "block", "reason": "..."}`
- PostToolUse/PreCompact: non-blocking feedback only

**Acceptance criteria:**
1. Trying to stop with stale HANDOFF/HISTORY is blocked in Claude Code
2. Commit with stale docs is blocked by pre-commit
3. PR with stale docs fails CI
4. Updating HANDOFF+HISTORY in same session unblocks all gates
5. False-positive rate stays low across 10+ sessions

### Design Constraints for Future Compatibility

The validator must be extensible for future B/C integration:
- Check functions are modular (add new checks without modifying existing ones)
- Support optional `--check <name>` flag to run specific checks only
- JSON output format can grow (add fields, never remove)
- If B's monthly HISTORY sharding is adopted later, only the `history-entry` check function changes
- If B's `work_unit_id` or session manifests are adopted, they become new check functions

### Initiative B: CE V2 (deferred, split into subfases)

**Document:** `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md` (untracked, 407 lines)
**Status:** Deferred until Phase 1 pilot data available. Too large for single pilot — split into:
- B1: Traceability (work_unit_id, session manifests)
- B2: Review discipline (monthly reviews, SHA pinning)
- B3: Solutions library (candidate/canonical lifecycle)

Adopt only parts that solve problems demonstrated during pilot.

### Initiative C: Code Factory Recommendations (deferred)

**Document:** `documento.md` (untracked, 264 lines, Spanish)
**Status:** Separate policy milestone. Key items (risk tiers, CONTRACT.yaml, SHA discipline) adopt only if pilot data shows need.

---

## Files in This Repository

### Committed (in git)
- `VERSION` -> 4.4.0
- `scripts/dockit-sync.sh` -> template propagation (1192 lines)
- `scripts/dockit-sync-check.sh` -> downstream status checker
- `scripts/bump-version.sh` -> atomic version bump
- `scripts/check-version-sync.sh` -> version drift validator
- `scripts/pre-commit-hook.sh` -> git hook template
- `scripts/dockit-validate-session.sh` -> documentation enforcement validator (Phase 1 + external-context)
- `scripts/dockit-generate-external-context.sh` -> External Context section generator
- `.claude/settings.json` -> Claude Code hook configuration (Phase 1)
- `.claude/rules/require-docs-on-code-change.md` -> path-triggered doc reminder
- `.claude/skills/update-docs/SKILL.md` -> /update-docs convenience command
- `.claude/skills/adopt-dockit/SKILL.md` -> /adopt-dockit skill for existing repos
- `.github/workflows/doc-validation.yml` -> CI validation for PRs
- `dockit-sync-manifest.yml` -> sync strategies per file
- `docs/version-sync-manifest.yml` -> version-tracked files
- `LLM_START_HERE.md` -> mandatory LLM rules (9 template sections)
- `HOW_TO_USE.md` -> complete setup guide
- Full docs/ structure (see docs/STRUCTURE.md)

### Untracked (local only, not in git)
- `docs/HOOKS_ENFORCEMENT_PROPOSAL.md` — initial hooks proposal (superseded by this Decision Lock)
- `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md` — RFC for Compound Engineering v2 (Initiative B, 407 lines)
- `documento.md` — comparative analysis: LLM-DocKit vs Code Factory (Initiative C, 264 lines, Spanish)

## Current Versions
- LLM-DocKit: 4.4.0
- sync_tool_version: 1.0.0

## Top Priorities
1. Pilot: 10 sessions with enforcement active in LLM-DocKit repo
2. ~~Git tags~~ done (v4.0.0, v4.1.0, v4.2.0 — v4.3.0 pending after commit)
3. Evaluate pilot data and decide B/C adoption
4. Rollout to downstream projects (nas-backup, youtube2text) — after pilot

## Key Decisions (Links)
- D-001: Restricted flat grammar for manifest — see docs/llm/DECISIONS.md
- D-002: Runtime in .git/.dockit/ — see docs/llm/DECISIONS.md
- D-003: CONFLICT without --force triggers full rollback — see docs/llm/DECISIONS.md
- D-004: OUTDATED = template_version string compare, not SemVer — see docs/llm/DECISIONS.md (corrected 2026-03-01)
- D-005: Pre-commit blocks product code commits without VERSION bump — see docs/llm/DECISIONS.md
- D-006: External context uses separate markers (DOCKIT-EXTERNAL-CONTEXT) — see docs/llm/DECISIONS.md

## Do Not Touch
- scripts/bump-version.sh, scripts/check-version-sync.sh (template-managed, synced via copy)
- dockit-sync-manifest.yml schema (schema_version: 1)

## External Context Plugin

Design: `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`

**v1 (implemented, v4.2.0):** Generation script + `check_external_context` in validator. Projects declare external doc repos in `.dockit-config.yml`. Populates `LLM_START_HERE.md` between `DOCKIT-EXTERNAL-CONTEXT` markers. Validates path + file existence. `DOCKIT_SKIP_EXTERNAL=1` skips in CI.

**v1.1 (implemented, v4.3.0):** `check_external_triggers` in validator (WARN when local changes match update_triggers). `--claude-rules` flag generates `.claude/rules/external-context-triggers.md` with glob frontmatter (no absolute paths).

## Claude Code Documentation References (verified 2026-03-01)
- Hooks (17 events): https://docs.anthropic.com/en/docs/claude-code/hooks
- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Memory & rules: https://docs.anthropic.com/en/docs/claude-code/memory
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
