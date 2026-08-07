#!/bin/sh
# dockit-init-project.sh -- Initialize a new project from the LLM-DocKit scaffold.
#
# Portable POSIX sh. Zero external dependencies beyond standard tools (git, sed,
# find). Produces a self-contained new project with the LLM-DocKit documentation
# structure ready for first session.
#
# What it does:
#   1. Validate inputs (slug pattern, target directory does not exist).
#   2. Copy LLM-DocKit content to the target directory.
#   3. Strip .git and DocKit-internal meta files (HOW_TO_USE, DOWNSTREAM_FEEDBACK,
#      ROADMAP, dockit-sync*, dockit-init-project, dockit-sync-manifest.yml).
#   4. Demote optional template-only docs so they do not masquerade as live
#      project documentation.
#   5. Reset the live operational docs (CHANGELOG, HANDOFF, HISTORY, DECISIONS)
#      to fresh stubs for the new project.
#   6. Substitute placeholders (<PROJECT_NAME>, <CONVERSATION_LANGUAGE>,
#      <YYYY-MM-DD>) in remaining markdown files.
#   7. Run scripts/bump-version.sh 0.1.0 to set VERSION and sync doc-version
#      markers atomically.
#   8. Initialize a fresh git repository with a single "Initial scaffold from
#      LLM-DocKit" commit.
#
# What it does NOT do:
#   - Does not create a GitHub remote or push (that is the caller's choice).
#   - Does not apply ecosystem-specific profiles (those live in their own repos
#     and are applied by separate scripts).
#   - Does not edit ~/.claude/ or any global configuration.
#
# Usage:
#   dockit-init-project.sh <project-name>
#   dockit-init-project.sh <project-name> --target-dir ./path/to/<project-name>
#   dockit-init-project.sh <project-name> --language English
#   dockit-init-project.sh <project-name> --source ~/path/to/LLM-DocKit
#
# Defaults:
#   --target-dir  ./<project-name>          (resolved relative to current dir)
#   --language    Spanish                    (passed through to placeholders)
#   --source      "$LLM_DOCKIT_ROOT" or path of this script's repository
#
# Exit codes:
#   0 -- success
#   1 -- validation failure (target exists, bad name, source not found)
#   2 -- script error (missing tool, sed/git failure)

set -eu

PROJECT_NAME=""
TARGET_DIR=""
LANGUAGE="Spanish"
SOURCE_DIR=""
TODAY=$(date +%Y-%m-%d)

# ── Parse arguments ──────────────────────────────────────────────────────────

while [ $# -gt 0 ]; do
    case "$1" in
        --target-dir)
            TARGET_DIR="${2:?--target-dir requires a path}"
            shift 2
            ;;
        --language)
            LANGUAGE="${2:?--language requires a value}"
            shift 2
            ;;
        --source)
            SOURCE_DIR="${2:?--source requires a path}"
            shift 2
            ;;
        --help|-h)
            sed -n '2,40p' "$0"
            exit 0
            ;;
        -*)
            echo "ERROR: unknown flag: $1" >&2
            exit 2
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
                shift
            else
                echo "ERROR: unexpected argument: $1" >&2
                exit 2
            fi
            ;;
    esac
done

# ── Validate inputs ──────────────────────────────────────────────────────────

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: project name required" >&2
    echo "Usage: $0 <project-name> [--target-dir PATH] [--language LANG] [--source PATH]" >&2
    exit 1
fi

case "$PROJECT_NAME" in
    *[!a-zA-Z0-9_-]*|"")
        echo "ERROR: project name must contain only [a-zA-Z0-9_-]: $PROJECT_NAME" >&2
        exit 1
        ;;
esac

if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="./$PROJECT_NAME"
fi

if [ -e "$TARGET_DIR" ]; then
    echo "ERROR: target already exists: $TARGET_DIR" >&2
    echo "Refusing to overwrite. Remove it manually and re-run if intended." >&2
    exit 1
fi

if [ -z "$SOURCE_DIR" ]; then
    if [ -n "${LLM_DOCKIT_ROOT:-}" ]; then
        SOURCE_DIR="$LLM_DOCKIT_ROOT"
    else
        # Default: the repo containing this script
        SOURCE_DIR=$(cd "$(dirname "$0")/.." && pwd)
    fi
fi

if [ ! -d "$SOURCE_DIR" ] || [ ! -f "$SOURCE_DIR/VERSION" ]; then
    echo "ERROR: source does not look like an LLM-DocKit checkout: $SOURCE_DIR" >&2
    echo "Hint: pass --source PATH or set LLM_DOCKIT_ROOT." >&2
    exit 1
fi

DOCKIT_VERSION=$(head -1 "$SOURCE_DIR/VERSION" | tr -d '[:space:]')

echo "Initializing project: $PROJECT_NAME"
echo "  Target:        $TARGET_DIR"
echo "  Language:      $LANGUAGE"
echo "  Source:        $SOURCE_DIR (LLM-DocKit $DOCKIT_VERSION)"
echo ""

# ── 1. Copy scaffold ─────────────────────────────────────────────────────────

mkdir -p "$TARGET_DIR"
TARGET_ABS=$(cd "$TARGET_DIR" && pwd)

# Use git archive rather than a working-tree copy so untracked drafts in
# the source LLM-DocKit checkout (proposals, scratch notes, local-only docs)
# never leak into the new project. Only files committed to HEAD travel.
if [ ! -d "$SOURCE_DIR/.git" ]; then
    echo "ERROR: source is not a git repository: $SOURCE_DIR" >&2
    echo "Hint: clone LLM-DocKit instead of using a working-tree copy." >&2
    exit 1
fi

git -C "$SOURCE_DIR" archive HEAD | tar -x -C "$TARGET_ABS"

cd "$TARGET_ABS"
echo "  copied scaffold (tracked files only, via git archive)"

# ── 2. Remove DocKit-internal meta files ────────────────────────────────────
#
# These files exist in the LLM-DocKit repo but are not meant for downstream
# projects:
#   - HOW_TO_USE.md          -- LLM-DocKit's own user guide
#   - DOWNSTREAM_FEEDBACK.md -- LLM-DocKit's adopter-feedback log
#   - ROADMAP.md             -- LLM-DocKit source roadmap, not project roadmap
#   - dockit-sync-manifest.yml -- template-propagation manifest
#   - scripts/dockit-sync.sh, dockit-sync-check.sh -- template propagation
#   - scripts/dockit-init-project.sh -- this script itself
#
# Downstream projects can always invoke them from the source LLM-DocKit
# checkout if they need to.

rm -f HOW_TO_USE.md
rm -f docs/DOWNSTREAM_FEEDBACK.md
rm -f docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md
rm -f docs/ROADMAP.md
rm -f dockit-sync-manifest.yml
rm -f scripts/dockit-sync.sh
rm -f scripts/dockit-sync-check.sh
rm -f scripts/dockit-init-project.sh

echo "  pruned DocKit-internal meta files"

# ── 3. Demote optional template-only docs ───────────────────────────────────
#
# `docs/ARCHITECTURE.md` in LLM-DocKit is an optional starter template. A fresh
# downstream project should not receive it as if it were real architecture.
# Keep the template available as `.example` until the project deliberately
# materializes a live `docs/ARCHITECTURE.md`.

if [ -f docs/ARCHITECTURE.md ]; then
    mv docs/ARCHITECTURE.md docs/ARCHITECTURE.md.example
    if [ -f docs/version-sync-manifest.yml ]; then
        sed -i 's|path: docs/ARCHITECTURE\.md[[:space:]]*marker: html-comment|path: docs/ARCHITECTURE.md.example marker: html-comment|' \
            docs/version-sync-manifest.yml
    fi
    echo "  demoted optional architecture template to docs/ARCHITECTURE.md.example"
fi

# ── 4. Reset live operational docs ──────────────────────────────────────────
#
# These files in the LLM-DocKit repo carry LLM-DocKit's own operational state
# (its DF entries, its session history, its decisions about its own internals).
# A new project starts with a fresh slate.

cat > CHANGELOG.md <<EOF
# Changelog

All notable changes to this project are documented in this file.

This project follows Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

## [0.1.0] - $TODAY

### Added

- Initial scaffold from LLM-DocKit $DOCKIT_VERSION.

### Changed

### Fixed
EOF

cat > docs/llm/HANDOFF.md <<EOF
<!-- doc-version: 0.1.0 -->
# LLM Work Handoff

This file is the current operational snapshot. Long-form rationale lives in
\`docs/llm/DECISIONS.md\`.

## Trace Anchor

- Role: executor
- Current target: none (initial scaffold; no implementation or audit target yet)
- State verified: local scaffold generated before first project session
- Validation: pending first \`scripts/dockit-validate-session.sh --human\`
- Next gate: first project session fills project context and starts implementation

## Current Status

- Last Updated: $TODAY - LLM-DocKit init
- Session Focus: Initial scaffold from LLM-DocKit $DOCKIT_VERSION.
- Status: Project just scaffolded. No application code yet.

## Project Summary

$PROJECT_NAME — describe what this project does in 1-2 paragraphs.

## Open work — next concrete step

Canonical declaration of "what to do next" for any LLM session opening this
repository. Must name concrete file paths inside the repo so a fresh session
can dispatch without bespoke prompting. Enforced by
\`scripts/dockit-validate-session.sh --check orientation\`.

For a freshly-scaffolded project (no work done yet):

1. Edit \`docs/PROJECT_CONTEXT.md\` with vision, objectives, stakeholders.
2. Edit \`docs/STRUCTURE.md\` with the actual repository layout once code lands.
3. Begin implementation in your first LLM session.

## Key Decisions

None yet. Add entries to \`docs/llm/DECISIONS.md\` when durable architectural
choices are made.

## Open Questions

None yet.

## Files To Read First

- \`README.md\`
- \`LLM_START_HERE.md\`
- \`docs/PROJECT_CONTEXT.md\`
- \`docs/llm/DECISIONS.md\`
EOF

cat > docs/llm/HISTORY.md <<EOF
# LLM Session History

Append-only record of meaningful LLM-assisted work on this project.

## Format

YYYY-MM-DD - <LLM_NAME> - <Brief summary> - Files: [list] - Version impact: <yes/no + details> - Trace: role=<executor|auditor|advisor>; commits=<local hash|none>; [external=<repo>@<hash>;] state=<repo state>; validation=<checks>; next=<gate>

## Entries

- $TODAY - LLM-DocKit init - Initial scaffold from LLM-DocKit $DOCKIT_VERSION. Conversation language: $LANGUAGE. - Files: [* (initial scaffold)] - Version impact: yes (initial 0.1.0) - Trace: role=executor; commits=none; state=local scaffold before first project session; validation=not-run; next=first-session
EOF

cat > docs/llm/DECISIONS.md <<EOF
# Decision Log

Durable architectural decisions for $PROJECT_NAME.

Format:
- Use IDs: \`D-001\`, \`D-002\`, ...
- Keep each decision self-contained.
- Prefer facts and tradeoffs over narration.

---

(No decisions recorded yet. Add the first entry as \`## D-001 - <title>\` when
the first durable choice is made.)
EOF

cat > .dockit-config.yml <<EOF
adoption_mode: full

trace_protocol:
  enabled: true
  since: $TODAY
  local_timezone: Europe/Madrid
EOF

echo "  reset CHANGELOG and docs/llm/{HANDOFF,HISTORY,DECISIONS}.md"
echo "  enabled Trace Protocol in .dockit-config.yml"

# ── 5. Substitute placeholders in remaining markdown ────────────────────────
#
# Files that ship as template skeletons (not LLM-DocKit's own content) carry
# placeholders. Replace them in every .md, .yml, .json under the new project.

# Linux GNU sed -i takes no argument; this script targets Linux explicitly
# (the LLM-DocKit ecosystem runs on dev-vm with GNU sed).
find . -type f \
    \( -name '*.md' -o -name '*.yml' -o -name '*.yaml' -o -name '*.json' \) \
    -not -path './.git/*' \
    -exec sed -i \
        -e "s|<PROJECT_NAME>|$PROJECT_NAME|g" \
        -e "s|<CONVERSATION_LANGUAGE>|$LANGUAGE|g" \
        -e "s|<YYYY-MM-DD>|$TODAY|g" \
        -e "s|<YYYY-MM-DD - Author>|$TODAY - LLM-DocKit init|g" \
        -e "s|<Feature or task>|Initial scaffold|g" \
        -e "s|<Short status summary>|Scaffolded from LLM-DocKit, ready for first session|g" \
        {} +

echo "  substituted placeholders"

# ── 6. Strip scaffold-author voice from starter docs ────────────────────────
#
# These lines are useful in LLM-DocKit itself but become misleading once the
# project has already been scaffolded. Remove or rewrite them before the first
# downstream commit so `template-residue` passes from day zero.

if [ -f LLM_START_HERE.md ]; then
    sed -i '/Replace angle-bracket placeholders/d' LLM_START_HERE.md
    _tmp_start=$(mktemp)
    awk '
        /^## Customization Notes for Maintainers$/ { skip = 1; next }
        skip && /^## Quick Navigation$/ { skip = 0 }
        !skip { print }
    ' LLM_START_HERE.md > "$_tmp_start"
    mv "$_tmp_start" LLM_START_HERE.md
fi

if [ -f docs/STRUCTURE.md ]; then
    sed -i \
        -e 's|Use this template to document how the repository is organized. Update the table below once your folders and files are in place.|Document the repository structure here. Replace this paragraph and the example tree below with the project-specific layout once the tree stabilizes.|' \
        -e "s|<PROJECT_ROOT>|$PROJECT_NAME|g" \
        -e 's|+- ARCHITECTURE.md            (optional)|+- ARCHITECTURE.md.example    (optional starter; copy to ARCHITECTURE.md when real)|' \
        docs/STRUCTURE.md
fi

if [ -f README.md ]; then
    sed -i \
        -e 's|\[docs/ARCHITECTURE.md\](docs/ARCHITECTURE.md)|[docs/ARCHITECTURE.md.example](docs/ARCHITECTURE.md.example)|' \
        -e 's|Technical architecture details|Optional architecture starter example|' \
        README.md
fi

echo "  stripped scaffold-author residue from starter docs"

# ── 7. Set version 0.1.0 via the canonical bump script ──────────────────────

if [ -x scripts/bump-version.sh ]; then
    scripts/bump-version.sh 0.1.0 > /dev/null 2>&1 || {
        echo "WARN: bump-version.sh exited non-zero; doc-version markers may need manual sync" >&2
    }
    echo "  version set to 0.1.0 (markers synced via bump-version.sh)"
else
    echo "WARN: scripts/bump-version.sh missing or not executable" >&2
fi

# ── 8. Make scripts executable ──────────────────────────────────────────────

if [ -d scripts ]; then
    find scripts -type f -name '*.sh' -exec chmod +x {} +
fi

# ── 9. Initialize fresh git repository ──────────────────────────────────────
#
# Force the default branch to `main` regardless of the system's
# init.defaultBranch setting. Using `git symbolic-ref` rather than
# `git init -b main` keeps the script portable to Git < 2.28.

git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git -c user.email='no-reply@local' -c user.name='LLM-DocKit init' \
    commit -q -m "chore: initial scaffold from LLM-DocKit $DOCKIT_VERSION

Generated by scripts/dockit-init-project.sh.

Conversation language: $LANGUAGE.
Project: $PROJECT_NAME."

echo "  git repository initialized with first commit"

# ── 10. Summary ─────────────────────────────────────────────────────────────

echo ""
echo "Project ready: $TARGET_ABS"
echo ""
echo "Next steps:"
echo "  cd $TARGET_DIR"
echo "  \$EDITOR docs/PROJECT_CONTEXT.md     # vision, objectives, stakeholders"
echo "  \$EDITOR docs/llm/HANDOFF.md          # session focus"
echo "  scripts/dockit-validate-session.sh --human"
echo ""
echo "If this project participates in an ecosystem with its own profile"
echo "(for example a homelab integration), apply that profile next:"
echo "  ~/src/<ecosystem-repo>/integrations/dockit/apply-profile.sh"
