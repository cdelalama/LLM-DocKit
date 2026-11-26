#!/bin/sh
# test-validator.sh -- Smoke tests for dockit-validate-session.sh.
#
# Portable POSIX sh. Creates throwaway git repos under /tmp and verifies the
# validator behaviours that have regressed or produced false positives in real
# sessions.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
VALIDATOR="$PROJECT_ROOT/scripts/dockit-validate-session.sh"
SESSION_GATE="$PROJECT_ROOT/scripts/dockit-session-gate.sh"
CHECK_VERSION="$PROJECT_ROOT/scripts/check-version-sync.sh"
BUMP_VERSION="$PROJECT_ROOT/scripts/bump-version.sh"
SYNC_TOOL="$PROJECT_ROOT/scripts/dockit-sync.sh"
TRACE_STATUS="$PROJECT_ROOT/scripts/dockit-trace-status.sh"
CODEX_INSTALLER="$PROJECT_ROOT/scripts/dockit-install-codex-hook.sh"

TMP_ROOT=${TMPDIR:-/tmp}/dockit-validator-smoke.$$
OUT="$TMP_ROOT/out.txt"
TODAY=$(date +%Y-%m-%d)

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

pass_count=0
fail_count=0

note_pass() {
    pass_count=$((pass_count + 1))
    printf 'PASS: %s\n' "$1"
}

note_fail() {
    fail_count=$((fail_count + 1))
    printf 'FAIL: %s\n' "$1"
    if [ -f "$OUT" ]; then
        sed 's/^/  /' "$OUT"
    fi
}

expect_pass() {
    _name="$1"
    shift
    if "$@" >"$OUT" 2>&1; then
        note_pass "$_name"
    else
        note_fail "$_name"
    fi
}

expect_fail() {
    _name="$1"
    shift
    if "$@" >"$OUT" 2>&1; then
        note_fail "$_name"
    else
        note_pass "$_name"
    fi
}

init_repo() {
    _repo="$1"
    mkdir -p "$_repo/docs/llm" "$_repo/scripts" "$_repo/docs"

    cat >"$_repo/docs/llm/HANDOFF.md" <<'EOF'
# Handoff

## Open work -- next concrete step

Touch `scripts/foo.sh` and ignore `*_PROPOSAL.md`.

- Last Updated: 2000-01-01
EOF

    cat >"$_repo/docs/llm/HISTORY.md" <<'EOF'
# History
EOF

    cat >"$_repo/docs/llm/DECISIONS.md" <<'EOF'
# Decisions
EOF

    cat >"$_repo/scripts/foo.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$_repo/scripts/foo.sh"

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    git -C "$_repo" commit -qm initial
}

init_malformed_repo() {
    _repo="$1"
    _missing="$2"
    mkdir -p "$_repo/docs/llm"

    if [ "$_missing" != "handoff" ]; then
        cat >"$_repo/docs/llm/HANDOFF.md" <<'EOF'
# Handoff
- Last Updated: 2000-01-01
EOF
    fi

    if [ "$_missing" != "history" ]; then
        cat >"$_repo/docs/llm/HISTORY.md" <<'EOF'
# History
EOF
    fi

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    git -C "$_repo" commit -qm initial
}

init_reference_date_repo() {
    _repo="$1"
    _date="$2"
    mkdir -p "$_repo/docs/llm" "$_repo/scripts"

    cat >"$_repo/docs/llm/HANDOFF.md" <<EOF
# Handoff
- Last Updated: $_date
EOF

    cat >"$_repo/docs/llm/HISTORY.md" <<EOF
# History

- $_date - Smoke - Commit-date entry. - Files: [docs/llm/HANDOFF.md, docs/llm/HISTORY.md] - Version impact: no
EOF

    cat >"$_repo/docs/llm/DECISIONS.md" <<'EOF'
# Decisions
EOF

    cat >"$_repo/scripts/foo.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$_repo/scripts/foo.sh"

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    GIT_AUTHOR_DATE="${_date}T12:00:00Z" GIT_COMMITTER_DATE="${_date}T12:00:00Z" \
        git -C "$_repo" commit -qm initial
}

init_gate_repo() {
    _repo="$1"
    mkdir -p "$_repo/docs/llm" "$_repo/docs" "$_repo/scripts"

    cp "$VALIDATOR" "$_repo/scripts/dockit-validate-session.sh"
    cp "$SESSION_GATE" "$_repo/scripts/dockit-session-gate.sh"
    cp "$PROJECT_ROOT/scripts/dockit-stop.py" "$_repo/scripts/dockit-stop.py"
    cp "$PROJECT_ROOT/scripts/dockit-trace-check.py" "$_repo/scripts/dockit-trace-check.py"
    cp "$CHECK_VERSION" "$_repo/scripts/check-version-sync.sh"
    chmod +x "$_repo/scripts/dockit-validate-session.sh" \
        "$_repo/scripts/dockit-session-gate.sh" \
        "$_repo/scripts/check-version-sync.sh"

    cat >"$_repo/docs/llm/HANDOFF.md" <<'EOF'
# Handoff

## Open work -- next concrete step

Touch `scripts/foo.sh`.

- Last Updated: 2000-01-01
EOF

    cat >"$_repo/docs/llm/HISTORY.md" <<'EOF'
# History

- 2000-01-01 - Smoke - Initial entry. - Files: [scripts/foo.sh] - Version impact: no
EOF

    cat >"$_repo/docs/llm/DECISIONS.md" <<'EOF'
# Decisions
EOF

    cat >"$_repo/scripts/foo.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$_repo/scripts/foo.sh"

    printf '0.1.0\n' >"$_repo/VERSION"
    cat >"$_repo/docs/version-sync-manifest.yml" <<'EOF'
targets:
- path: VERSION marker: version-file
EOF

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    GIT_AUTHOR_DATE="2000-01-01T12:00:00Z" GIT_COMMITTER_DATE="2000-01-01T12:00:00Z" \
        git -C "$_repo" commit -qm initial
}

write_version_files() {
    _repo="$1"
    _version="$2"

    cat >"$_repo/package.json" <<EOF
{
  "name": "version-smoke",
  "version": "$_version",
  "private": true
}
EOF

    cat >"$_repo/openapi.yml" <<EOF
openapi: 3.1.0
info:
  title: Version Smoke
  version: "$_version"
paths: {}
EOF

    cat >"$_repo/package-lock.json" <<EOF
{
  "name": "version-smoke",
  "version": "$_version",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "version-smoke",
      "version": "$_version"
    }
  }
}
EOF
}

init_version_repo() {
    _repo="$1"
    mkdir -p "$_repo/scripts" "$_repo/docs"
    cp "$CHECK_VERSION" "$_repo/scripts/check-version-sync.sh"
    cp "$BUMP_VERSION" "$_repo/scripts/bump-version.sh"
    chmod +x "$_repo/scripts/check-version-sync.sh" "$_repo/scripts/bump-version.sh"
    printf '1.2.3\n' >"$_repo/VERSION"
    cat >"$_repo/docs/version-sync-manifest.yml" <<'EOF'
targets:
- path: VERSION            marker: version-file
- path: package.json       marker: json-version
- path: openapi.yml        marker: yaml-info-version
- path: package-lock.json  marker: package-lock-version
EOF
    write_version_files "$_repo" "1.2.3"
}

init_sync_section_repo() {
    _repo="$1"
    _footer_mode="$2"
    mkdir -p "$_repo"

    cat >"$_repo/.dockit-enabled" <<'EOF'
enabled: true
EOF

    cat >"$_repo/.dockit-config.yml" <<'EOF'
adoption_mode: full
EOF

    if [ "$_footer_mode" = "with-footer" ]; then
        cat >"$_repo/LLM_START_HERE.md" <<'EOF'
# Old adopter start guide

Local project prose stays above synced template sections.

<!-- DOCKIT-TEMPLATE:START footer -->
---
Old footer text.
<!-- DOCKIT-TEMPLATE:END footer -->
EOF
    else
        cat >"$_repo/LLM_START_HERE.md" <<'EOF'
# Old adopter start guide

Local project prose with no footer marker.
EOF
    fi

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    git -C "$_repo" commit -qm initial
}

init_sync_versioned_doc_repo() {
    _repo="$1"
    mkdir -p "$_repo/docs" "$_repo/scripts"

    printf '0.1.0\n' >"$_repo/VERSION"
    cat >"$_repo/LLM_START_HERE.md" <<'EOF'
<!-- doc-version: 0.1.0 -->
# Versioned adopter start guide

<!-- DOCKIT-TEMPLATE:START footer -->
---
Old footer text.
<!-- DOCKIT-TEMPLATE:END footer -->
EOF

    cat >"$_repo/.dockit-enabled" <<'EOF'
enabled: true
EOF

    cat >"$_repo/.dockit-config.yml" <<'EOF'
adoption_mode: full
EOF

    cat >"$_repo/docs/version-sync-manifest.yml" <<'EOF'
targets:
- path: VERSION           marker: version-file
- path: LLM_START_HERE.md marker: html-comment
EOF

    git -C "$_repo" init -q
    git -C "$_repo" config user.email smoke@example.invalid
    git -C "$_repo" config user.name Smoke
    git -C "$_repo" add .
    git -C "$_repo" commit -qm initial
}

init_orientation_drift_repo() {
    _repo="$1"
    _mode="$2"
    mkdir -p "$_repo/docs/llm" "$_repo/docs"

    cat >"$_repo/.dockit-config.yml" <<'EOF'
orientation_drift:
  enabled: true
  roadmap: docs/ROADMAP.md
  docs:
    - LLM_START_HERE.md
    - docs/llm/HANDOFF.md
EOF

    cat >"$_repo/docs/ROADMAP.md" <<'EOF'
# Roadmap

## Phase 1
Status: complete

## Phase 2
Status: planned
EOF

    if [ "$_mode" = "drift" ]; then
        cat >"$_repo/LLM_START_HERE.md" <<'EOF'
# Start

Next work: Phase 1 cleanup.
EOF
    else
        cat >"$_repo/LLM_START_HERE.md" <<'EOF'
# Start

Next work: Phase 2 implementation.
EOF
    fi

    cat >"$_repo/docs/llm/HANDOFF.md" <<'EOF'
# Handoff

Next work: Phase 2 implementation.
EOF
}

mkdir -p "$TMP_ROOT"

REPO="$TMP_ROOT/main"
init_repo "$REPO"

expect_pass "env + clean stale handoff/history skips" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date --check history-entry

expect_fail "no env + clean stale handoff/history fails normally" \
    "$VALIDATOR" --project "$REPO" --quiet --check handoff-date --check history-entry

REFERENCE_DATE_REPO="$TMP_ROOT/reference-date"
init_reference_date_repo "$REFERENCE_DATE_REPO" "2001-02-03"
expect_pass "clean tree validates HANDOFF/HISTORY against last commit date, not wall clock" \
    "$VALIDATOR" --project "$REFERENCE_DATE_REPO" --quiet --check handoff-date --check history-entry

printf '\n# dirty\n' >>"$REFERENCE_DATE_REPO/scripts/foo.sh"
expect_fail "dirty tree validates HANDOFF/HISTORY against wall clock" \
    "$VALIDATOR" --project "$REFERENCE_DATE_REPO" --quiet --check handoff-date --check history-entry

if [ ! -x "$SESSION_GATE" ]; then
    note_pass "session gate smokes skipped when gate script is absent"
else
    GATE_REPO="$TMP_ROOT/session-gate"
    init_gate_repo "$GATE_REPO"
    printf '\n# inherited dirty state\n' >>"$GATE_REPO/scripts/foo.sh"

    printf '%s\n' '{"session_id":"unchanged","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    UNCHANGED_SLOT="$GATE_REPO/.git/.dockit/session-baselines/unchanged"
    touch -t 200001010000 "$UNCHANGED_SLOT"
    if printf '%s\n' '{"session_id":"unchanged","stop_hook_active":false}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && [ ! -s "$OUT" ] \
        && [ -f "$UNCHANGED_SLOT/state" ] \
        && find "$UNCHANGED_SLOT" -prune -mtime 0 -print 2>/dev/null | grep -q .; then
        FIRST_STOP_OK=1
    else
        FIRST_STOP_OK=0
    fi
    touch -t 200001010000 "$UNCHANGED_SLOT" 2>/dev/null || true
    if printf '%s\n' '{"session_id":"unchanged","stop_hook_active":false}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && [ ! -s "$OUT" ] \
        && [ -f "$UNCHANGED_SLOT/state" ] \
        && find "$UNCHANGED_SLOT" -prune -mtime 0 -print 2>/dev/null | grep -q . \
        && [ "$FIRST_STOP_OK" -eq 1 ]; then
        note_pass "inherited dirty session retains and refreshes its baseline across two read-only Stops"
    else
        note_fail "inherited dirty session retains and refreshes its baseline across two read-only Stops"
    fi

    printf '%s\n' '{"session_id":"changed-same-path","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    printf '\n# changed during session\n' >>"$GATE_REPO/scripts/foo.sh"
    if printf '%s\n' '{"session_id":"changed-same-path","stop_hook_active":false}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && grep -q '"decision":"block"' "$OUT" \
        && grep -q 'handoff-date' "$OUT" \
        && grep -q 'Last Updated is 2000-01-01' "$OUT"; then
        note_pass "session gate detects changes to an already-dirty path and reports real failures"
    else
        note_fail "session gate detects changes to an already-dirty path and reports real failures"
    fi

    CHANGED_SLOT="$GATE_REPO/.git/.dockit/session-baselines/changed-same-path"
    touch -t 200001010000 "$CHANGED_SLOT"
    if printf '%s\n' '{"session_id":"changed-same-path","stop_hook_active":true}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && [ ! -s "$OUT" ] \
        && [ -f "$CHANGED_SLOT/state" ] \
        && find "$CHANGED_SLOT" -prune -mtime 0 -print 2>/dev/null | grep -q .; then
        note_pass "active Stop hook yields and retains and refreshes its baseline"
    else
        note_fail "active Stop hook yields and retains and refreshes its baseline"
    fi

    printf '%s\n' '{"session_id":"stable-on-compact","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    cp "$GATE_REPO/.git/.dockit/session-baselines/stable-on-compact/state" "$OUT.baseline"
    printf '\n# post-baseline change\n' >>"$GATE_REPO/scripts/foo.sh"
    printf '%s\n' '{"session_id":"stable-on-compact","source":"compact"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    printf '%s\n' '{"session_id":"stable-on-compact","source":"resume"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    if cmp -s "$OUT.baseline" "$GATE_REPO/.git/.dockit/session-baselines/stable-on-compact/state"; then
        note_pass "compact and resume do not overwrite an existing baseline"
    else
        note_fail "compact and resume do not overwrite an existing baseline"
    fi

    printf '%s\n' '{"session_id":"parallel-a","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    printf '%s\n' '{"session_id":"parallel-b","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    if [ -f "$GATE_REPO/.git/.dockit/session-baselines/parallel-a/state" ] \
        && [ -f "$GATE_REPO/.git/.dockit/session-baselines/parallel-b/state" ]; then
        note_pass "parallel sessions keep isolated baselines"
    else
        note_fail "parallel sessions keep isolated baselines"
    fi

    printf '%s\n' '{"session_id":"untracked-only","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    printf 'draft\n' >"$GATE_REPO/untracked-draft.txt"
    if printf '%s\n' '{"session_id":"untracked-only","stop_hook_active":false}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && [ ! -s "$OUT" ]; then
        note_pass "session baseline explicitly excludes untracked files"
    else
        note_fail "session baseline explicitly excludes untracked files"
    fi
    rm -f "$GATE_REPO/untracked-draft.txt"

    printf '%s\n' '{"session_id":"invalid-baseline","source":"startup"}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    printf 'invalid\n' >"$GATE_REPO/.git/.dockit/session-baselines/invalid-baseline/state"
    if printf '%s\n' '{"session_id":"invalid-baseline","stop_hook_active":false}' \
        | "$GATE_REPO/scripts/dockit-session-gate.sh" --stop --project "$GATE_REPO" >"$OUT" 2>&1 \
        && grep -q '"decision":"block"' "$OUT"; then
        note_pass "invalid session baseline fails closed"
    else
        note_fail "invalid session baseline fails closed"
    fi

    mkdir -p "$GATE_REPO/.git/.dockit/session-baselines/stale-baseline"
    SLOTS="$GATE_REPO/.git/.dockit/session-baselines"
    mkdir -p "$SLOTS/old-in-use"
    printf 'retain\n' >"$SLOTS/old-in-use/state"
    printf 'retain\n' >"$SLOTS/old-in-use/unrelated"
    touch -t 200001010000 "$SLOTS/old-in-use" "$SLOTS/stale-baseline"
    printf '%s\n' '{"session_id":"prune-trigger","source":"startup"}' \
        | DOCKIT_BASELINE_MAX_AGE_DAYS=7 "$GATE_REPO/scripts/dockit-session-gate.sh" --start --project "$GATE_REPO" >"$OUT" 2>&1
    if [ ! -d "$SLOTS/stale-baseline" ] && [ -f "$SLOTS/old-in-use/state" ] && [ -f "$SLOTS/old-in-use/unrelated" ]; then
        note_pass "session baseline writer retires only empty expired slots"
    else
        note_fail "session baseline writer retires only empty expired slots"
    fi
fi

printf '\nchange\n' >>"$REPO/docs/llm/HANDOFF.md"
expect_fail "env + modified HANDOFF does not skip" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date
git -C "$REPO" checkout -q -- docs/llm/HANDOFF.md

printf '\n# change\n' >>"$REPO/scripts/foo.sh"
expect_fail "env + modified unrelated tracked file does not skip" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date
git -C "$REPO" checkout -q -- scripts/foo.sh

printf 'draft\n' >"$REPO/documento.md"
expect_pass "env + only untracked files skips" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date --check history-entry
rm -f "$REPO/documento.md"

printf '\n# staged\n' >>"$REPO/scripts/foo.sh"
git -C "$REPO" add scripts/foo.sh
expect_fail "env + staged change does not skip" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date
git -C "$REPO" reset -q --hard HEAD

expect_pass "orientation ignores glob-shaped backtick strings" \
    "$VALIDATOR" --project "$REPO" --quiet --check orientation

expect_pass "orientation-drift skips without config" \
    "$VALIDATOR" --project "$REPO" --quiet --check orientation-drift

ORIENTATION_OK="$TMP_ROOT/orientation-ok"
init_orientation_drift_repo "$ORIENTATION_OK" "clean"
expect_pass "orientation-drift accepts current docs after completed roadmap phase" \
    "$VALIDATOR" --project "$ORIENTATION_OK" --quiet --check orientation-drift

ORIENTATION_DRIFT="$TMP_ROOT/orientation-drift"
init_orientation_drift_repo "$ORIENTATION_DRIFT" "drift"
expect_fail "orientation-drift rejects docs that call a completed phase next" \
    "$VALIDATOR" --project "$ORIENTATION_DRIFT" --quiet --check orientation-drift

MISSING_HANDOFF="$TMP_ROOT/missing-handoff"
init_malformed_repo "$MISSING_HANDOFF" handoff
expect_fail "env + clean malformed repo without HANDOFF still fails" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$MISSING_HANDOFF" --quiet --check handoff-date

MISSING_HISTORY="$TMP_ROOT/missing-history"
init_malformed_repo "$MISSING_HISTORY" history
expect_fail "env + clean malformed repo without HISTORY still fails" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$MISSING_HISTORY" --quiet --check history-entry

HISTORY_REPO="$TMP_ROOT/history"
init_repo "$HISTORY_REPO"

cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

YYYY-MM-DD - Template - Example line that must not count.
\`\`\`
2025-01-15 - Template - Concrete fenced example that must not count.
\`\`\`
$TODAY - Smoke - No-dash entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_pass "history default any accepts no-dash and skips template examples" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

- $TODAY - Smoke - Dash entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_pass "history default any accepts dash" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

cat >"$HISTORY_REPO/.dockit-config.yml" <<'EOF'
history_format: dash
EOF
cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

$TODAY - Smoke - No-dash entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_fail "history strict dash rejects no-dash" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

cat >"$HISTORY_REPO/.dockit-config.yml" <<'EOF'
history_format: no-dash
EOF
cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

- $TODAY - Smoke - Dash entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_fail "history strict no-dash rejects dash" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

$TODAY - Smoke - No-dash entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_pass "history strict no-dash accepts no-dash" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

rm -f "$HISTORY_REPO/.dockit-config.yml"
cat >"$HISTORY_REPO/docs/llm/HISTORY.md" <<EOF
# History

- $TODAY - Smoke - Current entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
- 2999-12-31 - Smoke - Future entry below current entry. - Files: [docs/llm/HISTORY.md] - Version impact: no
EOF
expect_fail "history newest-first rejects later date below first entry" \
    "$VALIDATOR" --project "$HISTORY_REPO" --quiet --check history-entry

expect_pass "trace-protocol skips without .dockit-config.yml" \
    "$VALIDATOR" --project "$REPO" --quiet --check trace-protocol

TRACE_REPO="$TMP_ROOT/trace"
init_repo "$TRACE_REPO"
TRACE_HASH=$(git -C "$TRACE_REPO" rev-parse --short=7 HEAD)
TRACE_SUBJECT=$(git -C "$TRACE_REPO" show -s --format=%s HEAD)
TRACE_TIME=$(TZ=UTC git -C "$TRACE_REPO" show -s --format=%cd \
    --date=format-local:'%Y-%m-%d %H:%M:%S UTC' HEAD)

cat >"$TRACE_REPO/.dockit-config.yml" <<'EOF'
adoption_mode: full

trace_protocol:
  enabled: true
  since: 2000-01-01
EOF

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Current target: \`$TRACE_HASH\` $TRACE_SUBJECT
- Commit time: $TRACE_TIME
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Audited \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF

expect_pass "trace-protocol valid anchor and HISTORY footer pass" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

TRACE_OFFSET_REPO="$TMP_ROOT/trace-offset"
init_repo "$TRACE_OFFSET_REPO"
GIT_AUTHOR_DATE="2000-01-02T08:43:29+0200" \
GIT_COMMITTER_DATE="2000-01-02T08:43:29+0200" \
    git -C "$TRACE_OFFSET_REPO" commit --allow-empty -qm "offset commit"
TRACE_OFFSET_HASH=$(git -C "$TRACE_OFFSET_REPO" rev-parse --short=7 HEAD)
TRACE_OFFSET_SUBJECT=$(git -C "$TRACE_OFFSET_REPO" show -s --format=%s HEAD)
TRACE_OFFSET_TIME=$(TZ=UTC git -C "$TRACE_OFFSET_REPO" show -s --format=%cd \
    --date=format-local:'%Y-%m-%d %H:%M:%S UTC' HEAD)
cat >"$TRACE_OFFSET_REPO/.dockit-config.yml" <<'EOF'
adoption_mode: full

trace_protocol:
  enabled: true
  since: 2000-01-01
EOF
cat >"$TRACE_OFFSET_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Subject: \`$TRACE_OFFSET_HASH\` $TRACE_OFFSET_SUBJECT
- Commit time: $TRACE_OFFSET_TIME
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF
cat >"$TRACE_OFFSET_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-03 - Smoke - Audited \`$TRACE_OFFSET_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_OFFSET_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_pass "trace-protocol renders non-UTC commit offsets as UTC" \
    "$VALIDATOR" --project "$TRACE_OFFSET_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Audited local \`$TRACE_HASH\` against ForgeOS \`deadbee\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; external=forgeos@deadbee; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_pass "trace-protocol accepts explicitly namespaced external commits" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Audited local \`$TRACE_HASH\` against ForgeOS \`deadbee\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_fail "trace-protocol rejects undeclared external-looking commits" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Audited local \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; external=forgeos-deadbee; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_fail "trace-protocol rejects malformed external commit references" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

2000-01-02 - Smoke - Audited \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_pass "trace-protocol accepts no-dash HISTORY footer" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: advisor
- Current target: \`$TRACE_HASH\` $TRACE_SUBJECT
- Commit time: $TRACE_TIME
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Advised on \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=advisor; commits=$TRACE_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF

expect_pass "trace-protocol accepts advisor role" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

TRACE_TIME_MINUTES=$(TZ=UTC git -C "$TRACE_REPO" show -s --format=%cd \
    --date=format-local:'%Y-%m-%d %H:%M UTC' HEAD)
cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Current target: \`$TRACE_HASH\` $TRACE_SUBJECT
- Commit time: $TRACE_TIME_MINUTES
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF

expect_pass "trace-protocol accepts commit time without seconds" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/.dockit-config.yml" <<'EOF'
adoption_mode: full

trace_protocol:
  enabled: true
  since: 2000-01-01
  reject_current_anchor_label: true
EOF

expect_fail "trace-protocol can reject current-labelled anchors" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Subject: \`$TRACE_HASH\` $TRACE_SUBJECT
- Commit time: $TRACE_TIME
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF

expect_pass "trace-protocol accepts neutral Subject anchor label" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

TRACE_STATUS_REPO="$TMP_ROOT/trace-status"
init_repo "$TRACE_STATUS_REPO"
TRACE_STATUS_HASH=$(git -C "$TRACE_STATUS_REPO" rev-parse --short=7 HEAD)
expect_pass "trace-status emits current HEAD and clean repo state" \
    sh -c "'$TRACE_STATUS' --format text --project '$TRACE_STATUS_REPO' --role executor --subject smoke --validation smoke-pass --next operator >'$OUT' && grep -q 'HEAD=$TRACE_STATUS_HASH' '$OUT' && grep -q 'Repo state: .*clean' '$OUT'"

expect_pass "trace-status accepts advisor role" \
    sh -c "'$TRACE_STATUS' --format text --project '$TRACE_STATUS_REPO' --role advisor --subject smoke --validation smoke-pass --next operator >'$OUT' && grep -q 'Role: advisor' '$OUT'"

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 2000-01-02 - Smoke - Audited \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no
EOF
expect_fail "trace-protocol backticked HISTORY hash requires footer" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

- 1999-12-31 - Smoke - Audited \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no
EOF
expect_pass "trace-protocol ignores pre-since HISTORY hashes" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF
expect_fail "trace-protocol enabled requires HANDOFF Trace Anchor" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Current target: \`deadbeefdead\` fake subject
- Commit time: 2000-01-01 00:00 UTC
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF
expect_fail "trace-protocol invalid anchor hash fails" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

cat >"$TRACE_REPO/docs/llm/HANDOFF.md" <<EOF
# Handoff

## Trace Anchor

- Role: auditor
- Current target: \`$TRACE_HASH\` $TRACE_SUBJECT
- Commit time: $TRACE_TIME
- State verified: local main, no origin remote in smoke repo
- Validation: smoke=pass
- Next gate: operator

## Open work -- next concrete step

Touch \`scripts/foo.sh\`.
EOF

cat >"$TRACE_REPO/.dockit-config.yml" <<'EOF'
adoption_mode: full

trace_protocol:
  enabled: true
EOF
expect_fail "trace-protocol enabled requires since date" \
    "$VALIDATOR" --project "$TRACE_REPO" --quiet --check trace-protocol

VERSION_REPO="$TMP_ROOT/version"
init_version_repo "$VERSION_REPO"

expect_pass "version-sync accepts matching json/yaml/package-lock markers" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"

write_version_files "$VERSION_REPO" "1.2.3"
sed 's/"version": "1.2.3"/"version": "9.9.9"/' "$VERSION_REPO/package.json" >"$VERSION_REPO/package.json.tmp"
mv "$VERSION_REPO/package.json.tmp" "$VERSION_REPO/package.json"
expect_fail "version-sync detects json-version drift" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"

write_version_files "$VERSION_REPO" "1.2.3"
sed 's/version: "1.2.3"/version: "9.9.9"/' "$VERSION_REPO/openapi.yml" >"$VERSION_REPO/openapi.yml.tmp"
mv "$VERSION_REPO/openapi.yml.tmp" "$VERSION_REPO/openapi.yml"
expect_fail "version-sync detects yaml-info-version drift" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"

write_version_files "$VERSION_REPO" "1.2.3"
awk '
    /"version": "1.2.3"/ && !done { sub(/"1.2.3"/, "\"9.9.9\""); done = 1 }
    { print }
' "$VERSION_REPO/package-lock.json" >"$VERSION_REPO/package-lock.json.tmp"
mv "$VERSION_REPO/package-lock.json.tmp" "$VERSION_REPO/package-lock.json"
expect_fail "version-sync detects package-lock top-level drift" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"

write_version_files "$VERSION_REPO" "1.2.3"
awk '
    /"version": "1.2.3"/ { count += 1 }
    count == 2 && /"version": "1.2.3"/ { sub(/"1.2.3"/, "\"9.9.9\"") }
    { print }
' "$VERSION_REPO/package-lock.json" >"$VERSION_REPO/package-lock.json.tmp"
mv "$VERSION_REPO/package-lock.json.tmp" "$VERSION_REPO/package-lock.json"
expect_fail "version-sync detects package-lock root package drift" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"

write_version_files "$VERSION_REPO" "1.2.3"
cp "$VERSION_REPO/docs/version-sync-manifest.yml" "$VERSION_REPO/docs/version-sync-manifest.yml.good"
sed 's/json-version/unknown-marker/' "$VERSION_REPO/docs/version-sync-manifest.yml.good" >"$VERSION_REPO/docs/version-sync-manifest.yml"
expect_fail "version-sync rejects unknown marker type" \
    sh -c "cd '$VERSION_REPO' && scripts/check-version-sync.sh"
mv "$VERSION_REPO/docs/version-sync-manifest.yml.good" "$VERSION_REPO/docs/version-sync-manifest.yml"

write_version_files "$VERSION_REPO" "1.2.3"
expect_pass "bump-version updates json/yaml/package-lock markers" \
    sh -c "cd '$VERSION_REPO' && scripts/bump-version.sh 2.0.0"

if grep -q '"version": "2.0.0"' "$VERSION_REPO/package.json" \
    && grep -q 'version: 2.0.0' "$VERSION_REPO/openapi.yml" \
    && [ "$(grep -c '"version": "2.0.0"' "$VERSION_REPO/package-lock.json")" -ge 2 ]; then
    note_pass "bump-version wrote package-lock top-level and root package versions"
else
    {
        echo "package.json/openapi.yml/package-lock.json did not all reach 2.0.0"
        sed -n '1,80p' "$VERSION_REPO/package-lock.json"
    } >"$OUT"
    note_fail "bump-version wrote package-lock top-level and root package versions"
fi

if [ ! -x "$SYNC_TOOL" ]; then
    note_pass "dockit-sync missing-section smoke skipped when sync tool is absent"
else
    SYNC_FOOTER_REPO="$TMP_ROOT/sync-footer"
    init_sync_section_repo "$SYNC_FOOTER_REPO" "with-footer"
    if "$SYNC_TOOL" --init-state --project "$SYNC_FOOTER_REPO" >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --apply --project "$SYNC_FOOTER_REPO" >"$OUT" 2>&1 \
        && awk '
            /<!-- DOCKIT-TEMPLATE:START trace-protocol -->/ { trace = NR }
            /<!-- DOCKIT-TEMPLATE:START footer -->/ { footer = NR }
            END { exit !(trace > 0 && footer > 0 && trace < footer) }
        ' "$SYNC_FOOTER_REPO/LLM_START_HERE.md" \
        && grep -q 'WARN: Sync applied successfully' "$OUT" \
        && ! grep -q 'CONFLICT\|ERROR' "$OUT"; then
        note_pass "dockit-sync inserts missing full-adopter sections before footer"
    else
        {
            echo "dockit-sync did not insert missing section before footer"
            [ -f "$SYNC_FOOTER_REPO/LLM_START_HERE.md" ] && sed -n '1,220p' "$SYNC_FOOTER_REPO/LLM_START_HERE.md"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync inserts missing full-adopter sections before footer"
    fi

    # Placement of a newly added section, line endings and repeated syncs.
    sync_fixture() {
        _sf_repo="$TMP_ROOT/$1"; _sf_eol="$2"; shift 2
        init_sync_section_repo "$_sf_repo" "with-footer"
        printf "%s$_sf_eol" "$@" '<!-- DOCKIT-TEMPLATE:START footer -->' '---' 'Old footer text.' \
            '<!-- DOCKIT-TEMPLATE:END footer -->' >"$_sf_repo/LLM_START_HERE.md"
        git -C "$_sf_repo" commit -qam fixture
    }
    sync_twice() {
        "$SYNC_TOOL" --init-state --project "$1" >"$OUT" 2>&1 \
            && "$SYNC_TOOL" --apply --only LLM_START_HERE.md --project "$1" >"$OUT.first" 2>&1 \
            && "$SYNC_TOOL" --apply --only LLM_START_HERE.md --project "$1" >"$OUT" 2>&1 \
            && ! grep -q 'CONFLICT\|ERROR' "$OUT.first" "$OUT"
    }
    # One leave-no-residue section, at RELATION to the first line matching ANCHOR.
    sync_rule_once() {
        tr -d '\r' <"$1/LLM_START_HERE.md" | awk -v anchor="$2" -v relation="$3" '
            $0 == anchor && !at { at = NR }
            /^<!-- DOCKIT-TEMPLATE:START leave-no-residue -->$/ { rule = NR; rules++ }
            /^<!-- DOCKIT-TEMPLATE:END checklist -->$/ { checklist_end = NR }
            /^<!-- DOCKIT-TEMPLATE:START footer -->$/ { footer = NR; footers++ }
            END {
                ok = (rules == 1 && footers == 1 && at > 0 && rule < footer)
                if (relation == "under") ok = ok && rule == at + 2
                if (relation == "after") ok = ok && rule > at + 2
                if (relation == "past-checklist") ok = ok && rule > checklist_end
                exit !ok
            }'
    }
    sync_case() { if eval "$2"; then note_pass "$1"; else cat "$OUT.first" "$OUT" >"$OUT.tmp" 2>/dev/null; mv "$OUT.tmp" "$OUT"; note_fail "$1"; fi; }
    SYNC_CR=$(printf '\r')
    SYNC_HEADING='## Critical Rules (Non-Negotiable)'
    SYNC_FALLBACK='using the footer placement instead'

    sync_fixture sync-anchor-lf '\n' '# Guide' '' "$SYNC_HEADING" '' '### Language Policy' '- Local rule.' ''
    sync_case "dockit-sync inserts a heading-anchored section under its heading, once after two LF syncs" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" under && ! grep -q "$SYNC_CR" "$_sf_repo/LLM_START_HERE.md"'

    SYNC_LF_RESULT="$_sf_repo/LLM_START_HERE.md"
    sync_fixture sync-backup-retention '\n' '# Guide' '' "$SYNC_HEADING" ''
    _backup_root="$_sf_repo/.git/.dockit/backups"
    for _old in 1 2 3 4 5 6 7; do
        mkdir -p "$_backup_root/old-$_old"
        printf 'custody-%s\n' "$_old" > "$_backup_root/old-$_old/backup-manifest.txt"
    done
    sync_backups_preserved() {
        sync_twice "$_sf_repo" || return 1
        for _old in 1 2 3 4 5 6 7; do
            [ "$(cat "$_backup_root/old-$_old/backup-manifest.txt")" = "custody-$_old" ] || return 1
        done
        # Select only the section-merge file: full-sync YAML normalization is
        # separately tested and can legitimately change on its second apply.
        # First apply retains its real rollback; the unchanged second apply
        # removes only its own empty directory, not that first backup.
        [ "$(find "$_backup_root" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 8 ] \
            && grep -q 'Rollback backup retained:' "$OUT.first"
    }
    sync_case "dockit-sync preserves all previous backups and retires its own no-change scaffold" sync_backups_preserved

    sync_fixture sync-crlf-present '\r\n' '# placeholder'
    sed "s/\$/$SYNC_CR/" "$SYNC_LF_RESULT" >"$_sf_repo/LLM_START_HERE.md"
    git -C "$_sf_repo" commit -qam "CRLF file that already carries every section"
    sync_case "dockit-sync keeps one section and CRLF endings when a CRLF file already carries it" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" under && ! grep -qv "$SYNC_CR\$" "$_sf_repo/LLM_START_HERE.md" && git -C "$_sf_repo" diff --quiet -- LLM_START_HERE.md'

    sync_fixture sync-crlf-missing '\r\n' '# Guide' '' "$SYNC_HEADING" '' '### Language Policy' '- Local rule.' ''
    sync_case "dockit-sync inserts one CRLF section under its heading after two CRLF syncs" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" under && ! grep -qv "$SYNC_CR\$" "$_sf_repo/LLM_START_HERE.md"'

    sync_fixture sync-anchor-fence '\n' '# Guide' '' '```markdown' "$SYNC_HEADING" '```' '' 'Local prose.' ''
    sync_case "dockit-sync does not anchor on a heading inside a code block and says so" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" after && grep -qF "$SYNC_FALLBACK" "$OUT.first"'

    sync_fixture sync-anchor-managed '\n' '# Guide' '' '<!-- DOCKIT-TEMPLATE:START checklist -->' "$SYNC_HEADING" \
        '<!-- DOCKIT-TEMPLATE:END checklist -->' ''
    sync_case "dockit-sync does not anchor on a heading inside another managed section and says so" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "<!-- DOCKIT-TEMPLATE:START checklist -->" past-checklist && grep -qF "$SYNC_FALLBACK" "$OUT.first"'

    sync_fixture sync-anchor-twice '\n' '# Guide' '' "$SYNC_HEADING" '' "$SYNC_HEADING" ''
    sync_case "dockit-sync does not anchor on a heading that occurs twice and says so" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" after && grep -qF "$SYNC_FALLBACK" "$OUT.first"'

    # Doubt about what precedes the heading keeps the footer placement.
    sync_fallback_case() {
        _sfc_name="$1"; _sfc_repo="$2"; shift 2
        sync_fixture "$_sfc_repo" '\n' "$@"
        sync_case "dockit-sync keeps the footer placement: $_sfc_name" \
            'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" after && grep -qF "$SYNC_FALLBACK" "$OUT.first"'
    }
    sync_fallback_case "inline triple backticks before a fenced example" sync-anchor-inline \
        '# Guide' '' '``` inline code ```' '' '```' "$SYNC_HEADING" '```' ''
    sync_fallback_case "heading inside <pre>" sync-anchor-pre '# Guide' '' '<pre>' '' "$SYNC_HEADING" '' '</pre>' ''
    sync_fallback_case "heading inside an HTML comment closed before the footer" sync-anchor-comment '# Guide' '' '<!-- draft' '' "$SYNC_HEADING" '' 'Local prose.' '-->' ''
    sync_fallback_case "heading inside a tilde fence" sync-anchor-tilde '# Guide' '' '~~~' '' "$SYNC_HEADING" '' '~~~' ''
    sync_fallback_case "heading not preceded by a blank line" sync-anchor-tight '# Guide' '' '<div>' "$SYNC_HEADING" '</div>' ''
    sync_fixture sync-anchor-nested '\n' '# Guide' '' '<!-- DOCKIT-TEMPLATE:START checklist -->' \
        '<!-- DOCKIT-TEMPLATE:START do-not-touch -->' '<!-- DOCKIT-TEMPLATE:END do-not-touch -->' '' "$SYNC_HEADING" '' \
        '<!-- DOCKIT-TEMPLATE:END checklist -->' ''
    sync_case "dockit-sync keeps the footer placement: heading after a nested managed section closes" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "<!-- DOCKIT-TEMPLATE:START checklist -->" past-checklist && grep -qF "$SYNC_FALLBACK" "$OUT.first"'

    sync_unsafe_footer_case() {
        _suf_label="$1"; _suf_open="$2"
        sync_fixture "sync-unsafe-$_suf_label" '\n' '# Guide' '' "$_suf_open" '' "$SYNC_HEADING" ''
        sync_case "dockit-sync refuses a footer inside an unclosed $_suf_label without changing source" \
            '"$SYNC_TOOL" --init-state --project "$_sf_repo" >"$OUT.first" 2>&1 && ! "$SYNC_TOOL" --apply --project "$_sf_repo" >"$OUT" 2>&1 && grep -q "footer is inside an unclosed" "$OUT" && git -C "$_sf_repo" diff --quiet -- LLM_START_HERE.md'
    }
    sync_unsafe_footer_case comment '<!-- draft'
    sync_unsafe_footer_case fence '```markdown'
    sync_unsafe_footer_case literal '<pre>'
    sync_unsafe_footer_case cdata '<![CDATA['
    sync_unsafe_footer_case processing '<?draft'

    sync_fixture sync-anchor-paired '\n' '<!-- doc-version: 1.0.0 -->' '# Guide' '' '```sh' 'echo one' '```' '' '~~~' 'two' '~~~' '' \
        "$SYNC_HEADING" '' '### Language Policy' ''
    sync_case "dockit-sync still anchors after closed fences and a closed comment" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" under && ! grep -qF "$SYNC_FALLBACK" "$OUT.first"'

    sync_fixture sync-lf-present '\n' '# placeholder'
    cp "$SYNC_LF_RESULT" "$_sf_repo/LLM_START_HERE.md"
    git -C "$_sf_repo" commit -qam "LF file that already carries every section"
    sync_case "dockit-sync leaves an LF file that carries every section byte-identical" \
        'sync_twice "$_sf_repo" && git -C "$_sf_repo" diff --quiet -- LLM_START_HERE.md'

    sync_fixture sync-managed-title '\n' '# Guide' '' '<!-- DOCKIT-TEMPLATE:START checklist -->' '### Leave no residue' \
        '<!-- DOCKIT-TEMPLATE:END checklist -->' '' "$SYNC_HEADING" ''
    sync_case "dockit-sync does not report a conflict for the title inside managed content" \
        'sync_twice "$_sf_repo" && sync_rule_once "$_sf_repo" "$SYNC_HEADING" under'

    sync_fixture sync-partial-local '\n' '# Guide' '' "$SYNC_HEADING" '' '### Leave no residue' 'Local wording.' ''
    printf 'adoption_mode: partial\n' >"$_sf_repo/.dockit-config.yml"
    git -C "$_sf_repo" commit -qam "partial adopter with its own rule"
    sync_case "dockit-sync leaves a partial adopter's local rule alone and updates its footer" \
        'sync_twice "$_sf_repo" && ! grep -q "DOCKIT-TEMPLATE:START leave-no-residue" "$_sf_repo/LLM_START_HERE.md" && grep -qx "Local wording." "$_sf_repo/LLM_START_HERE.md" && ! grep -q "Old footer text." "$_sf_repo/LLM_START_HERE.md"'

    sync_fixture sync-local-rule '\n' '# Guide' '' "$SYNC_HEADING" '' '### Leave no residue' 'Local wording.' ''
    sync_case "dockit-sync reports an unmarked local section instead of duplicating it" \
        '"$SYNC_TOOL" --init-state --project "$_sf_repo" >"$OUT.first" 2>&1 && ! "$SYNC_TOOL" --apply --project "$_sf_repo" >"$OUT" 2>&1 && grep -q "ERROR .*unmarked local section .### Leave no residue. at line 5" "$OUT" && ! grep -q "DOCKIT-TEMPLATE:START leave-no-residue" "$_sf_repo/LLM_START_HERE.md" && git -C "$_sf_repo" diff --quiet -- LLM_START_HERE.md'

    SYNC_APPEND_REPO="$TMP_ROOT/sync-append"
    init_sync_section_repo "$SYNC_APPEND_REPO" "without-footer"
    if "$SYNC_TOOL" --init-state --project "$SYNC_APPEND_REPO" >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --apply --project "$SYNC_APPEND_REPO" >"$OUT" 2>&1 \
        && grep -q '<!-- DOCKIT-TEMPLATE:START trace-protocol -->' "$SYNC_APPEND_REPO/LLM_START_HERE.md" \
        && grep -q '<!-- DOCKIT-TEMPLATE:START footer -->' "$SYNC_APPEND_REPO/LLM_START_HERE.md" \
        && ! grep -q 'CONFLICT\|ERROR' "$OUT"; then
        note_pass "dockit-sync appends missing full-adopter sections without footer"
    else
        {
            echo "dockit-sync did not append missing sections without footer"
            [ -f "$SYNC_APPEND_REPO/LLM_START_HERE.md" ] && sed -n '1,220p' "$SYNC_APPEND_REPO/LLM_START_HERE.md"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync appends missing full-adopter sections without footer"
    fi

    SYNC_VERSIONED_REPO="$TMP_ROOT/sync-versioned-doc"
    init_sync_versioned_doc_repo "$SYNC_VERSIONED_REPO"
    if "$SYNC_TOOL" --init-state --project "$SYNC_VERSIONED_REPO" >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --apply --project "$SYNC_VERSIONED_REPO" >"$OUT" 2>&1 \
        && grep -q '<!-- doc-version: 0.1.0 -->' "$SYNC_VERSIONED_REPO/docs/integrations/CODEX.md" \
        && sh -c "cd '$SYNC_VERSIONED_REPO' && scripts/check-version-sync.sh" >"$OUT" 2>&1; then
        note_pass "dockit-sync normalizes copied doc-version markers to project version"
    else
        {
            echo "dockit-sync did not normalize copied doc-version markers"
            [ -f "$SYNC_VERSIONED_REPO/docs/integrations/CODEX.md" ] && sed -n '1,40p' "$SYNC_VERSIONED_REPO/docs/integrations/CODEX.md"
            [ -f "$SYNC_VERSIONED_REPO/docs/version-sync-manifest.yml" ] && sed -n '1,80p' "$SYNC_VERSIONED_REPO/docs/version-sync-manifest.yml"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync normalizes copied doc-version markers to project version"
    fi

    SYNC_ONLY_REPO="$TMP_ROOT/sync-only-section"
    init_sync_section_repo "$SYNC_ONLY_REPO" "with-footer"
    if "$SYNC_TOOL" --init-state --project "$SYNC_ONLY_REPO" >"$OUT" 2>&1; then
        SYNC_ONLY_STATE="$SYNC_ONLY_REPO/.git/.dockit/state.yml"
        sed 's/^template_version:.*/template_version: "3.9.9"/' \
            "$SYNC_ONLY_STATE" >"$SYNC_ONLY_STATE.tmp"
        mv "$SYNC_ONLY_STATE.tmp" "$SYNC_ONLY_STATE"
    fi

    if "$SYNC_TOOL" --apply --project "$SYNC_ONLY_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q '<!-- DOCKIT-TEMPLATE:START independent-review-policy -->' \
            "$SYNC_ONLY_REPO/LLM_START_HERE.md" \
        && grep -q 'Old footer text.' "$SYNC_ONLY_REPO/LLM_START_HERE.md" \
        && ! grep -q '<!-- DOCKIT-TEMPLATE:START trace-protocol -->' \
            "$SYNC_ONLY_REPO/LLM_START_HERE.md" \
        && grep -q '^template_version: "3.9.9"$' "$SYNC_ONLY_STATE" \
        && grep -Eq '^    independent-review-policy: "[0-9a-f]{64}"$' "$SYNC_ONLY_STATE" \
        && grep -Eq '^    footer: "[0-9a-f]{64}"$' "$SYNC_ONLY_STATE" \
        && grep -q '^last_sync_mode: "apply-selective"$' "$SYNC_ONLY_STATE" \
        && grep -q 'preserved template_version/template_ref' "$OUT" \
        && [ "$(git -C "$SYNC_ONLY_REPO" status --porcelain)" = " M LLM_START_HERE.md" ]; then
        note_pass "dockit-sync selects one section without claiming full template currency"
    else
        {
            echo "dockit-sync did not isolate the selected section or preserve state"
            [ -f "$SYNC_ONLY_REPO/LLM_START_HERE.md" ] && sed -n '1,240p' "$SYNC_ONLY_REPO/LLM_START_HERE.md"
            [ -f "$SYNC_ONLY_STATE" ] && sed -n '1,80p' "$SYNC_ONLY_STATE"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync selects one section without claiming full template currency"
    fi

    SYNC_PRE_REG_REPO="$TMP_ROOT/sync-pre-registration"
    init_sync_section_repo "$SYNC_PRE_REG_REPO" "with-footer"
    if "$SYNC_TOOL" --init-state --untracked-existing-adoption \
            --project "$SYNC_PRE_REG_REPO" >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --init-state --untracked-existing-adoption \
            --project "$SYNC_PRE_REG_REPO" >"$OUT" 2>&1 \
        && grep -q '^template_version: "pre-registration"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && grep -q '^template_ref: "untracked-existing-adoption"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && grep -Eq '^    footer: "[0-9a-f]{64}"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && "$SYNC_TOOL" --apply --project "$SYNC_PRE_REG_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q '^template_version: "pre-registration"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && grep -q '^template_ref: "untracked-existing-adoption"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && grep -Eq '^    independent-review-policy: "[0-9a-f]{64}"$' \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml"; then
        note_pass "dockit-sync creates honest pre-registration state and preserves it"
    else
        note_fail "dockit-sync creates honest pre-registration state and preserves it"
    fi

    cp "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" "$TMP_ROOT/pre-registration.state"
    if ! "$SYNC_TOOL" --init-state --project "$SYNC_PRE_REG_REPO" >"$OUT" 2>&1 \
        && cmp -s "$TMP_ROOT/pre-registration.state" \
            "$SYNC_PRE_REG_REPO/.git/.dockit/state.yml" \
        && grep -q 'Refusing to replace sync identity pre-registration / untracked-existing-adoption' "$OUT"; then
        note_pass "dockit-sync protects pre-registration identity from plain reinitialization"
    else
        note_fail "dockit-sync protects pre-registration identity from plain reinitialization"
    fi

    SYNC_KNOWN_IDENTITY_REPO="$TMP_ROOT/sync-known-identity"
    init_sync_section_repo "$SYNC_KNOWN_IDENTITY_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_KNOWN_IDENTITY_REPO" >"$OUT" 2>&1
    cp "$SYNC_KNOWN_IDENTITY_REPO/.git/.dockit/state.yml" "$TMP_ROOT/known-identity.state"
    if ! "$SYNC_TOOL" --init-state --untracked-existing-adoption \
            --project "$SYNC_KNOWN_IDENTITY_REPO" >"$OUT" 2>&1 \
        && cmp -s "$TMP_ROOT/known-identity.state" \
            "$SYNC_KNOWN_IDENTITY_REPO/.git/.dockit/state.yml" \
        && grep -q 'Refusing to replace sync identity' "$OUT" \
        && grep -q -- '-> pre-registration / untracked-existing-adoption' "$OUT"; then
        note_pass "dockit-sync protects evidenced identity from sentinel replacement"
    else
        note_fail "dockit-sync protects evidenced identity from sentinel replacement"
    fi

    if "$SYNC_TOOL" --init-state --untracked-existing-adoption --force \
            --project "$SYNC_KNOWN_IDENTITY_REPO" >"$OUT" 2>&1 \
        && grep -q '^template_version: "pre-registration"$' \
            "$SYNC_KNOWN_IDENTITY_REPO/.git/.dockit/state.yml" \
        && grep -q 'Replacing sync identity' "$OUT"; then
        note_pass "dockit-sync requires explicit force for identity replacement"
    else
        note_fail "dockit-sync requires explicit force for identity replacement"
    fi

    if ! "$SYNC_TOOL" --dry-run --untracked-existing-adoption \
            --project "$SYNC_PRE_REG_REPO" >"$OUT" 2>&1 \
        && grep -q -- '--untracked-existing-adoption requires --init-state' "$OUT"; then
        note_pass "dockit-sync rejects pre-registration identity outside init-state"
    else
        note_fail "dockit-sync rejects pre-registration identity outside init-state"
    fi

    if ! "$SYNC_TOOL" --init-state --untracked-existing-adoption \
            --all --src-root "$TMP_ROOT" >"$OUT" 2>&1 \
        && grep -q -- '--untracked-existing-adoption requires one --project, not --all' "$OUT"; then
        note_pass "dockit-sync rejects fleet-wide pre-registration initialization"
    else
        note_fail "dockit-sync rejects fleet-wide pre-registration initialization"
    fi

    cp "$SYNC_ONLY_REPO/LLM_START_HERE.md" "$SYNC_ONLY_REPO/LLM_START_HERE.before-invalid"
    if ! "$SYNC_TOOL" --apply --project "$SYNC_ONLY_REPO" \
            --only LLM_START_HERE.md:not-a-template-section >"$OUT" 2>&1 \
        && cmp -s "$SYNC_ONLY_REPO/LLM_START_HERE.before-invalid" \
            "$SYNC_ONLY_REPO/LLM_START_HERE.md" \
        && grep -q 'Unknown --only section' "$OUT"; then
        note_pass "dockit-sync rejects invalid selectors before project mutation"
    else
        {
            echo "dockit-sync accepted an invalid selector or mutated the project"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync rejects invalid selectors before project mutation"
    fi

    sed '/^<!-- DOCKIT-TEMPLATE:START independent-review-policy -->$/a\
Local project review constraint retained by the conflict test.' "$SYNC_ONLY_REPO/LLM_START_HERE.md" \
        >"$SYNC_ONLY_REPO/LLM_START_HERE.local"
    mv "$SYNC_ONLY_REPO/LLM_START_HERE.local" "$SYNC_ONLY_REPO/LLM_START_HERE.md"
    cp "$SYNC_ONLY_REPO/LLM_START_HERE.md" "$SYNC_ONLY_REPO/LLM_START_HERE.before-conflict"
    if ! "$SYNC_TOOL" --apply --project "$SYNC_ONLY_REPO" >"$OUT" 2>&1 \
        && grep -q 'LLM_START_HERE.md:independent-review-policy.*CONFLICT' "$OUT" \
        && cmp -s "$SYNC_ONLY_REPO/LLM_START_HERE.before-conflict" \
            "$SYNC_ONLY_REPO/LLM_START_HERE.md"; then
        note_pass "dockit-sync selective baseline protects a later local policy edit"
    else
        {
            echo "full sync did not conflict and preserve the post-selective local edit"
            [ -f "$OUT" ] && sed -n '1,200p' "$OUT"
            diff -u "$SYNC_ONLY_REPO/LLM_START_HERE.before-conflict" \
                "$SYNC_ONLY_REPO/LLM_START_HERE.md" || true
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync selective baseline protects a later local policy edit"
    fi

    SYNC_PARTIAL_REPO="$TMP_ROOT/sync-only-partial"
    init_sync_section_repo "$SYNC_PARTIAL_REPO" "with-footer"
    sed 's/adoption_mode: full/adoption_mode: partial/' \
        "$SYNC_PARTIAL_REPO/.dockit-config.yml" >"$SYNC_PARTIAL_REPO/.dockit-config.yml.tmp"
    mv "$SYNC_PARTIAL_REPO/.dockit-config.yml.tmp" "$SYNC_PARTIAL_REPO/.dockit-config.yml"
    "$SYNC_TOOL" --init-state --project "$SYNC_PARTIAL_REPO" >"$OUT" 2>&1
    cp "$SYNC_PARTIAL_REPO/LLM_START_HERE.md" "$SYNC_PARTIAL_REPO/LLM_START_HERE.before"
    if "$SYNC_TOOL" --dry-run --project "$SYNC_PARTIAL_REPO" --json \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>"$OUT.err" \
        && cmp -s "$SYNC_PARTIAL_REPO/LLM_START_HERE.before" \
            "$SYNC_PARTIAL_REPO/LLM_START_HERE.md" \
        && grep -q '"project": "sync-only-partial"' "$OUT" \
        && grep -q '"detail": "no markers (partial adopter)"' "$OUT" \
        && ! grep -q 'all sections up to date' "$OUT"; then
        note_pass "dockit-sync classifies a selected section missing from a partial adopter"
    else
        note_fail "dockit-sync classifies a selected section missing from a partial adopter"
    fi

    SYNC_EXCLUDED_REPO="$TMP_ROOT/sync-only-excluded"
    init_sync_section_repo "$SYNC_EXCLUDED_REPO" "with-footer"
    cat >>"$SYNC_EXCLUDED_REPO/.dockit-config.yml" <<'EOF'
exclude_sections:
  LLM_START_HERE.md:
    - independent-review-policy
EOF
    "$SYNC_TOOL" --init-state --project "$SYNC_EXCLUDED_REPO" >"$OUT" 2>&1
    cp "$SYNC_EXCLUDED_REPO/LLM_START_HERE.md" "$SYNC_EXCLUDED_REPO/LLM_START_HERE.before"
    if "$SYNC_TOOL" --dry-run --project "$SYNC_EXCLUDED_REPO" --json \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>"$OUT.err" \
        && cmp -s "$SYNC_EXCLUDED_REPO/LLM_START_HERE.before" \
            "$SYNC_EXCLUDED_REPO/LLM_START_HERE.md" \
        && grep -q '"detail": "excluded by .dockit-config.yml"' "$OUT" \
        && ! grep -q 'all sections up to date' "$OUT"; then
        note_pass "dockit-sync classifies an explicitly excluded selected section"
    else
        note_fail "dockit-sync classifies an explicitly excluded selected section"
    fi

    SYNC_CURRENT_REPO="$TMP_ROOT/sync-only-current"
    init_sync_section_repo "$SYNC_CURRENT_REPO" "with-footer"
    if "$SYNC_TOOL" --init-state --project "$SYNC_CURRENT_REPO" >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --apply --project "$SYNC_CURRENT_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && "$SYNC_TOOL" --apply --project "$SYNC_CURRENT_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q 'section already current' "$OUT" \
        && ! grep -q 'preserved template_version/template_ref' "$OUT"; then
        note_pass "dockit-sync distinguishes current sections without an applied-change warning"
    else
        note_fail "dockit-sync distinguishes current sections without an applied-change warning"
    fi

    SYNC_WHOLE_REPO="$TMP_ROOT/sync-only-whole"
    init_sync_section_repo "$SYNC_WHOLE_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_WHOLE_REPO" >"$OUT" 2>&1
    if "$SYNC_TOOL" --dry-run --project "$SYNC_WHOLE_REPO" \
            --only LLM_START_HERE.md \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q 'LLM_START_HERE.md:trace-protocol' "$OUT" \
        && grep -q 'LLM_START_HERE.md:independent-review-policy' "$OUT"; then
        note_pass "dockit-sync supports whole-file and repeated selectors"
    else
        note_fail "dockit-sync supports whole-file and repeated selectors"
    fi

    if ! "$SYNC_TOOL" --init-state --project "$SYNC_WHOLE_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && ! "$SYNC_TOOL" --restore 20000101_000000 --project "$SYNC_WHOLE_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && ! "$SYNC_TOOL" --dry-run --project "$SYNC_WHOLE_REPO" \
            --only NOT_IN_MANIFEST.md >"$OUT" 2>&1 \
        && ! "$SYNC_TOOL" --dry-run --project "$SYNC_WHOLE_REPO" \
            --only docs/integrations/CODEX.md:not-a-section >"$OUT" 2>&1 \
        && ! "$SYNC_TOOL" --dry-run --project "$SYNC_WHOLE_REPO" \
            --only VERSION >"$OUT" 2>&1 \
        && ! "$SYNC_TOOL" --dry-run --project "$SYNC_WHOLE_REPO" \
            --only LLM_START_HERE.md:commit.policy >"$OUT" 2>&1; then
        note_pass "dockit-sync rejects incompatible, unknown, skip, and regex-like selectors"
    else
        note_fail "dockit-sync rejects incompatible, unknown, skip, and regex-like selectors"
    fi

    SYNC_MISSING_REPO="$TMP_ROOT/sync-only-missing-file"
    init_sync_section_repo "$SYNC_MISSING_REPO" "with-footer"
    rm "$SYNC_MISSING_REPO/LLM_START_HERE.md"
    git -C "$SYNC_MISSING_REPO" add -u
    git -C "$SYNC_MISSING_REPO" commit -qm "remove start guide"
    "$SYNC_TOOL" --init-state --project "$SYNC_MISSING_REPO" >"$OUT" 2>&1
    expect_fail "dockit-sync rejects a section selector when the downstream file is missing" \
        "$SYNC_TOOL" --dry-run --project "$SYNC_MISSING_REPO" \
        --only LLM_START_HERE.md:independent-review-policy

    if "$SYNC_TOOL" --apply --project "$SYNC_MISSING_REPO" \
            --only LLM_START_HERE.md >"$OUT" 2>&1; then
        SYNC_MISSING_STATE="$SYNC_MISSING_REPO/.git/.dockit/state.yml"
        TEMPLATE_SECTION_COUNT=$(grep -c '<!-- DOCKIT-TEMPLATE:START ' \
            "$PROJECT_ROOT/LLM_START_HERE.md")
        STATE_SECTION_COUNT=$(grep -c '^    [^[:space:]][^:]*:' "$SYNC_MISSING_STATE")
    else
        TEMPLATE_SECTION_COUNT=0
        STATE_SECTION_COUNT=-1
    fi
    if [ "$TEMPLATE_SECTION_COUNT" -gt 0 ] \
        && [ "$STATE_SECTION_COUNT" -eq "$TEMPLATE_SECTION_COUNT" ]; then
        note_pass "dockit-sync records every section baseline when selective sync creates a file"
    else
        {
            echo "selective whole-file creation did not record all section baselines"
            [ -f "$SYNC_MISSING_STATE" ] && sed -n '1,180p' "$SYNC_MISSING_STATE"
            [ -f "$OUT" ] && sed -n '1,160p' "$OUT"
            echo "template_sections=$TEMPLATE_SECTION_COUNT state_sections=$STATE_SECTION_COUNT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync records every section baseline when selective sync creates a file"
    fi

    sed '/^<!-- DOCKIT-TEMPLATE:START independent-review-policy -->$/a\
Local project review constraint retained by the conflict test.' "$SYNC_MISSING_REPO/LLM_START_HERE.md" \
        >"$SYNC_MISSING_REPO/LLM_START_HERE.local"
    mv "$SYNC_MISSING_REPO/LLM_START_HERE.local" "$SYNC_MISSING_REPO/LLM_START_HERE.md"
    cp "$SYNC_MISSING_REPO/LLM_START_HERE.md" "$SYNC_MISSING_REPO/LLM_START_HERE.before-conflict"
    if ! "$SYNC_TOOL" --apply --project "$SYNC_MISSING_REPO" >"$OUT" 2>&1 \
        && grep -q 'LLM_START_HERE.md:independent-review-policy.*CONFLICT' "$OUT" \
        && grep -q '__project__.*ERROR.*rolled back: conflicts' "$OUT" \
        && cmp -s "$SYNC_MISSING_REPO/LLM_START_HERE.before-conflict" \
            "$SYNC_MISSING_REPO/LLM_START_HERE.md"; then
        note_pass "dockit-sync protects local edits after selective whole-file creation"
    else
        note_fail "dockit-sync protects local edits after selective whole-file creation"
    fi

    SYNC_MALFORMED_STATE_REPO="$TMP_ROOT/sync-only-malformed-state"
    init_sync_section_repo "$SYNC_MALFORMED_STATE_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_MALFORMED_STATE_REPO" >"$OUT" 2>&1
    SYNC_MALFORMED_STATE="$SYNC_MALFORMED_STATE_REPO/.git/.dockit/state.yml"
    sed 's/^    footer:/   footer:/' "$SYNC_MALFORMED_STATE" >"$SYNC_MALFORMED_STATE.tmp"
    mv "$SYNC_MALFORMED_STATE.tmp" "$SYNC_MALFORMED_STATE"
    cp "$SYNC_MALFORMED_STATE" "$SYNC_MALFORMED_STATE.before"
    cp "$SYNC_MALFORMED_STATE_REPO/LLM_START_HERE.md" \
        "$SYNC_MALFORMED_STATE_REPO/LLM_START_HERE.before"
    if ! "$SYNC_TOOL" --apply --project "$SYNC_MALFORMED_STATE_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q 'rejected malformed section_hashes' "$OUT" \
        && grep -q '__project__.*ERROR.*rolled back: selective state merge failure' "$OUT" \
        && cmp -s "$SYNC_MALFORMED_STATE.before" "$SYNC_MALFORMED_STATE" \
        && cmp -s "$SYNC_MALFORMED_STATE_REPO/LLM_START_HERE.before" \
            "$SYNC_MALFORMED_STATE_REPO/LLM_START_HERE.md"; then
        note_pass "dockit-sync rejects malformed state and rolls back file plus state"
    else
        note_fail "dockit-sync rejects malformed state and rolls back file plus state"
    fi

    SYNC_EMPTY_HASH_REPO="$TMP_ROOT/sync-only-empty-hash"
    init_sync_section_repo "$SYNC_EMPTY_HASH_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_EMPTY_HASH_REPO" >"$OUT" 2>&1
    SYNC_EMPTY_HASH_STATE="$SYNC_EMPTY_HASH_REPO/.git/.dockit/state.yml"
    sed 's/^    footer: .*/    footer: ""/' "$SYNC_EMPTY_HASH_STATE" \
        >"$SYNC_EMPTY_HASH_STATE.tmp"
    mv "$SYNC_EMPTY_HASH_STATE.tmp" "$SYNC_EMPTY_HASH_STATE"
    cp "$SYNC_EMPTY_HASH_STATE" "$SYNC_EMPTY_HASH_STATE.before"
    if ! "$SYNC_TOOL" --apply --project "$SYNC_EMPTY_HASH_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q 'rejected malformed section_hashes' "$OUT" \
        && cmp -s "$SYNC_EMPTY_HASH_STATE.before" "$SYNC_EMPTY_HASH_STATE"; then
        note_pass "dockit-sync rejects an empty quoted section baseline"
    else
        note_fail "dockit-sync rejects an empty quoted section baseline"
    fi

    SYNC_BRANCH_REPO="$TMP_ROOT/sync-only-branch-collision"
    init_sync_section_repo "$SYNC_BRANCH_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_BRANCH_REPO" >"$OUT" 2>&1
    DOCKIT_VERSION=$(sed -n '1p' "$PROJECT_ROOT/VERSION")
    git -C "$SYNC_BRANCH_REPO" branch "dockit-sync-${DOCKIT_VERSION}-selective"
    if "$SYNC_TOOL" --apply --git-branch --project "$SYNC_BRANCH_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && git -C "$SYNC_BRANCH_REPO" branch --show-current \
            | grep -Eq "^dockit-sync-${DOCKIT_VERSION}-selective-[0-9]{14}$"; then
        note_pass "dockit-sync preserves selective naming after branch collision"
    else
        note_fail "dockit-sync preserves selective naming after branch collision"
    fi

    SYNC_BRANCH_FAILURE_REPO="$TMP_ROOT/sync-branch-failure"
    init_sync_section_repo "$SYNC_BRANCH_FAILURE_REPO" "with-footer"
    "$SYNC_TOOL" --init-state --project "$SYNC_BRANCH_FAILURE_REPO" >"$OUT" 2>&1
    # A fixture-owned ref lock makes ordinary Git refuse branch creation. Do not
    # replace or bypass the installed Git launcher to simulate that failure.
    SYNC_BRANCH_LOCK="$SYNC_BRANCH_FAILURE_REPO/.git/refs/heads/dockit-sync-${DOCKIT_VERSION}-selective.lock"
    printf 'synthetic branch contention\n' > "$SYNC_BRANCH_LOCK"
    if ! "$SYNC_TOOL" --apply --git-branch --project "$SYNC_BRANCH_FAILURE_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q 'failed to create sync branch' "$OUT" \
        && [ "$(find "$SYNC_BRANCH_FAILURE_REPO/.git/.dockit/backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 0 ] \
        && [ ! -e "$SYNC_BRANCH_FAILURE_REPO/.git/.dockit/sync.lock" ]; then
        note_pass "dockit-sync retires its empty backup scaffold when branch creation fails"
    else
        note_fail "dockit-sync retires its empty backup scaffold when branch creation fails"
    fi
    rm -f "$SYNC_BRANCH_LOCK"

    SYNC_PREFLIGHT_REPO="$TMP_ROOT/sync-only-preflight"
    init_sync_versioned_doc_repo "$SYNC_PREFLIGHT_REPO"
    cp "$CHECK_VERSION" "$SYNC_PREFLIGHT_REPO/scripts/check-version-sync.sh"
    chmod +x "$SYNC_PREFLIGHT_REPO/scripts/check-version-sync.sh"
    "$SYNC_TOOL" --init-state --project "$SYNC_PREFLIGHT_REPO" >"$OUT" 2>&1
    sed 's/doc-version: 0.1.0/doc-version: 9.9.9/' \
        "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.md" >"$SYNC_PREFLIGHT_REPO/LLM_START_HERE.drift"
    mv "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.drift" "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.md"
    cp "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.md" "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.before"
    if "$SYNC_TOOL" --apply --project "$SYNC_PREFLIGHT_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && cmp -s "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.before" \
            "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.md" \
        && grep -q 'pre-existing validation failure' "$OUT" \
        && ! grep -q '<!-- DOCKIT-TEMPLATE:START independent-review-policy -->' \
            "$SYNC_PREFLIGHT_REPO/LLM_START_HERE.md"; then
        note_pass "dockit-sync classifies pre-existing validation failure before mutation"
    else
        note_fail "dockit-sync classifies pre-existing validation failure before mutation"
    fi

    SYNC_ALL_ROOT="$TMP_ROOT/sync-only-all"
    mkdir -p "$SYNC_ALL_ROOT"
    init_sync_section_repo "$SYNC_ALL_ROOT/adopter-one" "with-footer"
    init_sync_section_repo "$SYNC_ALL_ROOT/adopter-two" "with-footer"
    init_sync_section_repo "$SYNC_ALL_ROOT/adopter-three" "with-footer"
    sed 's/adoption_mode: full/adoption_mode: partial/' \
        "$SYNC_ALL_ROOT/adopter-two/.dockit-config.yml" \
        >"$SYNC_ALL_ROOT/adopter-two/.dockit-config.yml.tmp"
    mv "$SYNC_ALL_ROOT/adopter-two/.dockit-config.yml.tmp" \
        "$SYNC_ALL_ROOT/adopter-two/.dockit-config.yml"
    "$SYNC_TOOL" --init-state --project "$SYNC_ALL_ROOT/adopter-one" >"$OUT" 2>&1
    "$SYNC_TOOL" --init-state --project "$SYNC_ALL_ROOT/adopter-two" >"$OUT" 2>&1
    "$SYNC_TOOL" --init-state --project "$SYNC_ALL_ROOT/adopter-three" >"$OUT" 2>&1
    if "$SYNC_TOOL" --dry-run --all --src-root "$SYNC_ALL_ROOT" --json \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>"$OUT.err" \
        && [ "$(head -n 1 "$OUT")" = "[" ] \
        && [ "$(tail -n 1 "$OUT")" = "]" ] \
        && [ "$(grep -c '"project":' "$OUT")" -eq 3 ] \
        && grep -q '"project": "adopter-one"' "$OUT" \
        && grep -q '"project": "adopter-two"' "$OUT" \
        && grep -q '"project": "adopter-three"' "$OUT" \
        && grep -q '"detail": "no markers (partial adopter)"' "$OUT" \
        && ! grep -q 'LLM-DocKit Sync\|Template:\|Mode:\|Scope:' "$OUT"; then
        note_pass "dockit-sync emits one attributable mixed JSON report for --all --only"
    else
        {
            echo "selective --all JSON output was not singular and attributable"
            sed -n '1,200p' "$OUT"
            [ -s "$OUT.err" ] && sed -n '1,120p' "$OUT.err"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync emits one attributable mixed JSON report for --all --only"
    fi

    mkdir -p "$SYNC_ALL_ROOT/adopter-one/.git/.dockit"
    printf '%s\n' "$$" >"$SYNC_ALL_ROOT/adopter-one/.git/.dockit/sync.lock"
    if "$SYNC_TOOL" --dry-run --all --src-root "$SYNC_ALL_ROOT" --json \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>"$OUT.err"; then
        LIVE_LOCK_EXITED_ZERO=true
    else
        LIVE_LOCK_EXITED_ZERO=false
    fi
    if ! $LIVE_LOCK_EXITED_ZERO \
        && [ "$(head -n 1 "$OUT")" = "[" ] \
        && [ "$(tail -n 1 "$OUT")" = "]" ] \
        && grep -q '"project": "adopter-one".*"status": "ERROR".*locked by active PID' "$OUT" \
        && grep -q '"project": "adopter-two"' "$OUT" \
        && grep -q '"project": "adopter-three"' "$OUT" \
        && [ -f "$SYNC_ALL_ROOT/adopter-one/.git/.dockit/sync.lock" ] \
        && [ "$(cat "$SYNC_ALL_ROOT/adopter-one/.git/.dockit/sync.lock")" = "$$" ]; then
        note_pass "dockit-sync preserves live locks and still emits the fleet JSON report"
    else
        {
            echo "live lock aborted or erased the fleet report"
            sed -n '1,200p' "$OUT"
            [ -s "$OUT.err" ] && sed -n '1,120p' "$OUT.err"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-sync preserves live locks and still emits the fleet JSON report"
    fi

    SYNC_LOCK_FAILURE_REPO="$TMP_ROOT/sync-only-lock-failure"
    init_sync_section_repo "$SYNC_LOCK_FAILURE_REPO" "with-footer"
    ln -s /dev/null "$SYNC_LOCK_FAILURE_REPO/.git/.dockit"
    if ! "$SYNC_TOOL" --dry-run --project "$SYNC_LOCK_FAILURE_REPO" \
            --only LLM_START_HERE.md:independent-review-policy >"$OUT" 2>&1 \
        && grep -q '__project__.*ERROR.*cannot create lock directory' "$OUT"; then
        note_pass "dockit-sync reports non-holder lock acquisition failures"
    else
        note_fail "dockit-sync reports non-holder lock acquisition failures"
    fi
fi

if [ ! -x "$CODEX_INSTALLER" ]; then
    note_pass "codex hook installer smoke skipped when installer is absent"
else
    CODEX_CONFIG="$TMP_ROOT/codex-config.toml"
    cat >"$CODEX_CONFIG" <<'EOF'
personality = "pragmatic"

# --- LLM-DocKit DF-033 / D-007: SessionStart enforcement (added 2026-05-03) ---
# Old unmarked managed block with the wrong Claude-Code JSON mode.

[features]
hooks = true

[[hooks.SessionStart]]

[[hooks.SessionStart.hooks]]
type = "command"
command = "sh -lc 'root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); script=/tmp/dockit-bootstrap-context.sh; if [ -x \"$script\" ]; then \"$script\" --json --project \"$root\"; fi'"
timeout = 5

[hooks.state]

[hooks.state."/tmp/codex-config.toml:session_start:0:0"]
enabled = true
trusted_hash = "sha256:old"
EOF

    if "$CODEX_INSTALLER" --config "$CODEX_CONFIG" --script "$PROJECT_ROOT/scripts/dockit-bootstrap-context.sh" >"$OUT" 2>&1 \
        && grep -q -- '--human' "$CODEX_CONFIG" \
        && ! grep -q -- '--json' "$CODEX_CONFIG" \
        && grep -Fq 'command = "sh -c ' "$CODEX_CONFIG" \
        && ! grep -Fq 'command = "sh -lc ' "$CODEX_CONFIG" \
        && grep -q '^timeout = 15$' "$CODEX_CONFIG" \
        && grep -q 'trusted_hash = "sha256:old"' "$CODEX_CONFIG" \
        && ! grep -q 'Old unmarked managed block' "$CODEX_CONFIG" \
        && grep -q 'LLM-DocKit Codex SessionStart hook: BEGIN' "$CODEX_CONFIG"; then
        note_pass "codex hook installer replaces legacy hook without login shell"
    else
        {
            echo "installer did not replace legacy hook with the bounded non-login hook"
            sed -n '1,180p' "$CODEX_CONFIG"
            [ -f "$OUT" ] && sed -n '1,120p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "codex hook installer replaces legacy hook without login shell"
    fi

    CODEX_CONFIG_BEFORE="$TMP_ROOT/codex-config-before-second-install.toml"
    cp "$CODEX_CONFIG" "$CODEX_CONFIG_BEFORE"
    BEFORE_COUNT=$(grep -c 'dockit-bootstrap-context.sh' "$CODEX_CONFIG" || true)
    if "$CODEX_INSTALLER" --config "$CODEX_CONFIG" --script "$PROJECT_ROOT/scripts/dockit-bootstrap-context.sh" >"$OUT" 2>&1; then
        AFTER_COUNT=$(grep -c 'dockit-bootstrap-context.sh' "$CODEX_CONFIG" || true)
        if [ "$BEFORE_COUNT" = "$AFTER_COUNT" ] && [ "$AFTER_COUNT" -eq 1 ] \
            && cmp -s "$CODEX_CONFIG_BEFORE" "$CODEX_CONFIG"; then
            note_pass "codex hook installer is idempotent"
        else
            {
                echo "installer changed config on second run"
                echo "before=$BEFORE_COUNT after=$AFTER_COUNT"
                diff -u "$CODEX_CONFIG_BEFORE" "$CODEX_CONFIG" || true
                sed -n '1,220p' "$CODEX_CONFIG"
            } >"$OUT"
            note_fail "codex hook installer is idempotent"
        fi
    else
        note_fail "codex hook installer is idempotent"
    fi

    CODEX_INTERLEAVED_CONFIG="$TMP_ROOT/codex-interleaved-config.toml"
    cat >"$CODEX_INTERLEAVED_CONFIG" <<'EOF'
personality = "pragmatic"

[features]
hooks = true

# --- LLM-DocKit Codex SessionStart hook: BEGIN ---
# Managed by scripts/dockit-install-codex-hook.sh.
[[hooks.SessionStart]]

[[hooks.SessionStart.hooks]]
type = "command"
command = "sh -lc 'old command'"
timeout = 5

[hooks.state]

[hooks.state."/tmp/codex-config.toml:session_start:0:0"]
trusted_hash = "sha256:preserve-me"
enabled = true

[mcp_servers.preserve-me]
url = "https://example.invalid/mcp"
# --- LLM-DocKit Codex SessionStart hook: END ---
EOF

    if "$CODEX_INSTALLER" --config "$CODEX_INTERLEAVED_CONFIG" --script "$PROJECT_ROOT/scripts/dockit-bootstrap-context.sh" >"$OUT" 2>&1 \
        && grep -q 'trusted_hash = "sha256:preserve-me"' "$CODEX_INTERLEAVED_CONFIG" \
        && grep -q '^\[mcp_servers\.preserve-me\]$' "$CODEX_INTERLEAVED_CONFIG" \
        && grep -q 'url = "https://example.invalid/mcp"' "$CODEX_INTERLEAVED_CONFIG" \
        && [ "$(grep -c 'dockit-bootstrap-context.sh' "$CODEX_INTERLEAVED_CONFIG")" -eq 1 ] \
        && [ "$(grep -c 'LLM-DocKit Codex SessionStart hook: END' "$CODEX_INTERLEAVED_CONFIG")" -eq 1 ]; then
        note_pass "codex hook installer preserves interleaved trust and MCP tables"
    else
        {
            echo "installer removed or duplicated config outside its hook tables"
            sed -n '1,220p' "$CODEX_INTERLEAVED_CONFIG"
            [ -f "$OUT" ] && sed -n '1,120p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "codex hook installer preserves interleaved trust and MCP tables"
    fi
fi

if [ ! -x "$PROJECT_ROOT/scripts/dockit-init-project.sh" ]; then
    note_pass "dockit-init scaffold smoke skipped when init script is absent"
else
    INIT_SOURCE="$TMP_ROOT/init-source"
    mkdir -p "$INIT_SOURCE"
    git -C "$PROJECT_ROOT" ls-files | while IFS= read -r _file; do
        mkdir -p "$INIT_SOURCE/$(dirname "$_file")"
        cp "$PROJECT_ROOT/$_file" "$INIT_SOURCE/$_file"
    done
    mkdir -p "$INIT_SOURCE/.forgeos" "$INIT_SOURCE/docs/operations"
    printf '{"project_id":"source-only-identity"}\n' > "$INIT_SOURCE/.forgeos/dossier.json"
    printf 'source-only custody instructions\n' > "$INIT_SOURCE/docs/operations/DOSSIER.md"
    git -C "$INIT_SOURCE" init -q
    git -C "$INIT_SOURCE" config user.email smoke@example.invalid
    git -C "$INIT_SOURCE" config user.name Smoke
    git -C "$INIT_SOURCE" add .
    git -C "$INIT_SOURCE" commit -qm "snapshot current working tree"

    SCAFFOLD_PARENT="$TMP_ROOT/init"
    mkdir -p "$SCAFFOLD_PARENT"
    SCAFFOLD_REPO="$SCAFFOLD_PARENT/residue-smoke"
    # A synthetic scaffold is not a real host admission. Exercise the public
    # host-policy boundary with an isolated test host configuration, never the
    # operator's live admission registry or a production bypass flag.
    INIT_CONFIG="$TMP_ROOT/init-config"
    mkdir -p "$INIT_CONFIG/llm-dockit"
    cat > "$INIT_CONFIG/llm-dockit/init-policy" <<'POLICY'
#!/bin/sh
exit 1
POLICY
    chmod +x "$INIT_CONFIG/llm-dockit/init-policy"
    if XDG_CONFIG_HOME="$INIT_CONFIG" "$INIT_SOURCE/scripts/dockit-init-project.sh" residue-smoke \
        --target-dir "$SCAFFOLD_REPO" --source "$INIT_SOURCE" >"$OUT" 2>&1; then
        note_fail "dockit-init refuses a rejecting host policy before target creation"
    elif [ ! -e "$SCAFFOLD_REPO" ] && grep -q 'host intake policy rejected' "$OUT"; then
        note_pass "dockit-init refuses a rejecting host policy before target creation"
    else
        note_fail "dockit-init refuses a rejecting host policy before target creation"
    fi
    cat > "$INIT_CONFIG/llm-dockit/init-policy" <<'POLICY'
#!/bin/sh
# Permit exactly this test's named fixture and target; no wildcard admission.
[ "$#" -eq 4 ] && [ "$1" = --project-name ] && [ "$2" = residue-smoke ] \
    && [ "$3" = --target-dir ] && [ "$4" = "$DOCKIT_TEST_INIT_TARGET" ]
POLICY
    if XDG_CONFIG_HOME="$INIT_CONFIG" DOCKIT_TEST_INIT_TARGET="$SCAFFOLD_REPO" \
        "$INIT_SOURCE/scripts/dockit-init-project.sh" residue-smoke --target-dir "$SCAFFOLD_REPO" --source "$INIT_SOURCE" >"$OUT" 2>&1 \
        && [ ! -f "$SCAFFOLD_REPO/docs/ARCHITECTURE.md" ] \
        && [ ! -f "$SCAFFOLD_REPO/docs/ROADMAP.md" ] \
        && [ ! -d "$SCAFFOLD_REPO/docs/archive" ] \
        && [ ! -e "$SCAFFOLD_REPO/.forgeos/dossier.json" ] \
        && [ ! -e "$SCAFFOLD_REPO/docs/operations/DOSSIER.md" ] \
        && [ ! -e "$SCAFFOLD_REPO/docs/operations/DOSSIER_SHARED_DELIVERY_2026-09-25.json" ] \
        && [ ! -e "$SCAFFOLD_REPO/docs/operations/ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md" ] \
        && ! grep -q handoff_active_start "$SCAFFOLD_REPO/.dockit-config.yml" \
        && [ -f "$SCAFFOLD_REPO/docs/ARCHITECTURE.md.example" ] \
        && grep -q 'docs/ARCHITECTURE.md.example' "$SCAFFOLD_REPO/docs/version-sync-manifest.yml" \
        && ! grep -Eq 'path: docs/ARCHITECTURE\.md[[:space:]]+marker: html-comment' "$SCAFFOLD_REPO/docs/version-sync-manifest.yml" \
        && "$SCAFFOLD_REPO/scripts/dockit-validate-session.sh" --project "$SCAFFOLD_REPO" --quiet --check orientation --check template-residue --check version-sync >"$OUT" 2>&1; then
        note_pass "dockit-init demotes ARCHITECTURE.md and scaffold passes residue checks"
    else
        {
            echo "scaffold did not demote architecture cleanly or failed validator"
            [ -d "$SCAFFOLD_REPO" ] && find "$SCAFFOLD_REPO/docs" -maxdepth 2 -type f | sort
            [ -f "$SCAFFOLD_REPO/docs/version-sync-manifest.yml" ] && sed -n '1,80p' "$SCAFFOLD_REPO/docs/version-sync-manifest.yml"
            [ -f "$OUT" ] && sed -n '1,120p' "$OUT"
        } >"$OUT.tmp"
        mv "$OUT.tmp" "$OUT"
        note_fail "dockit-init demotes ARCHITECTURE.md and scaffold passes residue checks"
    fi
fi

# Coverage must remain honest even when PASS rows are filtered away.
COVERAGE_REPO="$TMP_ROOT/coverage"; init_gate_repo "$COVERAGE_REPO"
coverage_check() {
    "$VALIDATOR" --project "$COVERAGE_REPO" --json "$@" --check version-sync --check external-context > "$TMP_ROOT/coverage.json"
    grep -q '"checked":1,"skipped":1,"passed":1,"failed":0' "$TMP_ROOT/coverage.json"
}
expect_pass "selected JSON coverage distinguishes checked and skipped" coverage_check
expect_pass "quiet JSON retains totals before suppressing PASS rows" coverage_check --quiet
if grep -q '"checks":\[\]' "$TMP_ROOT/coverage.json"; then note_pass "quiet JSON suppresses only result rows"; else note_fail "quiet JSON suppresses only result rows"; fi
SHAPE_REPO="$TMP_ROOT/shape"; init_gate_repo "$SHAPE_REPO"
shape_check() { "$VALIDATOR" --project "$SHAPE_REPO" --json --check handoff-shape; }
expect_pass "no config preserves legacy validator behavior" shape_check
seq 201 > "$SHAPE_REPO/docs/llm/HANDOFF.md"
if shape_check > "$OUT" && grep -q '"status":"WARN"' "$OUT"; then note_pass "large HANDOFF warns without failing by default"; else note_fail "large HANDOFF warns without failing by default"; fi
cat > "$SHAPE_REPO/.dockit-config.yml" <<'SHAPECONFIG'
handoff_max_lines: 200
handoff_active_start: "<!-- ACTIVE -->"
handoff_active_end: "<!-- END -->"
handoff_singleton_sections: "Current Status,Open work,Do Not Touch"
handoff_version_label: "- Current source version:"
handoff_shape_strict: true
SHAPECONFIG
cat > "$SHAPE_REPO/docs/llm/HANDOFF.md" <<'SHAPEDOC'
# Handoff
<!-- ACTIVE -->
## Current Status
- Current source version: 0.1.0
## Open work -- next concrete step
Touch `scripts/foo.sh`.
## Do Not Touch
None.
> ## Do Not Touch
```
## Do Not Touch
- Current source version: 9.9.9
```
<!-- END -->
## Do Not Touch
- Current source version: 9.9.9
SHAPEDOC
expect_pass "strict shape excludes historical prose fences and quotes" shape_check
cp "$SHAPE_REPO/docs/llm/HANDOFF.md" "$TMP_ROOT/shape-clean"
sed '/None./a\## Do Not Touchstone' "$TMP_ROOT/shape-clean" > "$SHAPE_REPO/docs/llm/HANDOFF.md"
expect_pass "canonical title prefix requires a word boundary" shape_check
sed '/None./a\## Do Not Touch' "$TMP_ROOT/shape-clean" > "$SHAPE_REPO/docs/llm/HANDOFF.md"
expect_fail "strict shape rejects duplicate active singleton sections" shape_check
sed 's/handoff_shape_strict: true/handoff_shape_strict: false/' "$SHAPE_REPO/.dockit-config.yml" > "$TMP_ROOT/config"; cp "$TMP_ROOT/config" "$SHAPE_REPO/.dockit-config.yml"
if shape_check > "$OUT" && grep -q '"status":"WARN"' "$OUT"; then note_pass "content warnings fail only after strict opt-in"; else note_fail "content warnings fail only after strict opt-in"; fi
sed 's/handoff_shape_strict: false/handoff_shape_strict: true/' "$TMP_ROOT/config" > "$SHAPE_REPO/.dockit-config.yml"
sed 's/0.1.0/0.0.9/' "$TMP_ROOT/shape-clean" > "$SHAPE_REPO/docs/llm/HANDOFF.md"
expect_fail "strict shape catches explicit current-version drift" shape_check
sed '/<!-- END -->/d' "$TMP_ROOT/shape-clean" > "$SHAPE_REPO/docs/llm/HANDOFF.md"
expect_fail "strict shape rejects an unclosed active scope" shape_check

# workspace-leftovers: Git-only candidates warn; ledger-closed unretired workspaces fail.
WL_GIT=git; [ -x /usr/bin/git ] && WL_GIT=/usr/bin/git
WL_REPO="$TMP_ROOT/leftovers"; init_repo "$WL_REPO"
cp "$PROJECT_ROOT/scripts/dockit-leftovers.py" "$WL_REPO/scripts/"
git -C "$WL_REPO" add scripts; git -C "$WL_REPO" commit -qm checker
git -C "$WL_REPO" branch -M main
git init -q --bare "$TMP_ROOT/leftovers-origin.git"
git -C "$WL_REPO" remote add origin "$TMP_ROOT/leftovers-origin.git"
git -C "$WL_REPO" push -q origin main; git -C "$WL_REPO" fetch -q origin
WL_LEDGER="$TMP_ROOT/fake-task-workspace"
printf '#!/bin/sh\nprintf "%%s" "$WL_LEDGER_JSON"\n' > "$WL_LEDGER"; chmod +x "$WL_LEDGER"
DOCKIT_TASK_WORKSPACE="$WL_LEDGER"; export DOCKIT_TASK_WORKSPACE
DOCKIT_WORKSPACE_POLICY="$TMP_ROOT/no-policy.json"; export DOCKIT_WORKSPACE_POLICY
WL_LEDGER_JSON='{"items":{}}'; export WL_LEDGER_JSON
wl_status() { "$VALIDATOR" --project "${2:-$WL_REPO}" --json --check workspace-leftovers > "$OUT" 2>&1 || true; grep -q "\"status\":\"$1\"" "$OUT"; }
wl_expect() { if wl_status "$2" "${3:-}"; then note_pass "$1"; else note_fail "$1"; fi; }
wl_expect "workspace-leftovers passes without leftovers" PASS
# Residue files (docs/LEAVE_NO_RESIDUE.md) warn when tracked, or untracked and not ignored.
wl_note() { if wl_status "$2" && grep -qF "$3" "$OUT"; then note_pass "$1"; else note_fail "$1"; fi; }
git -C "$WL_REPO" config core.excludesFile /dev/null
: > "$WL_REPO/notes.md.bak"
wl_note "workspace-leftovers warns on an untracked residue file" WARN '1 backup/temporary file(s) left in the tree: notes.md.bak;'
printf '*.bak\n' > "$WL_REPO/.git/info/exclude"
wl_expect "workspace-leftovers does not report an ignored residue file" PASS
git -C "$WL_REPO" add -f notes.md.bak
wl_note "workspace-leftovers warns on a tracked residue file" WARN '1 backup/temporary file(s) left in the tree: notes.md.bak;'
: > "$WL_REPO/odd #1.bak"; git -C "$WL_REPO" add -f "odd #1.bak"
printf 'residue_allow:\n  - notes.md.bak  # fixture kept on purpose\n  - "odd #1.bak"  # quoted path containing " #"\n' > "$WL_REPO/.dockit-config.yml"
wl_expect "workspace-leftovers accepts allow-listed residue files, including a quoted path" PASS
for _wl_name in a.orig b.rej c.tmp 'd~' e.swp f.before g.before-20261126 h.incomplete-1 plain.md; do : > "$WL_REPO/$_wl_name"; done
wl_note "workspace-leftovers matches each residue pattern and only those" WARN '8 backup/temporary file(s) left in the tree: a.orig, b.rej, c.tmp, d~, e.swp (+3 more);'
wl_note "workspace-leftovers asks for origin before removal" WARN 'check origin and authorization first: remove only what this task created'
git -C "$WL_REPO" rm -q --cached notes.md.bak "odd #1.bak"
( cd "$WL_REPO" && rm -f notes.md.bak "odd #1.bak" a.orig b.rej c.tmp 'd~' e.swp f.before g.before-20261126 h.incomplete-1 plain.md .dockit-config.yml )
: > "$WL_REPO/.git/info/exclude"
# File names must never turn the warning into a failure, whatever the output encoding.
WL_UTF8_NAME=$(printf 'caf\303\251.tmp'); : > "$WL_REPO/$WL_UTF8_NAME"
PYTHONIOENCODING=ascii; export PYTHONIOENCODING
wl_note "workspace-leftovers warns on a non-ASCII name under an ASCII output encoding" WARN '1 backup/temporary file(s) left in the tree: caf'
unset PYTHONIOENCODING
rm -f "$WL_REPO/$WL_UTF8_NAME"
WL_RAW_NAME=$(printf 'raw\377.tmp')
if ( : > "$WL_REPO/$WL_RAW_NAME" ) 2>/dev/null && [ -e "$WL_REPO/$WL_RAW_NAME" ]; then
    wl_note "workspace-leftovers warns on a file name that is not valid UTF-8" WARN '1 backup/temporary file(s) left in the tree: raw'
    rm -f "$WL_REPO/$WL_RAW_NAME"
else
    note_pass "undecodable file name case skipped (filesystem rejects the name)"
fi
wl_expect "workspace-leftovers passes again once residue files are removed" PASS
git -C "$WL_REPO" branch merged-leftover
wl_expect "workspace-leftovers warns on a merged branch" WARN
git -C "$WL_REPO" branch -D -q merged-leftover
"$WL_GIT" -C "$WL_REPO" worktree add -q "$TMP_ROOT/leftovers-task" -b work/task main
wl_expect "workspace-leftovers only warns on a fresh Git-only worktree" WARN
WL_LEDGER_JSON="{\"items\":{\"task\":{\"path\":\"$TMP_ROOT/leftovers-task\",\"phase\":\"registered\",\"created\":\"2026-11-23T00:00:00Z\",\"record\":{\"state\":\"active\"}}}}"
wl_expect "workspace-leftovers keeps an active ledger workspace at warning" WARN
WL_LEDGER_JSON=$(printf '%s' "$WL_LEDGER_JSON" | sed 's/"active"/"closed"/')
wl_expect "workspace-leftovers fails on a closed unretired workspace" FAIL
wl_expect "workspace-leftovers lets the closed checkout itself close" WARN "$TMP_ROOT/leftovers-task"
WL_LEDGER_JSON='{"items":{}}'
git -C "$TMP_ROOT/leftovers-task" commit -q --allow-empty -m unpublished
wl_expect "workspace-leftovers ignores unpublished work" PASS
printf '#!/bin/sh\necho ledger down >&2\nexit 2\n' > "$TMP_ROOT/broken-task-workspace"; chmod +x "$TMP_ROOT/broken-task-workspace"
DOCKIT_TASK_WORKSPACE="$TMP_ROOT/broken-task-workspace"
wl_expect "workspace-leftovers warns when the host ledger is unavailable" WARN
unset DOCKIT_TASK_WORKSPACE WL_LEDGER_JSON DOCKIT_WORKSPACE_POLICY

printf '\nValidator smoke: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
