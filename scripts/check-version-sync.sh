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

json_top_version() {
    _file="$1"
    if command -v node >/dev/null 2>&1; then
        node - "$_file" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
if (typeof data.version !== 'string') process.exit(3);
console.log(data.version);
NODE
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$_file" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
version = data.get("version")
if not isinstance(version, str):
    sys.exit(3)
print(version)
PY
    else
        return 127
    fi
}

package_lock_versions() {
    _file="$1"
    if command -v node >/dev/null 2>&1; then
        node - "$_file" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
const top = data.version;
const root = data.packages && data.packages[''] && data.packages[''].version;
if (typeof top !== 'string' || typeof root !== 'string') process.exit(3);
console.log(`${top} ${root}`);
NODE
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$_file" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
top = data.get("version")
root = data.get("packages", {}).get("", {}).get("version")
if not isinstance(top, str) or not isinstance(root, str):
    sys.exit(3)
print(f"{top} {root}")
PY
    else
        return 127
    fi
}

yaml_info_version() {
    _file="$1"
    awk '
        /^[[:space:]]*info:[[:space:]]*$/ { in_info = 1; next }
        in_info && /^[^[:space:]][^:]*:/ { in_info = 0 }
        in_info && /^[[:space:]]+version:[[:space:]]*/ {
            v = $0
            sub(/^[[:space:]]+version:[[:space:]]*/, "", v)
            gsub(/^["\047]|["\047]$/, "", v)
            print v
            found = 1
            exit
        }
        END { if (!found) exit 1 }
    ' "$_file"
}

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
        json-version)
            FOUND=$(json_top_version "$filepath" 2>/dev/null || true)
            if [ -z "$FOUND" ]; then
                echo "DRIFT: $filepath missing readable JSON top-level version"
                ERRORS=$((ERRORS + 1))
            elif [ "$FOUND" != "$EXPECTED" ]; then
                echo "DRIFT: $filepath has '$FOUND', expected '$EXPECTED'"
                ERRORS=$((ERRORS + 1))
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        yaml-info-version)
            FOUND=$(yaml_info_version "$filepath" 2>/dev/null || true)
            if [ -z "$FOUND" ]; then
                echo "DRIFT: $filepath missing readable info.version"
                ERRORS=$((ERRORS + 1))
            elif [ "$FOUND" != "$EXPECTED" ]; then
                echo "DRIFT: $filepath info.version has '$FOUND', expected '$EXPECTED'"
                ERRORS=$((ERRORS + 1))
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        package-lock-version)
            FOUND=$(package_lock_versions "$filepath" 2>/dev/null || true)
            if [ -z "$FOUND" ]; then
                echo "DRIFT: $filepath missing readable top-level version and packages[\"\"].version"
                ERRORS=$((ERRORS + 1))
            else
                TOP_VERSION=$(printf '%s\n' "$FOUND" | awk '{print $1}')
                ROOT_VERSION=$(printf '%s\n' "$FOUND" | awk '{print $2}')
                if [ "$TOP_VERSION" != "$EXPECTED" ] || [ "$ROOT_VERSION" != "$EXPECTED" ]; then
                    echo "DRIFT: $filepath has top-level '$TOP_VERSION' and root package '$ROOT_VERSION', expected '$EXPECTED'"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
            CHECKED=$((CHECKED + 1))
            ;;
        *)
            echo "DRIFT: $filepath uses unknown marker type '$markertype'"
            ERRORS=$((ERRORS + 1))
            CHECKED=$((CHECKED + 1))
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
