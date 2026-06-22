#!/bin/sh
# dockit-validate-session.sh -- Validate LLM documentation state.
#
# Portable POSIX sh. Zero external dependencies.
# Designed as the single entry point for all enforcement drivers
# (Claude Code hooks, pre-commit, CI, manual).
#
# Exit codes:
#   0 -- all checks pass
#   1 -- at least one ERROR check failed
#   2 -- script error (bad arguments, missing files)
#
# Usage:
#   scripts/dockit-validate-session.sh                    # JSON output (default)
#   scripts/dockit-validate-session.sh --human            # plain text output
#   scripts/dockit-validate-session.sh --check handoff-date --check history-entry
#   scripts/dockit-validate-session.sh --quiet            # suppress PASS output
#   scripts/dockit-validate-session.sh --project /path    # custom project root

set -e

# ── Defaults ──────────────────────────────────────────────────────────────────

PROJECT_ROOT=""
OUTPUT_MODE="json"
QUIET=false
SELECTED_CHECKS=""
TODAY=$(date +%Y-%m-%d)

# ── Parse arguments ──────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --human)
            OUTPUT_MODE="human"
            shift
            ;;
        --json)
            OUTPUT_MODE="json"
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --check)
            if [ -z "$2" ]; then
                echo "ERROR: --check requires a value" >&2
                exit 2
            fi
            SELECTED_CHECKS="$SELECTED_CHECKS $2"
            shift 2
            ;;
        --project)
            if [ -z "$2" ]; then
                echo "ERROR: --project requires a path" >&2
                exit 2
            fi
            PROJECT_ROOT="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--human|--json] [--quiet] [--check NAME]... [--project PATH]"
            echo ""
            echo "Checks: handoff-date, history-entry, decisions-referenced, version-sync, external-context, external-triggers, orientation, orientation-drift, template-residue, trace-protocol"
            echo ""
            echo "Exit codes: 0=pass, 1=fail, 2=script error"
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# ── Resolve project root ────────────────────────────────────────────────────

if [ -z "$PROJECT_ROOT" ]; then
    # Try git root first, then fall back to script location
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$PROJECT_ROOT" ]; then
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
        PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
    fi
fi

if [ ! -d "$PROJECT_ROOT" ]; then
    echo "ERROR: project root not found: $PROJECT_ROOT" >&2
    exit 2
fi

# ── File paths ───────────────────────────────────────────────────────────────

HANDOFF="$PROJECT_ROOT/docs/llm/HANDOFF.md"
HISTORY="$PROJECT_ROOT/docs/llm/HISTORY.md"
DECISIONS="$PROJECT_ROOT/docs/llm/DECISIONS.md"
CHECK_VERSION_SCRIPT="$PROJECT_ROOT/scripts/check-version-sync.sh"
CONFIG_FILE="$PROJECT_ROOT/.dockit-config.yml"

# ── Results accumulator ─────────────────────────────────────────────────────

RESULTS=""
ERRORS=0
WARNINGS=0
CHECKS_RUN=0

add_result() {
    _name="$1"
    _status="$2"
    _message="$3"

    CHECKS_RUN=$((CHECKS_RUN + 1))

    if [ "$_status" = "FAIL" ]; then
        ERRORS=$((ERRORS + 1))
    elif [ "$_status" = "WARN" ]; then
        WARNINGS=$((WARNINGS + 1))
    fi

    # In quiet mode, suppress PASS results from output
    if [ "$QUIET" = true ] && [ "$_status" = "PASS" ]; then
        return
    fi

    if [ -n "$RESULTS" ]; then
        RESULTS="$RESULTS,"
    fi
    # Escape for valid JSON: backslashes, double quotes, newlines, tabs
    _escaped_msg=$(printf '%s' "$_message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ' | sed 's/\t/ /g')
    RESULTS="$RESULTS{\"name\":\"$_name\",\"status\":\"$_status\",\"message\":\"$_escaped_msg\"}"
}

# ── Check: should this check run? ───────────────────────────────────────────

should_run() {
    _check_name="$1"
    if [ -z "$SELECTED_CHECKS" ]; then
        return 0  # no filter = run all
    fi
    for _selected_check in $SELECTED_CHECKS; do
        if [ "$_selected_check" = "$_check_name" ]; then
            return 0
        fi
    done
    return 1
}

is_zero_diff_read_only_session() {
    [ "${DOCKIT_ALLOW_READ_ONLY_SKIP:-0}" = "1" ] || return 1
    (cd "$PROJECT_ROOT" \
        && git diff HEAD --quiet 2>/dev/null \
        && git diff --cached --quiet 2>/dev/null)
}

is_clean_tracked_tree() {
    (cd "$PROJECT_ROOT" \
        && git diff HEAD --quiet 2>/dev/null \
        && git diff --cached --quiet 2>/dev/null)
}

validation_reference_date() {
    if is_clean_tracked_tree; then
        _head_date=$(cd "$PROJECT_ROOT" && git show -s --format=%cd --date=format:%Y-%m-%d HEAD 2>/dev/null || true)
        if [ -n "$_head_date" ]; then
            echo "$_head_date|last commit date"
            return
        fi
    fi
    echo "$TODAY|today"
}

# Minimal top-level .dockit-config.yml reader. This intentionally handles only
# simple scalar keys at indentation 0; nested feature parsers stay separate.
_read_top_level_value() {
    _key="$1"
    [ -f "$CONFIG_FILE" ] || return
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        [ "$_i" -eq 0 ] || continue
        case "$_s" in
            "$_key":*)
                echo "$_s" | sed "s/^$_key: *//; s/^\"//; s/\"$//; s/^'//; s/'$//"
                return
                ;;
        esac
    done < "$CONFIG_FILE"
}

_read_history_format() {
    _format=$(_read_top_level_value history_format || true)
    if [ -n "$_format" ]; then
        echo "$_format"
    else
        echo "any"
    fi
}

_history_dated_entries() {
    awk '
        /^```/ { in_fence = !in_fence; next }
        in_fence { next }
        /^- [0-9]{4}-[0-9]{2}-[0-9]{2} - / {
            print substr($0, 3, 10) "|dash|" NR
            next
        }
        /^[0-9]{4}-[0-9]{2}-[0-9]{2} - / {
            print substr($0, 1, 10) "|no-dash|" NR
            next
        }
    ' "$HISTORY"
}

# ── Check functions ─────────────────────────────────────────────────────────

check_handoff_date() {
    if ! should_run "handoff-date"; then return; fi

    if [ ! -f "$HANDOFF" ]; then
        add_result "handoff-date" "FAIL" "HANDOFF.md not found at $HANDOFF"
        return
    fi

    if is_zero_diff_read_only_session; then
        add_result "handoff-date" "PASS" "Skipped (DOCKIT_ALLOW_READ_ONLY_SKIP=1, zero-diff session)"
        return
    fi

    _reference=$(validation_reference_date)
    _expected_date=$(printf '%s\n' "$_reference" | cut -d'|' -f1)
    _expected_label=$(printf '%s\n' "$_reference" | cut -d'|' -f2)

    # Look for "Last Updated: YYYY-MM-DD" pattern
    handoff_date=$(grep -E '^\s*-?\s*Last Updated:' "$HANDOFF" 2>/dev/null | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)

    if [ -z "$handoff_date" ]; then
        add_result "handoff-date" "FAIL" "No 'Last Updated' date found in HANDOFF.md"
    elif [ "$handoff_date" != "$_expected_date" ]; then
        add_result "handoff-date" "FAIL" "Last Updated is $handoff_date, expected $_expected_date ($_expected_label)"
    else
        add_result "handoff-date" "PASS" "HANDOFF.md has expected date ($_expected_date, $_expected_label)"
    fi
}

check_history_entry() {
    if ! should_run "history-entry"; then return; fi

    if [ ! -f "$HISTORY" ]; then
        add_result "history-entry" "FAIL" "HISTORY.md not found at $HISTORY"
        return
    fi

    if is_zero_diff_read_only_session; then
        add_result "history-entry" "PASS" "Skipped (DOCKIT_ALLOW_READ_ONLY_SKIP=1, zero-diff session)"
        return
    fi

    _history_format=$(_read_history_format)
    case "$_history_format" in
        any|dash|no-dash) ;;
        *)
            add_result "history-entry" "FAIL" "Invalid history_format '$_history_format' in .dockit-config.yml (expected any, dash, or no-dash)"
            return
            ;;
    esac

    _entries=$(_history_dated_entries)
    if [ -z "$_entries" ]; then
        add_result "history-entry" "FAIL" "No dated HISTORY.md entries found"
        return
    fi

    _first=$(printf '%s\n' "$_entries" | head -1)
    _first_date=$(printf '%s\n' "$_first" | cut -d'|' -f1)
    _first_format=$(printf '%s\n' "$_first" | cut -d'|' -f2)

    _reference=$(validation_reference_date)
    _expected_date=$(printf '%s\n' "$_reference" | cut -d'|' -f1)
    _expected_label=$(printf '%s\n' "$_reference" | cut -d'|' -f2)

    if [ "$_first_date" != "$_expected_date" ]; then
        add_result "history-entry" "FAIL" "First dated HISTORY.md entry is $_first_date, expected $_expected_date ($_expected_label)"
        return
    fi

    _format_error=""
    _order_error=""
    _prev_date=""
    _old_ifs="$IFS"
    IFS='
'
    for _entry in $_entries; do
        _date=$(printf '%s\n' "$_entry" | cut -d'|' -f1)
        _format=$(printf '%s\n' "$_entry" | cut -d'|' -f2)
        _line=$(printf '%s\n' "$_entry" | cut -d'|' -f3)

        if [ "$_history_format" = "dash" ] && [ "$_format" != "dash" ]; then
            _format_error="line $_line uses no-dash format but history_format=dash"
            break
        fi
        if [ "$_history_format" = "no-dash" ] && [ "$_format" != "no-dash" ]; then
            _format_error="line $_line uses dash format but history_format=no-dash"
            break
        fi

        if [ -n "$_prev_date" ] && awk -v prev="$_prev_date" -v curr="$_date" 'BEGIN { exit (curr > prev) ? 0 : 1 }'; then
            _order_error="line $_line has date $_date after newer entry $_prev_date; HISTORY.md must be newest-first"
            break
        fi
        _prev_date="$_date"
    done
    IFS="$_old_ifs"

    if [ -n "$_format_error" ]; then
        add_result "history-entry" "FAIL" "$_format_error"
    elif [ -n "$_order_error" ]; then
        add_result "history-entry" "FAIL" "$_order_error"
    else
        add_result "history-entry" "PASS" "HISTORY.md first dated entry is $_expected_date ($_expected_label); format $_first_format accepted by history_format=$_history_format; dated entries are newest-first"
    fi
}

check_decisions_referenced() {
    if ! should_run "decisions-referenced"; then return; fi

    if [ ! -f "$HANDOFF" ]; then
        add_result "decisions-referenced" "FAIL" "HANDOFF.md not found"
        return
    fi
    if [ ! -f "$DECISIONS" ]; then
        add_result "decisions-referenced" "FAIL" "DECISIONS.md not found"
        return
    fi

    # Extract D-xxx references from HANDOFF
    handoff_refs=$(grep -oE 'D-[0-9]{3}' "$HANDOFF" 2>/dev/null | sort -u || true)

    if [ -z "$handoff_refs" ]; then
        add_result "decisions-referenced" "PASS" "No D-xxx references in HANDOFF.md"
        return
    fi

    missing=""
    for ref in $handoff_refs; do
        if ! grep -q "^## $ref" "$DECISIONS" 2>/dev/null; then
            missing="$missing $ref"
        fi
    done

    if [ -n "$missing" ]; then
        add_result "decisions-referenced" "FAIL" "HANDOFF references D-xxx IDs not in DECISIONS.md:$missing"
    else
        count=$(echo "$handoff_refs" | wc -w | tr -d ' ')
        add_result "decisions-referenced" "PASS" "All $count D-xxx references found in DECISIONS.md"
    fi
}

check_version_sync() {
    if ! should_run "version-sync"; then return; fi

    if [ ! -f "$CHECK_VERSION_SCRIPT" ]; then
        add_result "version-sync" "FAIL" "check-version-sync.sh not found"
        return
    fi

    # Run from PROJECT_ROOT so relative paths in check-version-sync.sh work
    sync_output=$(cd "$PROJECT_ROOT" && "$CHECK_VERSION_SCRIPT" 2>&1) && sync_rc=0 || sync_rc=$?

    if [ "$sync_rc" -eq 0 ]; then
        add_result "version-sync" "PASS" "$sync_output"
    else
        add_result "version-sync" "FAIL" "$sync_output"
    fi
}

# ── External context parser helpers ──────────────────────────────────────────
# State-machine parser for .dockit-config.yml external_context section.
# Each helper reads CONFIG_FILE independently (simple, no shared state needed).

_read_ext_path() {
    [ -f "$CONFIG_FILE" ] || return
    _in=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "external_context:" ] && _in=true || _in=false
            continue
        fi
        if [ "$_in" = true ] && [ "$_i" -eq 2 ]; then
            case "$_s" in path:*) echo "$_s" | sed 's/^path: *//' ;; esac
        fi
    done < "$CONFIG_FILE"
}

_read_ext_read_files() {
    [ -f "$CONFIG_FILE" ] || return
    _in=false; _in_read=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "external_context:" ] && { _in=true; _in_read=false; } || { _in=false; _in_read=false; }
            continue
        fi
        [ "$_in" = false ] && continue
        if [ "$_i" -eq 2 ]; then
            [ "$_s" = "read:" ] && _in_read=true || _in_read=false
            continue
        fi
        if [ "$_i" -eq 4 ] && [ "$_in_read" = true ]; then
            echo "$_s" | sed 's/^- *//'
        fi
    done < "$CONFIG_FILE"
}

_read_ext_triggers() {
    [ -f "$CONFIG_FILE" ] || return
    _in=false; _in_trig=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "external_context:" ] && { _in=true; _in_trig=false; } || { _in=false; _in_trig=false; }
            continue
        fi
        [ "$_in" = false ] && continue
        if [ "$_i" -eq 2 ]; then
            [ "$_s" = "update_triggers:" ] && _in_trig=true || _in_trig=false
            continue
        fi
        if [ "$_i" -eq 4 ] && [ "$_in_trig" = true ]; then
            _t=$(echo "$_s" | sed 's/^- *//')
            _local=$(echo "$_t" | sed 's/^local: *//; s/ *target:.*$//')
            _target=$(echo "$_t" | sed 's/.*target: *//')
            echo "$_local|$_target"
        fi
    done < "$CONFIG_FILE"
}

# ── Trace protocol parser helpers ───────────────────────────────────────────
# State-machine parser for .dockit-config.yml trace_protocol section.
# The validator enforces the durable half only when projects explicitly set
# trace_protocol.enabled: true. Chat guidance is handled by SessionStart
# onboarding and can be disabled independently by setting enabled: false.

_read_trace_value() {
    _key="$1"
    [ -f "$CONFIG_FILE" ] || return
    _in=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "trace_protocol:" ] && _in=true || _in=false
            continue
        fi
        if [ "$_in" = true ] && [ "$_i" -eq 2 ]; then
            case "$_s" in
                "$_key":*)
                    echo "$_s" | sed "s/^$_key: *//; s/^\"//; s/\"$//"
                    return
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"
}

_trace_enabled_for_validation() {
    _enabled=$(_read_trace_value enabled)
    case "$_enabled" in
        true|yes|1) return 0 ;;
        *) return 1 ;;
    esac
}

_trace_reject_current_anchor_label() {
    _enabled=$(_read_trace_value reject_current_anchor_label)
    case "$_enabled" in
        true|yes|1) return 0 ;;
        *) return 1 ;;
    esac
}

_infer_trace_since() {
    [ -f "$CONFIG_FILE" ] || return
    _commits=$(cd "$PROJECT_ROOT" && git log --reverse --format=%H -- .dockit-config.yml 2>/dev/null || true)
    [ -n "$_commits" ] || return

    for _commit in $_commits; do
        if cd "$PROJECT_ROOT" && git show "$_commit:.dockit-config.yml" 2>/dev/null | awk '
            /^[[:space:]]*trace_protocol:[[:space:]]*$/ { in_trace = 1; next }
            /^[^[:space:]]/ { in_trace = 0 }
            in_trace && /^[[:space:]]{2}enabled:[[:space:]]*(true|yes|1)[[:space:]]*$/ { found = 1 }
            END { exit found ? 0 : 1 }
        '; then
            cd "$PROJECT_ROOT" && git show -s --format=%cd --date=format:%Y-%m-%d "$_commit"
            return
        fi
    done
}

_detect_trace_upstream_branch() {
    _configured=$(_read_trace_value upstream_branch)
    if [ -n "$_configured" ]; then
        echo "$_configured"
        return
    fi

    _origin_head=$(cd "$PROJECT_ROOT" && git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    if [ -n "$_origin_head" ]; then
        echo "$_origin_head" | sed 's|^origin/||'
    else
        echo "main"
    fi
}

_trace_append_error() {
    _trace_errors="${_trace_errors}; $1"
}

_trace_append_warning() {
    _trace_warnings="${_trace_warnings}; $1"
}

_trace_hashes_from_text() {
    grep -oE '`[0-9A-Fa-f]{7,40}`' 2>/dev/null | tr -d '`' | tr 'A-F' 'a-f' | sort -u || true
}

_trace_validate_commit() {
    _hash="$1"
    _context="$2"
    _text="$3"
    _require_subject_time="$4"
    _upstream_branch="$5"

    if ! git -C "$PROJECT_ROOT" cat-file -e "$_hash^{commit}" 2>/dev/null; then
        _trace_append_error "$_context references commit $_hash, but git cannot resolve it"
        return
    fi

    _short=$(git -C "$PROJECT_ROOT" rev-parse --short=7 "$_hash" 2>/dev/null || true)
    if [ -n "$_short" ] && ! printf '%s\n' "$_text" | grep -qF "$_short"; then
        _trace_append_error "$_context references $_hash but does not contain canonical short hash $_short"
    fi

    if [ "$_require_subject_time" = true ]; then
        _subject=$(git -C "$PROJECT_ROOT" show -s --format=%s "$_hash" 2>/dev/null || true)
        _commit_time_seconds=$(git -C "$PROJECT_ROOT" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M:%S UTC' "$_hash" 2>/dev/null || true)
        _commit_time_minutes=$(git -C "$PROJECT_ROOT" show -s --format=%cd --date=format:'%Y-%m-%d %H:%M UTC' "$_hash" 2>/dev/null || true)
        if [ -n "$_subject" ] && ! printf '%s\n' "$_text" | grep -qF "$_subject"; then
            _trace_append_error "$_context target $_short is missing commit subject: $_subject"
        fi
        if [ -n "$_commit_time_seconds" ] \
            && ! printf '%s\n' "$_text" | grep -qF "$_commit_time_seconds" \
            && ! printf '%s\n' "$_text" | grep -qF "$_commit_time_minutes"; then
            _trace_append_error "$_context target $_short is missing commit time: $_commit_time_seconds (or $_commit_time_minutes)"
        fi
    fi

    _upstream_ref="refs/remotes/origin/$_upstream_branch"
    if git -C "$PROJECT_ROOT" show-ref --verify --quiet "$_upstream_ref" 2>/dev/null; then
        if git -C "$PROJECT_ROOT" merge-base --is-ancestor "$_hash" "$_upstream_ref" 2>/dev/null; then
            return
        fi

        _on_remote=false
        _remote_refs=$(git -C "$PROJECT_ROOT" for-each-ref --format='%(refname)' refs/remotes/origin 2>/dev/null || true)
        for _ref in $_remote_refs; do
            case "$_ref" in */HEAD) continue ;; esac
            if git -C "$PROJECT_ROOT" merge-base --is-ancestor "$_hash" "$_ref" 2>/dev/null; then
                _on_remote=true
                _trace_append_warning "$_context target $_short is on remote ref $_ref, not origin/$_upstream_branch"
                break
            fi
        done

        if [ "$_on_remote" = false ]; then
            _trace_append_error "$_context target $_short is not an ancestor of origin/$_upstream_branch or any origin/* remote ref"
        fi
    fi
}

check_external_context() {
    if ! should_run "external-context"; then return; fi

    # CI portability: skip if env var set
    if [ "${DOCKIT_SKIP_EXTERNAL:-0}" = "1" ]; then
        add_result "external-context" "PASS" "Skipped (DOCKIT_SKIP_EXTERNAL=1)"
        return
    fi

    # No config file -> explicit skip (opt-in feature)
    if [ ! -f "$CONFIG_FILE" ]; then
        add_result "external-context" "PASS" "Skipped (no .dockit-config.yml)"
        return
    fi

    # Read path from config
    _ext_path=$(_read_ext_path)

    # No external_context section -> explicit skip
    if [ -z "$_ext_path" ]; then
        add_result "external-context" "PASS" "Skipped (no external_context in config)"
        return
    fi

    # Normalize path (~ expansion, resolve)
    _expanded=$(echo "$_ext_path" | sed "s|^~|$HOME|")
    _resolved=$(cd "$_expanded" 2>/dev/null && pwd) || {
        add_result "external-context" "FAIL" "External docs path not accessible: $_ext_path"
        return
    }

    # Read file list and validate existence
    _files=$(_read_ext_read_files)
    if [ -z "$_files" ]; then
        add_result "external-context" "FAIL" "external_context.path set but no read: files in $CONFIG_FILE"
        return
    fi

    _missing=""
    _count=0
    _old_ifs="$IFS"
    IFS='
'
    for _f in $_files; do
        [ -z "$_f" ] && continue
        _count=$((_count + 1))
        if [ ! -f "$_resolved/$_f" ]; then
            _missing="$_missing $_f"
        fi
    done
    IFS="$_old_ifs"

    if [ -n "$_missing" ]; then
        add_result "external-context" "FAIL" "Missing files in $_ext_path:$_missing"
    else
        add_result "external-context" "PASS" "All $_count external context files exist at $_ext_path"
    fi
}

check_external_triggers() {
    if ! should_run "external-triggers"; then return; fi

    # CI portability: skip if env var set
    if [ "${DOCKIT_SKIP_EXTERNAL:-0}" = "1" ]; then
        add_result "external-triggers" "PASS" "Skipped (DOCKIT_SKIP_EXTERNAL=1)"
        return
    fi

    # No config file -> explicit skip
    if [ ! -f "$CONFIG_FILE" ]; then
        add_result "external-triggers" "PASS" "Skipped (no .dockit-config.yml)"
        return
    fi

    # Read triggers from config
    _triggers=$(_read_ext_triggers)
    if [ -z "$_triggers" ]; then
        add_result "external-triggers" "PASS" "No update_triggers defined"
        return
    fi

    # Get changed files: staged + unstaged working tree
    _changed=$(cd "$PROJECT_ROOT" && {
        git diff --name-only HEAD 2>/dev/null
        git diff --cached --name-only 2>/dev/null
    } | sort -u) || true

    if [ -z "$_changed" ]; then
        add_result "external-triggers" "PASS" "No local changes to match against triggers"
        return
    fi

    # Match changed files against trigger globs
    _matched=""
    _old_ifs="$IFS"
    IFS='
'
    for _trigger in $_triggers; do
        _glob=$(echo "$_trigger" | cut -d'|' -f1)
        _target=$(echo "$_trigger" | cut -d'|' -f2)
        for _file in $_changed; do
            [ -z "$_file" ] && continue
            # POSIX glob matching via case
            eval "case \"\$_file\" in $_glob) _matched=\"\$_matched \$_file->$_target\" ;; esac"
        done
    done
    IFS="$_old_ifs"

    if [ -n "$_matched" ]; then
        add_result "external-triggers" "WARN" "Local changes may require external doc updates:$_matched"
    else
        add_result "external-triggers" "PASS" "No trigger matches in changed files"
    fi
}

# ── Check: orientation (DF-034) ──────────────────────────────────────────────
# Asserts HANDOFF.md declares the next concrete step in a recognisable section
# that names at least one in-repo file path, and that each named path exists.
# Accepted section headings (operator-configurable): "Open work", "Next concrete
# step", "Next Steps". Paths are detected as backtick-quoted markdown spans
# matching common source extensions; cross-repo absolute paths (~/, /) are
# excluded from the existence check.

check_orientation() {
    if ! should_run "orientation"; then return; fi

    if [ ! -f "$HANDOFF" ]; then
        add_result "orientation" "FAIL" "HANDOFF.md not found at $HANDOFF"
        return
    fi

    section_start=$(grep -nE '^##[[:space:]]+(Open [Ww]ork|Next concrete step|Next [Ss]teps)' "$HANDOFF" | head -1 | cut -d: -f1)
    if [ -z "$section_start" ]; then
        add_result "orientation" "FAIL" "No 'Open work' section found in HANDOFF.md (accepted headings: 'Open work', 'Next concrete step', 'Next Steps')"
        return
    fi

    section_end=$(awk -v start="$section_start" 'NR>start && /^## / {print NR-1; exit}' "$HANDOFF")
    if [ -z "$section_end" ]; then
        section_end=$(wc -l < "$HANDOFF")
    fi

    paths=$(sed -n "${section_start},${section_end}p" "$HANDOFF" \
        | grep -oE '`[^`]+\.(md|sh|yml|yaml|json|txt|py|js|ts|toml)`' \
        | sed 's/`//g' \
        | grep -vE '^(/|~)' \
        | grep -vE '[*?[]' \
        | sort -u)

    if [ -z "$paths" ]; then
        add_result "orientation" "FAIL" "Open work section names no in-repo file paths (expected backtick-quoted paths like \`scripts/foo.sh\`)"
        return
    fi

    missing=""
    count=0
    for p in $paths; do
        count=$((count + 1))
        if [ ! -e "$PROJECT_ROOT/$p" ]; then
            missing="$missing $p"
        fi
    done

    if [ -n "$missing" ]; then
        add_result "orientation" "FAIL" "Open work names $count path(s); missing in repo:$missing"
    else
        add_result "orientation" "PASS" "Open work names $count file path(s), all present in repo"
    fi
}

# ── Check: orientation-drift (DF-047) ───────────────────────────────────────
# Optional semantic guard for projects with a phase-based roadmap. It catches
# the recurrent MED failure where entry docs still say "next phase X" after
# ROADMAP marks Phase X complete. Disabled unless .dockit-config.yml opts in.

_read_orientation_drift_value() {
    _key="$1"
    [ -f "$CONFIG_FILE" ] || return
    _in=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "orientation_drift:" ] && _in=true || _in=false
            continue
        fi
        if [ "$_in" = true ] && [ "$_i" -eq 2 ]; then
            case "$_s" in
                "$_key":*)
                    echo "$_s" | sed "s/^$_key: *//; s/^\"//; s/\"$//; s/^'//; s/'$//"
                    return
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"
}

_read_orientation_drift_docs() {
    [ -f "$CONFIG_FILE" ] || return
    _in=false
    _in_docs=false
    while IFS= read -r _line || [ -n "$_line" ]; do
        case "$_line" in ""|\#*) continue ;; esac
        _s=$(echo "$_line" | sed 's/^ *//')
        _i=$(( ${#_line} - ${#_s} ))
        if [ "$_i" -eq 0 ]; then
            [ "$_s" = "orientation_drift:" ] && _in=true || _in=false
            _in_docs=false
            continue
        fi
        [ "$_in" = true ] || continue
        if [ "$_i" -eq 2 ]; then
            [ "$_s" = "docs:" ] && _in_docs=true || _in_docs=false
            continue
        fi
        if [ "$_in_docs" = true ] && [ "$_i" -eq 4 ]; then
            case "$_s" in
                -*)
                    echo "$_s" | sed 's/^- *//; s/^"//; s/"$//; s/^'\''//; s/'\''$//'
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"
}

_orientation_drift_enabled() {
    _enabled=$(_read_orientation_drift_value enabled)
    case "$_enabled" in
        true|yes|1) return 0 ;;
        *) return 1 ;;
    esac
}

_escape_phase_regex() {
    printf '%s' "$1" | sed 's/[][\\.^$*+?{}|()]/\\&/g'
}

check_orientation_drift() {
    if ! should_run "orientation-drift"; then return; fi

    if [ ! -f "$CONFIG_FILE" ]; then
        add_result "orientation-drift" "PASS" "Skipped (no .dockit-config.yml; enable with orientation_drift.enabled: true)"
        return
    fi

    if ! _orientation_drift_enabled; then
        add_result "orientation-drift" "PASS" "Skipped (orientation_drift.enabled is not true)"
        return
    fi

    _roadmap=$(_read_orientation_drift_value roadmap)
    [ -n "$_roadmap" ] || _roadmap="docs/ROADMAP.md"
    _roadmap_path="$PROJECT_ROOT/$_roadmap"
    if [ ! -f "$_roadmap_path" ]; then
        add_result "orientation-drift" "FAIL" "orientation_drift roadmap not found: $_roadmap"
        return
    fi

    _docs=$(_read_orientation_drift_docs | tr '\n' ' ')
    _docs_configured=true
    if [ -z "$_docs" ]; then
        _docs_configured=false
        _docs="LLM_START_HERE.md README.md docs/PROJECT_CONTEXT.md docs/ARCHITECTURE.md docs/llm/HANDOFF.md"
    fi

    _completed=$(awk '
        /^##[[:space:]]+Phase[[:space:]]+/ {
            current = $0
            sub(/^##[[:space:]]+Phase[[:space:]]+/, "", current)
            sub(/[[:space:]].*$/, "", current)
            next
        }
        /^Status:[[:space:]]*complete([[:space:]]|$)/ {
            if (current != "") print current
            current = ""
            next
        }
        /^Status:/ { current = "" }
    ' "$_roadmap_path")

    if [ -z "$_completed" ]; then
        add_result "orientation-drift" "FAIL" "No completed phases parsed from $_roadmap (expected '## Phase N' followed by 'Status: complete')"
        return
    fi

    _issues=""
    _checked=0
    _missing=""
    for _doc in $_docs; do
        _doc_path="$PROJECT_ROOT/$_doc"
        if [ ! -f "$_doc_path" ]; then
            if [ "$_docs_configured" = true ]; then
                _missing="$_missing $_doc"
            fi
            continue
        fi
        _checked=$((_checked + 1))
        for _phase in $_completed; do
            _esc=$(_escape_phase_regex "$_phase")
            _hits=$(grep -inE "next[^.]*phase ${_esc}([^0-9A-Za-z.]|$)" "$_doc_path" 2>/dev/null || true)
            if [ -n "$_hits" ]; then
                _issues="$_issues; $_doc claims completed Phase $_phase is next"
            fi
        done
    done

    if [ -n "$_missing" ]; then
        add_result "orientation-drift" "FAIL" "orientation_drift configured doc(s) not found:$_missing"
    elif [ "$_checked" -eq 0 ]; then
        add_result "orientation-drift" "FAIL" "orientation_drift has no existing docs to check"
    elif [ -n "$_issues" ]; then
        _msg=$(echo "$_issues" | sed 's/^; //')
        add_result "orientation-drift" "FAIL" "$_msg"
    else
        add_result "orientation-drift" "PASS" "No completed roadmap phase is described as next in $_checked doc(s)"
    fi
}

# ── Check: template-residue (DF-035 option (a)) ──────────────────────────────
# Greps canonical scaffold-shipped docs for known author-voice / template
# placeholder patterns that survive `dockit-init-project.sh` and poison
# fresh-session orientation. Skips on the LLM-DocKit source repo itself
# (templates contain placeholders by design — `dockit-sync-manifest.yml` is
# the source-repo marker, stripped from downstream by `dockit-init-project.sh`).
# DECISIONS.md emptiness is reported as WARN once the repo crosses a configurable
# commit threshold (DOCKIT_DECISIONS_EMPTY_THRESHOLD_COMMITS, default 5).

check_template_residue() {
    if ! should_run "template-residue"; then return; fi

    if [ -f "$PROJECT_ROOT/dockit-sync-manifest.yml" ]; then
        add_result "template-residue" "PASS" "Skipped (LLM-DocKit source repo; templates carry placeholders by design)"
        return
    fi

    _issues=""

    _f="$PROJECT_ROOT/LLM_START_HERE.md"
    if [ -f "$_f" ]; then
        for _pat in 'Replace angle-bracket placeholders' 'Customization Notes for Maintainers'; do
            if grep -qF "$_pat" "$_f"; then
                _issues="$_issues; LLM_START_HERE.md: '$_pat'"
            fi
        done
        if grep -qE 'Replace [A-Za-z0-9_-]+ with the actual project name' "$_f"; then
            _issues="$_issues; LLM_START_HERE.md: 'Replace <project> with the actual project name' (scaffold author voice)"
        fi
    fi

    _f="$PROJECT_ROOT/docs/STRUCTURE.md"
    if [ -f "$_f" ]; then
        for _pat in 'Use this template to document' '<PROJECT_ROOT>'; do
            if grep -qF "$_pat" "$_f"; then
                _issues="$_issues; STRUCTURE.md: '$_pat'"
            fi
        done
    fi

    _f="$PROJECT_ROOT/docs/ARCHITECTURE.md"
    if [ -f "$_f" ]; then
        for _pat in '<Names>' '<Invariant' '<Step>' '<Phase 0>' 'Authors: <Names>'; do
            if grep -qF "$_pat" "$_f"; then
                _issues="$_issues; ARCHITECTURE.md: '$_pat'"
            fi
        done
    fi

    _warn=""
    _f="$PROJECT_ROOT/docs/llm/DECISIONS.md"
    if [ -f "$_f" ]; then
        if ! grep -qE '^## D-[0-9]{3}' "$_f"; then
            _threshold="${DOCKIT_DECISIONS_EMPTY_THRESHOLD_COMMITS:-5}"
            _commits=$(cd "$PROJECT_ROOT" && git rev-list --count HEAD 2>/dev/null || echo 0)
            if [ "$_commits" -ge "$_threshold" ]; then
                _warn="DECISIONS.md has no D-NNN entry after $_commits commits (threshold: $_threshold). Extract durable decisions from HANDOFF inline accumulation."
            fi
        fi
    fi

    if [ -n "$_issues" ]; then
        _msg=$(echo "$_issues" | sed 's/^; //')
        add_result "template-residue" "FAIL" "Template residue: $_msg"
    elif [ -n "$_warn" ]; then
        add_result "template-residue" "WARN" "$_warn"
    else
        add_result "template-residue" "PASS" "No template residue in canonical scaffold-shipped docs"
    fi
}

# ── Check: trace-protocol (DF-040) ──────────────────────────────────────────
# Enforces the durable half of the Trace Protocol when a project opts into it
# with .dockit-config.yml trace_protocol.enabled: true. The chat-message Trace
# header is a SessionStart/onboarding convention and cannot be validated here.
#
# Durable v1 contract:
#   - HANDOFF.md contains a "## Trace Anchor" section with role, target, state,
#     validation, and next-gate fields.
#   - If the anchor references commit hashes in backticks, the hashes resolve,
#     canonical short hash / subject / commit time appear in the anchor, and
#     remote ancestry is checked when origin refs are available.
#   - HISTORY.md entries dated >= trace_protocol.since that reference backticked
#     hashes include an inline Trace footer:
#       Trace: role=executor|auditor|advisor; commits=...; state=...; validation=...; next=...

check_trace_protocol() {
    if ! should_run "trace-protocol"; then return; fi

    if [ ! -f "$CONFIG_FILE" ]; then
        add_result "trace-protocol" "PASS" "Skipped (no .dockit-config.yml; durable Trace enforcement activates via trace_protocol.enabled: true)"
        return
    fi

    if ! _trace_enabled_for_validation; then
        add_result "trace-protocol" "PASS" "Skipped (trace_protocol.enabled is not true)"
        return
    fi

    _trace_errors=""
    _trace_warnings=""
    _trace_since=$(_read_trace_value since)
    if [ -z "$_trace_since" ]; then
        _trace_since=$(_infer_trace_since)
    fi
    if ! printf '%s\n' "$_trace_since" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        add_result "trace-protocol" "FAIL" "trace_protocol.enabled=true requires trace_protocol.since: YYYY-MM-DD (or a committed activation date that can be inferred)"
        return
    fi

    _trace_upstream=$(_detect_trace_upstream_branch)

    if [ ! -f "$HANDOFF" ]; then
        _trace_append_error "HANDOFF.md not found"
    else
        _anchor=$(awk '
            /^##[[:space:]]+Trace Anchor[[:space:]]*$/ { capture = 1; next }
            capture && /^##[[:space:]]+/ { exit }
            capture { print }
        ' "$HANDOFF")

        if [ -z "$_anchor" ]; then
            _trace_append_error "HANDOFF.md is missing required ## Trace Anchor section"
        else
            if ! printf '%s\n' "$_anchor" | grep -qE 'Role:[[:space:]]*(executor|auditor|advisor)'; then
                _trace_append_error "Trace Anchor missing Role: executor|auditor|advisor"
            fi
            if ! printf '%s\n' "$_anchor" | grep -qE '(Current target|Current audit target|Trace target|Subject):'; then
                _trace_append_error "Trace Anchor missing Trace target/Subject"
            fi
            if ! printf '%s\n' "$_anchor" | grep -qE '(State verified|Repo state):'; then
                _trace_append_error "Trace Anchor missing State verified/Repo state"
            fi
            if ! printf '%s\n' "$_anchor" | grep -qE 'Validation:'; then
                _trace_append_error "Trace Anchor missing Validation"
            fi
            if ! printf '%s\n' "$_anchor" | grep -qE '(Next gate|Next):'; then
                _trace_append_error "Trace Anchor missing Next gate/Next"
            fi

            _anchor_hashes=$(printf '%s\n' "$_anchor" | _trace_hashes_from_text)
            for _hash in $_anchor_hashes; do
                _trace_validate_commit "$_hash" "HANDOFF Trace Anchor" "$_anchor" true "$_trace_upstream"
            done

            if _trace_reject_current_anchor_label \
                && printf '%s\n' "$_anchor" | grep -qE '(Current target|Current audit target):'; then
                _trace_append_error "trace_protocol.reject_current_anchor_label=true disallows HANDOFF Trace Anchor labels that imply currency; use Subject: or Trace target: instead"
            fi
        fi
    fi

    if [ ! -f "$HISTORY" ]; then
        _trace_append_error "HISTORY.md not found"
    else
        _history_entries=$(awk -v since="$_trace_since" '
            /^- [0-9]{4}-[0-9]{2}-[0-9]{2} - / {
                d = substr($0, 3, 10)
                if (d >= since) print d "|" $0
                next
            }
            /^[0-9]{4}-[0-9]{2}-[0-9]{2} - / {
                d = substr($0, 1, 10)
                if (d >= since) print d "|" $0
            }
        ' "$HISTORY")

        _old_ifs="$IFS"
        IFS='
'
        for _history_record in $_history_entries; do
            _date=$(printf '%s\n' "$_history_record" | cut -d'|' -f1)
            _entry=$(printf '%s\n' "$_history_record" | cut -d'|' -f2-)
            _entry_hashes=$(printf '%s\n' "$_entry" | _trace_hashes_from_text)
            [ -z "$_entry_hashes" ] && continue

            if ! printf '%s\n' "$_entry" | grep -qE 'Trace: role=(executor|auditor|advisor); commits=[^;]+; state=[^;]+; validation=[^;]+; next=.+'; then
                _trace_append_error "HISTORY entry $_date references backticked commit hash(es) but lacks inline Trace footer"
                continue
            fi

            _commits_field=$(printf '%s\n' "$_entry" | sed 's/.*Trace: role=[^;]*; commits=\([^;]*\); state=.*/\1/')
            _commits_csv=",$(printf '%s' "$_commits_field" | tr -d ' '),"
            for _hash in $_entry_hashes; do
                _short=$(cd "$PROJECT_ROOT" && git rev-parse --short=7 "$_hash" 2>/dev/null || printf '%s' "$_hash")
                case "$_commits_csv" in
                    *,"$_hash",*|*,"$_short",*) ;;
                    *) _trace_append_error "HISTORY Trace footer commits= does not include referenced hash $_hash" ;;
                esac
                _trace_validate_commit "$_hash" "HISTORY Trace footer" "$_entry" false "$_trace_upstream"
            done
        done
        IFS="$_old_ifs"
    fi

    if [ -n "$_trace_errors" ]; then
        _msg=$(echo "$_trace_errors" | sed 's/^; //')
        add_result "trace-protocol" "FAIL" "$_msg"
    elif [ -n "$_trace_warnings" ]; then
        _msg=$(echo "$_trace_warnings" | sed 's/^; //')
        add_result "trace-protocol" "WARN" "$_msg"
    else
        add_result "trace-protocol" "PASS" "Trace Protocol durable contract satisfied since $_trace_since"
    fi
}

# ── Run all checks ──────────────────────────────────────────────────────────

check_handoff_date
check_history_entry
check_decisions_referenced
check_version_sync
check_external_context
check_external_triggers
check_orientation
check_orientation_drift
check_template_residue
check_trace_protocol

# ── Output ───────────────────────────────────────────────────────────────────

if [ "$CHECKS_RUN" -eq 0 ]; then
    echo "ERROR: no checks were run (check --check arguments)" >&2
    exit 2
fi

OK_VALUE="true"
if [ "$ERRORS" -gt 0 ]; then
    OK_VALUE="false"
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

if [ "$OUTPUT_MODE" = "json" ]; then
    printf '{"ok":%s,"warnings":%d,"timestamp":"%s","checks":[%s]}\n' "$OK_VALUE" "$WARNINGS" "$TIMESTAMP" "$RESULTS"
else
    # Human-readable output
    echo "=== Documentation Validation ==="
    echo "Date: $TODAY"
    echo ""

    # Parse results for human display
    if [ "$ERRORS" -gt 0 ]; then
        echo "RESULT: FAIL ($ERRORS error(s), $WARNINGS warning(s) in $CHECKS_RUN check(s))"
    elif [ "$WARNINGS" -gt 0 ]; then
        echo "RESULT: PASS with $WARNINGS warning(s) ($CHECKS_RUN check(s))"
    else
        echo "RESULT: PASS ($CHECKS_RUN check(s) passed)"
    fi
    echo ""

    # Print each result from JSON (simple approach: re-extract from accumulated data)
    echo "$RESULTS" | sed 's/},{/}\n{/g' | while IFS= read -r entry; do
        name=$(printf '%s' "$entry" | sed 's/.*"name":"\([^"]*\)".*/\1/')
        status=$(printf '%s' "$entry" | sed 's/.*"status":"\([^"]*\)".*/\1/')
        message=$(printf '%s' "$entry" | sed 's/.*"message":"\([^"]*\)".*/\1/' | sed 's/\\"/"/g')

        printf '  [%s] %s: %s\n' "$status" "$name" "$message"
    done
fi

# ── Exit code ────────────────────────────────────────────────────────────────

if [ "$ERRORS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
