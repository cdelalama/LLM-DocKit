# Repository Structure Guide

Use this template to document how the repository is organized. Update the table below once your folders and files are in place.

## Top-Level Layout
```
<PROJECT_ROOT>/
+- README.md                    (project introduction and quick start)
+- LLM_START_HERE.md             (mandatory reading for LLM contributors)
+- VERSION                       (project version, source of truth)
+- CHANGELOG.md                  (user-visible change log)
+- HOW_TO_USE.md                 (scaffold setup guide for humans)
+- dockit-sync-manifest.yml      (sync strategies per file -- template only)
+- .dockit-enabled               (opt-in marker for sync -- downstream only)
+- .dockit-config.yml            (sync config: adoption_mode -- downstream only)
+- docs/
|  +- PROJECT_CONTEXT.md
|  +- ARCHITECTURE.md            (optional)
|  +- STRUCTURE.md                (this file)
|  +- VERSIONING_RULES.md
|  +- version-sync-manifest.yml  (lists files tracked for version sync)
|  +- llm/                       (LLM working memory)
|  +- operations/                 (runbooks)
+- scripts/
|  +- bump-version.sh            (updates version markers in all tracked files)
|  +- check-version-sync.sh      (validates version markers match VERSION)
|  +- pre-commit-hook.sh         (git pre-commit hook template)
|  +- dockit-sync.sh             (sync template to downstream -- template only)
|  +- dockit-sync-check.sh       (check downstream sync status -- template only)
+- src/ (optional)
+- tests/ (optional)
+- .github/ (optional)
```

## Directory Descriptions
| Path | Purpose | Notes |
|------|---------|-------|
| docs/ | Central documentation, policies, and runbooks | Required |
| docs/llm/ | Handoff and history for LLM contributors | Required |
| docs/operations/ | Runbooks and operational procedures | Recommended |
| docs/version-sync-manifest.yml | Lists files requiring version markers | Required |
| dockit-sync-manifest.yml | Sync strategy per file (copy/skip/section-merge/yaml-merge) | Template only |
| scripts/bump-version.sh | Updates version markers in all tracked files | Required for version bumps |
| scripts/check-version-sync.sh | Validates version sync across tracked files | Required |
| scripts/pre-commit-hook.sh | Git pre-commit hook template | Recommended |
| scripts/dockit-sync.sh | Propagates template updates to downstream projects | Template only |
| scripts/dockit-sync-check.sh | Reports sync status of all downstream projects | Template only |
| .dockit-enabled | Empty marker file opting a project into sync | Downstream only |
| .dockit-config.yml | Human-managed sync config (adoption_mode, exclude_sections) | Downstream only |
| .git/.dockit/ | Auto-generated sync runtime (state, lock, backups) | Downstream only, inside .git/ |
| src/ | Application or library source code | Optional |
| tests/ | Automated tests | Optional |
| .github/ | Issue/PR templates and workflows | Optional |

## Generated / Runtime Directories (Optional)
Document directories that are produced at runtime/build time and should not be committed.

Examples:
- `output/` - generated artifacts
- `audio/` - downloaded or derived media
- `dist/` - build outputs
- `node_modules/` - dependencies (Node.js)
- `.venv/` - virtual environment (Python)

## Custom Modules or Packages
Document any additional folders specific to your project. Explain how they relate to the architecture in docs/PROJECT_CONTEXT.md.

## Naming Conventions
Outline conventions for file names, branches, environment variables, or other project-wide patterns.

## Onboarding Notes
Provide tips for new contributors (human or LLM) on where to start, which directories to explore first, and any caveats about legacy code or experimental features.
