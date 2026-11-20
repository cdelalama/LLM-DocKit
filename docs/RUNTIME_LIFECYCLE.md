# Disposable runtime lifecycle

Authority: Carlos, 2026-11-20; D-033. Applies to every adopted project when
creating test containers, temporary readers, clones or snapshots. A Dossier is a
curated project view and durable records; its helper container is not the record.
Retaining evidence does not require retaining successful disposable runtimes.

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
