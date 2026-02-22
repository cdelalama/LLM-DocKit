# How to Use This Scaffold

This guide walks you through setting up a new project using LLM-DocKit.

## Quick Start (5 Minutes)

### 1. Fork or Clone This Repository

**Linux/macOS/Git Bash:**
```bash
git clone https://github.com/<your-username>/LLM-DocKit.git my-new-project
cd my-new-project
rm -rf .git
git init
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/<your-username>/LLM-DocKit.git my-new-project
cd my-new-project
Remove-Item -Recurse -Force .git
git init
```

### 2. Replace Project Name Placeholders

Search and replace the following placeholders throughout all files:

| Placeholder | Replace With | Where |
|-------------|--------------|-------|
| `<PROJECT_NAME>` | Your actual project name | All documentation files |
| `<CONVERSATION_LANGUAGE>` | Language for LLM conversations (e.g., Spanish, English) | [LLM_START_HERE.md](LLM_START_HERE.md) |
| `<YYYY-MM-DD>` | Current date in ISO format | [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md), [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) |

**Quick command (Linux with GNU sed)**:
```bash
# Replace all placeholders at once
find . -type f -name "*.md" -exec sed -i \
  -e 's/<PROJECT_NAME>/YourProjectName/g' \
  -e 's/<CONVERSATION_LANGUAGE>/Spanish/g' \
  -e "s/<YYYY-MM-DD>/$(date +%Y-%m-%d)/g" {} +
```

**macOS (BSD sed requires empty string after -i)**:
```bash
# Replace all placeholders at once
find . -type f -name "*.md" -exec sed -i '' \
  -e 's/<PROJECT_NAME>/YourProjectName/g' \
  -e 's/<CONVERSATION_LANGUAGE>/Spanish/g' \
  -e "s/<YYYY-MM-DD>/$(date +%Y-%m-%d)/g" {} +
```

**Windows (PowerShell)**:
```powershell
# Replace all placeholders at once
$projectName = "YourProjectName"
$language = "Spanish"
$today = Get-Date -Format "yyyy-MM-dd"

Get-ChildItem -Recurse -Filter *.md | ForEach-Object {
    (Get-Content $_.FullName -Encoding UTF8) `
        -replace '<PROJECT_NAME>', $projectName `
        -replace '<CONVERSATION_LANGUAGE>', $language `
        -replace '<YYYY-MM-DD>', $today |
    Set-Content $_.FullName -Encoding UTF8
}
```

### 3. Customize Core Documentation

Edit these files with your project details:

#### [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
- **Vision**: What problem are you solving?
- **Objectives**: What are you building?
- **Stakeholders**: Who owns this?
- **Architecture**: High-level design

#### [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (Optional)
- Capture architecture, contracts, and roadmap/phases (keeps PROJECT_CONTEXT shorter).

#### [docs/STRUCTURE.md](docs/STRUCTURE.md)
- Document your actual folder structure
- Explain naming conventions
- Add onboarding notes

#### [LLM_START_HERE.md](LLM_START_HERE.md)
- Review all rules and adapt to your workflow
- Update the "Current Focus" section
- Remove sections that don't apply

### Optional: Pin the Scaffold Version (If You Forked LLM-DocKit)
If you want reproducible scaffolds, keep the upstream version information:
- `VERSION` (human-readable SemVer)
- `CHANGELOG.md` (what changed)

If you do not want scaffold metadata in your new project, remove those files after forking.

#### LLM Working Memory (`docs/llm/`)
- Start with [docs/llm/README.md](docs/llm/README.md) (what goes where)
- Keep [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) short and actionable
- Put long rationale in [docs/llm/DECISIONS.md](docs/llm/DECISIONS.md)

### 4. Initialize Your Project Structure

Choose what you need:

**For a web application:**
```bash
# Keep: src/, tests/, .github/
# Remove: scripts/ (unless you need build scripts)
rm -rf scripts/
```

**For infrastructure/DevOps:**
```bash
# Keep: scripts/, tests/
# Remove: src/ (or rename to infrastructure/)
rm -rf src/
```

**For a library/package:**
```bash
# Keep: src/, tests/, .github/
# Remove: scripts/ (or use for build tools)
```

**For CLI tools:**
```bash
# Keep: src/, scripts/, tests/
# Rename: src/ to cli/ or bin/
mv src/ cli/
```

**Important**: After removing unnecessary directories, review and customize [.gitignore](.gitignore) for your tech stack. The default includes patterns for Node.js, Python, Ruby, Go, and Rust. Remove or add sections as needed, and uncomment lock file ignores if desired.

### 5. Start Your First LLM Session

1. Share [LLM_START_HERE.md](LLM_START_HERE.md) with your LLM
2. Ask it to read [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
3. Start working on your first feature
4. **Important**: Ensure the LLM updates [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) and [docs/llm/HISTORY.md](docs/llm/HISTORY.md) after every change

## Keeping Downstream Projects in Sync (dockit-sync)

When LLM-DocKit improves (new scripts, updated rules, better checklist), your existing projects fall behind. The **dockit-sync** tool propagates template updates to all your projects without losing project-specific content.

### How It Works

Each file in the template has a **sync strategy** defined in `dockit-sync-manifest.yml`:

| Strategy | What it does | Example files |
|----------|-------------|---------------|
| `copy` | Overwrites downstream with template version | `scripts/bump-version.sh`, GitHub templates |
| `skip` | Never touches (100% project-specific) | `VERSION`, `CHANGELOG.md`, `docs/llm/HANDOFF.md` |
| `section-merge` | Replaces only marked sections, preserves everything else | `LLM_START_HERE.md` |
| `yaml-merge` | Merges by identity key, preserves local-only entries | `docs/version-sync-manifest.yml` |

### Section Markers in LLM_START_HERE.md

Template-managed sections are wrapped in markers:

```markdown
<!-- DOCKIT-TEMPLATE:START commit-policy -->
### Commit Message Policy
- Every response that includes code...
<!-- DOCKIT-TEMPLATE:END commit-policy -->
```

Content **between** markers gets updated by sync. Content **outside** markers (your project name, custom rules, Quick Navigation) is never touched.

### Opting In a Project

1. Create an empty `.dockit-enabled` file in the project root:
   ```sh
   touch .dockit-enabled
   ```

2. Add `DOCKIT-TEMPLATE:START/END` markers to your project's `LLM_START_HERE.md`, wrapping the sections that match the template. Leave your custom rules (Security, Architecture, etc.) **outside** the markers.

3. Establish the baseline (required before first sync):
   ```sh
   /path/to/LLM-DocKit/scripts/dockit-sync.sh --init-state --project /path/to/your-project
   ```

4. Preview what would change:
   ```sh
   /path/to/LLM-DocKit/scripts/dockit-sync.sh --dry-run --project /path/to/your-project
   ```

5. Apply when ready:
   ```sh
   /path/to/LLM-DocKit/scripts/dockit-sync.sh --apply --project /path/to/your-project
   ```

### Checking All Projects at Once

```sh
scripts/dockit-sync-check.sh
```

Output:
```
  PROJECT                        STATUS       DETAILS
  -------                        ------       -------
  nas-backup                     CURRENT      v4.0.0
  cortex                         OUTDATED     v3.0.0 -> v4.0.0
  youtube2text                   NO_STATE     run --init-state
```

### Adoption Modes

Create `.dockit-config.yml` in your project root:

```yaml
# full: all template sections must have markers (missing = ERROR)
# partial: only marked sections are synced (missing = WARN, skip)
adoption_mode: full

# Sections to exclude from sync (optional)
exclude_sections:
  LLM_START_HERE.md:
    - llm-communication    # project has a completely rewritten version
```

### Safety Features

- **Dry-run by default**: `--apply` is required to make changes
- **Automatic backup**: every apply creates a backup in `.git/.dockit/backups/`
- **Conflict detection**: if you edited a section locally AND the template changed, the tool reports CONFLICT and rolls back
- **Auto-rollback**: if post-sync validation fails, all changes are reverted
- **Lock file**: prevents concurrent syncs on the same project

### Syncing All Projects

```sh
# Preview changes across all .dockit-enabled projects
scripts/dockit-sync.sh --dry-run --all

# Apply to all
scripts/dockit-sync.sh --apply --all
```

### Restoring from Backup

```sh
# List available backups
ls /path/to/project/.git/.dockit/backups/

# Restore a specific backup
scripts/dockit-sync.sh --restore 20260222_163000 --project /path/to/project
```

### Full CLI Reference

```
scripts/dockit-sync.sh [options]

  --dry-run          Show changes without applying (DEFAULT)
  --apply            Apply changes
  --init-state       Bootstrap: adopt current state as baseline
  --project PATH     Sync a single project
  --all              Sync all .dockit-enabled projects
  --src-root PATH    Root directory for projects (default: ~/src)
  --force            Overwrite even with conflicts
  --git-branch       Create git branch before applying
  --json             Report in JSON format
  --restore TS       Restore backup by timestamp
```

## Detailed Customization

### Update README.md
Replace the generic content in [README.md](README.md) with:
- Project description
- Installation instructions
- Usage examples
- Contribution guidelines

### Configure Versioning
Edit [docs/VERSIONING_RULES.md](docs/VERSIONING_RULES.md):
- Define where versions live in your project (e.g., `package.json`, `pyproject.toml`, script headers)
- Adapt the version bump rules to your workflow
- Add examples specific to your tech stack

### Set Up GitHub Templates (Optional)
If using GitHub, customize:
- [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)
- [.github/ISSUE_TEMPLATE/bug_report.md](.github/ISSUE_TEMPLATE/bug_report.md)
- Add more issue templates as needed (feature requests, documentation, etc.)

### Create Your First Runbook
Add operational procedures to [docs/operations/](docs/operations/):
- Deployment steps
- Rollback procedures
- Incident response
- Backup/restore processes

## Workflow Integration

### Working with LLMs

**Before each session:**
1. LLM reads [LLM_START_HERE.md](LLM_START_HERE.md)
2. LLM checks [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) for current state
3. LLM reviews [docs/VERSIONING_RULES.md](docs/VERSIONING_RULES.md) if touching versioned files

**After each session:**
1. LLM updates [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) with new status
2. LLM appends to [docs/llm/HISTORY.md](docs/llm/HISTORY.md) with format:
   ```
   YYYY-MM-DD - <LLM_NAME> - <Summary> - Files: [list] - Version impact: <yes/no>
   ```
3. LLM provides commit info in response

### Version Management

When bumping versions:
1. Consult [docs/VERSIONING_RULES.md](docs/VERSIONING_RULES.md) for impact level
2. Run `scripts/bump-version.sh <new_version>` to update all tracked files
3. Fill in the CHANGELOG.md section created by the bump script
4. Document in [docs/llm/HISTORY.md](docs/llm/HISTORY.md)
5. Update [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) "Current Versions" section (prose, not just marker)
6. Run `scripts/check-version-sync.sh` to validate

### Documentation Maintenance

Keep these files synchronized:
- [LLM_START_HERE.md](LLM_START_HERE.md) "Current Focus" <-> [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) "Current Status"
- [docs/STRUCTURE.md](docs/STRUCTURE.md) <-> actual folder structure
- [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) <-> architecture reality
- Version markers in documentation files: managed by `scripts/bump-version.sh`, tracked in [docs/version-sync-manifest.yml](docs/version-sync-manifest.yml)

## Common Scenarios

### Scenario 1: Pure Web App (React + Node.js)
```bash
# Structure
src/
  frontend/  # React components
  backend/   # Node.js API
tests/
  unit/
  integration/
docs/

# Update STRUCTURE.md with this layout
# Add package.json version tracking to VERSIONING_RULES.md
```

### Scenario 2: Python Data Science Project
```bash
# Structure
src/
  data/          # Data processing
  models/        # ML models
  notebooks/     # Jupyter notebooks
tests/
scripts/         # Training/evaluation scripts
docs/

# Update VERSIONING_RULES.md to track versions in __init__.py or pyproject.toml
```

### Scenario 3: Infrastructure as Code
```bash
# Structure
infrastructure/
  terraform/
  ansible/
  kubernetes/
scripts/         # Deployment scripts
docs/
  operations/    # Runbooks (critical for ops)

# Remove src/ and tests/ if not needed
# Focus on runbooks in docs/operations/
```

### Scenario 4: CLI Tool
```bash
# Structure
cli/             # Renamed from src/
  commands/
  utils/
tests/
scripts/         # Build/release scripts
docs/

# Add installation instructions to README.md
```

## Maintenance Tips

### Regular Updates
- Review [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) at the start of each day/session
- Archive old [docs/llm/HISTORY.md](docs/llm/HISTORY.md) entries yearly (keep last 12 months visible)
- Update [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) when architecture changes

### Multi-LLM Collaboration
- Different LLMs can work on the same project by following the handoff protocol
- [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) is the single source of truth for current state
- "Do Not Touch" section prevents conflicts

### Human + LLM Collaboration
- Humans should also update [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) and [docs/llm/HISTORY.md](docs/llm/HISTORY.md)
- Use the same commit message format for consistency
- Review LLM changes before committing

## Troubleshooting

**Q: LLM doesn't follow the rules**
- Ensure [LLM_START_HERE.md](LLM_START_HERE.md) is shared at the beginning of every session
- Explicitly remind the LLM to update HANDOFF and HISTORY
- Check if rules are marked as "non-negotiable"

**Q: Documentation gets out of sync**
- Run `scripts/check-version-sync.sh` to detect version drift
- Run `scripts/dockit-sync-check.sh` to see which projects need updating
- Install the pre-commit hook: `cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
- Make documentation updates part of your definition of "done"

**Q: dockit-sync says "missing markers for section"**
- Your project's `LLM_START_HERE.md` needs `<!-- DOCKIT-TEMPLATE:START/END -->` markers around the template sections
- If you only want to sync some sections, set `adoption_mode: partial` in `.dockit-config.yml`

**Q: dockit-sync shows CONFLICT**
- You edited a section locally AND the template changed the same section
- Review both versions and decide which to keep
- Use `--force` to accept the template version, or update the template to include your changes

**Q: "No sync state found" error**
- Run `--init-state` first: `scripts/dockit-sync.sh --init-state --project /path`
- This is required once per project to establish the baseline (it does not modify any files)

**Q: Too much history in HISTORY.md**
- Archive entries older than 12 months to `docs/llm/HISTORY_ARCHIVE_<YEAR>.md`
- Keep recent history visible for context

**Q: Multiple people/LLMs editing at once**
- Use Git branches for parallel work
- Merge HANDOFF.md carefully, keeping the most recent "Current Status"
- Append all HISTORY.md entries chronologically

## Next Steps

1. [ ] Complete the Quick Start steps above
2. [ ] Customize [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)
3. [ ] Update [docs/STRUCTURE.md](docs/STRUCTURE.md) with your layout
4. [ ] Have your first LLM session
5. [ ] Commit everything and push to your repository

## Getting Help

- Review the [PiHA-Deployer example](https://github.com/cdchushig/PiHA-Deployer) that inspired this scaffold
- Open an issue in the [LLM-DocKit repository](https://github.com/cdchushig/LLM-DocKit/issues)
- Adapt this scaffold to your needs - it's meant to be flexible!

---

**Remember**: This scaffold is a starting point. Adapt it to your workflow, remove what you don't need, and add what makes sense for your project. The core value is the LLM handoff protocol and documentation discipline.
