#!/bin/sh
# dockit-trace-status.sh -- Print current git/time facts for a Trace header.
#
# This helper cannot make an LLM use the output, but it removes the most common
# source of stale Trace reports: copying HEAD/time from an earlier mental state.

set -eu

PROJECT_ROOT=""
ROLE="executor"
SUBJECT="<fill subject>"
VALIDATION="<fill validation>"
NEXT_GATE="<fill next gate>"
GATE="next-slice"
NOTE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            PROJECT_ROOT="${2:-}"
            [ -n "$PROJECT_ROOT" ] || { echo "ERROR: --project requires a path" >&2; exit 2; }
            shift 2
            ;;
        --role)
            ROLE="${2:-}"
            [ -n "$ROLE" ] || { echo "ERROR: --role requires executor|auditor" >&2; exit 2; }
            shift 2
            ;;
        --subject)
            SUBJECT="${2:-}"
            [ -n "$SUBJECT" ] || { echo "ERROR: --subject requires text" >&2; exit 2; }
            shift 2
            ;;
        --validation)
            VALIDATION="${2:-}"
            [ -n "$VALIDATION" ] || { echo "ERROR: --validation requires text" >&2; exit 2; }
            shift 2
            ;;
        --next)
            NEXT_GATE="${2:-}"
            [ -n "$NEXT_GATE" ] || { echo "ERROR: --next requires text" >&2; exit 2; }
            shift 2
            ;;
        --gate)
            GATE="${2:-}"
            [ -n "$GATE" ] || { echo "ERROR: --gate requires text" >&2; exit 2; }
            shift 2
            ;;
        --note)
            NOTE="${2:-}"
            shift 2
            ;;
        --help|-h)
            cat <<'EOF'
Usage: scripts/dockit-trace-status.sh [options]

Options:
  --project PATH       Project root (default: git top-level or cwd)
  --role ROLE          executor|auditor (default: executor)
  --subject TEXT       Subject line for the Trace header
  --validation TEXT    Validation summary
  --next TEXT          Next gate text
  --gate TEXT          Resulting-state gate value (default: next-slice)
  --note TEXT          Optional short note appended to Resulting state
EOF
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

case "$ROLE" in
    executor|auditor) ;;
    *) echo "ERROR: --role must be executor or auditor" >&2; exit 2 ;;
esac

if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)

CONFIG_FILE="$PROJECT_ROOT/.dockit-config.yml"

trace_local_timezone() {
    [ -f "$CONFIG_FILE" ] || { echo "Europe/Madrid"; return; }
    awk '
        /^[[:space:]]*trace_protocol:[[:space:]]*$/ { in_trace = 1; next }
        /^[^[:space:]]/ { in_trace = 0 }
        in_trace && /^[[:space:]]{2}local_timezone:/ {
            sub(/^[[:space:]]{2}local_timezone:[[:space:]]*/, "")
            gsub(/^["'\'']|["'\'']$/, "")
            print
            found = 1
            exit
        }
        END { if (!found) print "Europe/Madrid" }
    ' "$CONFIG_FILE"
}

LOCAL_TZ=$(trace_local_timezone)
LOCAL_STAMP=$(TZ="$LOCAL_TZ" date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -u '+%Y-%m-%d %H:%M:%S')
UTC_STAMP=$(date -u '+%H:%M:%S UTC')

HEAD_FULL=$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || printf 'none')
if [ "$HEAD_FULL" = "none" ]; then
    HEAD_SHORT="none"
else
    HEAD_SHORT=$(git -C "$PROJECT_ROOT" rev-parse --short=7 HEAD)
fi

BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf 'detached')
UPSTREAM=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
UPSTREAM_SHORT=""
if [ -n "$UPSTREAM" ]; then
    UPSTREAM_FULL=$(git -C "$PROJECT_ROOT" rev-parse "$UPSTREAM" 2>/dev/null || true)
    if [ -n "$UPSTREAM_FULL" ]; then
        UPSTREAM_SHORT=$(git -C "$PROJECT_ROOT" rev-parse --short=7 "$UPSTREAM_FULL")
    fi
fi

if [ -z "$(git -C "$PROJECT_ROOT" status --porcelain=v1 2>/dev/null)" ]; then
    TREE_STATE="clean"
else
    TREE_STATE="dirty"
fi

VERSION="none"
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION=$(sed -n '1p' "$PROJECT_ROOT/VERSION")
fi

if [ -n "$UPSTREAM" ] && [ -n "$UPSTREAM_SHORT" ]; then
    REPO_STATE="local $BRANCH=$HEAD_SHORT, $UPSTREAM=$UPSTREAM_SHORT, $TREE_STATE"
else
    REPO_STATE="local $BRANCH=$HEAD_SHORT, no upstream, $TREE_STATE"
fi

RESULT_NOTE=""
if [ -n "$NOTE" ]; then
    RESULT_NOTE="; $NOTE"
fi

cat <<EOF
Trace
Role: $ROLE
Sent: $LOCAL_STAMP $LOCAL_TZ ($UTC_STAMP)
Subject: $SUBJECT
Resulting state: HEAD=$HEAD_SHORT; version=$VERSION; gate=$GATE$RESULT_NOTE
Repo state: $REPO_STATE
Validation: $VALIDATION
Next gate: $NEXT_GATE
EOF
