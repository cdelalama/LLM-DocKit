#!/bin/sh
# dockit-generate-external-context.sh -- Generate External Context section
# for LLM_START_HERE.md from .dockit-config.yml.
#
# Portable POSIX sh. Zero external dependencies.
#
# Usage:
#   scripts/dockit-generate-external-context.sh                     # dry-run (default)
#   scripts/dockit-generate-external-context.sh --apply             # replace markers in LLM_START_HERE.md
#   scripts/dockit-generate-external-context.sh --claude-rules      # generate .claude/rules/ trigger file
#   scripts/dockit-generate-external-context.sh --project /path     # custom project root
#
# Exit codes:
#   0 -- success
#   1 -- validation error (missing path, missing files)
#   2 -- script error (bad arguments, missing markers, missing config)

set -e

# ── Defaults ──────────────────────────────────────────────────────────────────

PROJECT_ROOT=""
MODE="dry-run"
CLAUDE_RULES=false

# ── Parse arguments ──────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            MODE="dry-run"
            shift
            ;;
        --apply)
            MODE="apply"
            shift
            ;;
        --claude-rules)
            CLAUDE_RULES=true
            shift
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
            echo "Usage: $0 [--dry-run|--apply] [--claude-rules] [--project PATH]"
            echo ""
            echo "Generates External Context section for LLM_START_HERE.md"
            echo "from .dockit-config.yml external_context configuration."
            echo ""
            echo "Modes:"
            echo "  --dry-run       Print generated markdown to stdout (default)"
            echo "  --apply         Replace content between markers in LLM_START_HERE.md"
            echo "  --claude-rules  Generate .claude/rules/external-context-triggers.md"
            echo ""
            echo "Exit codes: 0=success, 1=validation error, 2=script error"
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

CONFIG_FILE="$PROJECT_ROOT/.dockit-config.yml"
LLM_FILE="$PROJECT_ROOT/LLM_START_HERE.md"
START_MARKER="<!-- DOCKIT-EXTERNAL-CONTEXT:START -->"
END_MARKER="<!-- DOCKIT-EXTERNAL-CONTEXT:END -->"

# ── Helpers ──────────────────────────────────────────────────────────────────

die() {
    echo "ERROR: $1" >&2
    exit 2
}

# ── Parse .dockit-config.yml external_context section ────────────────────────
# State-machine parser. Tracks indentation to enter/exit sections.
# Produces: EXT_PATH, EXT_READ_FILES (newline-separated), EXT_TRIGGERS (pairs)

parse_external_context() {
    if [ ! -f "$CONFIG_FILE" ]; then
        die "Config file not found: $CONFIG_FILE"
    fi

    EXT_PATH=""
    EXT_READ_FILES=""
    EXT_TRIGGERS=""

    _in_ext=false
    _in_read=false
    _in_triggers=false

    while IFS= read -r _line || [ -n "$_line" ]; do
        # Skip blank lines and comments
        case "$_line" in
            ""|\#*) continue ;;
        esac

        # Detect indentation level (count leading spaces)
        _stripped=$(echo "$_line" | sed 's/^ *//')
        _indent=$(( ${#_line} - ${#_stripped} ))

        # Top-level key (0 indent) -- enter or exit external_context
        if [ "$_indent" -eq 0 ]; then
            if [ "$_stripped" = "external_context:" ]; then
                _in_ext=true
                _in_read=false
                _in_triggers=false
            else
                _in_ext=false
                _in_read=false
                _in_triggers=false
            fi
            continue
        fi

        # Only process lines inside external_context
        if [ "$_in_ext" = false ]; then
            continue
        fi

        # 2-space indent: section keys within external_context
        if [ "$_indent" -eq 2 ]; then
            _in_read=false
            _in_triggers=false

            case "$_stripped" in
                path:*)
                    # Extract value after "path: "
                    EXT_PATH=$(echo "$_stripped" | sed 's/^path: *//')
                    ;;
                read:)
                    _in_read=true
                    ;;
                update_triggers:)
                    _in_triggers=true
                    ;;
            esac
            continue
        fi

        # 4-space indent: list items
        if [ "$_indent" -eq 4 ]; then
            if [ "$_in_read" = true ]; then
                # Strip "- " prefix
                _item=$(echo "$_stripped" | sed 's/^- *//')
                if [ -n "$_item" ]; then
                    if [ -n "$EXT_READ_FILES" ]; then
                        EXT_READ_FILES="$EXT_READ_FILES
$_item"
                    else
                        EXT_READ_FILES="$_item"
                    fi
                fi
            elif [ "$_in_triggers" = true ]; then
                # Parse: - local: <glob>  target: <filename>
                _trigger_line=$(echo "$_stripped" | sed 's/^- *//')
                _local=$(echo "$_trigger_line" | sed 's/^local: *//; s/ *target:.*$//')
                _target=$(echo "$_trigger_line" | sed 's/.*target: *//')
                if [ -n "$_local" ] && [ -n "$_target" ]; then
                    if [ -n "$EXT_TRIGGERS" ]; then
                        EXT_TRIGGERS="$EXT_TRIGGERS
$_local|$_target"
                    else
                        EXT_TRIGGERS="$_local|$_target"
                    fi
                fi
            fi
            continue
        fi

    done < "$CONFIG_FILE"
}

# ── Normalize and validate path ──────────────────────────────────────────────

normalize_path() {
    _raw="$1"
    # Expand ~ to $HOME
    _expanded=$(echo "$_raw" | sed "s|^~|$HOME|")
    # Resolve to canonical absolute path
    _resolved=$(cd "$_expanded" 2>/dev/null && pwd) || {
        echo "ERROR: External docs path not accessible: $_raw" >&2
        exit 1
    }
    echo "$_resolved"
}

# ── Validate read files exist ────────────────────────────────────────────────

validate_read_files() {
    _base_path="$1"
    _files="$2"
    _missing=""

    echo "$_files" | while IFS= read -r _f; do
        [ -z "$_f" ] && continue
        if [ ! -f "$_base_path/$_f" ]; then
            echo "$_f"
        fi
    done
}

# ── Generate markdown content ────────────────────────────────────────────────

generate_markdown() {
    _display_path="$1"
    _read_files="$2"
    _triggers="$3"

    echo "### External Context"
    echo ""
    echo "**Source:** $_display_path"
    echo ""
    echo "**Read these files at the start of every session:**"

    _n=1
    echo "$_read_files" | while IFS= read -r _f; do
        [ -z "$_f" ] && continue
        echo "$_n. $_f"
        _n=$((_n + 1))
    done

    if [ -n "$_triggers" ]; then
        echo ""
        echo "**Update triggers** -- when you modify files matching these patterns, update the corresponding external doc:"
        echo "| Local file pattern | External doc to update |"
        echo "|--------------------|------------------------|"
        echo "$_triggers" | while IFS='|' read -r _local _target; do
            [ -z "$_local" ] && continue
            echo "| $_local | $_target |"
        done
    fi
}

# ── Apply: replace content between markers ───────────────────────────────────

apply_to_file() {
    _content_file="$1"

    if [ ! -f "$LLM_FILE" ]; then
        die "LLM_START_HERE.md not found at $LLM_FILE"
    fi

    # Check markers exist (exactly once each)
    _start_count=$(grep -c "^${START_MARKER}$" "$LLM_FILE" 2>/dev/null) || true
    _end_count=$(grep -c "^${END_MARKER}$" "$LLM_FILE" 2>/dev/null) || true

    if [ "$_start_count" -eq 0 ] || [ "$_end_count" -eq 0 ]; then
        die "Missing DOCKIT-EXTERNAL-CONTEXT markers in $LLM_FILE. Add them manually first."
    fi
    if [ "$_start_count" -gt 1 ] || [ "$_end_count" -gt 1 ]; then
        die "Duplicate DOCKIT-EXTERNAL-CONTEXT markers in $LLM_FILE."
    fi

    # Replace content between markers (idempotent)
    _replaced=$(mktemp)
    awk -v start="$START_MARKER" -v end="$END_MARKER" -v tfile="$_content_file" '
        $0 == start { print; while ((getline l < tfile) > 0) print l; close(tfile); skip=1; next }
        $0 == end   { skip=0; print; next }
        !skip { print }
    ' "$LLM_FILE" > "$_replaced"

    cp "$_replaced" "$LLM_FILE"
    rm -f "$_replaced"
}

# ── Generate Claude rules file ───────────────────────────────────────────────

generate_claude_rules() {
    _triggers="$1"
    _rules_dir="$PROJECT_ROOT/.claude/rules"
    _rules_file="$_rules_dir/external-context-triggers.md"

    if [ -z "$_triggers" ]; then
        echo "No update_triggers defined -- skipping --claude-rules generation." >&2
        return
    fi

    # Build globs list for frontmatter
    _globs=""
    echo "$_triggers" | while IFS='|' read -r _local _target; do
        [ -z "$_local" ] && continue
        echo "  - \"$_local\""
    done > /tmp/_dockit_globs.tmp
    _globs=$(cat /tmp/_dockit_globs.tmp)
    rm -f /tmp/_dockit_globs.tmp

    mkdir -p "$_rules_dir"

    cat > "$_rules_file" << RULEEOF
---
globs:
$_globs
---
When modifying these files, check .dockit-config.yml external_context.update_triggers
for external docs that may need updating.
Run: scripts/dockit-validate-session.sh --check external-triggers --human
RULEEOF

    echo "OK: Claude rules written to $_rules_file"
}

# ── Main ─────────────────────────────────────────────────────────────────────

parse_external_context

# No external_context section found
if [ -z "$EXT_PATH" ]; then
    echo "No external_context section found in $CONFIG_FILE. Nothing to generate." >&2
    exit 0
fi

if [ -z "$EXT_READ_FILES" ]; then
    die "external_context.path is set but no read: files specified in $CONFIG_FILE"
fi

# Normalize and validate path
RESOLVED_PATH=$(normalize_path "$EXT_PATH")

# Validate read files exist
_missing=$(validate_read_files "$RESOLVED_PATH" "$EXT_READ_FILES")
if [ -n "$_missing" ]; then
    echo "ERROR: Missing files in $EXT_PATH:" >&2
    echo "$_missing" | while IFS= read -r _m; do
        [ -z "$_m" ] && continue
        echo "  - $_m" >&2
    done
    exit 1
fi

# Generate markdown
_tmpfile=$(mktemp)
generate_markdown "$EXT_PATH" "$EXT_READ_FILES" "$EXT_TRIGGERS" > "$_tmpfile"

if [ "$MODE" = "dry-run" ]; then
    echo "$START_MARKER"
    cat "$_tmpfile"
    echo "$END_MARKER"
    rm -f "$_tmpfile"
elif [ "$MODE" = "apply" ]; then
    apply_to_file "$_tmpfile"
    rm -f "$_tmpfile"
    echo "OK: External context section applied to $LLM_FILE"
fi

# Generate Claude rules if requested (independent of mode)
if [ "$CLAUDE_RULES" = true ]; then
    generate_claude_rules "$EXT_TRIGGERS"
fi

exit 0
