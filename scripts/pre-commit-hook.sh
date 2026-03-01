#!/bin/sh
# pre-commit-hook.sh -- Git pre-commit hook for version sync validation.
#
# Installation (choose one):
#   cp scripts/pre-commit-hook.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
#   ln -sf ../../scripts/pre-commit-hook.sh .git/hooks/pre-commit
#
# What it does:
# 1. If VERSION is staged, verifies all manifest targets are also staged.
# 2. If product code/config files changed, BLOCKS if VERSION is not also staged.
#    (excludes .claude/, .github/, docs/ -- tooling, not product code)
# 3. If code/config files changed, warns if HISTORY.md not updated.
# 4. Runs check-version-sync.sh to catch any version drift.
# 5. Runs dockit-validate-session.sh to check documentation state.

MANIFEST="docs/version-sync-manifest.yml"
CHECK_SCRIPT="scripts/check-version-sync.sh"

# Get list of staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED" ]; then
    exit 0
fi

# --- Check 1: VERSION staged -> all manifest targets must be staged ---
if echo "$STAGED" | grep -q '^VERSION$'; then
    if [ -f "$MANIFEST" ]; then
        MISSING=""
        TMPFILE=$(mktemp)
        trap 'rm -f "$TMPFILE"' EXIT
        grep '^- path:' "$MANIFEST" | sed 's/^- path: *\([^ ]*\).*/\1/' > "$TMPFILE"

        while read -r filepath; do
            if [ "$filepath" = "VERSION" ]; then continue; fi
            if [ ! -f "$filepath" ]; then continue; fi
            if ! echo "$STAGED" | grep -q "^${filepath}$"; then
                MISSING="$MISSING  - $filepath"
            fi
        done < "$TMPFILE"

        if [ -n "$MISSING" ]; then
            echo "ERROR: VERSION is staged but these manifest targets are not:"
            echo "$MISSING"
            echo ""
            echo "Run: scripts/bump-version.sh $(head -1 VERSION)"
            echo "Then stage all changed files."
            exit 1
        fi
    fi
fi

# --- Check 2: Product code/config changed -> VERSION must be staged ---
# Excludes tooling paths (.claude/, .github/, docs/) that are not product code.
CODE_CHANGED=$(echo "$STAGED" | grep -E '\.(sh|ps1|py|js|ts|yml|yaml|json|toml|cfg|conf|sql)$' \
    | grep -v 'version-sync-manifest' \
    | grep -v '^\\.claude/' \
    | grep -v '^\\.github/' \
    | grep -v '^docs/' \
    || true)
if [ -n "$CODE_CHANGED" ]; then
    if ! echo "$STAGED" | grep -q '^VERSION$'; then
        echo "ERROR: Product code/config files changed but VERSION not staged."
        echo "Changed: $(echo "$CODE_CHANGED" | tr '\n' ' ')"
        echo ""
        echo "Run: scripts/bump-version.sh <new_version>"
        exit 1
    fi
fi

# --- Check 3: Code/config changed -> warn if HISTORY.md not updated ---
if [ -n "$CODE_CHANGED" ]; then
    if ! echo "$STAGED" | grep -q 'docs/llm/HISTORY.md'; then
        echo "WARNING: Code/config files changed but docs/llm/HISTORY.md not staged."
        echo "Consider adding a HISTORY entry for this session."
        echo ""
        # Warning only, not blocking
    fi
fi

# --- Check 4: Full version sync validation ---
if [ -f "$CHECK_SCRIPT" ]; then
    "$CHECK_SCRIPT"
fi

# --- Check 5: Documentation session validation ---
VALIDATE_SCRIPT="scripts/dockit-validate-session.sh"
if [ -f "$VALIDATE_SCRIPT" ]; then
    if ! "$VALIDATE_SCRIPT" --quiet --check handoff-date --check history-entry >/dev/null 2>&1; then
        echo "WARNING: Documentation not up to date (HANDOFF.md or HISTORY.md)."
        echo "Run: scripts/dockit-validate-session.sh --human"
        echo ""
        # Warning only, not blocking (pre-commit should not block normal code commits)
    fi
fi
