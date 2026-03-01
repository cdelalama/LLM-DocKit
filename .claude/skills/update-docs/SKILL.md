# Skill: Update Documentation

Update the LLM documentation files (HANDOFF.md, HISTORY.md) for the current session.

## Instructions

When the user invokes `/update-docs`, perform these steps:

1. Read the current `docs/llm/HANDOFF.md` and update:
   - `Last Updated` to today's date and your LLM name
   - `Session Focus` to describe what was done this session
   - `Status` to reflect current state
   - Any other sections that changed (priorities, files, decisions)

2. Append a new entry to `docs/llm/HISTORY.md` following the format:
   ```
   - YYYY-MM-DD - <LLM_NAME> - <Brief summary> - Files: [list of touched files] - Version impact: <yes/no + details>
   ```

3. If any new architectural decisions were made, add D-xxx entries to `docs/llm/DECISIONS.md`.

4. Run the validation script to confirm:
   ```
   !`scripts/dockit-validate-session.sh --human`!
   ```

5. Report the validation results to the user.
