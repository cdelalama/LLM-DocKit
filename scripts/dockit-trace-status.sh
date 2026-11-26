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
FORMAT="auto"
CLIENT=""
MODEL=""
MODEL_FAMILY=""
ACCOUNT=""
SESSION=""
TASK=""
DOSSIER=""
LANGUAGE="en"

while [ $# -gt 0 ]; do
    case "$1" in
        --project)
            PROJECT_ROOT="${2:-}"
            [ -n "$PROJECT_ROOT" ] || { echo "ERROR: --project requires a path" >&2; exit 2; }
            shift 2
            ;;
        --role)
            ROLE="${2:-}"
            [ -n "$ROLE" ] || { echo "ERROR: --role requires executor|auditor|advisor" >&2; exit 2; }
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
        --format|--client|--model|--model-family|--account|--session|--task|--dossier|--language)
            [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "ERROR: $1 requires a value" >&2; exit 2; }
            case "$1" in
                --format) FORMAT=$2 ;;
                --client) CLIENT=$2 ;;
                --model) MODEL=$2 ;;
                --model-family) MODEL_FAMILY=$2 ;;
                --account) ACCOUNT=$2 ;;
                --session) SESSION=$2 ;;
                --task) TASK=$2 ;;
                --dossier) DOSSIER=$2 ;;
                --language) LANGUAGE=$2 ;;
            esac
            shift 2
            ;;
        --help|-h)
            cat <<'EOF'
Usage: scripts/dockit-trace-status.sh [options]

Options:
  --project PATH       Project root (default: git top-level or cwd)
  --role ROLE          executor|auditor|advisor (default: executor)
  --subject TEXT       Subject line for the Trace header
  --validation TEXT    Validation summary
  --next TEXT          Next gate text
  --gate TEXT          Resulting-state gate value (default: next-slice)
  --note TEXT          Optional short note appended to Resulting state
  --format FORMAT      auto (default), text, html, or json
  --client TEXT        Optional observed client identity
  --model TEXT         Optional verified actual model; unknown when unverified
  --model-family TEXT  Optional observed model family (not an account)
  --account TEXT       Optional opaque, non-secret account alias
  --session TEXT       Optional non-secret session identity
  --task TEXT          Optional task identity
  --dossier TEXT       Optional last checked Dossier status (no network probe)
  --language LANG      HTML labels: en (default) or es; text is unchanged

auto writes static HTML only when ORCA_CHAT_SCRATCH_DIR names an existing
directory; stdout then contains the Orca visual directive. Missing capability,
renderer, Python, size overflow or a write failure falls back to ordinary text.
html requires the same declared Orca capability and also falls back to text.
json emits the same snapshot as structured data (Python 3 required).
Never supply credentials or private account addresses in any field.
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
    executor|auditor|advisor) ;;
    *) echo "ERROR: --role must be executor, auditor, or advisor" >&2; exit 2 ;;
esac
case "$LANGUAGE" in
    en|es) ;;
    *) echo "ERROR: --language must be en or es" >&2; exit 2 ;;
esac

case "$FORMAT" in
    auto|text|html|json) ;;
    *) echo "ERROR: --format must be auto, text, html, or json" >&2; exit 2 ;;
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

# Capture one UTC instant, then convert it. Git Bash date may ignore named TZ
# values without failing; matching UTC is not evidence of a bad zone (London
# in winter is legitimately UTC). Every converter must know the requested zone.
TRACE_PYTHON=""
for _python in python3 python; do
    if command -v "$_python" >/dev/null 2>&1 && "$_python" -c 'import sys; sys.exit(sys.version_info.major != 3)' 2>/dev/null; then
        TRACE_PYTHON=$_python
        break
    fi
done
TRACE_POWERSHELL=""
if [ "${OS:-}" = Windows_NT ]; then
    for _powershell in powershell.exe pwsh powershell; do
        if command -v "$_powershell" >/dev/null 2>&1; then
            TRACE_POWERSHELL=$_powershell
            break
        fi
    done
fi

trace_epoch_valid() {
    case "$1" in ''|*[!0-9]*) return 1 ;; esac
    [ "${#1}" -le 12 ]
}
TRACE_EPOCH=$(date -u '+%s' 2>/dev/null || true)
if ! trace_epoch_valid "$TRACE_EPOCH" && [ -n "$TRACE_PYTHON" ]; then
    TRACE_EPOCH=$("$TRACE_PYTHON" -c 'import time; print(int(time.time()))' 2>/dev/null || true)
fi
if ! trace_epoch_valid "$TRACE_EPOCH" && [ -n "$TRACE_POWERSHELL" ]; then
    TRACE_EPOCH=$("$TRACE_POWERSHELL" -NoProfile -NonInteractive -Command \
        '[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()' 2>/dev/null | tr -d '\r')
fi

trace_python_time() {
    [ -n "$TRACE_PYTHON" ] || return 1
    "$TRACE_PYTHON" - "$TRACE_EPOCH" "$LOCAL_TZ" <<'PYTIME'
import sys
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
instant = datetime.fromtimestamp(int(sys.argv[1]), timezone.utc)
local = instant.astimezone(ZoneInfo(sys.argv[2]))
print(local.strftime("%Y-%m-%d %H:%M:%S") + "|" + instant.strftime("%H:%M:%S UTC"))
PYTIME
}

trace_powershell_time() {
    [ -n "$TRACE_POWERSHELL" ] || return 1
    # Try native IANA resolution first. Windows PowerShell may only know
    # Windows IDs: explicitly map the default Madrid zone, never invent offsets
    # or treat other European zones as equivalent. Unknown zones fail closed.
    DOCKIT_TRACE_EPOCH="$TRACE_EPOCH" DOCKIT_TRACE_ZONE="$LOCAL_TZ" \
    "$TRACE_POWERSHELL" -NoProfile -NonInteractive -Command '
$ErrorActionPreference = "Stop"
try {
    $name = $env:DOCKIT_TRACE_ZONE
    try { $zone = [TimeZoneInfo]::FindSystemTimeZoneById($name) }
    catch {
        if ($name -eq "Europe/Madrid") { $id = "Romance Standard Time" }
        elseif ($name -eq "Etc/UTC" -or $name -eq "UTC") { $id = "UTC" }
        else { throw }
        $zone = [TimeZoneInfo]::FindSystemTimeZoneById($id)
    }
    $utc = [DateTimeOffset]::FromUnixTimeSeconds([long]$env:DOCKIT_TRACE_EPOCH).UtcDateTime
    $local = [TimeZoneInfo]::ConvertTimeFromUtc($utc, $zone)
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $local.ToString("yyyy-MM-dd HH:mm:ss", $culture) + "|" + $utc.ToString("HH:mm:ss", $culture) + " UTC"
} catch { exit 1 }
'
}

trace_date_time() {
    # Without Python, use date only after a real TZif capability probe. A known
    # nonzero sentinel catches date implementations silently ignoring TZ. Both
    # the requested zone and sentinel must be actual system zoneinfo files.
    case "$LOCAL_TZ" in ''|/*|*..*|*[!A-Za-z0-9_+/-]*) return 1 ;; esac
    for _tzroot in /usr/share/zoneinfo /usr/share/lib/zoneinfo /var/db/timezone/zoneinfo; do
        _zone=$_tzroot/$LOCAL_TZ
        _sentinel=$_tzroot/Etc/GMT-12
        [ -f "$_zone" ] && [ -f "$_sentinel" ] || continue
        [ "$(dd if="$_zone" bs=4 count=1 2>/dev/null)" = TZif ] || continue
        [ "$(dd if="$_sentinel" bs=4 count=1 2>/dev/null)" = TZif ] || continue
        for _date_style in gnu bsd; do
            if [ "$_date_style" = gnu ]; then set -- -d '@0'; else set -- -r 0; fi
            _probe=$(TZ=":$_sentinel" date "$@" '+%Y-%m-%d %H:%M:%S' 2>/dev/null) || continue
            [ "$_probe" = '1970-01-01 12:00:00' ] || continue
            if [ "$_date_style" = gnu ]; then set -- -d "@$TRACE_EPOCH"; else set -- -r "$TRACE_EPOCH"; fi
            _local=$(TZ=":$_zone" date "$@" '+%Y-%m-%d %H:%M:%S' 2>/dev/null) || continue
            _utc=$(date -u "$@" '+%H:%M:%S UTC' 2>/dev/null) || continue
            printf '%s|%s\n' "$_local" "$_utc"
            return 0
        done
    done
    return 1
}

LOCAL_TZ=$(trace_local_timezone)
SENT="unverified client time (clock unavailable; requested zone $LOCAL_TZ)"
if trace_epoch_valid "$TRACE_EPOCH"; then
    SENT="unverified client time (UTC epoch $TRACE_EPOCH; requested zone $LOCAL_TZ)"
    TIME_PAIR=$(trace_python_time 2>/dev/null || trace_powershell_time 2>/dev/null || trace_date_time 2>/dev/null || true)
    TIME_PAIR=$(printf '%s' "$TIME_PAIR" | tr -d '\r')
    if printf '%s\n' "$TIME_PAIR" | LC_ALL=C awk '
        /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\|[0-9]{2}:[0-9]{2}:[0-9]{2} UTC$/ { valid++; next }
        { bad = 1 }
        END { exit !(valid == 1 && !bad) }
    '; then
        SENT="${TIME_PAIR%%|*} $LOCAL_TZ (${TIME_PAIR#*|})"
    fi
fi

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

trace_text() {
cat <<EOF
Trace
Role: $ROLE
Sent: $SENT
Subject: $SUBJECT
Resulting state: HEAD=$HEAD_SHORT; version=$VERSION; gate=$GATE$RESULT_NOTE
Repo state: $REPO_STATE
Validation: $VALIDATION
Next gate: $NEXT_GATE
EOF
    [ -z "$CLIENT" ] || printf 'Client: %s\n' "$CLIENT"
    [ -z "$MODEL" ] || printf 'Model: %s\n' "$MODEL"
    [ -z "$MODEL_FAMILY" ] || printf 'Model family: %s\n' "$MODEL_FAMILY"
    [ -z "$ACCOUNT" ] || printf 'Account: %s\n' "$ACCOUNT"
    [ -z "$SESSION" ] || printf 'Session: %s\n' "$SESSION"
    [ -z "$TASK" ] || printf 'Task: %s\n' "$TASK"
    [ -z "$DOSSIER" ] || printf 'Dossier: %s\n' "$DOSSIER"
    return 0
}

# Read-only Git/time collection above happens once. Rendering never recollects
# facts, starts a service, or creates a scratch directory. Plain terminals keep
# the exact default text shape, including when Python is unavailable.
if [ "$FORMAT" = text ] || { [ "$FORMAT" = auto ] && [ -z "${ORCA_CHAT_SCRATCH_DIR:-}" ]; }; then
    trace_text
    exit 0
fi
RENDERER=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)/dockit-trace-render.py
if [ -z "$TRACE_PYTHON" ] || [ ! -f "$RENDERER" ]; then
    if [ "$FORMAT" = json ]; then
        echo "ERROR: JSON Trace requires Python 3 and dockit-trace-render.py" >&2
        exit 2
    fi
    echo "Trace HTML unavailable: missing Python 3 or renderer; using text." >&2
    trace_text
    exit 0
fi
if "$TRACE_PYTHON" -B "$RENDERER" --format "$FORMAT" --language "$LANGUAGE" \
    --role="$ROLE" --sent="$SENT" \
    --subject="$SUBJECT" --resulting-state="HEAD=$HEAD_SHORT; version=$VERSION; gate=$GATE$RESULT_NOTE" \
    --repo-state="$REPO_STATE" --validation="$VALIDATION" --next="$NEXT_GATE" \
    --client="$CLIENT" --model="$MODEL" --model-family="$MODEL_FAMILY" \
    --account="$ACCOUNT" --session="$SESSION" --task="$TASK" --dossier="$DOSSIER"; then
    exit 0
fi
if [ "$FORMAT" = json ]; then exit 2; fi
echo "Trace HTML unavailable: renderer failed; using text." >&2
trace_text
