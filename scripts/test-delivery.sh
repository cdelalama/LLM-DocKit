#!/bin/sh
# Behavioral tests: guarded command side effects, continuity and recovery.
set -eu
KIT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export KIT
TMP=$(mktemp -d "${TMPDIR:-/tmp}/dockit-delivery-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
R=$TMP/project; C=docs/llm/delivery/remote.contract; OUT=$TMP/output
passed=0; failed=0
ok() { label=$1; shift; if "$@" > "$OUT" 2>&1; then passed=$((passed+1)); printf 'PASS: %s\n' "$label"; else failed=$((failed+1)); printf 'FAIL: %s\n' "$label"; cat "$OUT"; fi; }
no() { label=$1; shift; if "$@" > "$OUT" 2>&1; then failed=$((failed+1)); printf 'FAIL: %s unexpectedly allowed\n' "$label"; cat "$OUT"; else passed=$((passed+1)); printf 'PASS: %s\n' "$label"; fi; }
record() { "$KIT/dockit-delivery-record.sh" "$@" --project "$R" --contract "$C"; }
check() { "$KIT/dockit-delivery-check.sh" --project "$R" --contract "$C" "$@"; }
probe() {
 status=$1; cause=$2; at=${3:-$(date +%s)}
 printf 'prerequisite=dns\nenvironment=development\nobserved_at=%s\nstatus=pass\ncause=dns-ready\n' "$(date +%s)" > "$R/dns-observation"
 record evidence --file dns-observation >/dev/null
 printf 'prerequisite=ingress\nenvironment=development\nobserved_at=%s\nstatus=%s\ncause=%s\n' "$at" "$status" "$cause" > "$R/observation"
 record evidence --file observation
}
mkdir -p "$R/docs/llm/delivery" "$R/scripts" "$R/docs/operations"
cat > "$R/$C" <<'DECL'
schema=1
work=remote
environment=development
entrypoint=scripts/entrypoint.sh
probe=scripts/probe.sh
negative_test=scripts/negative.sh
outcome=docs/operations/outcome.md
authority=docs/operations/authority.md
max_age=300
integration_max_age=86400
attempt_limit=2
review_limit=2
prerequisite=ingress
prerequisite=dns
binding=scripts/empty-input
DECL
: > "$R/scripts/empty-input"
printf 'Declared user acceptance.\n' > "$R/docs/operations/outcome.md"
printf 'Local fixture only, never real infrastructure.\n' > "$R/docs/operations/authority.md"
printf 'review evidence\n' > "$R/review.md"
printf 'recovery evidence\n' > "$R/recovery.md"
printf 'bounded redesign rationale and new evidence\n' > "$R/reassessment.md"
printf '#!/bin/sh\nexit 0\n' > "$R/scripts/probe.sh"
cat > "$R/scripts/entrypoint.sh" <<'ENTRY'
#!/bin/sh
set -eu
# The bypass exists ONLY in this adverse reproducer, never in shipped guards.
if [ "${DOCKIT_REPRO_UNGUARDED:-0}" = 1 ]; then echo mutation >> mutation.calls; exit 0; fi
attempt=$("$KIT/dockit-delivery-record.sh" begin --project "$PWD" --contract docs/llm/delivery/remote.contract)
echo mutation >> mutation.calls
"$KIT/dockit-delivery-record.sh" finish --attempt "$attempt" --result success --recovered yes --project "$PWD" --contract docs/llm/delivery/remote.contract
ENTRY
cat > "$R/scripts/negative.sh" <<'NEGATIVE'
#!/bin/sh
set -eu
n=$(mktemp -d)
trap 'rm -rf "$n"' EXIT HUP INT TERM
git clone -q --no-hardlinks "$PWD" "$n/repo"
cd "$n/repo"
# Test the actual committed entrypoint in an isolated fresh adopter clone.
if [ -f docs/llm/delivery/remote.log ]; then action=restore; else action=init; fi
"$KIT/dockit-delivery-record.sh" "$action" --project "$PWD" --contract docs/llm/delivery/remote.contract >/dev/null
printf 'prerequisite=dns\nenvironment=development\nobserved_at=%s\nstatus=pass\ncause=dns-ready\n' "$(date +%s)" > dns-observation
"$KIT/dockit-delivery-record.sh" evidence --file dns-observation --project "$PWD" --contract docs/llm/delivery/remote.contract >/dev/null
printf 'prerequisite=ingress\nenvironment=development\nobserved_at=%s\nstatus=fail\ncause=no-public-lease\n' "$(date +%s)" > observation
"$KIT/dockit-delivery-record.sh" evidence --file observation --project "$PWD" --contract docs/llm/delivery/remote.contract >/dev/null
if sh scripts/entrypoint.sh > "$n/result" 2>&1; then exit 1; fi
test ! -e mutation.calls
grep -q 'PREREQUISITE: failed ingress' "$n/result"
NEGATIVE
chmod +x "$R/scripts/negative.sh"
git -C "$R" init -q; git -C "$R" config user.name Fixture; git -C "$R" config user.email fixture@example.invalid
git -C "$R" add .; git -C "$R" commit -qm fixture
fixture_base=$(git -C "$R" rev-parse HEAD)
entry() { (cd "$R" && sh scripts/entrypoint.sh); }
reproduce_unguarded() { (cd "$R" && DOCKIT_REPRO_UNGUARDED=1 sh scripts/entrypoint.sh); test ! -e "$R/mutation.calls"; }
no 'original late-prerequisite reproducer really mutates without the guard' reproduce_unguarded
rm -f "$R/mutation.calls"
ok 'register committed declaration' record init
no 'missing prerequisite blocks actual entrypoint' entry
printf 'prerequisite=ingress\nenvironment=development\nobserved_at=%s\nstatus=pass\ncause=lease-restored\n' "$(date +%s)" > "$R/observation"
record evidence --file observation >/dev/null
no 'one passing prerequisite cannot hide a missing second prerequisite' entry
no 'finish zero without a reservation is an invalid transition' record finish --attempt 0 --result success --recovered yes
ok 'refused entrypoint performed zero mutations' test ! -e "$R/mutation.calls"
ok 'record failed real dependency observation' probe fail no-public-lease
no 'failed ingress blocks before any peer/server call' entry
ok 'no mutations after failed ingress' test ! -e "$R/mutation.calls"
ok 'negative integration artifact really runs the same entrypoint' record integration
ok 'record exact candidate review' record review --verdict approved --blockers 0 --file review.md
ok 'record restored public ingress' probe pass lease-restored
ok 'fresh prerequisites and review allow readiness' check
printf changed > "$R/scripts/empty-input"
no 'extra binding drift invalidates exact candidate approval' check
: > "$R/scripts/empty-input"
printf 'prerequisite=dns\nenvironment=development\nobserved_at=1\nstatus=pass\ncause=dns-ready\n' > "$R/dns-observation"
record evidence --file dns-observation >/dev/null
no 'one passing prerequisite cannot hide a stale second prerequisite' check
probe pass lease-restored >/dev/null
ok 'both fresh prerequisites restore readiness' check
first=$(record begin)
no 'parallel/new begin cannot reuse an in-flight reservation' record begin
cp "$R/$C" "$TMP/pending-contract"
printf '\n# declaration maintenance while recovery is pending\n' >> "$R/$C"
git -C "$R" add "$C"; git -C "$R" commit -qm 'declaration changed during reserved attempt'
pending_checkpoint=$(find "$R/.git/.dockit/delivery" -name checkpoint -type f)
rm "$pending_checkpoint"
ok 'repair survives declaration drift while attempt remains pending' record repair
ok 'repeated repair is idempotent after checkpoint reconstruction' record repair
no 'repaired checkpoint never grants ordinary readiness during recovery' check
ok 'failure can close with incomplete recovery after declaration edit'  record finish --attempt "$first" --result failure --recovered no
no 'unfinished recovery blocks ordinary work' check
ok 'recovery path available regardless of ordinary checks' check --recovery
ok 'attributed recovery closes pending attempt despite declaration edit' record recovered --attempt "$first" --file recovery.md
cp "$TMP/pending-contract" "$R/$C"
git -C "$R" add "$C"; git -C "$R" commit -qm 'restore original declaration after recovery'
ok 'new timestamp for unchanged evidence is recorded' probe pass lease-restored
record evidence --file dns-observation >/dev/null
no 'same failed causes remain equivalent after timestamp and observation-order changes' record begin
ok 'changed causal prerequisite is recorded' probe pass route-corrected
second=$(record begin)
ok 'changed evidence allowed next attempt' test "$second" -gt "$first"
ok 'second failed attempt with successful cleanup' record finish --attempt "$second" --result failure --recovered yes
ok 'another changed cause does not reset work budget' probe pass provider-corrected
no 'exhausted budget blocks ordinary begin' record begin
ok 'recovery still available after exhausted budget' check --recovery
ok 'bounded reassessment grants explicit new allowances' record reassess --file reassessment.md --attempts 1 --reviews 1 --owner fixture-owner
ok 'one successful user-path attempt through actual entrypoint' entry
ok 'exactly one real mutation occurred' test "$(wc -l < "$R/mutation.calls" | tr -d ' ')" = 1
no 'allowance consumed; not silently reset by successful attempt' record begin
ok 'review records supported unresolved finding' record review --verdict changes --blockers 1 --file review.md
ok 'attempt allowance cannot waive security finding' record reassess --file reassessment.md --attempts 1 --reviews 1 --owner fixture-owner
no 'unresolved finding prevents readiness' check
no 'approval with a nonzero blocker count rejected' record review --verdict approved --blockers 1 --file review.md
ok 'explicit reviewed closure restores approval' record review --verdict approved --blockers 0 --file review.md
ok 'fresh observed cause supplied' probe pass repaired-again
ok 'ready only after finding closure' check
no 'review allowance itself cannot be exceeded' record review --verdict approved --blockers 0 --file review.md
# Inherited state survives a second process and an exact committed clone.
ok 'separate process resumes existing counters' check
cp "$R/docs/llm/delivery/remote.log" "$TMP/saved-log"
head -n 1 "$TMP/saved-log" > "$R/docs/llm/delivery/remote.log"
no 'uncommitted journal truncation detected' check
ok 'recovery remains available with corrupt journal' check --recovery
cp "$TMP/saved-log" "$R/docs/llm/delivery/remote.log"
rm "$R/docs/llm/delivery/remote.log"
no 'missing journal not treated as zero attempts' record begin
no 'init cannot reset a missing journal' record init
cp "$TMP/saved-log" "$R/docs/llm/delivery/remote.log"
git -C "$R" add docs/llm/delivery/remote.log; git -C "$R" commit -qm 'retain attempt evidence'
git clone -q --no-hardlinks "$R" "$TMP/clone"
original=$R; R=$TMP/clone
no 'fresh clone does not silently drop checkpoint requirement' check
ok 'explicit restoration accepts exact committed history' record restore
no 'clone must rerun integration when local artifact is absent' check
ok 'cloned adopter reproduces negative integration' record integration
ok 'restored clone retains legitimate readiness' check
R=$original
# Stale/future/wrong-context observations are not refreshed by append time.
ok 'record old observation without pretending it is fresh' probe pass repaired-again 1
no 'stale observation blocks actual entrypoint' entry
no 'future observation rejected' probe pass repaired-again "$(( $(date +%s) + 120 ))"
probe pass repaired-again >/dev/null
sed 's/environment=development/environment=production/' "$R/observation" > "$R/wrong-observation"
no 'wrong-environment observation rejected' record evidence --file wrong-observation
# Candidate review/integration cannot survive implementation-byte drift.
printf '\n# changed implementation\n' >> "$R/scripts/entrypoint.sh"
no 'changed entrypoint invalidates old evidence/review/integration' check
probe pass repaired-again >/dev/null
no 'fresh evidence alone cannot approve changed candidate' check
git -C "$R" checkout -- scripts/entrypoint.sh
# Malformed config and symlinks fail closed rather than being sourced.
cp "$R/$C" "$TMP/contract"
printf 'unexpected=value\n' >> "$R/$C"
no 'unknown config field rejected' check
cp "$TMP/contract" "$R/$C"
mv "$R/observation" "$R/real-observation"; ln -s real-observation "$R/observation"
no 'symlink evidence rejected' record evidence --file observation
# Exercise causal history, concurrency, retained transactions and clone identity.
R=$TMP/clone
ok 'explicit allowance does not reset cumulative counters' record reassess --file reassessment.md --attempts 5 --reviews 2 --owner fixture-owner
probe pass cause-A >/dev/null
aba_first=$(record begin); record finish --attempt "$aba_first" --result failure --recovered yes >/dev/null
probe pass cause-B >/dev/null
aba_second=$(record begin); record finish --attempt "$aba_second" --result failure --recovered yes >/dev/null
probe pass cause-A >/dev/null
no 'A to B to A cannot evade failed-cause memory' record begin
cp "$OUT" "$TMP/aba-output"
ok 'A-B-A refusal identifies causal equivalence' grep -q 'equivalent failed attempt' "$TMP/aba-output"
probe pass cause-C >/dev/null
success_id=$(record begin); record finish --attempt "$success_id" --result success --recovered yes >/dev/null
probe pass cause-A >/dev/null
no 'successful intervening attempt does not erase earlier failed cause' record begin
probe pass cause-D >/dev/null
(record begin > "$TMP/concurrent-1" 2>&1) & pid1=$!
(record begin > "$TMP/concurrent-2" 2>&1) & pid2=$!
rc1=0; wait "$pid1" || rc1=$?
rc2=0; wait "$pid2" || rc2=$?
if [ "$rc1" = 0 ] && [ "$rc2" != 0 ]; then reserved=$(cat "$TMP/concurrent-1");
elif [ "$rc2" = 0 ] && [ "$rc1" != 0 ]; then reserved=$(cat "$TMP/concurrent-2");
else echo 'FAIL: simultaneous begins did not produce exactly one reservation'; exit 1; fi
ok 'simultaneous processes reserve exactly one attempt' record finish --attempt "$reserved" --result failure --recovered yes
store=$(find "$R/.git/.dockit/delivery" -name identity -type f); store=${store%/identity}
cp "$R/docs/llm/delivery/remote.log" "$TMP/before-transaction"
probe pass cause-E >/dev/null
cp "$R/docs/llm/delivery/remote.log" "$store/pending"
cp "$TMP/before-transaction" "$store/last-good"
no 'retained interrupted transaction blocks ordinary work' check
ok 'repair completes retained append without dropping history' record repair
ok 'repaired history retains legitimate readiness' check
rm "$store/checkpoint"
no 'missing checkpoint blocks without resetting history' check
ok 'repair reconstructs missing checkpoint from identical retained bytes' record repair
ok 'checkpoint reconstruction preserves readiness' check
artifact=$(find "$store/artifacts" -type f | head -n 1)
mv "$artifact" "$TMP/retained-artifact"
no 'missing negative-test output invalidates integration status' check
mv "$TMP/retained-artifact" "$artifact"
mkdir "$store/lock"
no 'writer refuses an existing lock without deleting it' record evidence --file observation
ok 'contending writer preserves incumbent lock' test -d "$store/lock"
rmdir "$store/lock"
# Original work history remains visible even after an attempted path/name rename.
git -C "$R" add docs/llm/delivery/remote.log; git -C "$R" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm 'retain expanded history'
git clone -q --no-hardlinks "$R" "$TMP/renamed"
R=$TMP/renamed
sed 's/work=remote/work=renamed/' "$R/$C" > "$R/docs/llm/delivery/renamed.contract"
git -C "$R" add docs/llm/delivery/renamed.contract; git -C "$R" -c user.name=Fixture -c user.email=fixture@example.invalid commit -qm rename
C=docs/llm/delivery/renamed.contract
no 'fresh clone cannot rename work to reset outcome history' record init
cp "$OUT" "$TMP/rename-output"
ok 'rename refusal identifies historical outcome' grep -q 'historical outcome identity' "$TMP/rename-output"
R=$TMP/shallow; C=docs/llm/delivery/remote.contract
git clone -q --depth 1 "file://$original" "$R"
no 'shallow clone cannot claim complete continuity' record restore

# Independent short-TTL declaration: integration age is not probe age.
R=$TMP/ttl; mkdir "$R"
git -C "$original" archive "$fixture_base" | tar -x -C "$R"
sed 's/integration_max_age=86400/integration_max_age=5/' "$R/$C" > "$TMP/ttl-contract"; cp "$TMP/ttl-contract" "$R/$C"
git -C "$R" init -q; git -C "$R" config user.name Fixture; git -C "$R" config user.email fixture@example.invalid
git -C "$R" add .; git -C "$R" commit -qm 'short integration lifetime'
record init >/dev/null; probe pass ttl-case >/dev/null
record review --verdict approved --blockers 0 --file review.md >/dev/null
record integration >/dev/null
ok 'explicit independent integration TTL initially allows readiness' check
sleep 6
no 'expired integration receipt blocks with still-fresh probe evidence' check
cp "$OUT" "$TMP/ttl-output"
ok 'expired receipt reports integration rather than probe failure' grep -q 'INTEGRATION: stale' "$TMP/ttl-output"
sed 's/integration_max_age=5/integration_max_age=0/' "$R/$C" > "$TMP/invalid-age"; cp "$TMP/invalid-age" "$R/$C"
no 'invalid explicit integration TTL rejected' check
cp "$OUT" "$TMP/invalid-ttl-output"
ok 'invalid TTL refusal names the range guard' grep -q 'integration_max_age must be' "$TMP/invalid-ttl-output"

printf '\nDelivery tests: %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
