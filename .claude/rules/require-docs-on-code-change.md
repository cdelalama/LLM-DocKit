---
globs:
  - "scripts/**/*.sh"
  - "src/**/*"
  - "*.yml"
  - "*.yaml"
---
When modifying files matching these paths, you MUST also update:
1. `docs/llm/HANDOFF.md` — update "Last Updated" date and "Session Focus"
2. `docs/llm/HISTORY.md` — append an entry with today's date

Run `scripts/dockit-validate-session.sh --human` to verify compliance before ending the session.
