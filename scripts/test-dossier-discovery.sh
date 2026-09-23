#!/bin/sh
set -eu
SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT HUP INT TERM
mkdir -p "$TMPDIR_TEST/repo/docs/llm" "$TMPDIR_TEST/repo/.forgeos"
printf 'Recommended reading order:\n1. This file\n\n' > "$TMPDIR_TEST/repo/LLM_START_HERE.md"
sh "$SOURCE/dockit-bootstrap-context.sh" --project "$TMPDIR_TEST/repo" --human > "$TMPDIR_TEST/before"
! grep -q 'Dossier declaration detected' "$TMPDIR_TEST/before"
printf '{"command":"touch SHOULD_NOT_EXIST"}\n' > "$TMPDIR_TEST/repo/.forgeos/dossier.json"
sh "$SOURCE/dockit-bootstrap-context.sh" --project "$TMPDIR_TEST/repo" --json > "$TMPDIR_TEST/after"
grep -q 'Dossier declaration detected' "$TMPDIR_TEST/after"
grep -q 'not validated' "$TMPDIR_TEST/after"
[ ! -e "$TMPDIR_TEST/repo/SHOULD_NOT_EXIST" ]
[ ! -e "$TMPDIR_TEST/repo/.claude" ]
[ ! -e "$TMPDIR_TEST/repo/.codex" ]
printf 'malformed' > "$TMPDIR_TEST/repo/.forgeos/dossier.json"
sh "$SOURCE/dockit-bootstrap-context.sh" --project "$TMPDIR_TEST/repo" --human > "$TMPDIR_TEST/malformed"
grep -q 'Dossier declaration detected' "$TMPDIR_TEST/malformed"
rm "$TMPDIR_TEST/repo/.forgeos/dossier.json"
sh "$SOURCE/dockit-bootstrap-context.sh" --project "$TMPDIR_TEST/repo" --human > "$TMPDIR_TEST/final"
cmp "$TMPDIR_TEST/before" "$TMPDIR_TEST/final"
printf 'PASS: optional discovery, inert malformed data, unchanged non-adopter output, no hooks\n'
