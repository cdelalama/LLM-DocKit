<!-- doc-version: 4.3.0 -->
# LLM Work Handoff

This file is the current operational snapshot. Long-form rationale lives in `docs/llm/DECISIONS.md`.

## Current Status
- Last Updated: 2026-03-01 - Claude Opus 4.6
- Session Focus: External Context plugin v1 + v1.1 implementation
- Status: v4.3.0. Phase 1 enforcement active. External Context plugin complete (v1: generation + existence, v1.1: trigger WARN + --claude-rules).

## Project Summary

**LLM-DocKit** is a documentation scaffold for LLM-assisted projects. It solves the problem of memory loss between LLM sessions by providing:
- `docs/llm/HANDOFF.md` — operational snapshot (this file)
- `docs/llm/HISTORY.md` — append-only change log per session
- `docs/llm/DECISIONS.md` — durable architectural decisions with rationale
- `LLM_START_HERE.md` — mandatory rules for any LLM working on the project
- Version sync tooling (bump-version.sh, check-version-sync.sh, pre-commit hook)
- Downstream template sync (dockit-sync.sh, 1192 lines POSIX sh, 4 strategies)

**Repository:** https://github.com/cdelalama/LLM-DocKit
**Current version:** 4.3.0
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
- `VERSION` -> 4.3.0
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
- LLM-DocKit: 4.3.0
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
