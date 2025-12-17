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
1. Consult [docs/VERSIONING_RULES.md](docs/VERSIONING_RULES.md)
2. Update all related files in the same component
3. Document in [docs/llm/HISTORY.md](docs/llm/HISTORY.md)
4. Update [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) "Current Versions" section

### Documentation Maintenance

Keep these files synchronized:
- [LLM_START_HERE.md](LLM_START_HERE.md) "Current Focus" <-> [docs/llm/HANDOFF.md](docs/llm/HANDOFF.md) "Current Status"
- [docs/STRUCTURE.md](docs/STRUCTURE.md) <-> actual folder structure
- [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md) <-> architecture reality

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
- Set up a pre-commit hook to check HANDOFF/HISTORY have recent dates
- Make documentation updates part of your definition of "done"

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
