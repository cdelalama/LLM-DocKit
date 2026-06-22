<!-- doc-version: 4.12.3 -->
# LLM Start Guide - <PROJECT_NAME>

## Read This First (Mandatory)

Welcome to <PROJECT_NAME>. Before you contribute, review and adapt the sections below to match the project requirements. Replace angle-bracket placeholders (<...>) with real values and share this file with every LLM agent.

Recommended reading order:
1. This file (rules, workflows, and current expectations)
2. docs/PROJECT_CONTEXT.md (vision, architecture, current state)
3. docs/ARCHITECTURE.md if present; otherwise docs/ARCHITECTURE.md.example as the optional starter template
4. docs/VERSIONING_RULES.md (version management policy)
5. docs/llm/README.md (LLM docs index)
6. docs/llm/HANDOFF.md — current work state. Read the **Open work — next concrete step** section near the top first; it is the canonical declaration of "what to do next" and must name concrete file paths inside the repo. The static check `scripts/dockit-validate-session.sh --check orientation` enforces that contract.
7. docs/llm/DECISIONS.md (stable rationale; link from HANDOFF)

Session-start scope:
- This reading order is mandatory once at session start, not on every turn.
- If you already loaded it in this same conversation and no relevant onboarding file changed, do not re-read the full list on later turns.
- For later turns, follow the stale-read re-verification rule: re-check the current clock before writing Trace, `git status`, current HEAD, and any files directly relevant to the new request.
- Re-read the full onboarding only when the operator explicitly widens scope or when repo state/doc changes make the prior onboarding stale. In that case begin with `Onboarding loaded (mid-session).`

## Critical Rules (Non-Negotiable)

### Language Policy
- All code and documentation: English (update if your project needs a different language)
- Conversation with the user: <CONVERSATION_LANGUAGE>
- Comments in code: English
- File names: English

<!-- DOCKIT-TEMPLATE:START doc-update-rules -->
### Documentation Update Rules
- Update docs/llm/HANDOFF.md every time you make a change.
- Append an entry to docs/llm/HISTORY.md in every session.
- HISTORY format defaults to `any`: either `- YYYY-MM-DD - <LLM_NAME> - ...` or `YYYY-MM-DD - <LLM_NAME> - ...` is accepted. Set top-level `history_format: dash` or `history_format: no-dash` in `.dockit-config.yml` when a project wants strict enforcement.
- Projects with a phase-based roadmap can opt into semantic phase drift checks with `.dockit-config.yml` `orientation_drift.enabled: true`; this fails when entry docs describe a completed roadmap phase as "next".
- Put long-form rationale in docs/llm/DECISIONS.md and link to it from HANDOFF.
- Prefer ASCII-only in docs/llm/* to avoid Windows encoding issues.
<!-- DOCKIT-TEMPLATE:END doc-update-rules -->

<!-- DOCKIT-TEMPLATE:START doc-sync-rules -->
### Documentation Sync Rules
- Keep this file's "Current Focus" section synchronized with docs/llm/HANDOFF.md "Current Status".
- Keep docs/STRUCTURE.md synchronized with the actual repository file tree.
- Keep docs/PROJECT_CONTEXT.md synchronized with architectural reality.
- Version markers (`<!-- doc-version: X.Y.Z -->`) in documentation files are managed by `scripts/bump-version.sh`. See `docs/version-sync-manifest.yml` for the full list of tracked files.
<!-- DOCKIT-TEMPLATE:END doc-sync-rules -->

<!-- DOCKIT-TEMPLATE:START commit-policy -->
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
<!-- DOCKIT-TEMPLATE:END commit-policy -->

<!-- DOCKIT-TEMPLATE:START version-management -->
### Version Management
- Every commit that changes code/config files MUST include a version bump. The pre-commit hook enforces this.
- For version bumps, run `scripts/bump-version.sh <new_version>`; do not edit version strings manually.
- The bump script reads `docs/version-sync-manifest.yml` to update all tracked files atomically.
- Supported manifest marker types are `version-file`, `changelog`, `html-comment`, `json-version`, `yaml-info-version`, and `package-lock-version`.
- Validate sync with `scripts/check-version-sync.sh` (also available as pre-commit hook).
- Do not bump versions without consulting docs/VERSIONING_RULES.md for impact level (patch/minor/major).
- Do NOT batch multiple code commits without versioning. No exceptions.
<!-- DOCKIT-TEMPLATE:END version-management -->

<!-- DOCKIT-TEMPLATE:START env-policy -->
### Environment Files (If Applicable)
- Do not edit generated .env.example files directly.
- Never change or remove existing credentials in .env or equivalent secret stores.
- If a new variable is needed, document it in the relevant README and ask the user to add it manually.
<!-- DOCKIT-TEMPLATE:END env-policy -->

## Current Focus (Snapshot)

Source of truth: docs/llm/HANDOFF.md.
- Last Updated: <YYYY-MM-DD - Author>
- Working on: <Feature or task>
- Status: <Short status summary>

Keep this section synchronized with the "Current Status" block in docs/llm/HANDOFF.md.

<!-- DOCKIT-TEMPLATE:START checklist -->
## Getting Started Checklist
- [ ] Read this entire file and update placeholders
- [ ] Review docs/PROJECT_CONTEXT.md
- [ ] Review docs/VERSIONING_RULES.md
- [ ] Read the current docs/llm/HANDOFF.md
- [ ] Install pre-commit hook: `cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
- [ ] Run `scripts/check-version-sync.sh` to verify version markers
- [ ] Confirm scope with the user
- [ ] Complete the work
- [ ] Update docs/llm/HANDOFF.md
- [ ] Add an entry to docs/llm/HISTORY.md
<!-- DOCKIT-TEMPLATE:END checklist -->

## Customization Notes for Maintainers
- Replace <PROJECT_NAME> with the actual project name.
- Define the conversation language (or remove the rule if not applicable).
- Remove or adapt any sections that do not align with your workflow (e.g., environment file policy).
- Populate docs/STRUCTURE.md with details about your repository layout.

## Quick Navigation
- Project Overview: docs/PROJECT_CONTEXT.md
- Architecture: docs/ARCHITECTURE.md if present; otherwise docs/ARCHITECTURE.md.example
- Version Rules: docs/VERSIONING_RULES.md
- Version Sync Manifest: docs/version-sync-manifest.yml
- Codex CLI Integration: docs/integrations/CODEX.md
- LLM Docs Index: docs/llm/README.md
- Current Work State: docs/llm/HANDOFF.md
- Change History: docs/llm/HISTORY.md
- Decision Rationale: docs/llm/DECISIONS.md
- Reviews (optional): docs/llm/REVIEWS.md
- Runbooks: docs/operations/

<!-- DOCKIT-TEMPLATE:START llm-communication -->
## LLM-to-LLM Communication
When handing off to another LLM:
1. Update docs/llm/HANDOFF.md with the current state and next steps.
2. Append an entry to docs/llm/HISTORY.md following the required format.
3. Ensure the snapshot in this file matches the latest status.
<!-- DOCKIT-TEMPLATE:END llm-communication -->

<!-- DOCKIT-TEMPLATE:START trace-protocol -->
## Trace Protocol

Every substantive assistant turn in a DocKit-governed session must begin with
a compact `Trace` header, then continue with the normal explanation in prose.
This includes execution, audit, design opinions, recommendations,
brainstorming, clarifying questions, status reports, and go/no-go calls.

A turn is substantive if the operator might need to find it when returning to
a multi-window workflow: it contains a decision, opinion, recommendation,
status, audit, action, or clarifying question. Non-substantive turns such as a
pure acknowledgement under 50 characters do not require Trace, but emitting
Trace is always safe. The header is for orientation; it does not replace the
message.

Required chat header fields:
- `Role`: `executor`, `auditor`, or `advisor`
- `Sent`: `YYYY-MM-DD HH:MM:SS <local-tz> (HH:MM:SS UTC)`. The order and
  precision are mandatory: local time first, UTC second in parentheses, seconds
  included on both sides.
- `Subject`: current task, question, recommendation, or commit hash/title being implemented or audited
- `Resulting state`: what this message leaves true after it is sent
- `Repo state`: local branch vs origin and worktree status verified now
- `Validation`: checks run and result
- `Next gate`: who/what should act next

Time verification:
- Verify `Sent` before writing it; do not infer or mentally convert the time.
- If shell access is available, run both:
  ```sh
  date -u '+%Y-%m-%d %H:%M:%S UTC'
  TZ=Europe/Madrid date '+%Y-%m-%d %H:%M:%S %Z'
  ```
- Replace `Europe/Madrid` with `trace_protocol.local_timezone` from
  `.dockit-config.yml` when the project sets one.
- If the agent cannot verify the clock, write:
  `Sent: unverified client time YYYY-MM-DD HH:MM:SS <claimed-tz>`.
- Prefer generating the close-out scaffold immediately before sending it:
  ```sh
  scripts/dockit-trace-status.sh --role executor --subject "<commit/task>" \
    --validation "<checks>" --next "<next gate>"
  ```
  This prints current HEAD, local/upstream state, worktree cleanliness, version,
  and verified local/UTC time from git/date instead of relying on memory.

Recommended `Resulting state` shape:

```text
Resulting state: HEAD=<hash|unchanged (hash)>; version=<version|none>; gate=<opened|cleared|blocked|superseded|next-slice>; <short note>
```

Examples:

```text
Resulting state: HEAD=01f90bb; version=4.9.1; gate=cleared; supersedes audit of d6fc816
Resulting state: HEAD=unchanged (01f90bb); version=none; gate=cleared; ready for next slice
Resulting state: HEAD=unchanged (d6fc816); version=none; gate=blocked; requires executor patch v4.9.1
```

Use clear prose after the header. Explain what changed, why it matters, what
was verified, and what risk remains.

When reading an older Trace block, do not treat its `Repo state` as current
without checking the tree again. If the `Sent` time is more than a few minutes
old, or another LLM/operator may have acted since it was written, verify
`git status`, `git log -1`, and the current clock before acting on the report.

When `trace_protocol.enabled: true` is set in `.dockit-config.yml`, the durable
half is enforced by `scripts/dockit-validate-session.sh --check trace-protocol`:
- `docs/llm/HANDOFF.md` must contain a `## Trace Anchor` section.
- HANDOFF Trace Anchor commit times may use `YYYY-MM-DD HH:MM:SS UTC` or
  `YYYY-MM-DD HH:MM UTC`.
- A committed HANDOFF Trace Anchor is a durable repo-side anchor, not a
  guaranteed live HEAD pointer. Prefer neutral labels such as `Subject:` or
  `Trace target:`. Projects can set
  `trace_protocol.reject_current_anchor_label: true` to fail anchors labelled
  `Current target:` or `Current audit target:`.
- `docs/llm/HISTORY.md` entries dated on or after `trace_protocol.since` that
  reference backtick-quoted commit hashes must end with an inline footer:
  `Trace: role=executor|auditor|advisor; commits=hash1,hash2; state=...; validation=...; next=...`

Projects can set the local timezone used in `Sent` with:

```yaml
trace_protocol:
  local_timezone: Europe/Madrid
```

Projects that do not use Trace-oriented LLM windows can disable the chat-side
convention with:

```yaml
trace_protocol:
  enabled: false
```
<!-- DOCKIT-TEMPLATE:END trace-protocol -->

<!-- DOCKIT-TEMPLATE:START do-not-touch -->
## Do Not Touch Zones
Use the Do Not Touch section in docs/llm/HANDOFF.md to flag any files or areas that must remain unchanged without explicit approval from the user.
<!-- DOCKIT-TEMPLATE:END do-not-touch -->

<!-- DOCKIT-EXTERNAL-CONTEXT:START -->
<!-- DOCKIT-EXTERNAL-CONTEXT:END -->

<!-- DOCKIT-TEMPLATE:START footer -->
---

Every change must be documented. If you are unsure about a rule, ask the user before proceeding.
<!-- DOCKIT-TEMPLATE:END footer -->
