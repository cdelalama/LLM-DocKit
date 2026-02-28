<!-- doc-version: 4.0.0 -->
# LLM Work Handoff

This file is the current operational snapshot. Keep it short.
Long-form rationale lives in `docs/llm/DECISIONS.md`.

## Current Status
- Last Updated: 2026-02-22 - Claude Opus 4.6
- Session Focus: dockit-sync tool system (v4.0.0)
- Status: Core implementation complete. All scripts created and tested. Rollout to downstream projects pending.

## Immediate Context
LLM-DocKit now has a sync tool system to propagate template updates to downstream projects. The system uses 4 strategies: copy (scripts), skip (project-specific), section-merge (LLM_START_HERE.md), yaml-merge (version-sync-manifest.yml). Sync scripts run only from LLM-DocKit root (control-plane), never copied to downstream.

## Active Files
- dockit-sync-manifest.yml (new: sync strategy per file)
- scripts/dockit-sync.sh (new: main sync tool, ~1200 lines)
- scripts/dockit-sync-check.sh (new: status checker)
- LLM_START_HERE.md (modified: 9 DOCKIT-TEMPLATE markers added)
- HOW_TO_USE.md (updated: full sync tool docs, troubleshooting)
- docs/STRUCTURE.md (updated: new files in tree and table)
- README.md (updated: HOW_TO_USE.md in docs table)
- CHANGELOG.md (updated: v4.0.0 entries)

## Current Versions
- LLM-DocKit: 4.0.0
- sync_tool_version: 1.0.0

## Top Priorities
1. Rollout first wave: nas-backup (full) + youtube2text (partial) -- add markers to their LLM_START_HERE.md
2. Rollout remaining projects
3. Commit + tag v4.0.0

## Key Decisions (Links)
- Restricted flat grammar for manifest (not generic YAML parser) -- see plan file
- Runtime in .git/.dockit/ (auto-ignored, no .gitignore changes needed)
- CONFLICT without --force triggers full rollback, no state written
- OUTDATED = string compare (not SemVer), (partial) is detail suffix not state

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
