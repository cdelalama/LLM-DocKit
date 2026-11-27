#!/bin/sh
# dockit-sync-check.sh -- Check which downstream projects need syncing.
# Scans for .dockit-enabled projects and reports their sync status.
#
# Usage: scripts/dockit-sync-check.sh [--src-root PATH]
#
# States:
#   CURRENT   -- template_version matches LLM-DocKit VERSION
#   OUTDATED  -- template_version differs (string compare, not SemVer)
#   NO_STATE  -- has .dockit-enabled but no state.yml in its Git directory
#   (partial) -- detail suffix when adoption_mode=partial in .dockit-config.yml
#
# Exit 0 if all CURRENT, exit 1 if any OUTDATED or NO_STATE.
#
# This script runs ONLY from LLM-DocKit root. It is NOT copied to downstream.

set -e
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE \
    GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE

# ============================================================================
# Init
# ============================================================================

DOCKIT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC_ROOT="$HOME/src"

# Parse args
while [ $# -gt 0 ]; do
    case "$1" in
        --src-root)
            shift
            SRC_ROOT="$1"
            ;;
        -h|--help)
            tail -n +2 "$0" | head -14 | grep '^#' | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# Validate
if [ ! -f "$DOCKIT_ROOT/VERSION" ]; then
    echo "ERROR: VERSION file not found. Are you running from LLM-DocKit root?" >&2
    exit 1
fi

TEMPLATE_VERSION=$(head -1 "$DOCKIT_ROOT/VERSION" | tr -d '[:space:]')

echo "LLM-DocKit Sync Check"
echo "Template version: $TEMPLATE_VERSION"
echo "Scanning: $SRC_ROOT"
echo ""

# ============================================================================
# Scan projects
# ============================================================================

HAS_PROBLEMS=false
PROJECT_COUNT=0

printf "  %-30s %-12s %s\n" "PROJECT" "STATUS" "DETAILS"
printf "  %-30s %-12s %s\n" "-------" "------" "-------"

for _dir in "$SRC_ROOT"/*/; do
    [ -d "$_dir" ] || continue
    [ -f "$_dir/.dockit-enabled" ] || continue
    _git_dir=$(git -C "$_dir" rev-parse --absolute-git-dir 2>/dev/null) || continue
    [ -d "$_git_dir" ] || continue
    _actual_root=$(git -C "$_dir" rev-parse --show-toplevel 2>/dev/null) || continue
    _requested_root=$(cd "$_dir" && pwd -P) || continue
    [ "$_actual_root" = "$_requested_root" ] || continue
    [ -e "$_requested_root/.git" ] || continue

    PROJECT_COUNT=$((PROJECT_COUNT + 1))
    _name=$(basename "$_dir")
    _state_file="$_git_dir/.dockit/state.yml"

    # Read adoption_mode for (partial) detail
    _adoption_detail=""
    _config_file="$_dir/.dockit-config.yml"
    if [ -f "$_config_file" ]; then
        _amode=$(grep '^adoption_mode:' "$_config_file" 2>/dev/null | head -1 | \
            sed 's/^adoption_mode:[[:space:]]*//' | tr -d '[:space:]')
        if [ "$_amode" = "partial" ]; then
            _adoption_detail=" (partial)"
        fi
    fi

    # Determine status
    if [ ! -f "$_state_file" ]; then
        _common_git_dir=$(git -C "$_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || _common_git_dir=""
        if [ -n "$_common_git_dir" ] && [ "$_common_git_dir" != "$_git_dir" ]; then
            _next="review custody; --init-state --untracked-existing-adoption"
        else
            _next="run --init-state"
        fi
        printf "  %-30s %-12s %s\n" "$_name" "NO_STATE" "$_next"
        HAS_PROBLEMS=true
        continue
    fi

    # Read template_version from state
    _project_version=$(grep '^template_version:' "$_state_file" 2>/dev/null | head -1 | \
        sed 's/^template_version:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d '[:space:]')

    if [ "$_project_version" = "$TEMPLATE_VERSION" ]; then
        printf "  %-30s %-12s %s\n" "$_name" "CURRENT${_adoption_detail}" "v$_project_version"
    else
        printf "  %-30s %-12s %s\n" "$_name" "OUTDATED${_adoption_detail}" "v$_project_version -> v$TEMPLATE_VERSION"
        HAS_PROBLEMS=true
    fi
done

# ============================================================================
# Summary
# ============================================================================

echo ""
if [ "$PROJECT_COUNT" -eq 0 ]; then
    echo "No .dockit-enabled projects found in $SRC_ROOT"
    exit 0
fi

echo "Checked $PROJECT_COUNT project(s)."

if $HAS_PROBLEMS; then
    echo "Some projects need attention. Run: scripts/dockit-sync.sh --dry-run --project PATH"
    exit 1
else
    echo "All projects up to date."
    exit 0
fi
