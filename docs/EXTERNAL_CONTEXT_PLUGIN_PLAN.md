# Plan: External Context / Infrastructure Plugin

> Status: **Designed, approved, deferred to next version**
> Date: 2026-03-01
> Authors: Claude Opus 4.6 + ChatGPT (Codex GPT-5) review
> Approved by: Human owner after cross-LLM review

## Context

Projects need to reference external doc repos (e.g., infrastructure docs at `~/src/home-infra/docs/`). Currently handled via `~/.claude/CLAUDE.md` global instructions — tool-specific (Claude Code only), advisory (no enforcement), and manual. This plugin makes it generic, portable, and validated.

GPT reviewed the initial design and approved it with 5 operational adjustments (all incorporated below) and a 2-step rollout.

## Rollout Strategy

**v1:** Generation script + existence checks (path + read files)
**v1.1:** Trigger detection (WARN) + `--claude-rules` generation

---

## v1 Scope: Generation + Existence Validation

### Config Format (downstream `.dockit-config.yml`)

```yaml
adoption_mode: full

external_context:
  path: ~/src/home-infra/docs
  read:
    - INVENTORY.md
    - SERVICES.md
    - PROJECTS.md
    - CONVENTIONS.md
  update_triggers:
    - local: docker-compose*.yml  target: SERVICES.md
    - local: scripts/deploy*.sh   target: SERVICES.md
    - local: VERSION               target: PROJECTS.md
```

Parser grammar rules (same pattern as sync manifest `- path: X strategy: Y`):
- `^external_context:$` — anchored to line start, no indent, enters section
- `  path: <value>` — 2-space indent, required, exactly one
- `  read:` — 2-space indent, section header
- `    - <filename>` — 4-space indent + dash, list items under `read:`
- `  update_triggers:` — 2-space indent, section header (parsed in v1 for generation, detection deferred to v1.1)
- `    - local: <glob>  target: <filename>` — trigger entries
- Any line with 0-indent or a different 2-indent key exits `external_context` section

### Parser Robustness (GPT Adjustment #2)

The parser MUST:
- Enter `external_context` only on exact `^external_context:` match (anchored, like `^adoption_mode:`)
- Track state: `_in_ext=false`, `_in_read=false`, `_in_triggers=false`
- Exit `external_context` when indentation returns to 0 (another top-level key)
- Exit `read:` / `update_triggers:` subsections when indentation returns to 2 (another ext_context key)
- Never consume lines belonging to `adoption_mode` or `exclude_sections`
- Ignore blank lines and comment-only lines (lines starting with `#`)

### Path Normalization (GPT Adjustment #3)

Before validating `external_context.path`:
```sh
# Expand ~ to $HOME
_ext_path=$(echo "$_raw_path" | sed "s|^~|$HOME|")
# Resolve to canonical absolute path (handles relative, symlinks)
_ext_path=$(cd "$_ext_path" 2>/dev/null && pwd) || {
    add_result "external-context" "FAIL" "External docs path not accessible: $_raw_path"
    return
}
```

### Step 1: Create `scripts/dockit-generate-external-context.sh`

CLI:
```
scripts/dockit-generate-external-context.sh [--project PATH] [--dry-run|--apply]
```

Note: `--claude-rules` deferred to v1.1.

Behavior:
1. Read `.dockit-config.yml` from project root
2. Parse `external_context` section (path, read files, update_triggers)
3. Normalize path (~ expansion, cd+pwd resolution)
4. Validate: path exists, read files exist
5. Generate markdown block
6. `--dry-run`: print to stdout
7. `--apply`: insert/replace between markers in `LLM_START_HERE.md`

### Idempotent Insertion (GPT Adjustment #4)

Insertion in `LLM_START_HERE.md` follows the exact same AWK pattern as `dockit-sync.sh` section-merge:

```sh
# If markers don't exist -> ERROR, do not create them silently
_start_marker="<!-- DOCKIT-EXTERNAL-CONTEXT:START -->"
_end_marker="<!-- DOCKIT-EXTERNAL-CONTEXT:END -->"
_start_count=$(grep -c "^${_start_marker}$" "$_llm_file" 2>/dev/null) || true
_end_count=$(grep -c "^${_end_marker}$" "$_llm_file" 2>/dev/null) || true

if [ "$_start_count" -eq 0 ] || [ "$_end_count" -eq 0 ]; then
    die "ERROR: Missing DOCKIT-EXTERNAL-CONTEXT markers in $LLM_FILE."
fi
if [ "$_start_count" -gt 1 ] || [ "$_end_count" -gt 1 ]; then
    die "ERROR: Duplicate DOCKIT-EXTERNAL-CONTEXT markers in $LLM_FILE."
fi

# Replace content between markers (idempotent)
awk -v start="$_start_marker" -v end="$_end_marker" -v tfile="$_content_file" '
    $0 == start { print; while ((getline l < tfile) > 0) print l; close(tfile); skip=1; next }
    $0 == end   { skip=0; print; next }
    !skip { print }
' "$_llm_file" > "$_replaced"
```

Properties:
- Markers must exist, error if missing (never silently created)
- Duplicate markers, error
- Running twice, identical output (idempotent)
- Content between markers fully replaced

Generated content example:
```markdown
<!-- DOCKIT-EXTERNAL-CONTEXT:START -->
### External Context

**Source:** ~/src/home-infra/docs

**Read these files at the start of every session:**
1. INVENTORY.md
2. SERVICES.md
3. PROJECTS.md
4. CONVENTIONS.md

**Update triggers (advisory, not enforced yet)** -- when you modify files matching these patterns, update the corresponding external doc:
| Local file pattern | External doc to update |
|--------------------|------------------------|
| docker-compose*.yml | SERVICES.md |
| scripts/deploy*.sh | SERVICES.md |
| VERSION | PROJECTS.md |
<!-- DOCKIT-EXTERNAL-CONTEXT:END -->
```

### Step 2: Add placeholder markers to `LLM_START_HERE.md`

Add empty markers after "Do Not Touch Zones" section, before footer:

```markdown
<!-- DOCKIT-EXTERNAL-CONTEXT:START -->
<!-- DOCKIT-EXTERNAL-CONTEXT:END -->
```

### Step 3: New check `check_external_context` in `dockit-validate-session.sh`

**v1 scope**: existence checks only (path + read files). No trigger detection.

```
check_external_context:
  1. Read .dockit-config.yml -> parse external_context section
  2. No external_context section -> skip silently (opt-in feature)
  3. Normalize path (~ expansion, cd+pwd)
  4. Path not accessible -> FAIL (unless DOCKIT_SKIP_EXTERNAL=1)
  5. For each file in read: -> check existence -> FAIL if missing
  6. All exist -> PASS with count
```

**CI portability (GPT Cautela #1):** If `DOCKIT_SKIP_EXTERNAL=1` env var is set, skip the external-context check entirely. This allows CI pipelines where the external repo is not available to pass validation.

Three parser helper functions added to the validator (NOT to dockit-sync.sh -- keep separate):
- `_read_ext_path()` -- extracts path value
- `_read_ext_read_files()` -- extracts read file list
- `_read_ext_triggers()` -- extracts trigger pairs (parsed in v1 for generation, detection deferred)

### Step 4: Update sync manifest and docs

- `dockit-sync-manifest.yml`: add `scripts/dockit-generate-external-context.sh` with `copy` strategy
- `docs/STRUCTURE.md`: document new script and config section
- `HANDOFF.md`: mark as implemented

### Step 5: HISTORY.md + D-006

- HISTORY entry
- D-006: External context uses separate markers (DOCKIT-EXTERNAL-CONTEXT, not DOCKIT-TEMPLATE) to avoid sync interference

---

## v1.1 Scope (deferred, future session)

### Trigger Detection Source (GPT Adjustment #1)

When implemented, trigger detection will use:
```sh
# All local changes: staged + unstaged working tree
_changed=$(cd "$PROJECT_ROOT" && {
    git diff --name-only HEAD 2>/dev/null
    git diff --cached --name-only 2>/dev/null
} | sort -u)
```

- Staged files (git diff --cached): about to be committed
- Working tree changes (git diff HEAD): modified but not yet staged
- NOT untracked files: new files that haven't been added to git aren't "changes" yet
- Glob matching via POSIX `case "$file" in $glob)` -- native shell globs

Triggers produce WARN (not FAIL). Rationale: can't verify external repo was updated.

### `--claude-rules` Opt-In (GPT Adjustment #5)

- Only with explicit `--claude-rules` flag
- Generated `.claude/rules/external-context-triggers.md` does NOT contain absolute paths
- Instead references the config generically:

```markdown
---
globs:
  - "docker-compose*.yml"
  - "scripts/deploy*.sh"
  - "VERSION"
---
When modifying these files, check .dockit-config.yml external_context.update_triggers
for external docs that may need updating.
Run: scripts/dockit-validate-session.sh --check external-context --human
```

- `.claude/rules/` is tracked in git (per .gitignore negation pattern), so no sensitive paths in the file
- The actual external path lives only in `.dockit-config.yml` (which is project-specific, not synced)

---

## GPT Cautelas (Pre-Implementation)

1. **CI portability**: `external_context.path` may not exist in CI. Solution: `DOCKIT_SKIP_EXTERNAL=1` env var skips the check.
2. **Parser contract**: Document exact `.dockit-config.yml` grammar in one place. Test against all parsers (dockit-sync.sh, dockit-validate-session.sh, dockit-generate-external-context.sh) to prevent drift.

---

## Files to Create

| File | Purpose |
|------|---------|
| `scripts/dockit-generate-external-context.sh` | Generate LLM_START_HERE.md section from config |

## Files to Modify

| File | Change |
|------|--------|
| `scripts/dockit-validate-session.sh` | Add `check_external_context()` + 3 parser functions (v1: existence only) |
| `LLM_START_HERE.md` | Add `DOCKIT-EXTERNAL-CONTEXT:START/END` placeholder markers |
| `dockit-sync-manifest.yml` | Add new script with `copy` strategy |
| `docs/STRUCTURE.md` | Document new script |
| `docs/llm/HANDOFF.md` | Mark as implemented |
| `docs/llm/HISTORY.md` | Add session entry |
| `docs/llm/DECISIONS.md` | Add D-006 |

## Verification

1. `sh -n scripts/dockit-generate-external-context.sh` -- syntax check
2. Create test `.dockit-config.yml` with `external_context` section
3. `--dry-run` -> verify generated markdown output
4. `--apply` -> verify markers in `LLM_START_HERE.md` replaced correctly
5. Run `--apply` twice -> verify idempotent (no diff on second run)
6. Remove markers -> run `--apply` -> verify ERROR (not silent creation)
7. `scripts/dockit-validate-session.sh --human` -> verify `external-context` check appears and PASS
8. Set path to nonexistent dir -> verify FAIL
9. Remove a read file -> verify FAIL
10. Run without `external_context` in config -> verify check is silently skipped
11. Test with existing `adoption_mode` + `exclude_sections` in same config -> verify they still parse correctly
12. Set `DOCKIT_SKIP_EXTERNAL=1` -> verify check is skipped
