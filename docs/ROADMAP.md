# LLM-DocKit Roadmap

This roadmap is source-specific. Current work is in `docs/llm/HANDOFF.md`;
review provenance is in `docs/llm/REVIEWS.md`. The 4.16.0 source candidate preserves legacy behavior outside explicit opt-in.

## Implementation status - 2026-09-21

Steps 1-4 are implemented in the 4.16.0 source candidate with 84 delivery and
96 validator regressions passing. Step 5 has exact-model source GO, a separately
integrated Riego local packaging pilot with adverse cases passing, and a read-only
38-adopter selective-sync preview. Final local acceptance/publication are recorded
in `docs/archive/DF058_IMPLEMENTATION_2026-09-21.md`. This is not gardener/off-LAN
acceptance, full fleet protection or closure of issue #1; those gates remain real.

## Outcome and acceptance boundary

The operator rejected the earlier documentation-first plan as insufficient.
This replacement addresses the actual DF-058 failure: repeated expensive work
without proving prerequisites, bounded progress or the intended usable result.
The earlier Opus agreement is superseded as a scope decision, not erased.
The same exact Opus session accepted this replacement for planning after the
operator correction; its integrity conditions are incorporated below.

**The first accepted delivery must prove the complete loop in a real adopter:**
check decisive prerequisites before mutation, prevent equivalent evidence-free
retries, consolidate review, preserve recovery, and accept the actual user path.
The following steps are implementation increments of that delivery. Prerequisite
and retry controls are not deferred to a later optional release.

The source candidate is expected to be v4.16.0 with explicit project adoption
and legacy-compatible defaults. Source publication can enable a pilot, but it
is not acceptance of the incident remediation. No deployment, physical action,
source publication or fleet mutation is authorized by this planning document.

## 1. Specify the smallest contract and reproduce the failures

**Deliverables:** proposed `docs/DELIVERY_CONTRACT.md`, a narrow ownership
clarification in `docs/llm/DECISIONS.md`, and failure fixtures in
`scripts/test-validator.sh` before changing behavior.

- Define one bounded delivery outcome and its user-visible acceptance criterion.
  Reference existing risk/authority records, classifying infrastructure changes
  separately from the size of the application. Reuse existing project records;
  do not require a second set of manually maintained forms or per-chat ceremony.
- Limit the new schema to stable identity and fields exercised by the two real
  reproducers: late ingress and an equivalent retry without new evidence. Link
  existing candidate, review, authority and acceptance records instead of
  inventing new forms or speculative fields. Generated records supply counters.
- Failing-dependency identity belongs in the reviewed prerequisite declaration,
  not per-attempt output. Changing it is a visible declaration change requiring
  reassessment; a fresh equivalence key never grants a fresh budget.
- Specify continuity across sessions, candidate versions and packet renames,
  atomic updates/concurrent access, parser/version compatibility and secret-safe
  evidence. A lost or malformed ledger is not a new zero-attempt delivery.
  Check record continuity against committed history and retained append
  checkpoints; detect deletion, truncation and rewriting as well as malformed
  syntax. Preserve uncommitted-event continuity without requiring a product
  release per attempt. Do not claim tamper-proofing against an actor controlling
  all repository evidence. No new runtime service or generic workflow engine.
- DocKit owns portable record/check contracts. Adopter tooling owns real probes
  and invoking checks in its actual mutation entrypoint. ForgeOS owns live
  orchestration and authority. A document field or model verdict grants neither.
  Delivery must not wait for a future ForgeOS module. A checker failure governs
  only the opted-in project command exit path, not general chat/Stop/session
  authority. Label the usable-outcome criterion as declared and its acceptance
  as an attributed observation; DocKit cannot independently certify real use.
- Reproduce the reported unavailable-ingress and equivalent-retry failures,
  retaining the distinction between historical evidence and live observations.
  Keep DF-058 and issue #1 tied to the full problem; link existing DF-003/006/010
  and create independent records only for genuinely distinct uncovered defects.

**Exit:** executable adverse cases and a reviewed, bounded contract name the
real entrypoint to protect. An outcome cannot be satisfied by document cleanup.

## 2. Check decisive prerequisites at the actual mutation entrypoint

**Deliverables:** proposed `scripts/dockit-delivery-check.sh`, prerequisite
fixtures, and a project-owned integration into the pilot's existing deployment
or acceptance command. `LLM_START_HERE.md` describes that contract.

- The project runs its actual host/container/network/auth probes as applicable;
  the portable checker consumes bounded evidence and never contacts the NAS,
  changes networking or authorizes deployment itself.
- The entrypoint runs the checker immediately before the relevant mutation.
  Missing, failed, stale or wrong-environment evidence stops that command before
  side effects. Changed conditions/expired evidence require another probe.
- Stop/session hooks provide reminders and reporting; they are not the sole
  barrier for a prerequisite that must be checked before a mutation.
- Evidence provenance and project adapters have meaningful tests. A free-text
  assertion of viability is insufficient. State the limits of evidence
  verification; do not claim arbitrary real-world truth from a file validator.
- Existing operational authority and rollback requirements remain binding.
  A missing entrypoint integration means adoption is incomplete, even if the
  scripts were copied successfully. Untouched legacy projects keep their flow.
- Store the negative integration test as a rerunnable artifact in the adopter
  repository: bad prerequisite must produce zero mutation calls. Derive
  integrated/tested status from that artifact, matching code/config identity
  and a fresh recorded run, not an agent assertion. Absent/stale evidence means
  scripts-only or integration-unverified, never protected.

**Exit:** the unavailable-ingress case produces zero peer/server mutation calls,
retains the healthy runtime and reports the failed dependency and next remedy.

## 3. Make attempts and review progression mechanically accountable

**Deliverables:** a small record-writing helper (proposed
`scripts/dockit-delivery-record.sh`), durable attempt/review records under the
step-1 contract, and enforcement in the same adopted project entrypoint.

- Derive counts from recorded events tied to stable outcome/dependency identity.
  New version, packet, peer, session or arbitrary identifier does not erase
  prior attempts. Missing/malformed history blocks ordinary continuation while
  preserving the separate recovery path.
- An equivalent retry requires genuinely changed causal evidence or documented
  redesign/reassessment within existing authority. New timestamps or a different
  digest alone do not qualify. Domain-specific evidence comparison belongs to
  the adapter; generic semantic equivalence is not claimed.
- Initial two failed substantive attempts per hypothesis and two substantive
  review rounds are provisional configurable reassessment thresholds. Crossing
  them stops ordinary repetition and produces a bounded next decision, never
  automatic approval. Record the hypothesis, evidence, owner and bound of any
  justified extension; ask the operator only when existing authority is exceeded.
- Review one releasable candidate, batch supported findings and review corrected
  deltas in the same D-020 session where practical. Check candidate identity
  mechanically. Keep non-blocking deferred findings explicit; cosmetic changes
  do not automatically restart the full review. Supported security findings
  cannot be dismissed merely by their severity label or exhausted budget.
- Recovery remains available after all delivery budgets expire. Incomplete
  recovery prevents a fresh ordinary attempt; it is not permission to abandon
  cleanup. Apply the existing D-020 fallback, not a new model-selection policy.

**Exit:** renamed equivalent retries are refused, corrected causal evidence
permits the next authorized attempt, resumes retain counts, and recovery works
when the ordinary delivery budget is exhausted.

## 4. Supply a clear current state in the same candidate

**Deliverables:** `scripts/dockit-validate-session.sh`, the source HANDOFF and
linked archive, source-local config/Trace/CI, init compatibility and guidance.

- Report source completion, deployed revision and actually usable outcome as
  separate facts, followed by the real blocker/next action. A source GO or a
  successful rollback never stands in for user acceptance.
- Keep HANDOFF short, preserve history, reconcile current restrictions and
  derive delivery summaries from the same evidence record where possible.
- Expose checked/skipped coverage honestly in human output and additive JSON,
  preserving existing status/exit compatibility. Count before quiet filtering
  and scope totals to selected checks.
- Keep the agreed default size-only WARN above a provisional configurable 200
  lines. Content checks require explicit active scope, bounded canonical-title
  aliases and current-version fields. History/fences/quotes do not count as
  present-state contradictions. New content failures require strict opt-in;
  new delivery gates apply only to explicitly integrated project entrypoints.
- Exercise applicable Trace/content checks in DocKit itself, supply an honest
  activation date and anchor/footer evidence, and configure full CI Git history.
  Preserve legitimate source exemptions and inapplicable-check skips.
- Prevent source-only archives/configuration from leaking into freshly generated
  targets. Preserve archives in the source and existing adopters. Test actual
  init and selective sync, rather than relying solely on unit fixtures.

**Exit:** an operator can identify what works, why delivery is blocked, what the
last attempt learned and what happens next, without reconstructing chronology.

## 5. Review, prove the complete flow in a real pilot, then distribute

**Deliverables:** one exact reviewed source candidate; one integrated clean
registered adopter; an acceptance record; then a selective rollout ledger.

- Run the relevant regression matrix, legacy/strict configurations, source
  validation, version sync, init/sync and consumer compatibility tests. Use the
  existing version-bump tool. Review the exact candidate independently under
  D-020; planning consensus never substitutes for source review. The new
  mechanical limits do not govern their own unimplemented candidate. Review
  under the current process; new limit enforcement starts at the wired pilot.
- Source publication and real pilot acceptance are distinct. Select a ready
  adopter; Riego may participate when stable, otherwise use a comparable clean
  application. Neither delivery waits on the other as a project prerequisite.
- Exercise the actual project entrypoint with safe adverse cases, then perform
  the real intended user-path acceptance under the existing authorization:
  1. Failed/stale prerequisite prevents mutation.
  2. Renamed equivalent retry without new evidence is refused.
  3. A genuinely corrected prerequisite allows the next authorized attempt.
  4. An unresolved security finding still blocks readiness.
  5. Failure recovers safely after the normal delivery budget is exhausted.
  6. A resumed session preserves attempt and review continuity.
  7. The intended user can actually use the result; physical/off-LAN checks
     remain real observations where required, not synthetic substitutes.
- Record actual attempts without new evidence, substantive review rounds,
  observed useful outcome and false positives. Measure active work/external wait
  prospectively; never infer historic hours from commit counts.
- After acceptance, selectively distribute under D-021/D-022. Distinguish
  scripts-only delivery from entrypoint-integrated-and-tested adoption derived
  from the rerunnable integration evidence, as well
  as conflict/excluded cases. Preserve dirty worktrees and stricter local rules;
  selective sync never proves full-template currency. Installation alone does
  not prove that a project's mutation path is protected.

**Exit:** complete pilot evidence for the original failure modes, followed by
attributable downstream adoption. Keep every unsupported closure or remaining
blocker explicit; do not close issue #1 on the strength of source publication,
a shorter HANDOFF or copied scripts. No promise of zero future mistakes or
unmeasured percentage improvement is made.

## Retained fleet context and unrelated follow-up

The following is the September 12 rollout record, not a fresh fleet inventory.
Maintain its publication and custody boundaries until reverified.

- `docs/FLEET_ROLLOUT_2026-09-12.md` is the exact ledger for 49 primary Git
  repositories, 38 registered adopters, 35 published policy revisions, one
  committed third-party overlay, and two protected no-remote worktrees.
- All evidenced existing DocKit adopters now have `.dockit-enabled`, including
  Irrigation Portal and the late-discovered PiHA-Deployer omission.
- Preserve the Fable-preferred, exact-Opus-on-recorded-quota policy and the
  explicit exceptions; do not treat this selected-section convergence as full
  template currency.
- New registration uses D-022's evidence boundary. Stale sync state or a
  directory name alone is not authority to enroll a repository.
- v4.15.0 makes that legacy-registration path executable through
  `--untracked-existing-adoption`, fixes UTC Trace comparison under DF-057,
  and records Travel Ledger's corrected 0.9.14 governance evidence.

Plan full-template upgrades separately, based on each adopter's own state.

- Use `dockit-sync-check.sh` and per-project dry runs to distinguish complete
  template drift from the already-delivered policy section.
- Before a full sync carries the DF-057 validator correction, repair the false
  UTC Trace-anchor timestamps currently detected in `buzz-lab` and
  `infra-portal`; a red gate must be fixed from Git evidence, never by reverting
  the validator.
- Keep `cambio-claro` and `juiced` local until their broader dirty worktrees and
  lack of remotes have an independently valid publication path.
- Keep `claude-quest` as a local governance overlay unless an operator-owned
  fork or other legitimate publication target is established.
- MED's active dirty checkout lacks the selected section and its marker pair;
  that local exception remains explicit even though its separate authoritative
  policy revision is published.
- Repositories with a stricter local model rule keep it until the operator
  explicitly supersedes that rule in the project.

## Other later candidates

Promote semantic checks only when they are opt-in, project-configured, and
backed by real downstream evidence.

Candidates include forbidden-token policy checks, prose-version drift,
doc-freshness, stronger review metadata, and stricter release modes. They
should not become fleet defaults until the false-positive shape is known.

## Out Of Scope

Do not implement consensus/runtime orchestration, LMConsole, ProtocolEngine,
VisualWorkbench, WorkEpisode, AuthorityEngine, or live multi-LLM routing in
LLM-DocKit.

The boundary is:

- LLM-DocKit: scaffold/documentation substrate, Trace, validators, hooks,
  sync, and init.
- ForgeOS: live operator runtime, LMConsole, ProtocolEngine, workbench, and
  orchestration.
- `llm-council`: curated deliberation archive/corpus, examples, fixtures, and
  lessons.
