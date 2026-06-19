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
CHECK_VERSION="$PROJECT_ROOT/scripts/check-version-sync.sh"
BUMP_VERSION="$PROJECT_ROOT/scripts/bump-version.sh"

TMP_ROOT=${TMPDIR:-/tmp}/dockit-validator-smoke.$$
OUT="$TMP_ROOT/out.txt"
TODAY=$(date +%Y-%m-%d)

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

cat >"$TRACE_REPO/docs/llm/HISTORY.md" <<EOF
# History

2000-01-02 - Smoke - Audited \`$TRACE_HASH\`. - Files: [scripts/foo.sh] - Version impact: no - Trace: role=auditor; commits=$TRACE_HASH; state=local-main-no-origin; validation=smoke-pass; next=operator
EOF
expect_pass "trace-protocol accepts no-dash HISTORY footer" \
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

printf '\nValidator smoke: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [ "$fail_count" -gt 0 ]; then
    exit 1
fi
