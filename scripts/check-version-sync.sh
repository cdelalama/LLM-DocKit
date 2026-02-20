#!/bin/sh
# check-version-sync.sh -- Validate all version-synced files match VERSION.
# Reads docs/version-sync-manifest.yml for the list of tracked files.
# Exit 0 if all in sync. Exit 1 with details if drift detected.
#
# Usage:
#   scripts/check-version-sync.sh           # check all targets
#   scripts/check-version-sync.sh --staged  # check only git-staged targets

set -e

MANIFEST="docs/version-sync-manifest.yml"
VERSION_FILE="VERSION"
STAGED_ONLY=false

if [ "$1" = "--staged" ]; then
    STAGED_ONLY=true
fi

# Verify prerequisites
if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: $VERSION_FILE not found" >&2
    exit 1
fi
if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: $MANIFEST not found" >&2
    exit 1
fi

EXPECTED=$(head -1 "$VERSION_FILE" | tr -d '[:space:]')
ERRORS=0
CHECKED=0

# Get staged files list if in staged mode
STAGED_LIST=""
if [ "$STAGED_ONLY" = true ]; then
    STAGED_LIST=$(git diff --cached --name-only 2>/dev/null || echo "")
fi

# Parse manifest targets to temp file (avoids subshell variable scoping)
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
grep '^- path:' "$MANIFEST" | sed 's/^- path: *\([^ ]*\) *marker: *\([^ ]*\).*/\1 \2/' > "$TMPFILE"

# Validate each target
while read -r filepath markertype; do
    # Skip if file doesn't exist
    if [ ! -f "$filepath" ]; then
        echo "WARN: $filepath not found, skipping"
        continue
    fi

    # In staged mode, skip files not in the staging area
    if [ "$STAGED_ONLY" = true ]; then
        if ! echo "$STAGED_LIST" | grep -q "^${filepath}$"; then
            continue
        fi
    fi

    case "$markertype" in
        version-file)
            FOUND=$(head -1 "$filepath" | tr -d '[:space:]')
            if [ "$FOUND" != "$EXPECTED" ]; then
                echo "DRIFT: $filepath has '$FOUND', expected '$EXPECTED'"
                ERRORS=$((ERRORS + 1))
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        html-comment)
            FOUND=$(grep -o '<!-- doc-version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* -->' "$filepath" 2>/dev/null | head -1 | sed 's/<!-- doc-version: \(.*\) -->/\1/')
            if [ -z "$FOUND" ]; then
                echo "DRIFT: $filepath missing <!-- doc-version: --> marker"
                ERRORS=$((ERRORS + 1))
            elif [ "$FOUND" != "$EXPECTED" ]; then
                echo "DRIFT: $filepath has '$FOUND', expected '$EXPECTED'"
                ERRORS=$((ERRORS + 1))
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        changelog)
            if ! grep -q "^## \[$EXPECTED\]" "$filepath" 2>/dev/null; then
                echo "DRIFT: $filepath missing ## [$EXPECTED] section"
                ERRORS=$((ERRORS + 1))
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        *)
            echo "WARN: unknown marker type '$markertype' for $filepath"
            ;;
    esac
done < "$TMPFILE"

# Summary
if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "FAILED: $ERRORS file(s) out of sync with VERSION ($EXPECTED). Checked $CHECKED target(s)."
    echo "Run: scripts/bump-version.sh $EXPECTED"
    exit 1
else
    echo "OK: $CHECKED target(s) in sync with VERSION ($EXPECTED)"
    exit 0
fi
