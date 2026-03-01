# Changelog

All notable changes to this scaffold are documented in this file.

This project follows Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

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

