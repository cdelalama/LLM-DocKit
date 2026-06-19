#!/bin/sh
# dockit-install-codex-hook.sh -- Install LLM-DocKit onboarding for Codex CLI.
#
# The hook must call dockit-bootstrap-context.sh in --human mode. The --json
# mode is for Claude Code's hook envelope and is not parsed by Codex CLI.

set -eu

CONFIG_FILE="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
BOOTSTRAP_SCRIPT=""

usage() {
    cat <<'EOF'
Usage: scripts/dockit-install-codex-hook.sh [--config PATH] [--script PATH]

Installs or updates the Codex CLI SessionStart hook for LLM-DocKit onboarding.
The installed hook invokes dockit-bootstrap-context.sh with --human.

Options:
  --config PATH  Codex config file to edit (default: ~/.codex/config.toml)
  --script PATH  dockit-bootstrap-context.sh path to call (default: sibling script)
  -h, --help     Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG_FILE="${2:?--config requires a path}"
            shift 2
            ;;
        --script)
            BOOTSTRAP_SCRIPT="${2:?--script requires a path}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$BOOTSTRAP_SCRIPT" ]; then
    SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
    BOOTSTRAP_SCRIPT="$SCRIPT_DIR/dockit-bootstrap-context.sh"
fi

case "$BOOTSTRAP_SCRIPT" in
    *\"*|*\\*)
        echo "ERROR: --script path cannot contain double quotes or backslashes: $BOOTSTRAP_SCRIPT" >&2
        exit 2
        ;;
esac

if [ ! -x "$BOOTSTRAP_SCRIPT" ]; then
    echo "ERROR: bootstrap script is not executable: $BOOTSTRAP_SCRIPT" >&2
    exit 1
fi

CONFIG_DIR=$(dirname "$CONFIG_FILE")
mkdir -p "$CONFIG_DIR"
[ -f "$CONFIG_FILE" ] || : >"$CONFIG_FILE"

TMP_BASE=$(mktemp)
TMP_FEATURES=$(mktemp)
TMP_TRIMMED=$(mktemp)
TMP_FINAL=$(mktemp)
trap 'rm -f "$TMP_BASE" "$TMP_FEATURES" "$TMP_TRIMMED" "$TMP_FINAL"' EXIT HUP INT TERM

# Remove blocks installed by previous LLM-DocKit versions. The old 2026-05-03
# block was appended at EOF without an END marker and used --json; removing it
# before appending the managed block prevents duplicate SessionStart hooks.
awk '
    /^# --- LLM-DocKit Codex SessionStart hook: BEGIN ---$/ { skip = 1; next }
    skip && /^# --- LLM-DocKit Codex SessionStart hook: END ---$/ { skip = 0; next }
    /^# --- LLM-DocKit DF-033 \/ D-007: SessionStart enforcement/ { skip = 1; next }
    skip { next }
    { print }
' "$CONFIG_FILE" > "$TMP_BASE"

# Ensure the global Codex hook feature flag is enabled. This preserves other
# config sections and only normalizes [features].hooks.
awk '
    BEGIN {
        in_features = 0
        saw_features = 0
        saw_hooks = 0
    }
    /^\[features\]$/ {
        if (in_features && !saw_hooks) print "hooks = true"
        in_features = 1
        saw_features = 1
        saw_hooks = 0
        print
        next
    }
    /^\[/ {
        if (in_features && !saw_hooks) print "hooks = true"
        in_features = 0
    }
    in_features && /^[[:space:]]*hooks[[:space:]]*=/ {
        print "hooks = true"
        saw_hooks = 1
        next
    }
    { print }
    END {
        if (in_features && !saw_hooks) print "hooks = true"
        if (!saw_features) {
            print ""
            print "[features]"
            print "hooks = true"
        }
    }
' "$TMP_BASE" > "$TMP_FEATURES"

COMMAND="sh -lc 'root=\$(git rev-parse --show-toplevel 2>/dev/null || pwd); script=$BOOTSTRAP_SCRIPT; if [ -x \\\"\$script\\\" ]; then \\\"\$script\\\" --human --project \\\"\$root\\\"; fi'"

awk '
    { lines[NR] = $0 }
    END {
        n = NR
        while (n > 0 && lines[n] == "") n--
        for (i = 1; i <= n; i++) print lines[i]
    }
' "$TMP_FEATURES" > "$TMP_TRIMMED"

cat "$TMP_TRIMMED" > "$TMP_FINAL"
cat >> "$TMP_FINAL" <<EOF

# --- LLM-DocKit Codex SessionStart hook: BEGIN ---
# Managed by scripts/dockit-install-codex-hook.sh.
# Codex CLI receives plain onboarding text; Claude Code uses the JSON envelope.
[[hooks.SessionStart]]

[[hooks.SessionStart.hooks]]
type = "command"
command = "$COMMAND"
timeout = 5
# --- LLM-DocKit Codex SessionStart hook: END ---
EOF

if cmp -s "$CONFIG_FILE" "$TMP_FINAL"; then
    echo "Codex SessionStart hook already installed in $CONFIG_FILE"
    exit 0
fi

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP="$CONFIG_FILE.bak.$STAMP"
cp "$CONFIG_FILE" "$BACKUP"
mv "$TMP_FINAL" "$CONFIG_FILE"
trap 'rm -f "$TMP_BASE" "$TMP_FEATURES" "$TMP_TRIMMED"' EXIT HUP INT TERM

echo "Installed Codex SessionStart hook in $CONFIG_FILE"
echo "Backup: $BACKUP"
echo "Mode: --human"
