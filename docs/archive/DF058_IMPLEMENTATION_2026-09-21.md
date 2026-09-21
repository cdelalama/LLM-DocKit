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
- Real local packaging acceptance: in progress after final independent delta GO; one actual attempt reserved.

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
