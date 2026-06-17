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

TMP_ROOT=${TMPDIR:-/tmp}/dockit-validator-smoke.$$
OUT="$TMP_ROOT/out.txt"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

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

mkdir -p "$TMP_ROOT"

REPO="$TMP_ROOT/main"
init_repo "$REPO"

expect_pass "env + clean stale handoff/history skips" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$REPO" --quiet --check handoff-date --check history-entry

expect_fail "no env + clean stale handoff/history fails normally" \
    "$VALIDATOR" --project "$REPO" --quiet --check handoff-date --check history-entry

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

MISSING_HANDOFF="$TMP_ROOT/missing-handoff"
init_malformed_repo "$MISSING_HANDOFF" handoff
expect_fail "env + clean malformed repo without HANDOFF still fails" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$MISSING_HANDOFF" --quiet --check handoff-date

MISSING_HISTORY="$TMP_ROOT/missing-history"
init_malformed_repo "$MISSING_HISTORY" history
expect_fail "env + clean malformed repo without HISTORY still fails" \
    env DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$MISSING_HISTORY" --quiet --check history-entry

expect_pass "trace-protocol skips without .dockit-config.yml" \
    "$VALIDATOR" --project "$REPO" --quiet --check trace-protocol

TRACE_REPO="$TMP_ROOT/trace"
init_repo "$TRACE_REPO"
TRACE_HASH=$(git -C "$TRACE_REPO" rev-parse --short=7 HEAD)
TRACE_SUBJECT=$(git -C "$TRACE_REPO" show -s --format=%s HEAD)
TRACE_TIME=$(git -C "$TRACE_REPO" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M:%S UTC' HEAD)

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

TRACE_TIME_MINUTES=$(git -C "$TRACE_REPO" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M UTC' HEAD)
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

printf '\nValidator smoke: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
