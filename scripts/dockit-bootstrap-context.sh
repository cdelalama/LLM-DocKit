#!/bin/sh
# dockit-bootstrap-context.sh -- Inject mandatory onboarding context at session start.
#
# Portable POSIX sh. Zero external dependencies.
# Designed as the SessionStart-side enforcement counterpart of
# dockit-validate-session.sh (which guards the Stop side).
#
# Failure mode addressed (DF-033):
#   Repo-level docs (LLM_START_HERE.md, CLAUDE.md, etc.) declare a mandatory
#   reading order, but compliance depends on LLM discipline alone. Empirical
#   observation: agents skip onboarding under narrow scopes ("audit X only"),
#   produce work on partial context, and only catch up when the operator
#   notices the gap. This script makes the reading order arrive at session
#   start as injected context (Claude Code SessionStart hook
#   `additionalContext`, or plain text for any other LLM).
#
# Output modes:
#   --json    Emit Claude Code SessionStart hook JSON
#             ({"hookSpecificOutput":{"hookEventName":"SessionStart",
#               "additionalContext":"..."}}). Default.
#   --human   Emit plain text suitable for the operator to paste into a
#             non-Claude LLM session (Codex CLI, Cursor, web ChatGPT, etc.).
#   --quiet   Emit nothing if the project lacks LLM_START_HERE.md (graceful
#             for repos that have not adopted LLM-DocKit). Default behaviour
#             of --json mode is silent on missing inputs anyway.
#
# Project root resolution:
#   --project PATH  Explicit override.
#   Otherwise: git rev-parse --show-toplevel, falling back to script-relative.
#
# Exit codes:
#   0  output produced (or silently empty by design)
#   2  script error (bad arguments)
#
# Size budget:
#   Claude Code's SessionStart additionalContext caps around 10,000 chars.
#   This script emits a compact instruction (~1.5 KB) that POINTS the LLM at
#   the docs to read; it does NOT concatenate the docs themselves. The
#   operator's heuristic (code/hook > prose) makes the point of the hook
#   "force the instruction to be visible", not "ship the content".

set -e

# -- Defaults --------------------------------------------------------------

PROJECT_ROOT=""
OUTPUT_MODE="json"
QUIET=false

# -- Parse arguments -------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        --json)   OUTPUT_MODE="json"; shift ;;
        --human)  OUTPUT_MODE="human"; shift ;;
        --quiet)  QUIET=true; shift ;;
        --project)
            if [ -z "$2" ]; then
                echo "ERROR: --project requires a path" >&2
                exit 2
            fi
            PROJECT_ROOT="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [--json|--human] [--quiet] [--project PATH]

Emits the project's mandatory onboarding instructions as Claude Code
SessionStart additionalContext (--json, default) or plain text (--human).

Reads LLM_START_HERE.md to extract the recommended reading order.
Adds docs/llm/HANDOFF.md as always-mandatory current-state pointer.

Exit 0 on success (including silently empty if no LLM_START_HERE.md).
Exit 2 on bad arguments.
EOF
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# -- Resolve project root --------------------------------------------------

if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$PROJECT_ROOT" ]; then
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
        PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
    fi
fi

START_HERE="$PROJECT_ROOT/LLM_START_HERE.md"
HANDOFF="$PROJECT_ROOT/docs/llm/HANDOFF.md"

# -- Graceful exit if onboarding not present -------------------------------

if [ ! -f "$START_HERE" ]; then
    # Repo does not adopt LLM-DocKit conventions; emit nothing so the hook
    # is a no-op and never breaks sessions in unrelated projects.
    exit 0
fi

# -- Extract recommended reading order from LLM_START_HERE.md --------------
#
# The template format (LLM-DocKit 4.x) declares it as:
#
#   Recommended reading order:
#   1. This file (rules, workflows, and current expectations)
#   2. docs/PROJECT_CONTEXT.md (vision, architecture, current state)
#   ...
#
# We extract the numbered list following the "Recommended reading order:"
# header. Blank lines BEFORE the first numbered item are skipped (some
# customised templates put a blank line between the header and the list);
# the first blank line AFTER capture has started terminates the list.

READING_ORDER=$(awk '
    /^[Rr]ecommended reading order:/   { capture = 1; next }
    capture && started && /^[[:space:]]*$/ { exit }
    capture && /^[[:space:]]*[0-9]+\./ { started = 1; print }
' "$START_HERE")

# If the section is missing or unrecognisable, fall back to a generic
# "read LLM_START_HERE.md and HANDOFF.md" instruction.

if [ -z "$READING_ORDER" ]; then
    READING_ORDER="  1. LLM_START_HERE.md (this project's mandatory onboarding)
  2. docs/llm/HANDOFF.md (current session focus and pending work)"
fi

# -- Build the message -----------------------------------------------------
#
# Tone is calibrated:
#  - Direct ("MUST"), not advisory.
#  - Names the failure mode it prevents (DF-033) so the LLM understands the
#    rule has empirical motivation, not just maintainer preference.
#  - Provides a small protocol the LLM can follow without ambiguity:
#    state "Onboarding loaded" or "Onboarding skipped: <reason>" before
#    proceeding. The string is short enough to be observable in transcripts.
#  - Allows trivial requests to skip onboarding so the gate does not become
#    ceremony for one-line edits.

MESSAGE=$(cat <<'EOF'
SESSION-START ONBOARDING (LLM-DocKit enforcement, DF-033)

This project declares a mandatory reading order in LLM_START_HERE.md.
Empirical observation (LLM-DocKit DF-033): passive instructions in repo
docs are skipped when the LLM is given a narrow scope ("audit X", "fix
Y"), producing work on partial context. This SessionStart hook forces
the instruction to be visible at the start of every session.

Before answering substantive questions about this project (architecture,
ecosystem, design, audit, refactor, planning), you MUST read:

EOF
)

MESSAGE="$MESSAGE
$READING_ORDER

  + docs/llm/HANDOFF.md (always — current session focus, do-not-touch zones)

Protocol:
  - First substantive reply must begin with one of:
      'Onboarding loaded.'           after reading the listed files, or
      'Onboarding skipped: <reason>' for trivial edits / syntax questions
        that do not depend on architectural context.
  - 'Onboarding skipped' without a reason is not acceptable.
  - If the user's request later widens scope, read the onboarding then
    and switch to 'Onboarding loaded (mid-session).'

This message is emitted by scripts/dockit-bootstrap-context.sh. To change
the reading order, edit LLM_START_HERE.md (the script reads it dynamically)."

# -- Append project root for absolute-path clarity -------------------------

MESSAGE="$MESSAGE

Project root: $PROJECT_ROOT"

if [ -f "$HANDOFF" ]; then
    HANDOFF_DATE=$(awk -F'-' '/Last Updated:/ { print; exit }' "$HANDOFF" 2>/dev/null | head -c 200)
    if [ -n "$HANDOFF_DATE" ]; then
        MESSAGE="$MESSAGE
HANDOFF.md: $HANDOFF_DATE"
    fi
fi

# -- Emit ------------------------------------------------------------------

case "$OUTPUT_MODE" in
    human)
        printf '%s\n' "$MESSAGE"
        ;;
    json)
        # JSON-escape the message: backslashes, double quotes, then newlines.
        # awk is POSIX and handles this safely without shell quoting hazards.
        ESCAPED=$(printf '%s' "$MESSAGE" | awk '
            BEGIN { ORS = "" }
            {
                gsub(/\\/, "\\\\")
                gsub(/"/, "\\\"")
                gsub(/\t/, "\\t")
                if (NR > 1) printf "\\n"
                printf "%s", $0
            }
        ')
        printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ESCAPED"
        ;;
esac

exit 0
