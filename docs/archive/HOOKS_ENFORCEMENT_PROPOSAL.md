# Proposal: Hook-Based Documentation Enforcement

> Archived: 2026-06-18
> Status: implemented by LLM-DocKit 4.x.
> Kept as historical lineage for the hook-enforcement design. The live
> implementation is `scripts/dockit-validate-session.sh`, `.claude/settings.json`,
> `scripts/pre-commit-hook.sh`, and `.github/workflows/doc-validation.yml`.
> Do not implement from this draft.

> Status: **Draft — Brainstorming**
> Date: 2026-03-01
> Author: Claude Opus 4.6 + human review
> Context: LLM-DocKit v4.0.0 governance audit revealed recurring drift despite CLAUDE.md rules

---

## Problem Statement

LLM-DocKit relies on CLAUDE.md instructions to maintain documentation discipline (HANDOFF.md, HISTORY.md, DECISIONS.md). These instructions are **advisory** — no mechanism prevents an LLM from ending a session without updating docs. Evidence: on 2026-02-28, HANDOFF.md was modified but its own `Last Updated` field was not changed, and HISTORY.md received no entry. The rules existed; they were simply not followed.

**Root cause:** compliance depends on LLM discipline, not on system enforcement.

---

## Proposed Solution: Enforcement Layer

Add a validation layer that **blocks session completion** when documentation is not up to date. The layer sits between the LLM tool (Claude Code, Cursor, etc.) and LLM-DocKit's documentation contract.

### Architecture: Two-Layer Design

```
+------------------------------------------+
|          LLM-DocKit (portable)           |
|                                          |
|  Validation contract:                    |
|  - scripts/dockit-validate-session.sh    |
|    (POSIX sh, runs anywhere)             |
|  - Checks: HANDOFF date, HISTORY entry,  |
|    DECISIONS consistency, version sync    |
|  - Returns: JSON {ok, errors[]}          |
|                                          |
+------------------+-----------------------+
                   |
                   | exit code + JSON
                   |
+------------------+-----------------------+
|        Driver (tool-specific)            |
|                                          |
|  Claude Code:                            |
|    .claude/settings.json → Stop hook     |
|    calls dockit-validate-session.sh      |
|                                          |
|  Cursor (future):                        |
|    .cursor/rules or extension            |
|    calls dockit-validate-session.sh      |
|                                          |
|  Other LLM tools (future):              |
|    Whatever hook mechanism they offer    |
|    calls the same validation script      |
|                                          |
+------------------------------------------+
```

**Key principle:** The validation logic lives in a portable POSIX script. The tool-specific driver is a thin adapter that calls it at the right lifecycle moment.

---

## Layer 1: Validation Contract (Portable)

### Script: `scripts/dockit-validate-session.sh`

A single POSIX sh script that checks documentation state. Zero external dependencies (same philosophy as existing scripts).

**Checks performed:**

| Check | What it validates | Severity |
|-------|-------------------|----------|
| `handoff-date` | HANDOFF.md contains today's date in "Last Updated" | ERROR |
| `history-entry` | HISTORY.md has an entry with today's date | ERROR |
| `handoff-history-consistency` | HANDOFF "Session Focus" aligns with latest HISTORY entry | WARNING |
| `decisions-referenced` | Any decision mentioned in HANDOFF has a D-xxx entry in DECISIONS.md | WARNING |
| `version-sync` | Delegates to existing check-version-sync.sh | ERROR |

**Output format (JSON to stdout):**

```json
{
  "ok": false,
  "timestamp": "2026-03-01T14:30:00Z",
  "checks": [
    {"name": "handoff-date", "status": "FAIL", "message": "Last Updated is 2026-02-22, expected 2026-03-01"},
    {"name": "history-entry", "status": "FAIL", "message": "No HISTORY.md entry for 2026-03-01"},
    {"name": "version-sync", "status": "PASS", "message": "8/8 targets in sync"}
  ]
}
```

**Exit codes:**
- `0` — all checks pass
- `1` — at least one ERROR check failed
- `2` — script error (bad arguments, missing files)

**CLI interface:**

```bash
# Full validation
scripts/dockit-validate-session.sh

# Specific checks only
scripts/dockit-validate-session.sh --check handoff-date --check history-entry

# Machine-readable output (default is JSON; --human for plain text)
scripts/dockit-validate-session.sh --human

# Custom project root (for downstream projects)
scripts/dockit-validate-session.sh --project /path/to/downstream
```

**Why a single script, not multiple:**
- One entry point for all drivers to call
- Atomic: either the session is compliant or it isn't
- Easier to extend (add a check function, add it to the check list)
- Follows existing pattern (dockit-sync.sh is also a single entry point)

---

## Layer 2: Drivers (Tool-Specific)

### Driver: Claude Code

Claude Code hooks can block the `Stop` event (session end). Configuration:

**File: `.claude/settings.json`**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "scripts/dockit-validate-session.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**Behavior:**
1. User or Claude tries to end session
2. Hook fires, runs validation script
3. If script returns `{"ok": false}` — Claude sees the errors and continues working to fix them
4. If script returns `{"ok": true}` — session ends normally

**Optional additional hooks:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "scripts/dockit-validate-session.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "scripts/dockit-validate-session.sh --check handoff-date --quiet",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

The `PostToolUse` hook is non-blocking (feedback only) but reminds Claude after every file write that docs may need updating. The `Stop` hook is the actual gate.

**Files to ship in LLM-DocKit template:**
- `.claude/settings.json` — hook configuration (synced via `copy` strategy)
- `scripts/dockit-validate-session.sh` — validation logic (synced via `copy` strategy)

### Driver: Cursor (Future)

Cursor uses `.cursor/rules` files for LLM instructions (similar to CLAUDE.md, advisory). As of March 2026, Cursor does not have a hook/enforcement system equivalent to Claude Code's Stop hook.

**When Cursor adds enforcement hooks:**
- Create `.cursor/settings.json` (or equivalent) that calls `scripts/dockit-validate-session.sh`
- The validation script is already portable — only the driver config changes

**Current workaround for Cursor:**
- `.cursor/rules` file with the same documentation rules as CLAUDE.md
- No enforcement possible — advisory only
- `scripts/dockit-validate-session.sh` can be run manually or via git pre-commit hook

### Driver: Git Pre-Commit (Universal Fallback)

For any LLM tool that lacks native hook support, git pre-commit is the universal fallback. It does not block **session end** (the ideal moment) but blocks **commits with stale docs**.

**File: `scripts/pre-commit-hook.sh` (extend existing)**

Add a call to `dockit-validate-session.sh` in the existing pre-commit hook. This already validates version sync; adding doc validation is a natural extension.

**Trade-off:** Pre-commit fires at commit time, not session end. An LLM could make changes, not update docs, and the human discovers the gap only when trying to commit. This is worse than a Stop hook but better than nothing.

### Driver: CI (Safety Net)

GitHub Actions or similar CI can run `dockit-validate-session.sh` on every PR as a final safety net.

```yaml
# .github/workflows/doc-validation.yml
name: Documentation Validation
on: [pull_request]
jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate documentation state
        run: scripts/dockit-validate-session.sh --human
```

**Trade-off:** CI catches drift after the fact (PR review time), not in real-time. But it prevents drift from reaching main.

---

## Enforcement Cascade

The drivers form a cascade — each layer catches what the previous one missed:

```
Stop hook (Claude Code)     ← Catches drift in real-time (best)
  |
  v  (if LLM tool has no hooks)
Pre-commit hook             ← Catches drift at commit time (good)
  |
  v  (if commit bypasses hooks)
CI validation               ← Catches drift at PR time (safety net)
  |
  v  (if CI skipped)
Manual: run validate script ← Human runs it (last resort)
```

All four layers call the same `dockit-validate-session.sh`. The investment is in the validation script; the drivers are thin wrappers.

---

## Portability Matrix

| LLM Tool | Stop/Session Hook | Pre-commit | CI | Manual |
|----------|-------------------|------------|-----|--------|
| Claude Code | Native (Stop hook) | Via existing hook | Yes | Yes |
| Cursor | Not yet (advisory rules only) | Via git hook | Yes | Yes |
| Windsurf | Not yet | Via git hook | Yes | Yes |
| Aider | Not yet | Via git hook | Yes | Yes |
| ChatGPT (web) | N/A | N/A | Yes (if git-based) | Yes |
| Any future tool | When they add hooks → thin driver | Via git hook | Yes | Yes |

**The design ensures:** even if only Claude Code can enforce today, the validation logic is reusable by any tool tomorrow.

---

## What This Does NOT Replace

| Existing LLM-DocKit Component | Status with this proposal |
|-------------------------------|--------------------------|
| CLAUDE.md / LLM_START_HERE.md rules | **Kept** — still needed as advisory context |
| scripts/bump-version.sh | **Kept** — version management is orthogonal |
| scripts/check-version-sync.sh | **Kept** — called BY validate-session as one check |
| scripts/dockit-sync.sh | **Kept** — template propagation is orthogonal |
| scripts/pre-commit-hook.sh | **Extended** — adds validate-session call |
| docs/llm/ files (HANDOFF, HISTORY, DECISIONS) | **Kept** — they ARE the documentation being enforced |

This proposal adds **one new script** and **one new config file**. Everything else stays.

---

## Optional Enhancements (Not in Scope for v1)

### A. Claude Code Skills for Doc Updates

Create `.claude/skills/update-docs/SKILL.md` so the user can type `/update-docs` to trigger a guided documentation update. This is convenience, not enforcement.

```
.claude/skills/update-docs/SKILL.md
```

### B. Agent-Based Stop Hook

Instead of a shell script, use Claude Code's `type: "agent"` hook for deeper validation — an LLM reads the docs and evaluates coherence, not just dates.

```json
{
  "type": "agent",
  "prompt": "Read HANDOFF.md and HISTORY.md. Verify: (1) HANDOFF has today's date, (2) HISTORY has an entry for today, (3) HANDOFF status is consistent with HISTORY's latest entry. Report any issues.",
  "timeout": 60
}
```

**Trade-off:** costs an API call per session end; more thorough than date checking.

### C. PostToolUse Nudge Hook

A non-blocking hook that fires after every Write/Edit and reminds Claude to update docs if code files changed. Reduces drift during the session, not just at the end.

### D. Infrastructure Plugin

The open question from HANDOFF.md: a mechanism for projects to reference external doc repos (e.g., home-infra). Could be a check in `dockit-validate-session.sh` that validates cross-repo references are current.

---

## Decision Required

| Question | Options |
|----------|---------|
| **Scope of v1** | (a) Stop hook only — minimal, prove the concept (b) Stop + PostToolUse + pre-commit — full cascade |
| **Validation depth** | (a) Date checks only (fast, simple) (b) Date + content consistency (slower, more thorough) |
| **Claude Code skill** | (a) Include `/update-docs` skill in v1 (b) Defer to v2 |
| **Agent hook** | (a) Shell script only in v1 (b) Agent-based hook for deeper validation |

---

## Estimated Effort

| Component | Effort | Dependencies |
|-----------|--------|-------------|
| `scripts/dockit-validate-session.sh` | ~2 hours | None |
| `.claude/settings.json` template | ~30 min | Validation script |
| Extend pre-commit-hook.sh | ~30 min | Validation script |
| CI workflow template | ~30 min | Validation script |
| Documentation (HOW_TO_USE.md update) | ~1 hour | All above |
| **Total** | ~4-5 hours | |

---

## References

- [Claude Code Hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Claude Code Settings](https://docs.anthropic.com/en/docs/claude-code/settings)
- [Claude Code Skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- LLM-DocKit HANDOFF.md — governance audit session 2026-03-01
- LLM-DocKit docs/LLM_DOCKIT_CE_V2_PROPOSAL.md — related RFC (untracked)
