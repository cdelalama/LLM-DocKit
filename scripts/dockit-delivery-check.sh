#!/bin/sh
set -eu
umask 077
LIB_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$LIB_DIR/dockit-delivery-lib.sh"
ROOT=.; CONTRACT=; ACTION=check; RECOVERY=false
while [ $# -gt 0 ]; do
 case "$1" in
 --project) ROOT=${2:?}; shift 2;;
 --contract) CONTRACT=${2:?}; shift 2;;
 --recovery) RECOVERY=true; shift;;
 --help) echo 'Usage: dockit-delivery-check.sh --project PATH --contract docs/llm/delivery/WORK.contract [--recovery]'; exit 0;;
 *) die "unknown option: $1";;
 esac
done
if [ "$RECOVERY" = true ]; then
 echo 'RECOVERY_ALLOWED: ordinary delivery checks do not authorize or prevent project-owned recovery'; exit 0
fi
setup
checkpoint
readiness
printf 'READY: candidate=%s attempts=%s/%s reviews=%s/%s; declared outcome=%s; real acceptance is project-owned\n' "$CANDIDATE" "$(field attempts)" "$(field attempt_limit)" "$(field reviews)" "$(field review_limit)" "$(value "$ROOT/$CONTRACT" outcome)"
