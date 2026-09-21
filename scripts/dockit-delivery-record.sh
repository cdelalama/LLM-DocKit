#!/bin/sh
set -eu
umask 077
LIB_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$LIB_DIR/dockit-delivery-lib.sh"
ROOT=.; CONTRACT=; ACTION=; FILE=; VERDICT=; BLOCKERS=; ATTEMPT=; RESULT=; RECOVERED=; EXTRA_A=; EXTRA_R=; OWNER=
while [ $# -gt 0 ]; do
 case "$1" in
 --project) ROOT=${2:?}; shift 2;; --contract) CONTRACT=${2:?}; shift 2;;
 --file) FILE=${2:?}; shift 2;; --verdict) VERDICT=${2:?}; shift 2;; --blockers) BLOCKERS=${2:?}; shift 2;;
 --attempt) ATTEMPT=${2:?}; shift 2;; --result) RESULT=${2:?}; shift 2;; --recovered) RECOVERED=${2:?}; shift 2;;
 --attempts) EXTRA_A=${2:?}; shift 2;; --reviews) EXTRA_R=${2:?}; shift 2;; --owner) OWNER=${2:?}; shift 2;;
 init|restore|evidence|review|integration|begin|finish|recovered|reassess|repair) [ -z "$ACTION" ] || die 'one action only'; ACTION=$1; shift;;
 --help) echo 'Usage: dockit-delivery-record.sh ACTION --project PATH --contract RELPATH [action options]; see docs/DELIVERY_CONTRACT.md'; exit 0;;
 *) die "unknown argument: $1";;
 esac
done
[ -n "$ACTION" ] || die 'action required'
setup
if [ "$ACTION" = integration ]; then
 # A real test run, not an asserted status. No writer lock during project tests.
 checkpoint
 integration_before=$(hash_file "$ROOT/$JOURNAL")
 integration_candidate=$CANDIDATE
 [ -x "$ROOT/$NEGATIVE" ] || die 'negative test must be executable; its shebang chooses the interpreter'
 if ! (cd "$ROOT" && "./$NEGATIVE") > "$TEMP/test-output" 2>&1; then die 'negative entrypoint integration test failed; no receipt recorded'; fi
 # Recompute binding without losing this temporary workspace/trap.
 refresh_binding
 [ "$CANDIDATE" = "$integration_candidate" ] && [ "$(hash_file "$ROOT/$JOURNAL")" = "$integration_before" ] || die 'candidate/journal changed during negative test'
fi
lock
case "$ACTION" in
 init|restore)
  [ ! -e "$STORE/identity" ] && [ ! -e "$STORE/checkpoint" ] && [ ! -e "$STORE/pending" ] || die 'identity already initialized; cannot reset history'
  if [ "$ACTION" = init ]; then
   [ ! -e "$ROOT/$JOURNAL" ] || die 'existing journal requires restore, never init'
   [ -z "$(git -C "$ROOT" log --all --format=%H -- "$JOURNAL")" ] || die 'historical journal exists; cannot reset'
   # A fresh clone has no registry: consult historical declarations as well.
   git -C "$ROOT" log --all --format=%H -- 'docs/llm/delivery/*.contract' > "$TEMP/declaration-commits"
   while IFS= read -r old_rev; do
    git -C "$ROOT" ls-tree -r --name-only "$old_rev" -- docs/llm/delivery > "$TEMP/old-paths"
    while IFS= read -r old_path; do
     case "$old_path" in *.contract) ;; *) continue;; esac
     git -C "$ROOT" show "$old_rev:$old_path" > "$TEMP/old-contract"
     if [ "$(value "$TEMP/old-contract" environment)" = "$ENVIRONMENT" ] && [ "$(value "$TEMP/old-contract" outcome)" = "$OUTCOME" ] && [ "$(value "$TEMP/old-contract" work)" != "$WORK" ]; then
      die 'historical outcome identity exists; rename cannot reset attempts in a clone'
     fi
    done < "$TEMP/old-paths"
   done < "$TEMP/declaration-commits"
   printf '1|%s|init|%s|%s|%s|-|-|-|-\n' "$NOW" "$DECLARATION" "$ATTEMPT_LIMIT" "$REVIEW_LIMIT" > "$TEMP/initial"
  else
   [ -f "$ROOT/$JOURNAL" ] || die 'restore requires committed journal'
   restore_hash=$(git -C "$ROOT" rev-parse "HEAD:$JOURNAL") || die 'restore requires committed journal'
   [ "$restore_hash" = "$(hash_file "$ROOT/$JOURNAL")" ] || die 'restore only accepts exact committed journal'
   cp "$ROOT/$JOURNAL" "$TEMP/initial"
  fi
  awk -v attempts="$ATTEMPT_LIMIT" -v reviews="$REVIEW_LIMIT" -f "$LIB_DIR/dockit-delivery-state.awk" "$TEMP/initial" > "$STATE" || die 'invalid restore journal'
  [ "$(field declaration)" = "$DECLARATION" ] || die 'restore declaration mismatch'
  printf '%s|%s|%s|%s\n' "$CONTRACT" "$WORK" "$ENVIRONMENT" "$OUTCOME" > "$STORE/identity"
  cp "$TEMP/initial" "$ROOT/$JOURNAL"
  cp "$TEMP/initial" "$STORE/last-good"
  hash_file "$TEMP/initial" > "$STORE/checkpoint"
  printf 'REGISTERED: %s; no readiness or runtime acceptance implied\n' "$WORK"
  exit 0;;
 repair)
  identity
  if [ ! -e "$STORE/pending" ]; then
   # Rebuild only a missing hash, never replace a conflicting checkpoint.
   if [ -e "$STORE/checkpoint" ]; then
    checkpoint
    echo 'UNCHANGED: retained checkpoint consistent; ordinary readiness is separate'; exit 0
   fi
   [ -f "$STORE/last-good" ] && [ -f "$ROOT/$JOURNAL" ] || die 'missing retained preimage; manual evidence reconciliation required'
   cmp -s "$STORE/last-good" "$ROOT/$JOURNAL" || die 'retained journal diverges; cannot discard events'
   awk -v attempts="$ATTEMPT_LIMIT" -v reviews="$REVIEW_LIMIT" -f "$LIB_DIR/dockit-delivery-state.awk" "$STORE/last-good" > "$STATE" || die 'invalid retained journal'
   hash_file "$STORE/last-good" > "$STORE/checkpoint.tmp"; mv "$STORE/checkpoint.tmp" "$STORE/checkpoint"
   rm -f "$STORE/git-checked"
   checkpoint
   echo 'REPAIRED: missing checkpoint reconstructed from identical retained journal'; exit 0
  fi
  [ -f "$STORE/pending" ] && [ ! -L "$STORE/pending" ] || die 'invalid retained append transaction'
  awk -v attempts="$ATTEMPT_LIMIT" -v reviews="$REVIEW_LIMIT" -f "$LIB_DIR/dockit-delivery-state.awk" "$STORE/pending" > "$STATE" || die 'invalid retained transaction'
  # Only finish an append when both surviving records are exact prefixes.
  for repair_path in "$ROOT/$JOURNAL" "$STORE/last-good"; do
   [ -f "$repair_path" ] && [ ! -L "$repair_path" ] || die 'missing transaction preimage; retain evidence for manual recovery'
   head -c "$(wc -c < "$repair_path" | tr -d ' ')" "$STORE/pending" > "$TEMP/prefix"
   cmp -s "$repair_path" "$TEMP/prefix" || die 'transaction conflicts; cannot repair by discarding evidence'
  done
  cp "$STORE/pending" "$ROOT/$JOURNAL.tmp"; mv "$ROOT/$JOURNAL.tmp" "$ROOT/$JOURNAL"
  cp "$STORE/pending" "$STORE/last-good.tmp"; mv "$STORE/last-good.tmp" "$STORE/last-good"
  hash_file "$STORE/pending" > "$STORE/checkpoint.tmp"; mv "$STORE/checkpoint.tmp" "$STORE/checkpoint"
  rm "$STORE/pending"
  echo 'REPAIRED: retained append completed; runtime recovery is a separate project action'; exit 0;;
esac
checkpoint
case "$ACTION" in
 evidence)
  require_file "$FILE"
  awk -F= 'NF!=2 || $1 !~ /^(prerequisite|environment|observed_at|status|cause)$/ || $2 !~ /^[A-Za-z0-9_.:-]+$/ || seen[$1]++ {exit 1} END {if(NR!=5) exit 1}' "$ROOT/$FILE" || die 'invalid probe evidence'
  ev_p=$(value "$ROOT/$FILE" prerequisite); ev_env=$(value "$ROOT/$FILE" environment)
  ev_at=$(value "$ROOT/$FILE" observed_at); ev_status=$(value "$ROOT/$FILE" status); ev_cause=$(value "$ROOT/$FILE" cause)
  printf '%s\n' "$PREREQS" | grep -qxF "$ev_p" || die 'undeclared prerequisite identity'
  [ "$ev_env" = "$ENVIRONMENT" ] || die 'wrong evidence environment'
  number "$ev_at" && [ "$ev_at" -le "$NOW" ] || die 'future/invalid evidence timestamp'
  case "$ev_status" in pass|fail) ;; *) die 'invalid evidence status';; esac
  token "$ev_cause" || die 'missing causal state'
  append evidence "$CANDIDATE" "$ev_p" "$ev_at" "$ev_status" "$ev_cause" "$ev_env" "$(hash_file "$ROOT/$FILE")";;
 review)
  require_file "$FILE"; number "$BLOCKERS" || die 'invalid blocker count'
  case "$VERDICT" in approved) [ "$BLOCKERS" = 0 ] || die 'approval cannot erase unresolved findings';; changes) ;; *) die 'invalid review verdict';; esac
  [ "$(field reviews)" -lt "$(field review_limit)" ] || die 'REASSESS: review budget exhausted; no automatic GO'
  append review "$CANDIDATE" "$VERDICT" "$BLOCKERS" "$(hash_file "$ROOT/$FILE")" "$FILE";;
 integration)
  [ "$CANDIDATE" = "$integration_candidate" ] && [ "$(hash_file "$ROOT/$JOURNAL")" = "$integration_before" ] || die 'candidate/journal changed before integration receipt'
  [ ! -L "$STORE/artifacts" ] || die 'symlinked artifact directory'
  mkdir -p "$STORE/artifacts"
  integration_artifact=$(hash_file "$TEMP/test-output")
  [ ! -L "$STORE/artifacts/$integration_artifact" ] || die 'symlinked artifact'
  cp "$TEMP/test-output" "$STORE/artifacts/$integration_artifact"
  append integration "$CANDIDATE" "$(hash_file "$ROOT/$NEGATIVE")" "$integration_artifact";;
 begin) readiness; append begin "$CANDIDATE" "$CAUSES";;
 finish)
  number "$ATTEMPT" || die 'invalid attempt ID'
  append finish "$ATTEMPT" "$RESULT" "$RECOVERED";;
 recovered)
  require_file "$FILE"; number "$ATTEMPT" || die 'invalid attempt ID'
  append recovered "$ATTEMPT" "$(hash_file "$ROOT/$FILE")" "$FILE";;
 reassess)
  require_file "$FILE"; token "$OWNER" || die 'reassessment owner required'
  number "$EXTRA_A" && number "$EXTRA_R" || die 'bounded attempt/review allowance required'
  [ "$EXTRA_A" -le 10 ] && [ "$EXTRA_R" -le 10 ] || die 'reassessment allowance at most 10'
  append reassess "$DECLARATION" "$(( $(field attempts)+EXTRA_A ))" "$(( $(field reviews)+EXTRA_R ))" "$(hash_file "$ROOT/$FILE")" "$FILE" "$OWNER";;
esac
