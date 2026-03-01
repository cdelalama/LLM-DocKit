<!-- doc-version: 4.0.0 -->
# LLM Work Handoff

This file is the current operational snapshot. Keep it short.
Long-form rationale lives in `docs/llm/DECISIONS.md`.

## Current Status
- Last Updated: 2026-03-01 - Claude Opus 4.6
- Session Focus: Governance audit and documentation alignment
- Status: Core tooling stable (v4.0.0). Governance gaps fixed (HANDOFF/HISTORY/DECISIONS realigned). Rollout to downstream projects pending.

## Immediate Context
LLM-DocKit now has a sync tool system to propagate template updates to downstream projects. The system uses 4 strategies: copy (scripts), skip (project-specific), section-merge (LLM_START_HERE.md), yaml-merge (version-sync-manifest.yml). Sync scripts run only from LLM-DocKit root (control-plane), never copied to downstream.

## Active Files
- docs/llm/HANDOFF.md (updated: date, status, priorities, active files)
- docs/llm/HISTORY.md (updated: added missing entries for 2026-02-28 and 2026-03-01)
- docs/llm/DECISIONS.md (updated: formalized D-001 through D-004 from HANDOFF key decisions)

## Current Versions
- LLM-DocKit: 4.0.0
- sync_tool_version: 1.0.0

## Top Priorities
1. Git tag v4.0.0 (commit 29b6c70 already exists, only tag missing)
2. Rollout first wave: nas-backup (full) + youtube2text (partial) -- add DOCKIT-TEMPLATE markers to their LLM_START_HERE.md
3. Rollout remaining downstream projects
4. Decide on CE V2 proposal adoption (see docs/LLM_DOCKIT_CE_V2_PROPOSAL.md, untracked)

## Key Decisions (Links)
- D-001: Restricted flat grammar for manifest -- see docs/llm/DECISIONS.md
- D-002: Runtime in .git/.dockit/ -- see docs/llm/DECISIONS.md
- D-003: CONFLICT without --force triggers full rollback -- see docs/llm/DECISIONS.md
- D-004: OUTDATED = string compare, not SemVer -- see docs/llm/DECISIONS.md

## Do Not Touch
- scripts/bump-version.sh, scripts/check-version-sync.sh, scripts/pre-commit-hook.sh (template-managed, synced via copy)
- dockit-sync-manifest.yml schema (schema_version: 1)

## Open Questions
- **Infrastructure plugin**: Add an optional mechanism for projects to reference a central infrastructure docs repo (e.g., `~/src/home-infra/docs/`). When a scaffolded project installs software, adds services, or changes versions, the LLM should automatically update the infra docs. This should be generic (not hardcoded to any specific path) — configurable via a file like `.llm-dockit.yml` or a section in the scaffold. The goal: any user of LLM-DocKit can point to their own infra repo, and all scaffolded projects inherit the cross-reference rule. Currently this is handled manually via `~/.claude/CLAUDE.md` global instructions, which is tool-specific and fragile.

## Testing Notes
- Syntax check: sh -n on both scripts -- PASS
- --help: displays usage correctly -- PASS
- --init-state on nas-backup: creates state.yml without modifying files -- PASS
- --dry-run on nas-backup: copy=SKIPPED (up to date), section-merge=ERROR (expected: no markers yet), yaml-merge=UPDATED -- PASS
- dockit-sync-check: reports nas-backup as CURRENT -- PASS
- --json output: valid JSON array -- PASS
- grep -c bug found and fixed (|| echo "0" caused double output) -- FIXED

---

Keep this file concise (ideally under two screens) and update it at the end of every session.
