<!-- doc-version: 4.9.6 -->
# Versioning Rules

## Version Format
Use Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

## Version Location
Document where version identifiers live in your project (e.g., VERSION="x.y.z" at the top of scripts, package.json, or pyproject.toml).

Current version sources:
- `VERSION`: primary source of truth for project version
- `docs/version-sync-manifest.yml`: lists all files tracked for version sync

## Scaffold Versioning (LLM-DocKit Itself)
If you are using LLM-DocKit as a scaffold/template repository, version the scaffold so downstream forks can pin a known structure.

Recommended sources of truth:
- Git tags / GitHub releases (e.g., `v2.0.0`)
- A `VERSION` file at repo root (e.g., `2.0.0`)
- `CHANGELOG.md` describing user-visible changes

## Version Bump Guidelines

### Patch (x.y.Z)
- Bug fixes or documentation updates
- Non-breaking maintenance tasks
- Logging improvements or refactoring without behaviour changes

### Minor (x.Y.z)
- Backward-compatible features
- Optional configuration additions
- New capabilities that do not break existing workflows

### Major (X.y.z)
- Breaking changes or required configuration updates
- Removals or incompatible behaviour changes
- Large architectural shifts that require operator action

## Synchronization Rules

All files requiring version markers are listed in `docs/version-sync-manifest.yml`.
This manifest is the single source of truth for version sync.

### Automated Version Bump
Run the bump script to update all tracked files atomically:
```
scripts/bump-version.sh <new_version>
```
The script reads the manifest and updates:
- `VERSION` file (plain version string)
- `<!-- doc-version: X.Y.Z -->` HTML comment markers in documentation files
- `CHANGELOG.md` section header (adds `## [X.Y.Z]` placeholder)
- JSON top-level `version` fields (`json-version`)
- OpenAPI-style YAML `info.version` fields (`yaml-info-version`)
- `package-lock.json` top-level `version` and `packages[""].version` fields (`package-lock-version`)

### Validation
Run the check script to detect version drift:
```
scripts/check-version-sync.sh
```
This exits 0 if all files match VERSION, or exits 1 with details on which files are out of sync.

### Pre-Commit Hook
Install the pre-commit hook to catch drift before it is committed:
```
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```
The hook:
1. Blocks commits where VERSION is staged but manifest targets are not.
2. Warns when code/config files change without a HISTORY.md update.
3. Runs check-version-sync.sh.

### Adding New Files to Version Tracking
To track a new file:
1. Add an entry to `docs/version-sync-manifest.yml`.
2. Choose the marker type that matches the file:
   - `version-file`: plain `X.Y.Z` on the first line.
   - `changelog`: `## [X.Y.Z]` section header.
   - `html-comment`: `<!-- doc-version: X.Y.Z -->`.
   - `json-version`: JSON top-level `"version": "X.Y.Z"`.
   - `yaml-info-version`: YAML `info.version`.
   - `package-lock-version`: both package-lock top-level `version` and `packages[""].version`.
3. Insert the marker/value matching current `VERSION`.
4. Run `scripts/check-version-sync.sh` to verify.

Unknown marker types are errors. If a project needs a new marker shape, add
matching support to both `scripts/check-version-sync.sh` and
`scripts/bump-version.sh` before using it in the manifest.

## Update Process
1. Determine the impact level (patch, minor, major).
2. Run `scripts/bump-version.sh <new_version>` to update all tracked files.
3. Fill in the CHANGELOG.md section created by the bump script.
4. Update docs/llm/HANDOFF.md with the new version context (prose, not just marker).
5. Append a HISTORY.md entry documenting the version change rationale.
6. Run `scripts/check-version-sync.sh` to confirm everything is in sync.

## Environment Variables (If Applicable)
- Avoid editing generated .env.example files directly; update the source .env or secrets management system and regenerate the template.
- Never commit real credentials.
- When adding new variables, document them and communicate the change in docs/llm/HISTORY.md and the relevant README.

## Tips
- When in doubt, choose the higher-impact version bump to avoid underreporting changes.
- Keep versioning consistent between code, documentation, and distribution artifacts.
- Record every version change in the history log with reasoning.
