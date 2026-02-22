# LLM Change History

Append new entries at the top so the most recent activity is easiest to find. Follow the required format:

YYYY-MM-DD - <LLM_NAME> - <Brief summary> - Files: [list of touched files] - Version impact: <yes/no + details>

## Log

### Example Entry Format

```
2025-01-15 - Claude - Add authentication module with JWT support - Files: [src/auth/jwt.js, src/auth/middleware.js, tests/auth.test.js, docs/llm/HANDOFF.md] - Version impact: yes (src/auth/jwt.js -> 1.1.0, breaking change requires new ENV var JWT_SECRET)
```

### Your Project History

- 2026-02-22 - Claude Opus 4.6 - Add dockit-sync tool system for template propagation to downstream projects. New sync manifest, sync script (~620 lines POSIX sh), check script. Added DOCKIT-TEMPLATE section markers to LLM_START_HERE.md. Bumped to v4.0.0. - Files: [dockit-sync-manifest.yml, scripts/dockit-sync.sh, scripts/dockit-sync-check.sh, LLM_START_HERE.md, CHANGELOG.md, docs/llm/HANDOFF.md, docs/llm/HISTORY.md, VERSION] - Version impact: yes (3.0.0 -> 4.0.0, major: requires downstream action to add markers and .dockit-enabled)
