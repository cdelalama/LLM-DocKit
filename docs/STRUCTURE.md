# Repository Structure Guide

Document the repository structure here. Replace this paragraph and the example tree below with the project-specific layout once the tree stabilizes.

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
+- .dockit-config.yml            (sync + trace config -- downstream/scaffold)
+- docs/
|  +- PROJECT_CONTEXT.md
|  +- ARCHITECTURE.md            (optional live architecture)
|  +- ARCHITECTURE.md.example    (optional starter template; copied to ARCHITECTURE.md when real)
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
|  +- dockit-validate-session.sh (validates LLM documentation state)
|  +- test-validator.sh          (smoke-tests validator edge cases)
|  +- dockit-generate-external-context.sh (generates External Context section)
+- .claude/
|  +- settings.json              (Claude Code hook configuration)
|  +- rules/
|  |  +- require-docs-on-code-change.md (path-triggered doc reminder)
|  +- skills/
|     +- update-docs/
|     |  +- SKILL.md              (/update-docs convenience command)
|     +- adopt-dockit/
|        +- SKILL.md              (/adopt-dockit: add scaffold to existing repo)
+- .github/
|  +- workflows/
|     +- doc-validation.yml      (CI documentation validation)
+- src/ (optional)
+- tests/ (optional)
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
| scripts/dockit-validate-session.sh | Validates HANDOFF/HISTORY/DECISIONS/version-sync state | Required for enforcement |
| scripts/test-validator.sh | Smoke-tests validator edge cases in throwaway repos | Recommended before validator changes |
| scripts/dockit-sync.sh | Propagates template updates to downstream projects | Template only |
| scripts/dockit-sync-check.sh | Reports sync status of all downstream projects | Template only |
| scripts/dockit-generate-external-context.sh | Generates External Context section in LLM_START_HERE.md from .dockit-config.yml | Downstream + template |
| .dockit-enabled | Empty marker file opting a project into sync | Downstream only |
| .dockit-config.yml | Human-managed sync/config file (adoption_mode, exclude_sections, external_context, trace_protocol) | Downstream + new scaffolds |
| .git/.dockit/ | Auto-generated sync runtime (state, lock, backups) | Downstream only, inside .git/ |
| src/ | Application or library source code | Optional |
| tests/ | Automated tests | Optional |
| .claude/settings.json | Claude Code hook configuration (Stop, PostToolUse, PreCompact) | Claude Code only |
| .claude/rules/ | Path-triggered rules for Claude Code | Claude Code only |
| .claude/skills/ | Custom slash commands for Claude Code | Claude Code only |
| .github/workflows/doc-validation.yml | CI validation for PRs | Recommended |
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
