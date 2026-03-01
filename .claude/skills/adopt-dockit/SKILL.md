# Skill: Adopt LLM-DocKit into Existing Project

Add the LLM-DocKit documentation scaffold to a project that does not have it yet. Typical use case: the user cloned a GitHub repo and wants to work on it with LLM assistance.

**Template source:** `~/src/LLM-DocKit/`

## Instructions

When the user invokes `/adopt-dockit`, perform these steps in order:

### 1. Analyze the project

- Read `README.md` (if it exists) to understand: project name, purpose, tech stack.
- Explore the directory structure to detect what already exists.
- Deduce **project name** from the directory name or README title.
- Deduce **conversation language** from `~/.claude/CLAUDE.md` global instructions (look for "Conversation with the user" rule). If not found, ask the user.
- Confirm the project name and language with the user before proceeding.

### 2. Copy template files

Read each file from `~/src/LLM-DocKit/` and write it to the project. Create directories as needed (`docs/`, `docs/llm/`, `docs/operations/`, `scripts/`, `.claude/rules/`, `.claude/skills/update-docs/`, `.github/workflows/`, `.github/ISSUE_TEMPLATE/`).

**Always copy** (template-managed utilities — overwrite if they exist):
- `scripts/bump-version.sh`
- `scripts/check-version-sync.sh`
- `scripts/pre-commit-hook.sh`
- `scripts/dockit-validate-session.sh`
- `scripts/dockit-generate-external-context.sh`

**Copy only if the file does NOT exist** (documentation skeleton):
- `LLM_START_HERE.md`
- `CHANGELOG.md`
- `docs/PROJECT_CONTEXT.md`
- `docs/ARCHITECTURE.md`
- `docs/STRUCTURE.md`
- `docs/VERSIONING_RULES.md`
- `docs/version-sync-manifest.yml`
- `docs/llm/README.md`
- `docs/llm/HANDOFF.md`
- `docs/llm/HISTORY.md`
- `docs/llm/DECISIONS.md`
- `.claude/settings.json`
- `.claude/rules/require-docs-on-code-change.md`
- `.claude/skills/update-docs/SKILL.md`
- `.github/workflows/doc-validation.yml`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

**Create new** (these won't exist in the template as-is):
- `VERSION` containing `0.1.0` (or the project's existing version if detected)
- `.dockit-enabled` (empty file)
- `.dockit-config.yml` containing `adoption_mode: full`

**Never overwrite:** `README.md`, `.gitignore`, `LICENSE`

### 3. Replace placeholders

In every file you copied, replace:
- `<PROJECT_NAME>` with the project name
- `<CONVERSATION_LANGUAGE>` with the conversation language
- `<YYYY-MM-DD - Author>` with today's date and your LLM name
- `<Feature or task>` with `Initial LLM-DocKit adoption`
- `<Short status summary>` with `Scaffold adopted, ready for first session`

### 4. Personalize with intelligence

This is what makes a skill better than a script. Use your understanding of the project to:
- **docs/PROJECT_CONTEXT.md**: Fill in the project vision, objectives, and tech stack based on what you read from the README and codebase. Don't leave placeholders — write real content.
- **docs/STRUCTURE.md**: Generate the actual directory structure of the repo (not the generic template). Describe what each directory contains.
- **docs/llm/HANDOFF.md**: Write a real operational snapshot. Describe what the project does, its current state, and that LLM-DocKit was just adopted. Remove template sections that don't apply.
- **docs/llm/HISTORY.md**: Add the first entry recording the adoption.
- **docs/llm/DECISIONS.md**: Leave the template structure (empty, ready for entries).

### 5. Technical setup

Run these commands in order:

```
!`scripts/bump-version.sh 0.1.0`!
```

Install the pre-commit hook:
```
!`cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`!
```

Make scripts executable:
```
!`chmod +x scripts/*.sh`!
```

Append to the existing `.gitignore` (do NOT overwrite it). Add these lines if they are not already present:
```
# Claude Code (LLM-DocKit)
.claude/*
!.claude/settings.json
!.claude/rules/
!.claude/skills/
```

### 6. Validate and report

Run validation:
```
!`scripts/dockit-validate-session.sh --human`!
!`scripts/check-version-sync.sh`!
```

Report to the user:
- List of files created
- List of existing files that were NOT overwritten
- Validation results
- Suggest: "Review `docs/PROJECT_CONTEXT.md` and `docs/llm/HANDOFF.md` to verify the generated content is accurate."

### 7. Optional: External Context

If the user's `~/.claude/CLAUDE.md` references external documentation repos (like infrastructure docs), ask if they want to configure external context:
- If yes, create `.dockit-config.yml` with the `external_context` section
- Run `scripts/dockit-generate-external-context.sh --apply` to populate `LLM_START_HERE.md`
