# DF-058 implementation evidence - 2026-09-21

## Scope and acceptance

The operator authorized the complete causal-control source candidate, not the
superseded documentation-only release. Version 4.16.0 implements prerequisite
checks at opted-in mutation commands, continuity-checked attempt/review journals,
candidate-bound approval and executed integration receipts, bounded reassessment,
independent recovery, honest validation coverage and optional HANDOFF structure.
DocKit owns records/checks; projects own real probes, semantics and recovery;
ForgeOS retains runtime/authority. See D-023 and `docs/DELIVERY_CONTRACT.md`.

Source publication, local pilot and incident closure are separate. The selected
Riego pilot protects `scripts/smoke-container.sh --delivery-guard` on the local
Docker socket. Its outcome is usable local packaging acceptance: real source
builds, starts in a hardened networkless container, serves health and the Spanish
login page, shuts down and removes its resources. It does not prove gardener,
physical or off-LAN access and cannot close DF-058 / issue #1. The existing remote
roadmap and runtime remain separately owned and gated.

## Executor verification

- Final delivery behavior suite: 84 passed, zero failed.
- Validator regressions: 96 passed, zero failed, including actual generated
  scaffold and selective-sync consumer behavior.
- Source validation: seven checks run/passed, four inapplicable checks explicitly
  skipped; version sync 10/10 at 4.16.0. HANDOFF is below the 200-line threshold.
- ShellCheck warning level passes the new delivery helpers/tests with SC1007
  (valid empty CDPATH assignment), SC1091 (dynamic shared source) and SC2034
  (cross-script shared variables) excluded explicitly.
- Adopter negative integration: actual entrypoint, absent Docker, zero mutation
  or cleanup calls. Candidate must match committed input bytes and the declared
  bindings must cover all tracked source/build inputs, including VERSION.
- Adopter fault controls: actual entrypoint under mocked Docker refuses equivalent
  retry, honors a synthetic unresolved review blocker, retains incomplete cleanup,
  permits recovery after exhaustion and preserves counts across processes.
  Synthetic fixture reviews are not independent approvals or real security findings.
- Real local packaging acceptance: PASS on one actual attempt and one recorded
  independent approval. Candidate f425279fbeebcab0a8249ceab6ed2456c2ee0e97,
  local source snapshot 9b4a3209a8347bb921d764324e3ddf07072132f0. The container
  passed build/native dependency checks, health/version, Spanish login, non-root,
  read-only/networkless isolation, DB modes and clean shutdown. Event 6 records
  attempt 5 as success/recovered=yes; fresh daemon reads confirm its exact owned
  container/image tag absent. Elapsed reservation-to-finish was 406 seconds;
  active labor versus dependency wait is not inferred. No second attempt ran.
  The retained actual journal/approval/acceptance live in the pilot repository.
  This is local packaging evidence, not remote/gardener acceptance.

Evidence was produced by the executor. The independent reviewer used Read/Glob/Grep
only; it did not run suites, compute hashes or independently verify Git identities.
Do not promote the executor's supplied identities into independently reproduced facts.

## Independent review provenance

Preferred exact `claude-fable-5-1`, high effort, returned direct quota exhaustion
(HTTP 429, no useful audit) in session 1ba32246-c5b9-4b1d-97ce-648fdb3d2605.
D-020 allowed exact `claude-opus-5[1m]`, high effort, in session
b0ae0593-d9c3-4f6c-a0eb-8cd4bda63baa. Initialization telemetry confirms the exact
requested model; assistant-message model metadata uses `claude-opus-5`.
No other model or subagent was used for the independent gate.

One contract review identified causal-set, clone identity, lock-time binding,
separate receipt TTL, retained-output, interpreter, prefix, lock metadata and
recovery-runbook issues. All supported issues were implemented; its padded-wc
arithmetic concern was rejected with the auditor's later explicit agreement.

The first implementation review found no remaining behavioral defect but required
multi-prerequisite, receipt-expiry and auxiliary-binding fixtures plus accurate
identity/isolation statements. Its closure gave **Source: GO** and **Pilot: GO**
for one local acceptance, with S1-S3 and P1-P3 recorded. Those narrow follow-ups
are implemented: idempotent repair across declaration drift, wider timing margin,
exact range assertion, bound VERSION, real-entrypoint failure/recovery tests and
actual HEAD/version metadata. The final bounded delta review returned **Source GO. Local-pilot GO.** Its exact
text is preserved in `DF058_OPUS_FINAL_REVIEW_2026-09-21.md` beside this record.
C1 identified that the separate synthetic control test must import the source tree
into a fresh fixture repository to remain rerunnable after real history is committed.
The executor applied that prescribed correction; it does not alter the bound
entrypoint/probe/negative test or authorize resetting real attempt history.
The executor also fixed empty valid auxiliary inputs, invalid finish-without-begin,
and recording recovery after a declaration edit. No supported disagreement remains.

Raw prompt/JSONL/test artifacts are retained locally under
`/tmp/dockit-df058-implementation-20260921/`; this dated document preserves the
portable findings, evidence limits and acceptance status. The current process
reviewed the not-yet-adopted kit itself; new journal budgets were exercised in the
pilot/fixtures, not falsely claimed as governing these prior development rounds.

## Selective distribution preview

A read-only selective dry run covered all 38 currently registered adopters and
seven selections each: the validator, four delivery implementation files, contract
guidance and the `delivery-evidence` managed section. It proposed 195 new and
69 updated items, with two intentional skips: MED and msgvault-lab have no managed
section markers as partial adopters. No project was mutated by that preview.
One existing adopter lacks an executable version-sync checker, so pre-sync
validation reported its existing absence instead of claiming a green baseline.

The machine-readable preview is `DF058_FLEET_PREVIEW_2026-09-21.json` beside this
record. Status labels in it describe proposed changes, never installed protection.
Installation is scripts-only until a project's actual entrypoint and current
negative integration evidence prove otherwise. Preserve local edits, partial
adoption, stricter rules and independent operational boundaries during rollout.
Full incident-remediation acceptance and broad entrypoint adoption remain open.

## Executor artifact digests

- `delivery-final.log` SHA-256: 529d0a91617d5c711a8be75079c0ccc07855a96f4c3942373a3f6fa904578899
- `validator-tests4.log` SHA-256: c1ef17419e3efb945b696fa796eb6afeb844a2080e2c2636f3651ab58126d277
- `pilot-real-container.log` SHA-256: 2729a103ee73d0d5c9b70cc1586562786b83fd8e51c11bb05fcec6f483b0168c
- `pilot-negative-final.log` SHA-256: 6b1500dc0f0f4fad5e1403543b92d3f81d03a49707756de80b656c071e7557e0
- `pilot-controls-final.log` SHA-256: 1e1535ce6ca777f938e329ab6e42642c1b420e86efe0e79de60d9d7fc833ae75

The actual adopter exposed generic `*.log` ignore rules hiding its journal from
ordinary status output. Its integration adds a scoped ignore exception and commits
the journal; the portable contract now requires that handoff check explicitly.
Local checkpoints preserve uncommitted events, but cannot transmit them to a clone.
