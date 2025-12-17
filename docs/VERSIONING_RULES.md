# Versioning Rules

## Version Format
Use Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

## Version Location
Document where version identifiers live in your project (e.g., VERSION="x.y.z" at the top of scripts, package.json, or pyproject.toml).

Current version sources:
- <File or module>: <Version>
- <File or module>: <Version>

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
When a change affects multiple files within the same component or module, update all relevant version identifiers to keep them aligned.

## Update Process
1. Determine the impact level (patch, minor, major).
2. Locate all affected version identifiers.
3. Update version numbers and document the rationale in docs/llm/HISTORY.md.
4. Reflect the change in docs/llm/HANDOFF.md (or a dedicated changelog) so the next contributor is aware.

## Environment Variables (If Applicable)
- Avoid editing generated .env.example files directly; update the source .env or secrets management system and regenerate the template.
- Never commit real credentials.
- When adding new variables, document them and communicate the change in docs/llm/HISTORY.md and the relevant README.

## Tips
- When in doubt, choose the higher-impact version bump to avoid underreporting changes.
- Keep versioning consistent between code, documentation, and distribution artifacts.
- Record every version change in the history log with reasoning.
