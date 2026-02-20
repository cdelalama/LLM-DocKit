#!/bin/sh
# bump-version.sh -- Update all version-synced files to a new version.
# Reads docs/version-sync-manifest.yml for the list of tracked files.
#
# Usage: scripts/bump-version.sh <new_version>
# Example: scripts/bump-version.sh 1.2.0
#
# This script:
# - Updates VERSION file
# - Updates <!-- doc-version: X.Y.Z --> markers in tracked docs
# - Adds a new ## [X.Y.Z] section to CHANGELOG.md
# - Runs check-version-sync.sh as self-test
#
# It does NOT:
# - Modify prose content in HANDOFF.md or HISTORY.md (LLM does that)
# - Stage or commit changes (user/LLM does that)

set -e

NEW_VERSION="$1"
if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <new_version>" >&2
    echo "Example: $0 1.2.0" >&2
    exit 1
fi

# Validate version format
echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || {
    echo "ERROR: version must be in X.Y.Z format (got: $NEW_VERSION)" >&2
    exit 1
}

MANIFEST="docs/version-sync-manifest.yml"
VERSION_FILE="VERSION"
SCRIPT_DIR=$(dirname "$0")

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: $MANIFEST not found" >&2
    exit 1
fi

OLD_VERSION=$(head -1 "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "unknown")

echo "Bumping version: $OLD_VERSION -> $NEW_VERSION"
echo ""

# Parse manifest targets to temp file
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
grep '^- path:' "$MANIFEST" | sed 's/^- path: *\([^ ]*\) *marker: *\([^ ]*\).*/\1 \2/' > "$TMPFILE"

UPDATED=0
FAILED=0
DATE=$(date +%Y-%m-%d)

while read -r filepath markertype; do
    if [ ! -f "$filepath" ]; then
        printf "  %-40s SKIP (not found)\n" "$filepath"
        continue
    fi

    case "$markertype" in
        version-file)
            # Replace first line with new version, preserve rest
            TMPOUT=$(mktemp)
            echo "$NEW_VERSION" > "$TMPOUT"
            tail -n +2 "$filepath" >> "$TMPOUT"
            mv "$TMPOUT" "$filepath"
            printf "  %-40s OK (version-file)\n" "$filepath"
            UPDATED=$((UPDATED + 1))
            ;;
        html-comment)
            # Replace <!-- doc-version: X.Y.Z --> marker
            if grep -q '<!-- doc-version:' "$filepath"; then
                TMPOUT=$(mktemp)
                sed "s/<!-- doc-version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]* -->/<!-- doc-version: $NEW_VERSION -->/" \
                    "$filepath" > "$TMPOUT"
                mv "$TMPOUT" "$filepath"
                printf "  %-40s OK (html-comment)\n" "$filepath"
                UPDATED=$((UPDATED + 1))
            else
                printf "  %-40s FAIL (no marker found)\n" "$filepath"
                FAILED=$((FAILED + 1))
            fi
            ;;
        changelog)
            # Insert new section before the first existing ## [ line
            if grep -q "^## \[$NEW_VERSION\]" "$filepath"; then
                printf "  %-40s SKIP (section already exists)\n" "$filepath"
                UPDATED=$((UPDATED + 1))
            else
                TMPOUT=$(mktemp)
                awk -v ver="$NEW_VERSION" -v dt="$DATE" '
                    /^## \[/ && !done {
                        print "## [" ver "] - " dt
                        print ""
                        print "### Added"
                        print ""
                        print "### Changed"
                        print ""
                        print "### Fixed"
                        print ""
                        done = 1
                    }
                    { print }
                ' "$filepath" > "$TMPOUT"
                mv "$TMPOUT" "$filepath"
                printf "  %-40s OK (changelog: added ## [%s])\n" "$filepath" "$NEW_VERSION"
                UPDATED=$((UPDATED + 1))
            fi
            ;;
        *)
            printf "  %-40s SKIP (unknown type: %s)\n" "$filepath" "$markertype"
            ;;
    esac
done < "$TMPFILE"

echo ""

if [ "$FAILED" -gt 0 ]; then
    echo "WARNING: $FAILED file(s) failed to update. $UPDATED file(s) updated."
    echo "Check files with missing markers and add <!-- doc-version: $NEW_VERSION --> manually."
    exit 1
fi

echo "All $UPDATED target(s) updated to $NEW_VERSION"
echo ""

# Self-test: run check script
echo "Running validation..."
"$SCRIPT_DIR/check-version-sync.sh"
