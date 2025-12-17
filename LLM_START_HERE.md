# LLM Start Guide - <PROJECT_NAME>

## Read This First (Mandatory)

Welcome to <PROJECT_NAME>. Before you contribute, review and adapt the sections below to match the project requirements. Replace angle-bracket placeholders (<...>) with real values and share this file with every LLM agent.

Recommended reading order:
1. This file (rules, workflows, and current expectations)
2. docs/PROJECT_CONTEXT.md (vision, architecture, current state)
3. docs/ARCHITECTURE.md (optional: architecture, contracts, roadmap)
4. docs/VERSIONING_RULES.md (version management policy)
5. docs/llm/README.md (LLM docs index)
6. docs/llm/HANDOFF.md (current work state and priorities)
7. docs/llm/DECISIONS.md (stable rationale; link from HANDOFF)

## Critical Rules (Non-Negotiable)

### Language Policy
- All code and documentation: English (update if your project needs a different language)
- Conversation with the user: <CONVERSATION_LANGUAGE>
- Comments in code: English
- File names: English

### Documentation Update Rules
- Update docs/llm/HANDOFF.md every time you make a change.
- Append an entry to docs/llm/HISTORY.md in every session.
- HISTORY format: YYYY-MM-DD - <LLM_NAME> - <Brief summary> - Files: [list] - Version impact: [yes/no + details]
- Put long-form rationale in docs/llm/DECISIONS.md and link to it from HANDOFF.
- Prefer ASCII-only in docs/llm/* to avoid Windows encoding issues.

### Commit Message Policy
- Every response that includes code or documentation changes must end with suggested commit information:
  - **Title:** under 72 characters
  - **Description:** under 200 characters, focused on user impact and why the change matters
- Format:
  `
  ## Commit Info
  **Title:** <concise title>
  **Description:** <short explanation of what changed and why>
  `

### Version Management
- Check VERSION declarations in scripts or modules before editing.
- Do not bump versions without consulting docs/VERSIONING_RULES.md.
- Synchronize version numbers across related files when changes span multiple scripts.

### Environment Files (If Applicable)
- Do not edit generated .env.example files directly.
- Never change or remove existing credentials in .env or equivalent secret stores.
- If a new variable is needed, document it in the relevant README and ask the user to add it manually.

## Current Focus (Snapshot)

Source of truth: docs/llm/HANDOFF.md.
- Last Updated: <YYYY-MM-DD - Author>
- Working on: <Feature or task>
- Status: <Short status summary>

Keep this section synchronized with the "Current Status" block in docs/llm/HANDOFF.md.

## Getting Started Checklist
- [ ] Read this entire file and update placeholders
- [ ] Review docs/PROJECT_CONTEXT.md
- [ ] Review docs/VERSIONING_RULES.md
- [ ] Read the current docs/llm/HANDOFF.md
- [ ] Confirm scope with the user
- [ ] Complete the work
- [ ] Update docs/llm/HANDOFF.md
- [ ] Add an entry to docs/llm/HISTORY.md

## Customization Notes for Maintainers
- Replace <PROJECT_NAME> with the actual project name.
- Define the conversation language (or remove the rule if not applicable).
- Remove or adapt any sections that do not align with your workflow (e.g., environment file policy).
- Populate docs/STRUCTURE.md with details about your repository layout.

## Quick Navigation
- Project Overview: docs/PROJECT_CONTEXT.md
- Architecture: docs/ARCHITECTURE.md
- Version Rules: docs/VERSIONING_RULES.md
- LLM Docs Index: docs/llm/README.md
- Current Work State: docs/llm/HANDOFF.md
- Change History: docs/llm/HISTORY.md
- Decision Rationale: docs/llm/DECISIONS.md
- Reviews (optional): docs/llm/REVIEWS.md
- Runbooks: docs/operations/

## LLM-to-LLM Communication
When handing off to another LLM:
1. Update docs/llm/HANDOFF.md with the current state and next steps.
2. Append an entry to docs/llm/HISTORY.md following the required format.
3. Ensure the snapshot in this file matches the latest status.

## Do Not Touch Zones
Use the Do Not Touch section in docs/llm/HANDOFF.md to flag any files or areas that must remain unchanged without explicit approval from the user.

---

Every change must be documented. If you are unsure about a rule, ask the user before proceeding.
