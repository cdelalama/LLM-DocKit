#!/bin/sh
# Portable delivery evidence primitives. No deployment or probe execution.
# Sourced only by the two public commands. Values are parsed, never evaluated.
set -eu

die() { printf 'BLOCKED: %s\n' "$*" >&2; exit 1; }
hash_file() { git hash-object -- "$1"; }
token() { case "$1" in ''|*[!A-Za-z0-9_.:/@+-]*) return 1;; esac; [ ${#1} -le 240 ]; }
number() { case "$1" in ''|*[!0-9]*|0[0-9]*) return 1;; esac; [ ${#1} -le 10 ]; }
value() { awk -F= -v k="$2" '$1==k {print substr($0,length(k)+2)}' "$1"; }
field() { awk -F'|' -v k="$1" '$1==k {print $2}' "$STATE"; }
safe_file() {
    case "$1" in ''|.|..|/*|*[!A-Za-z0-9_./-]*|../*|*/../*|*/..|./*|*/./*|*/.|*//*|.git|.git/*) die "unsafe path: $1";; esac
    sf_path=$ROOT
    sf_parts=$1
    while [ -n "$sf_parts" ]; do
        sf_part=${sf_parts%%/*}; sf_path=$sf_path/$sf_part
        [ ! -L "$sf_path" ] || die "symlink in path: $1"
        case "$sf_parts" in */*) sf_parts=${sf_parts#*/};; *) sf_parts=;; esac
    done
}
require_file() { safe_file "$1"; [ -f "$ROOT/$1" ] && [ -s "$ROOT/$1" ] || die "missing/empty file: $1"; }
committed_contract() {
    cc_hash=$(git -C "$ROOT" rev-parse "HEAD:$CONTRACT" 2>/dev/null) || die 'declaration must be committed before use'
    [ "$cc_hash" = "$(hash_file "$ROOT/$CONTRACT")" ] || die 'declaration changes require review and commit'
}
setup() {
    ROOT=$(cd "$ROOT" && pwd -P) || die 'project unavailable'
    [ "$(git -C "$ROOT" rev-parse --show-toplevel)" = "$ROOT" ] || die 'project must be Git root'
    [ "$(git -C "$ROOT" rev-parse --is-shallow-repository)" = false ] || die "full Git history required; fetch --unshallow before delivery work"
    require_file "$CONTRACT"
    awk -F= '
      /^#/ || /^$/ {next}
      NF!=2 || $1 !~ /^(schema|work|environment|entrypoint|probe|negative_test|outcome|authority|max_age|integration_max_age|attempt_limit|review_limit|prerequisite|binding)$/ || $2 !~ /^[A-Za-z0-9_.\/-]+$/ {exit 1}
      $1!="prerequisite" && $1!="binding" && ++seen[$1]>1 {exit 1}
      {pair=$1 "=" $2; if (pairs[pair]++) exit 1}
    ' "$ROOT/$CONTRACT" || die 'invalid/duplicate declaration field'
    for sc_key in schema work environment entrypoint probe negative_test outcome authority max_age attempt_limit review_limit prerequisite; do
        [ -n "$(value "$ROOT/$CONTRACT" "$sc_key")" ] || die "missing declaration field: $sc_key"
    done
    [ "$(value "$ROOT/$CONTRACT" schema)" = 1 ] || die 'unsupported delivery schema'
    WORK=$(value "$ROOT/$CONTRACT" work); ENVIRONMENT=$(value "$ROOT/$CONTRACT" environment)
    for sc_id in "$WORK" "$ENVIRONMENT"; do
        case "$sc_id" in ''|*[!A-Za-z0-9_-]*) die 'work/environment must be stable slugs';; esac
    done
    [ "$CONTRACT" = "docs/llm/delivery/$WORK.contract" ] || die 'declaration path must match stable work ID'
    ENTRY=$(value "$ROOT/$CONTRACT" entrypoint); PROBE=$(value "$ROOT/$CONTRACT" probe)
    NEGATIVE=$(value "$ROOT/$CONTRACT" negative_test)
    MAX_AGE=$(value "$ROOT/$CONTRACT" max_age)
    INTEGRATION_AGE=$(value "$ROOT/$CONTRACT" integration_max_age); INTEGRATION_AGE=${INTEGRATION_AGE:-86400}
    number "$INTEGRATION_AGE" && [ "$INTEGRATION_AGE" -ge 1 ] && [ "$INTEGRATION_AGE" -le 604800 ] || die 'integration_max_age must be 1..604800'
    OUTCOME=$(value "$ROOT/$CONTRACT" outcome)
    ATTEMPT_LIMIT=$(value "$ROOT/$CONTRACT" attempt_limit); REVIEW_LIMIT=$(value "$ROOT/$CONTRACT" review_limit)
    for sc_n in "$MAX_AGE" "$ATTEMPT_LIMIT" "$REVIEW_LIMIT"; do number "$sc_n" || die 'invalid numeric declaration field'; done
    [ "$MAX_AGE" -ge 1 ] && [ "$MAX_AGE" -le 86400 ] || die 'max_age must be 1..86400 seconds'
    [ "$ATTEMPT_LIMIT" -ge 1 ] && [ "$ATTEMPT_LIMIT" -le 10 ] && [ "$REVIEW_LIMIT" -ge 1 ] && [ "$REVIEW_LIMIT" -le 10 ] || die 'initial limits must be 1..10'
    PREREQS=$(value "$ROOT/$CONTRACT" prerequisite | LC_ALL=C sort)
    for sc_id in $PREREQS; do case "$sc_id" in ''|*[!A-Za-z0-9_-]*) die 'invalid prerequisite ID';; esac; done
    for sc_path in "$ENTRY" "$PROBE" "$NEGATIVE" "$(value "$ROOT/$CONTRACT" outcome)" "$(value "$ROOT/$CONTRACT" authority)"; do require_file "$sc_path"; done
    BINDINGS=$(printf '%s\n' "$ENTRY" "$PROBE" "$NEGATIVE" "$OUTCOME" "$(value "$ROOT/$CONTRACT" authority)"; value "$ROOT/$CONTRACT" binding)
    for sc_path in $BINDINGS; do safe_file "$sc_path"; [ -f "$ROOT/$sc_path" ] || die "missing binding: $sc_path"; done
    committed_contract
    DECLARATION=$(hash_file "$ROOT/$CONTRACT")
    refresh_binding
    JOURNAL=${CONTRACT%.contract}.log; safe_file "$JOURNAL"
    COMMON=$(git -C "$ROOT" rev-parse --git-common-dir)
    case "$COMMON" in /*) ;; *) COMMON=$ROOT/$COMMON;; esac
    COMMON=$(cd "$COMMON" && pwd -P)
    SCOPE=$(printf '%s\n%s\n' "$ENVIRONMENT" "$OUTCOME" | git hash-object --stdin)
    STORE=$COMMON/.dockit/delivery/$SCOPE
    [ ! -L "$COMMON/.dockit" ] && [ ! -L "$COMMON/.dockit/delivery" ] && [ ! -L "$STORE" ] || die 'symlinked delivery storage'
    NOW=$(date +%s)
    TEMP=$(mktemp -d "${TMPDIR:-/tmp}/dockit-delivery.XXXXXX")
    STATE=$TEMP/state
    LOCKED=false
    trap 'rm -rf "$TEMP"; if [ "$LOCKED" = true ]; then rm -f "$STORE/lock/owner"; rmdir "$STORE/lock" 2>/dev/null || :; fi' EXIT
    trap 'exit 130' HUP INT TERM
}
refresh_binding() {
    require_file "$CONTRACT"
    [ "$(hash_file "$ROOT/$CONTRACT")" = "$DECLARATION" ] || die 'declaration changed during command'
    committed_contract
    for sc_path in $BINDINGS; do safe_file "$sc_path"; [ -f "$ROOT/$sc_path" ] || die "missing binding: $sc_path"; done
    # Hash the manifest identities as well as bytes; mutable records are excluded.
    sc_material="declaration=$DECLARATION"
    for sc_path in $BINDINGS; do sc_material="$sc_material
$sc_path=$(hash_file "$ROOT/$sc_path")"; done
    for sc_path in dockit-delivery-lib.sh dockit-delivery-state.awk dockit-delivery-check.sh dockit-delivery-record.sh; do
        sc_material="$sc_material
kit/$sc_path=$(hash_file "$LIB_DIR/$sc_path")"
    done
    CANDIDATE=$(printf '%s\n' "$sc_material" | git hash-object --stdin)
    NOW=$(date +%s)
}
lock() {
    [ ! -L "$COMMON/.dockit" ] && [ ! -L "$COMMON/.dockit/delivery" ] && [ ! -L "$STORE" ] || die 'symlinked delivery storage'
    mkdir -p "$STORE"
    mkdir "$STORE/lock" 2>/dev/null || die 'delivery writer active; inspect abandoned lock, never reset history'
    LOCKED=true
    printf 'pid=%s\nhost=%s\naction=%s\nstarted=%s\nworktree=%s\n' "$$" "$(uname -n)" "$ACTION" "$NOW" "$ROOT" > "$STORE/lock/owner"
    for lock_name in identity checkpoint last-good pending pending.tmp checkpoint.tmp last-good.tmp git-checked git-checked.tmp; do
        [ ! -L "$STORE/$lock_name" ] || die 'symlink in delivery storage'
    done
    safe_file "$JOURNAL.tmp"
    # Recompute the complete binding and clock under the writer lock.
    refresh_binding
}
identity() {
    [ -f "$STORE/identity" ] && [ ! -L "$STORE/identity" ] || die 'identity missing; init/restore explicitly'
    [ "$(cat "$STORE/identity")" = "$CONTRACT|$WORK|$ENVIRONMENT|$OUTCOME" ] || die 'outcome identity already registered; renaming cannot reset work'
}
checkpoint() {
    identity
    [ ! -e "$STORE/pending" ] || die 'interrupted append; run repair before ordinary work'
    [ -f "$ROOT/$JOURNAL" ] && [ ! -L "$ROOT/$JOURNAL" ] || die 'journal missing'
    [ -f "$STORE/last-good" ] && [ -f "$STORE/checkpoint" ] || die 'checkpoint missing; never infer an empty history'
    [ ! -L "$STORE/last-good" ] && [ ! -L "$STORE/checkpoint" ] || die 'symlinked checkpoint'
    cp_hash=$(hash_file "$ROOT/$JOURNAL")
    [ "$cp_hash" = "$(cat "$STORE/checkpoint")" ] && [ "$cp_hash" = "$(hash_file "$STORE/last-good")" ] || die 'journal/checkpoint rewritten or truncated'
    # Cache historical prefix validation only while Git refs are unchanged.
    cp_refs=$( { git -C "$ROOT" rev-parse HEAD; git -C "$ROOT" for-each-ref --format='%(refname) %(objectname)'; } | git hash-object --stdin)
    if [ ! -f "$STORE/git-checked" ] || [ "$(cat "$STORE/git-checked")" != "$cp_refs" ]; then
    # Every reachable committed version must be a prefix, including other branches.
    git -C "$ROOT" log --all --format=%H -- "$JOURNAL" > "$TEMP/commits"
    while IFS= read -r cp_rev; do
        git -C "$ROOT" show "$cp_rev:$JOURNAL" > "$TEMP/committed" 2>/dev/null || continue
        cp_bytes=$(wc -c < "$TEMP/committed" | tr -d ' ')
        head -c "$cp_bytes" "$ROOT/$JOURNAL" > "$TEMP/prefix"
        cmp -s "$TEMP/committed" "$TEMP/prefix" || die 'committed journal history diverges from working record'
    done < "$TEMP/commits"
    if [ "$LOCKED" = true ]; then printf '%s\n' "$cp_refs" > "$STORE/git-checked.tmp"; mv "$STORE/git-checked.tmp" "$STORE/git-checked"; fi
    fi
    awk -v attempts="$ATTEMPT_LIMIT" -v reviews="$REVIEW_LIMIT" -f "$LIB_DIR/dockit-delivery-state.awk" "$ROOT/$JOURNAL" > "$STATE" || die 'invalid journal event/order'
    [ "$(field declaration)" = "$DECLARATION" ] || {
        case "$ACTION" in reassess|finish|recovered|repair) ;; *) die 'declaration changed; explicit reassessment required';; esac
    }
}
append() {
    ap_event=$1; shift
    ap_seq=$(( $(wc -l < "$ROOT/$JOURNAL") + 1 ))
    cp "$ROOT/$JOURNAL" "$TEMP/next"
    printf '%s|%s|%s' "$ap_seq" "$NOW" "$ap_event" >> "$TEMP/next"
    ap_n=0
    for ap_arg in "$@"; do token "$ap_arg" || die 'invalid event token'; printf '|%s' "$ap_arg" >> "$TEMP/next"; ap_n=$((ap_n+1)); done
    while [ "$ap_n" -lt 7 ]; do printf '|-' >> "$TEMP/next"; ap_n=$((ap_n+1)); done
    [ "$ap_n" -eq 7 ] || die 'internal event field count'
    printf '\n' >> "$TEMP/next"
    awk -v attempts="$ATTEMPT_LIMIT" -v reviews="$REVIEW_LIMIT" -f "$LIB_DIR/dockit-delivery-state.awk" "$TEMP/next" > "$TEMP/verified" || die 'invalid event transition'
    # Pending snapshot survives any interruption between the two installed copies.
    cp "$TEMP/next" "$STORE/pending.tmp"
    mv "$STORE/pending.tmp" "$STORE/pending"
    cp "$STORE/pending" "$ROOT/$JOURNAL.tmp"
    mv "$ROOT/$JOURNAL.tmp" "$ROOT/$JOURNAL"
    cp "$STORE/pending" "$STORE/last-good.tmp"
    mv "$STORE/last-good.tmp" "$STORE/last-good"
    hash_file "$STORE/pending" > "$STORE/checkpoint.tmp"
    mv "$STORE/checkpoint.tmp" "$STORE/checkpoint"
    rm "$STORE/pending"
    printf '%s\n' "$ap_seq"
}
readiness() {
    [ "$(field pending)" = 0 ] || die "RECOVERY_REQUIRED: attempt $(field pending) is unfinished"
    # Prerequisites precede review/integration checks: late ingress must be visible.
    rd_causes=""
    for rd_p in $PREREQS; do
        rd_row=$(awk -F'|' -v p="$rd_p" '$3=="evidence" && $5==p {r=$0} END {print r}' "$ROOT/$JOURNAL")
        [ -n "$rd_row" ] || die "PREREQUISITE: missing $rd_p"
        rd_candidate=$(printf '%s\n' "$rd_row" | cut -d'|' -f4)
        rd_at=$(printf '%s\n' "$rd_row" | cut -d'|' -f6)
        rd_status=$(printf '%s\n' "$rd_row" | cut -d'|' -f7)
        rd_cause=$(printf '%s\n' "$rd_row" | cut -d'|' -f8)
        rd_env=$(printf '%s\n' "$rd_row" | cut -d'|' -f9)
        [ "$rd_candidate" = "$CANDIDATE" ] && [ "$rd_env" = "$ENVIRONMENT" ] || die "PREREQUISITE: wrong candidate/environment for $rd_p"
        [ "$rd_status" = pass ] || die "PREREQUISITE: failed $rd_p"
        [ "$rd_at" -le "$NOW" ] && [ $((NOW-rd_at)) -le "$MAX_AGE" ] || die "PREREQUISITE: stale/future $rd_p"
        rd_causes="$rd_causes
$rd_p=$rd_cause"
    done
    CAUSES=$(printf '%s\n' "$rd_causes" | git hash-object --stdin)
    ! grep -qxF "failed_cause|$CAUSES" "$STATE" || die 'REASSESS: equivalent failed attempt; no changed causal evidence'
    [ "$(field blockers)" = 0 ] || die 'REVIEW: unresolved supported findings'
    [ "$(field approved)" = "$CANDIDATE" ] || die 'REVIEW: no approval of this exact declared candidate'
    [ "$(field integration)" = "$CANDIDATE" ] || die 'INTEGRATION: scripts-only; negative entrypoint test not current'
    rd_integration=$(field integration_time)
    [ "$rd_integration" -le "$NOW" ] && [ $((NOW-rd_integration)) -le "$INTEGRATION_AGE" ] || die 'INTEGRATION: stale negative-test receipt'
    rd_artifact=$(field integration_artifact)
    [ -f "$STORE/artifacts/$rd_artifact" ] && [ ! -L "$STORE/artifacts/$rd_artifact" ] && [ "$(hash_file "$STORE/artifacts/$rd_artifact")" = "$rd_artifact" ] || die 'INTEGRATION: receipt artifact missing; rerun negative integration test'
    [ "$(field attempts)" -lt "$(field attempt_limit)" ] || die 'REASSESS: attempt budget exhausted'
}
