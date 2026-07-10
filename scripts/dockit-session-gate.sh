#!/bin/sh
# dockit-session-gate.sh -- Session-aware Claude Code documentation gate.
#
# Portable POSIX sh. Reads Claude Code hook JSON from stdin.
# SessionStart records a per-session tracked-state baseline. Stop compares that
# baseline through dockit-validate-session.sh and blocks at most once per stop
# attempt by honoring stop_hook_active.

set -eu

MODE=""
PROJECT_ROOT=""
BASELINE_MAX_AGE_DAYS=${DOCKIT_BASELINE_MAX_AGE_DAYS:-7}

usage() {
    echo "Usage: $0 --start|--stop [--project PATH]" >&2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --start|--stop)
            MODE=${1#--}
            shift
            ;;
        --project)
            [ $# -ge 2 ] || { usage; exit 2; }
            PROJECT_ROOT="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

[ -n "$MODE" ] || { usage; exit 2; }

if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$PROJECT_ROOT" ]; then
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
        PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
    fi
fi

VALIDATOR="$PROJECT_ROOT/scripts/dockit-validate-session.sh"
INPUT=$(cat)
INPUT_ONE_LINE=$(printf '%s' "$INPUT" | tr '\n' ' ')

json_string_field() {
    _field="$1"
    printf '%s\n' "$INPUT_ONE_LINE" | sed -n "s/.*\"$_field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

json_boolean_true() {
    _field="$1"
    printf '%s\n' "$INPUT_ONE_LINE" | grep -Eq "\"$_field\"[[:space:]]*:[[:space:]]*true([[:space:],}]|$)"
}

SESSION_ID=$(json_string_field session_id)
SOURCE=$(json_string_field source)

case "$SESSION_ID" in
    ""|*[!A-Za-z0-9._-]*) SESSION_ID="" ;;
esac

baseline_root() {
    _git_dir=$(git -C "$PROJECT_ROOT" rev-parse --absolute-git-dir 2>/dev/null || true)
    [ -n "$_git_dir" ] || return 1
    printf '%s/.dockit/session-baselines\n' "$_git_dir"
}

BASELINE_ROOT=$(baseline_root || true)
BASELINE_SLOT=""
BASELINE_FILE=""
if [ -n "$SESSION_ID" ] && [ -n "$BASELINE_ROOT" ]; then
    BASELINE_SLOT="$BASELINE_ROOT/$SESSION_ID"
    BASELINE_FILE="$BASELINE_SLOT/state"
fi

prune_baselines() {
    [ -d "$BASELINE_ROOT" ] || return 0
    case "$BASELINE_MAX_AGE_DAYS" in
        ""|*[!0-9]*) return 0 ;;
    esac
    for _slot in "$BASELINE_ROOT"/*; do
        [ -d "$_slot" ] || continue
        if find "$_slot" -prune -mtime "+$BASELINE_MAX_AGE_DAYS" -print 2>/dev/null \
            | grep -q .; then
            rm -rf "$_slot"
        fi
    done
}

tracked_diff_hash() {
    _tmp_diff=$(mktemp "${TMPDIR:-/tmp}/dockit-session-diff.XXXXXX")
    if git -C "$PROJECT_ROOT" diff HEAD --binary --no-ext-diff >"$_tmp_diff" 2>/dev/null; then
        git -C "$PROJECT_ROOT" hash-object --stdin <"$_tmp_diff"
        _rc=0
    else
        _rc=1
    fi
    rm -f "$_tmp_diff"
    return "$_rc"
}

write_baseline() {
    [ -n "$BASELINE_FILE" ] || return 0
    mkdir -p "$BASELINE_ROOT"
    prune_baselines

    if [ "$SOURCE" != "clear" ] && [ -f "$BASELINE_FILE" ]; then
        return 0
    fi

    _head=$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || true)
    _diff=$(tracked_diff_hash || true)
    [ -n "$_head" ] && [ -n "$_diff" ] || return 0

    mkdir -p "$BASELINE_SLOT"
    _tmp_state="$BASELINE_SLOT/state.tmp.$$"
    {
        printf 'head=%s\n' "$_head"
        printf 'diff=%s\n' "$_diff"
        printf 'created_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)"
        printf 'untracked=excluded\n'
    } >"$_tmp_state"
    mv "$_tmp_state" "$BASELINE_FILE"
}

cleanup_baseline() {
    [ -n "$BASELINE_SLOT" ] || return 0
    rm -rf "$BASELINE_SLOT"
}

json_escape() {
    sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | sed 's/\t/ /g'
}

if [ "$MODE" = "start" ]; then
    case "$SOURCE" in
        startup|clear|"") write_baseline ;;
        resume|compact) : ;;
        *) : ;;
    esac
    exit 0
fi

if json_boolean_true stop_hook_active; then
    cleanup_baseline
    exit 0
fi

if [ ! -x "$VALIDATOR" ]; then
    _reason=$(printf 'Documentation validator not found or not executable: %s' "$VALIDATOR" | json_escape)
    printf '{"decision":"block","reason":"%s"}\n' "$_reason"
    exit 0
fi

if [ -n "$BASELINE_FILE" ] && [ -f "$BASELINE_FILE" ]; then
    DOCKIT_SESSION_BASELINE_FILE="$BASELINE_FILE"
    export DOCKIT_SESSION_BASELINE_FILE
fi

if _validation=$(DOCKIT_ALLOW_READ_ONLY_SKIP=1 "$VALIDATOR" --project "$PROJECT_ROOT" --json --quiet 2>&1); then
    cleanup_baseline
    exit 0
fi

_escaped_validation=$(printf '%s' "$_validation" | json_escape)
printf '{"decision":"block","reason":"Documentation validation failed: %s Run: scripts/dockit-validate-session.sh --human"}\n' "$_escaped_validation"
exit 0
