# Disposable runtime lifecycle

Authority: Carlos, 2026-11-20; D-033. Applies to every adopted project when
creating test containers, temporary readers, clones or snapshots. A Dossier is a
curated project view and durable records; its helper container is not the record.
Retaining evidence does not require retaining successful disposable runtimes.

## Validation processes and temporary files

Each hook or command owns its disposable children and scratch files. Prefer
streaming and a single explicit closeout. An ordinary edit must not start a
history scan. Run the full validator at the established closeout and propagate
its verdict. A timeout, cancellation or missing result leaves the check incomplete.

Before adding or enabling a producer, test success, failure, cancellation and
loss of its parent on each supported host. Verify that the run has no surviving
children or scratch files after each test. Concurrent sessions and linked
worktrees must preserve each other's work. When the OS cannot guarantee cleanup
after a crash, retain the exact run identity for reconciliation before a retry.
Reuse existing evidence for a normal hook; avoid a persistent receipt per edit.
If ownership is ambiguous, report the residue and suspend that producer.
Cleanup may remove only verified disposable resources of that run. Preserve
user files, active baselines, backups, review evidence and unknown objects.

Session startup can retire empty expired slot directories. All slots containing state remain available for resume and accumulate in the
worktree Git directory under .dockit/session-baselines until session-end
evidence is available. Startup skips their contents without launching a process.

Existing adopters should remove only the DocKit history reminder from their
project, local and user Write/Edit hook settings. Select the command running
dockit-validate-session.sh with both handoff-date and history-entry. Remove
only its hook object and drop an enclosing array only if empty. Check
an edit burst and a deliberately failing explicit closeout on the actual host.
A source change alone cannot establish host cancellation or retirement.

## Stop process ownership

The Claude Stop hook invokes `scripts/dockit-session-gate.sh --stop` through
Git Bash/POSIX sh and uses `scripts/dockit-stop.py` as the launcher. Python 3
must be installed as `python` on native Windows or `python3` on POSIX.
Claude Code 2.1.295+ is required for `onFailure: block`. A startup failure
blocks the hook. The validation worker inherits the selected Python executable.

Each call has an eight-second deadline inside the ten-second hook deadline.
POSIX uses a private session/process group and a guardian pipe. Windows enrolls
the launcher in a kill-on-close Job Object before creating validation workers
and watches the caller through Git Bash forwarding processes. Completion,
client death and timeout retire the owned validation family. These guards do
not delete project files or enumerate other running validation sessions.
The internal `--guarded-stop-worker` mode belongs to this launcher.

The real validator retains document failures and Stop recursion protection.
Explicit manual validation remains available without the short Stop deadline.
A timeout reports incomplete validation and retires the family. It must not be
interpreted as a passing documentation check.

Qualification uses `scripts/test-stop-lifecycle.py` for abrupt launcher/client
loss, deadline, unrelated concurrent session survival and failing-document
behavior. The native client probe additionally observed all 47 processes in its
parent Job Object retired after abrupt client exit. That test used a local API
fixture with the installed Claude client. Adopter acceptance still requires
checking the installed hooks and interpreter on that host.

Trace uses `scripts/dockit-trace-check.py` adjacent to the validator.
It resolves Git objects and metadata in batches, then checks the full history.
Idea continuity owns one Git object reader per referenced repository during
validation, reaps it in a finally block, and retains at most 256 immutable
historical texts totaling 16 MiB per checker. These caches exist only in memory
during the invocation. Worktree and mutable HEAD reads use the normal route.

Adoption of this follow-up includes both helpers and explicitly updating the
idea index's validator_sha256 to the exact installed idea helper. Verify full
Stop on the actual adopted repository before reenabling it. Synthetic fixtures
alone did not reveal the cost of large real histories in version 4.21.5.

## Required execution contract

Before creation, persist an external private run manifest with project, task,
run ID, host, purpose, expected data/evidence destinations and cleanup disposition.
Labels supplement that manifest. Use a unique idempotent run ID and record the
creation intent before calling the engine. Reconcile interrupted/unknown attempts
before retrying. Owner admission and runtime authority remain separate.

The producer must check the host owner's creation hold and allocation health
before creating objects. A health failure or failed previous cleanup stops that
producer. Do not create a container per read when a qualified existing reader or
native tool can perform the same operation. A policy file alone is not a running
creation guard: each producer must adopt the reviewed ForgeOS runner contract or an independently
qualified equivalent. The new candidate runner has no qualified NAS/DEV profile
yet: use native tests or retain the task with its blocker while qualification is
pending. Do not fabricate host-health receipts. Existing accepted long-lived
services and unrelated CI jobs are not replaced by this rollout.

After execution, save exit/OOM state, image identity, necessary output, mount/data
disposition and hashes outside the runtime. Protect private command/log/inspect
content; commit only sanitized receipt references. Verify custody before cleanup.
If post-exit inspection is required, retain the container only until capture ends,
then remove the exact immutable ID without force or volume removal. With --rm,
collect required evidence before automatic removal and verify disappearance.
A successful test remains operationally incomplete until retirement readback.

A failure/debug hold needs owner, reason, finite UTC lease and next action.
Expiry means reconcile and report, not permission to delete unknown data. Preserve
unrelated production, bind sources, volumes, images, family data and historical
records. Runtime snapshots owned by Docker are retired through Docker, never
through direct ZFS destroy. Timeout means unknown outcome: stop and reconcile.

## Portable receipts and checks

One sanitized JSON per execution: docs/llm/runtime/<run-id>.json, schema 1.
Required keys: schema, run_id (matching filename), project, task, state.
States: none, active, held, retired, unknown. none requires a task-specific reason
and means that task created no disposable runtime; it is not a project exemption.
All other states require host, object_id and owner. Active/held/unknown require
reason, lease_until (UTC timestamp), next_action. Retired requires evidence
{reference, sha256}, retirement {observed_at, absent: true}. References are opaque
private receipt identifiers or repository-relative sanitized artifacts, never raw
logs, secret paths or credentials. Archived evidence is immutable outside Git.

python3 scripts/dockit-runtime.py --project . checks declared receipt shape and
leases; it does not contact hosts or prove that assertions match live state.
The session validator initially reports migration gaps/invalid receipts as WARN.
Use --strict for a blocking task closeout. Missing receipt directory means
coverage unknown, never PASS/no runtime. A newly creating producer must adopt
receipts and its execution guard before running. Legacy objects are inventoried
separately; no retroactive fabricated receipts or automatic expiry deletion.

## Ownership and rollout

DocKit owns this common contract and portable checker; ForgeOS owns producer
execution/evidence capture; Home Infra owns host health and bounded cleanup;
Sentinel observes orphan/unlabelled objects, expired holds, removal failures and
metadata pressure without deleting. Host reconciliation is needed to discover
undeclared runtimes, which a document checker cannot find.

Roll out to every admitted project, first one clean pilot then exact selective
sync. Record installed hashes, validation, publication and exceptions separately.
Preserve dirty/non-default checkouts and historical evidence. Revert the scoped
section/helper through ordinary reviewed commits if needed; no source rollback
restores deleted runtime data. Fleet policy installation is not deployment of a
scheduler, nor a claim that all historical producers already use the contract.
