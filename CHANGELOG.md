# Changelog

All notable changes to this scaffold are documented in this file.

This project follows Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

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

