# Reviews

## 2026-09-25 - DocKit Dossier self-adoption, 4.17.0

Pilot receipt: real L1 local:42ac9f94606e4c6a82bea3d7cb8fb2a39b3cf4694b6b14021c330606eaa22025; retry/no_change,
actual clone/worktree, private modes and exact export/Trace pass. See the owning
runbook for capture ID, source anchors, registry evidence and backup limits.
Committed source tree after approved review receipt: b5ba4d1fd3bad8a58a7c615d42a49fa7b6029496.
Delta from reviewed tree: docs/llm/HANDOFF.md, docs/llm/REVIEWS.md only.
Further finalization remains limited to the four approved receipt files. No
code/config or version marker changes followed the reviewed candidate.

Exact claude-opus-5-5 at high effort returned SOURCE/LOCAL-CAPTURE GO with no
blockers. Effective modelUsage verified; session 0c11263b-e1df-4acb-9892-dc8aa799d80c.
Read-only invocation used --restricted --permission-mode dontAsk,
--tools Read,Glob,Grep --allowedTools Read,Glob,Grep, strict empty MCP and
settings disableAllHooks=true. No independent shell/test/hash execution claimed.
Reviewed candidate tree: aa886dacec58b63558fd297200e0b42effdf6074 (tree object, not a commit).

Executor evidence: 96 validator tests, inert discovery, 15 shared-tool synthetic
checks, 10 version targets, 7 session checks and 4 explicit skips. Registered
llm-dockit identity matches the supplied Home Infra registry projection.
The source init must exclude the declaration/runbook; its regression passes.

Approval covers source and this project's manual offline capture only. Commit
before capture; pin all sources; retain private native history; record actual
retry/no_change/clone/worktree/export evidence. The reader remains unavailable.
Receipt-only finalization in HANDOFF/HISTORY/REVIEWS/DOSSIER is approved; code,
configuration and version changes reopen review. Final source tests and CI must
pass, with unchanged main base 4866b59 before publication. Minor non-blocking
notes: generated STRUCTURE remains a customizable template with source pointers;
discovery test uses explicit sh; final handoff adds the new decision references.

## 2026-09-23 - Selective fleet rollout and 4.16.3 source publication

Status: SOURCE GO and ROLLOUT GO after five same-session rounds; source publication only.
Exact model: claude-opus-5-5, requested effort high, CLI 2.1.280.
All five completed rounds returned modelUsage with that exact model. Auditor session:
e06df549-3d43-4283-90a3-4f1833f7af04. Read-only tools: Read, Glob, Grep;
restricted mode, dontAsk, strict empty MCP configuration. Invocation selected
`--model claude-opus-5-5 --effort high` explicitly; resumes use the same session.
The initial --bare launch did not use OAuth and returned not-logged-in before
any model request; the normal restricted invocation authenticated successfully.

Initial review closed seven blockers after preserving local controls, clarifying
fresh Riego candidate evidence, explicit global policy authority, and publication
boundaries. Second review accepted the 36 ordinary candidates conditionally,
held Vaultwarden for its two-line manifest grammar and requested moving the source
HISTORY entry outside the example fence. Those fixes are now applied. Final exact-model review cleared source tree
9c5ec8d1772279274c5b59f1d460ac4d572fedfe and corrected Vaultwarden.
The two local side branches were cleared conditional on deleting only the stray
unpublished 0.1.2 changelog blocks; that exact deletion was verified.
Metadata-only receipt finalization is explicitly accepted without another round.
MED D-045 is an inherited default superseded by the operator-wide instruction;
this interpretation was explicitly reconciled with the same auditor.

Reviewed source tree before the final docs delta: 5b7151add15fed065789ff8da427bf1c89bb8a67
(tree object, not a commit). Packet location: /tmp/dockit-fleet-20260923.
Source tests: 84 delivery, 96 validator PASS. Local Plaud extensions: 38 PASS;
PiHA component adapter: positive and two negative cases PASS. All 38 adopter
version/session checks pass; 35 applicable pre-commit scripts pass. Two projects
have no hook script; convergence integration is explicitly deferred.
Riego initial full suite: 473 PASS and three checkout-mode failures, then all 15
affected tests PASS after restoring tracked 0755 modes; build and hygiene PASS.
All command outputs are executor evidence, not independently reproduced by Opus.

Source CI runs 35928204596 and 35928579232 exposed opposite-day synthetic
PR merge timestamps (+0200 versus UTC). Changing the document date simply
inverted the mismatch. The bounded CI correction checks out the exact authored
pull-request head SHA, matching the independently reviewed candidate; its
ordinary authored UTC commit date agrees with the source receipts. Full Git
history and every validation/test step remain enabled. The current hook mechanically requires a version bump for this workflow path,
so the correction is versioned as 4.16.3 without bypassing the hook. Fourth bounded review returned GO for source tree
3ac1c7cdf40d519dee3e2ac5b106ad1080fb87a0 and Riego tree
a27e1b36c9124ed133bfc9b41bb51368de8a9d6d. Both clean-commit Riego
fixtures must pass before publication; source CI must pass and its base remain
unchanged before merge. Receipt-only relabelling to 4.16.3 is approved.
The real host's low-storage refusal remains valid; only synthetic fixture
storage is mocked. The underlying validator timezone issue is a follow-up.

Fifth bounded review covers the devenv 0.14.7 ShellCheck adaptation only;
its reviewed/final trees and receipt delta are in the durable fleet ledger.
Source PR #4 CI passed; its base remained unchanged and merged tree matched
the reviewed candidate plus approved receipts. Both Riego clean-commit fixtures
and all four hosted jobs passed. The final ledger records actual publication
and distinct project CI failures; no universal green-CI claim is made.

Publication remains source-only, fast-forward and scoped. Dirty primary worktrees
and the old convergence checkout are not modified; side refs/patches carry their
pending adoption. No operational, deployment or end-user acceptance is claimed.


## 2026-09-23 - Opus 5.5 default policy review

**Status:** final bounded delta GO, 2026-09-23, exact claude-opus-5-5.
Third round explicitly selected the exact model and high effort, using the same
read-only flags. Returned modelUsage confirms the model. N1 populated/local-date
release notes and N2 durable provenance passed; no scope blockers remain.
Final reviewed candidate trees (non-commit objects):
- LLM-DocKit-opus-default: 5d9c33b85316a0ce4ca3c78aa8064542f0d196cd
- forgeos-opus-default: 2c8f82d22a8877728920fafaa118cb9cff4fbc72
Final validation-packet SHA-256: 16787b121a398f4fe3e1ecab757192412c79580667eb863bc29f3bd88e75d1b7

- Model provenance: returned modelUsage claude-opus-5-5 in both rounds; effort
  explicitly requested as high. Reasoning-budget behavior is not inferred.
- CLI: 2.1.280 on dev-vm. Tools disabled, strict empty MCP configuration,
  hooks disabled for the bounded review, no session persistence.
- Round 1 invocation: `claude -p --effort high --output-format json` plus the
  read-only isolation flags. No --model flag: the saved user default was exercised.
- Round 2 invocation: same isolation, explicit `--model claude-opus-5-5 --effort high`.
- The first packet omitted some staged version files; the second supplied the
  complete diff and actual validator output. Actual version files were present.
- Round 1: NO-GO on scope wording, instruction/enforcement distinction and
  missing version evidence. Round 2 confirms those resolved, then requires
  populated/local-date changelogs and this durable review record.
- Executor verified both remaining fixes: dated nonempty release notes in each
  repo and model/effort/command/tree/validation evidence here. The final bounded
  delta review above closes those findings after the corrections were inspected.

Round 1 candidate trees (non-commit objects):
- LLM-DocKit-opus-default: 0a17f2455aad7a3026cb8126543e8c1ce2fe1e3a
- forgeos-opus-default: 69171e9c8aa97f79e4a34df5f4a70aed95266e34

Round 2 candidate trees (non-commit objects):
- LLM-DocKit-opus-default: cc69fb2d8d858921059c46f377b14b46a7f9c510
- forgeos-opus-default: 2321f1c34a16e6b702d289ed3cc2cd3410e681b0

Validation: DocKit 7 passed / 4 legitimate skips; ForgeOS 10 passed;
version sync 10/12 targets; diff whitespace checks. Dates use Europe/Paris
(operator date 2026-09-23 while the VM UTC date was still 2026-09-22).


Audit trail of substantive reviews, audits, and arbitrated decisions in this
repo. Each entry should capture the **causal reasoning** that produced a
decision or verdict, not the transcript of the deliberation.

LLM-DocKit provides this file as a durable registry artifact. It no longer owns
the consensus/runtime protocol that may produce entries here; ForgeOS owns the
live orchestration runtime and `llm-council` owns the curated deliberation
archive/corpus. Historical entries may still reference the archived
`docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md`, but that proposal is lineage, not
the active normative source for new work.

---

## 2026-09-21 - DF-058 complete source controls and local pilot

**Status: SOURCE GO and LOCAL-PILOT GO; incident acceptance remains open.**
The operator's implementation GO covers the corrected complete source scope.
Exact preferred `claude-fable-5-1` high returned quota exhaustion (HTTP 429, no
useful review) in session `1ba32246-c5b9-4b1d-97ce-648fdb3d2605`.
D-020 fallback used exact `claude-opus-5[1m]` high in the same session
`b0ae0593-d9c3-4f6c-a0eb-8cd4bda63baa` for one contract review and three
implementation/delta rounds. Model initialization telemetry confirms the request;
assistant message metadata reports the underlying `claude-opus-5`. No other
review model or subagent was used.

The auditor had only Read/Glob/Grep, no shell. It inspected actual source and
accepted the narrow DocKit/adopter/ForgeOS boundary. It did not run tests, compute
hashes or independently verify Git identity. Executor-supplied code tree
ac30257291d1526e56286911c0bfde5fcd8fc08f and local pilot snapshot
9b4a3209a8347bb921d764324e3ddf07072132f0 are evidence inputs, not independent
reproductions. Later documentation records this verdict without claiming otherwise.

All supported core findings are closed: causal-set retention, identity across
clones, under-lock binding/clock, receipt TTL/artifacts, interpreter, committed
prefix/cache, missing-checkpoint recovery, coverage/isolation and exact binding.
The final S1-S3 and P1-P3 closures are in
`docs/archive/DF058_OPUS_FINAL_REVIEW_2026-09-21.md`; C1's synthetic-test
rerunnability correction was applied by the executor according to the review.
No supported issue is waived because a budget expired. A padded-wc arithmetic
concern was withdrawn by the auditor after the executor's counterargument.

Executor gates: delivery 84/84; validator 96/96; source seven checked/passed plus
four explicit legitimate skips; version 10/10. Riego adverse tests drive its real
entrypoint under mocked Docker, keeping synthetic review records clearly marked.
The one actual local networkless packaging attempt passed and is recorded in
`docs/archive/DF058_IMPLEMENTATION_2026-09-21.md`. It cannot establish gardener,
physical or off-LAN use or close DF-058 / issue #1. The 38-adopter selective preview
is read-only and confers no integration/protection status.

Reproducible review invocation (each prompt retained in the local evidence directory):
`claude --model 'claude-opus-5[1m]' --effort high --restricted --permission-mode dontAsk --tools Read,Glob,Grep --allowedTools Read,Glob,Grep --strict-mcp-config --mcp-config '{"mcpServers":{}}' --output-format stream-json --verbose --resume b0ae0593-d9c3-4f6c-a0eb-8cd4bda63baa -p <bounded-prompt>`.
The initial Opus call used `--session-id`; read access was limited to both audited
worktrees and `/tmp/dockit-df058-implementation-20260921`. Prompts, JSONL, direct
quota evidence and test logs remain there; the archive preserves portable outcomes.

## 2026-09-19 - Replacement roadmap after operator scope correction

**Status: AGREED FOR PLANNING with conditions incorporated; no source GO.**
Carlos rejected the first roadmap because it left prerequisite/retry controls
for later. The executor accepted the scope error and replaced the roadmap;
the earlier agreement below remains historical evidence. The deliverable now
covers the complete causal loop through a real integrated adopter pilot.

The executor resumed exact `claude-opus-5[1m]`, high effort, in the same session
`775e8c6d-1595-4089-a750-0c1c3d0c0cf4` under the already-recorded D-020 Fable
quota evidence. The round-2 restricted read-only command was reused with the
replacement prompt on stdin. Opus needed no additional file reads, made no
writes and assessed the proposal against the existing source baseline and
prior discussion. This is a planning verdict, not an independent run of the
proposed mechanisms or an exact-tree review of these documentation edits.

Opus agreed that the prior scope was too small and that the replacement fits
D-009/D-011: DocKit supplies the contract, checker and record writer; the adopter
owns probes and invocation in its existing mutation command; ForgeOS retains
runtime authority. No future ForgeOS implementation is a prerequisite here.

Its conditional verdict was AGREED FOR PLANNING. The executor incorporated
all four required integrity corrections and both wording corrections:

1. Derive integrated/tested adoption from a rerunnable negative integration
   artifact and fresh, matching execution evidence; copied scripts or an
   operator/agent assertion cannot claim a protected mutation path.
2. Detect record deletion/truncation/rewriting against committed history and
   retained append checkpoints, not merely valid syntax. Preserve continuity
   of uncommitted events without a product release for every attempt; never
   claim tamper-proofing against control of all evidence.
3. Stable failing-dependency identity lives in the reviewed declaration;
   changing it triggers reassessment instead of resetting the budget.
4. Limit the initial new schema to stable identity and fields exercised by
   the two actual reproducers. Link existing review/authority/acceptance
   records rather than inventing generic speculative fields.
5. The current source candidate is reviewed under existing D-020. New limits
   start operating at the integrated pilot, not retroactively on their own
   unimplemented code.
6. Usability is a declared criterion followed by attributed real acceptance
   evidence; the generic checker does not independently certify real use.
   Failures gate only the opted-in project entrypoint, not chat or Stop/session
   authority. Recovery remains available after ordinary budgets expire.

The first accepted improvement must show failed-prerequisite refusal before
mutation, equivalent-retry refusal despite renaming, corrected-evidence
continuation, supported-security-finding blocking, recovery after budget
exhaustion, session continuity and actual user-path acceptance. Source
publication is not incident-remediation acceptance. Riego remains an optional
pilot rather than a dependency, and selective fleet delivery follows evidence.

Temporary evidence: `/tmp/dockit-df058-consensus-20260919/opus-round3.txt`,
`opus-round3.jsonl` and `opus-round3-result.md`. Durable outcome and reasoning
are recorded here; temporary transcripts are not an archival guarantee.

Replacement prompt SHA-256: a0143a0675304a9f0bf4bedcc8d1e4edbf7329f1a2f2621d1ce7bf1390f0ac0e.
Verdict text SHA-256: 192ed066c4f4201bf3a64aff4f5431494ef7c199d8238032d412a4c2f5f1dc61.

## 2026-09-19 - DF-058 planning consensus with exact Opus

**Status: superseded by the operator-corrected complete-delivery plan above.**
The two-round agreement below was real, but its scope was insufficient: it
improved documentation while deferring the controls needed to address the
incident. Preserve it as history, not an implementation instruction. The live
sequence is now in `docs/ROADMAP.md`. No source-release GO was ever issued.

- Source baseline: commit `811077abd80a68cdf7a26671fe450557e8c55f77`, version
  4.15.0, clean local main matching the local origin/main tracking ref.
  Source tree: b0f05917283183c99ef2d7b16e74e1d353848140.
- Preferred model: exact `claude-fable-5-1`, effort high, session
  `7dedee7b-1e11-429f-b4ba-503dc93d50ca`. One attempt returned HTTP 429 and
  "You've reached your Fable limit." It produced no review.
- Effective auditor: exact `claude-opus-5[1m]`, effort high, session
  `775e8c6d-1595-4089-a750-0c1c3d0c0cf4`, resumed for the second round.
  Result telemetry confirms that exact requested model, canonical
  `claude-opus-5`, and context window 1000000; no alternative reviewer or
  subagent was used.
- Command: `claude -p --model 'claude-opus-5[1m]' --effort high --restricted
  --permission-mode plan --tools Read,Glob,Grep --allowedTools Read,Glob,Grep
  --strict-mcp-config --mcp-config '{"mcpServers":{}}'
  --add-dir /tmp/dockit-df058-consensus-20260919 --output-format stream-json
  --verbose --session-id 775e8c6d-1595-4089-a750-0c1c3d0c0cf4` with the
  first prompt on stdin. Round 2 used `--resume` with that same ID and
  `--permission-mode dontAsk`; all other model/tool restrictions remained.
  Fable used the same restricted invocation with its exact model/session.
- Capability: primary-file Read/Grep inspection, no shell, external services,
  writes or independent test execution. The executor supplied Git identity and
  validation evidence. Plan-mode scaffolding prompted one unavailable Write
  call to an operator plan path; the tool rejected it and no file was created.
  Round 2 used read-only tools without plan mode. Do not describe supplied
  test results as independently executed by Opus.
- Baseline validation: existing validator returned ten PASS-shaped results,
  five explicitly skipped; version sync was 9/9. No smoke-suite rerun or live
  Riego/infra acceptance was claimed in this planning session.
- Local evidence: prompts, JSONL results and baseline packet under
  `/tmp/dockit-df058-consensus-20260919/`; these are temporary transcripts,
  not a durable archive guarantee. This registry preserves the causal record.
  Round-2 prompt SHA-256:
  c8a4d449481f62d20b5619df8b3cc6077713667bed0634a2386fe40394d3ca22.
  Final verdict text SHA-256:
  ba0fc60c677f9e4998967141e2e37bb0feb1f63be60874aa05d56eb069abe6ed.

### Round 1 - CHANGES REQUIRED

Opus corroborated the stale source snapshot and verified that exact duplicate
H2 matching misses the actual Do Not Touch aliases. It confirmed that adding
config cannot honestly exercise four of the five skipped checks; Trace needs
an anchor, an honest activation date and CI commit history. It accepted
additive skip metadata while preserving existing status and exit contracts.

Disagreements remained: Opus initially wanted handoff-shape entirely opt-in,
opposed an umbrella DF convention, and wanted fleet delivery removed from the
release scope. The executor accepted the factual corrections, distinguished
source publication from eventual rollout, and proposed default size-only WARN
with explicitly configured content checks. Existing DF-003/006/010 were mapped
before creating new backlog entries. No undocumented policy became active.

### Round 2 - CONSENSUS STATUS: AGREED

Opus explicitly accepted the executor's compromise and withdrew the claim that
delivering the advisory had no adopter value. Both parties agreed:

1. Honest reporting fixes misleading coverage, not the entire delivery failure.
   Keep status/exit compatibility; count skips explicitly, before quiet filtering.
2. Default size-only WARN at a provisional configurable 200 lines. Grammar-based
   content checks require configured scope, canonical title boundaries/aliases
   and explicit current-version fields. Strict opt-in can fail contracted
   deterministic violations; length remains advisory. Document new WARN/SKIP
   displays and distinguish unconfigured content checks from exercised ones.
3. Source enables both applicable Trace and handoff checks, with the real
   activation date, anchor/footer evidence and full CI Git history. Do not
   invent external dependencies or phase grammar to obtain an artificial 10/10.
4. Preserve HANDOFF history in a linked archive, then exclude source-only
   archives from fresh init targets. Never delete the source's historical
   evidence or an existing adopter's archives. Test config regeneration too.
5. No new umbrella DF convention. Preserve the original intake provenance;
   narrow/reorder DF-058 for skip reporting, reuse DF-003 and DF-006, and keep
   DF-010 distinct. New later contracts, not this bookkeeping exercise, may
   justify DF-059+. The overall incident stays open.
6. One source candidate, exact independent source review, one real clean
   adopter pilot, then separately scoped selective delivery. Routine sync also
   carries copy-strategy scripts; planned delivery includes scripts wherever
   still outdated plus guidance/config recipes. D-021 template-currency limits
   and protected worktrees remain binding. Riego is not a blocking dependency.
7. No profile/gate/budget/attempt schema in v4.16.0. Future prerequisite evidence
   and mechanical retry grouping need separate contracts. Project probes and
   ForgeOS authority stay outside the validator; budgets never auto-approve
   supported findings or prevent recovery.

The executor accepted the three final non-blocking amendments: title-boundary
matching, source-archive pruning only in generated init targets with regression
coverage, and no premature DF-059+ entries. No substantive disagreement remains
on this roadmap. The agreed discussion predates these documentation edits;
this is not an exact-tree audit of the resulting docs or future implementation.

## 2026-09-12 - Exact Opus audit of the fleet-rollout closeout

- **Preferred auditor evidence**: exact `claude-fable-5-1` at high effort was
  retried three times and returned HTTP 429 with `You've reached your Fable
  limit.`; Claude `/status` showed the Fable weekly pool at 100% with reset on
  2026-09-16 14:00 UTC.
- **Effective auditor**: exact `claude-opus-5[1m]`, high effort, session
  `1c419dfc-06bd-4445-9101-0c9a1646734b`. The command explicitly selected that
  model and effort, prohibited edits and subagents, and limited the review to
  read-only inspection.
- **Auditor capability boundary**: no Bash/Git command tool materialized in
  the audit session. Opus read repository files and Git reference files through
  its read/glob tools; candidate tree, binary-diff digest, branch containment,
  validation execution and fleet counts remained executor-supplied evidence.
  The auditor cross-checked the documented ledger and reported no commit-string
  typo, but did not independently execute those identity or validation claims.
- **Round 1 target**: base
  `1301ffc55b078693c790167e0ecae9f642dc67f1`, proposed version 4.14.2,
  16 staged paths, tree `84c69f2d772bb6a4b5d9b7fa622376ea5b91989a`, binary diff SHA-256
  `c68b3aa80116499dbb5e7c52a3681ab74cdc4e85be7707d9e247c112320d424a`.
- **Round 1 verdict**: `GO WITH REQUIRED CHANGES`; two HIGH, five MEDIUM,
  four LOW and two NOTE findings.

### Round 1 reconciliation

- **A1 HIGH - AGREED**: the new HISTORY entry omitted six staged paths. The
  v4.15.0 entry now enumerates every final candidate path.
- **A2 HIGH - AGREED**: the Travel Ledger timezone explanation was false, while
  LLM-DocKit had a separate real UTC conversion defect. Travel Ledger 0.9.14
  fixes its omitted HISTORY footer hash and passes DocKit 10/10. The central
  validator now uses `TZ=UTC` plus Git `format-local`, with an offset regression;
  DF-057 preserves both causes without conflation.
- **A3 MEDIUM - AGREED**: MED's active worktree has neither the selected policy
  section nor its marker pair. The ledger no longer calls it a partial policy
  copy; it distinguishes that protected checkout from the published clean-
  worktree commit.
- **A4 MEDIUM - AGREED**: PiHA-Deployer retained its evidenced 4.9.5 /
  `723afb4` state. Pre-registration sentinels apply only where the complete
  prior template is unprovable.
- **A5 MEDIUM - AGREED**: the protected primary `devenv`, `forgeos`, and
  `devenv-entry` worktrees contain additive uncommitted policy edits; MED was
  not locally edited with the policy. The receipt states both facts.
- **A6 MEDIUM - AGREED**: manual pre-registration state was not reproducible.
  `dockit-sync.sh --init-state --untracked-existing-adoption --project <path>`
  now creates the honest identity and complete baselines under constrained,
  tested option combinations.
- **A7 MEDIUM - AGREED**: this review is now recorded here with exact model,
  session, candidate and capability boundaries.
- **A8 LOW - AGREED**: the `forgeos-convergence` revision is explicitly limited
  to its unmerged feature branch.
- **A9 LOW - AGREED**: no-bump rationales now cite ForgeOS convergence's
  integration-line version assignment and House Thermal Monitor's explicit
  documentation-only rule.
- **A10 LOW - AGREED**: the receipt says selected-policy convergence and notes
  that Irrigation Portal's commit also carries its independently authorized
  0.9.0 feature release.
- **A11 LOW - AGREED**: HANDOFF now includes v4.14.0, v4.14.1 and the final
  `1301ffc` audit-record commit in its immediate release chain.
- **N1 NOTE - AGREED**: all claims the auditor could not reproduce are labelled
  executor evidence rather than independent execution.
- **N2 NOTE - AGREED**: `.dockit-enabled` is documented as a presence marker;
  empty and comment-only forms are both accepted instead of being represented
  as one canonical byte shape.

### Round 2 verification and findings

- **Target**: tree `59c65c6fdfe3e80ac33c26b3b4f40d7755db7b94`, binary
  diff SHA-256 `fd6fa0d7f5bbe4d2ed02f6877688a970ad0a9e51e4d82ec6de04d0a427e1c2e0`,
  21 staged paths.
- **Independent execution**: a Bash/Git surface was available in this round.
  Opus independently reproduced tree and diff identity, 9/9 version sync,
  10/10 DocKit, shell syntax, diff hygiene, all 35 remote-branch containment
  checks, exact 49/38/11 inventory arithmetic, exact registration set equality,
  37 current sections plus markerless MED, Home Infra ancestry, the unmerged
  ForgeOS convergence branch and both no-bump rationales. It did not run the
  nominal dry-run because that command acquires transient locks in adopter Git
  directories; its read-only section-hash comparison reproduced the substance.
- **Verdict**: `GO WITH REQUIRED CHANGES`; one HIGH, two MEDIUM, one LOW and
  one NOTE, with no disagreement.
- **B1 HIGH - AGREED**: two legacy smoke fixtures still built UTC-labelled
  expectations with Git `format:`. They passed 82/82 under UTC but only 75/82
  under Europe/Madrid. Both now use `TZ=UTC` plus `format-local`; both host
  timezones are required in the replacement gate.
- **B2 MEDIUM - AGREED**: DF-057 and ROADMAP now record the validator migration
  census, name `buzz-lab` and `infra-portal` as the currently detected false-UTC
  anchors, and require evidence repair rather than validator reversion.
- **B3 MEDIUM - AGREED WITH STRONGER REMEDIATION**: instead of warning while
  still overwriting, init-state now refuses to cross the pre-registration
  boundary unless explicit `--force` is supplied. The error names both identities; tests
  cover sentinel preservation, evidenced-provenance preservation, idempotence
  and the forced escape.
- **B4 LOW - AGREED**: this block records the changed tool capability,
  independently reproduced axes, findings and verdict.
- **N3 NOTE - AGREED**: manifest column alignment is corrected.

### Round 3 closure and publication

- **Target and publication**: base
  `1301ffc55b078693c790167e0ecae9f642dc67f1`, tree
  `dc6659ba04143e0cb39db109c5623570398f584c`, binary diff SHA-256
  `9faa58b4d3cc32d78577061b0d68835aea4d0916cc25358b39b839ec7327cb17`,
  21 paths. The exact tree is published on `origin/main` as
  `761a99de144f0d6ad51b9da77da57d295dd9680a`.
- **Independent execution**: Opus reproduced the complete identity, 9/9
  version sync, 10/10 DocKit, 85/85 smoke results under UTC, Europe/Madrid,
  Pacific/Kiritimati and Pacific/Midway, 35/35 remote containment, exact
  49/38/11 inventory, the DF-057 census and all seven identity-crossing cases.
- **Closure**: B1-B4 and N3 are closed. The narrower pre-registration guard is
  accurately documented and leaves ordinary evidenced-version re-baselining
  unchanged. Round-1 A1-A11 and N1-N2 remain closed, with no disagreement.
- **Verdict**: `GO` for commit and push of that source tree only.
- **Identity integrity**: the executor reports that a pre-commit comparison
  typo was confined to its local guard string. A narrow same-session check
  independently confirmed the prompt digest, recomputed the tree and digest,
  proved no candidate byte changed and returned `IDENTITY INTEGRITY: GO`.
- **C1 LOW - IMPLEMENTED IN THIS FOLLOW-UP**: 14 registered adopters currently
  carry pre-registration identity. CHANGELOG, HOW_TO_USE and D-022 state that a
  reviewed full apply is the normal graduation path, selective apply preserves
  the sentinel, and `--force` is not a shortcut to claimed currency.
- **N4 NOTE - IMPLEMENTED IN THIS FOLLOW-UP**: DF-057 distinguishes intentional
  local-calendar date-only lookups with no UTC label from the corrected
  UTC-labelled timestamp path.

The corrections add a sync capability and repair validator behavior, so the
candidate moved from documentation-only 4.14.2 to backward-compatible minor
4.15.0. The audited source tree is published; only this non-behavioral review
record and the two recommended clarifications remain in the follow-up commit.

## 2026-09-12 - Exact Opus audit of the v4.14.0 selective-sync candidate

- **Preferred auditor evidence**: three exact `claude-fable-5-1` high-effort
  attempts returned HTTP 429 with `You've reached your Fable limit.`; Claude
  `/status` showed Fable week 100%, reset 2026-09-16 14:00 UTC, while the
  all-model pool retained capacity.
- **Effective auditor**: exact `claude-opus-5[1m]`, high effort, 1M context.
  Command explicitly set `--model 'claude-opus-5[1m]' --effort high`, supplied
  no fallback model, used restricted/plan mode, allowed only file reads and
  read-only Git commands, and requested no subagents. CLI telemetry identified
  Opus as the canonical result model and `subagent_stats.spawned: 0`; a tiny
  Haiku internal-CLI usage entry was not an auditor substitution and produced
  no finding or verdict.
- **Round 1 target**: base `e51fc6f64465fd28716c0e1eae374c70be9e3247`,
  candidate tree `dfd3627a0c1cac53889e8e30db73242e26690ebe`, binary
  diff SHA-256 `6d1b3d1739175c521116af0c3fce217dcf9015768dc1883da55b690e99760750`.
- **Round 1 validation packet**: 4.14.0 markers 9/9, DocKit checks 10/10,
  validator smoke 62/62, `git diff --check` PASS.
- **Round 1 verdict**: `GO WITH REQUIRED CHANGES`.
- **Round 2 target**: candidate tree
  `4dfb5923628a58f5340d0610c892e78a3305a214`, binary diff SHA-256
  `74b69d3ee8d527e4847f4d55129f471fd2d46a822ed20730428d4399d827e529`.
- **Round 2 validation packet**: markers 9/9, DocKit 10/10, smoke 71/71,
  `git diff --check` PASS, and real fleet dry-run 21 eligible / 2 partial / 0
  errors with one parseable 23-project JSON array.
- **Round 2 verdict**: `GO WITH REQUIRED CHANGES`; A1 remained partial because
  whole-file creation lacked baselines, and the round-1 diff hash was
  mistranscribed. Opus also recommended closing live-lock report loss,
  malformed-state baseline loss, and ambiguous rollback JSON before release.
- **Round 3 target**: candidate tree
  `b6a3d02cb8899bba86d9e7b27a10ef8942ffbee5`, binary diff SHA-256
  `280fbd418bb54511089cade6b6bf10074dab096905d9efe62fa1c7c47b2a5824`.
- **Round 3 validation packet**: markers 9/9, DocKit 10/10, smoke 75/75,
  shell syntax and `git diff --check` PASS, and a freshly repeated fleet
  dry-run with 21 eligible / 2 partial / 0 errors.
- **Round 3 verdict**: `GO`; no BLOCKER, HIGH, or MEDIUM findings remained.
  Opus identified two optional LOW hardening cases and four NOTES. The executor
  closed both LOW items plus the stale-count and branch-test NOTES; the two
  remaining NOTES were accepted as explicit reporting/deployment boundaries.
- **Round 4 release target**: tree
  `34915aa08174e217cb58c504ef04c44c9216c990`, binary diff SHA-256
  `72bc3edf1619669e736a53819ece19372e7c5cb9711738601e8a5a3e5c0a1d4d`.
- **Round 4 validation packet**: markers 9/9, DocKit 10/10, smoke 78/78,
  shell syntax and `git diff --check` PASS, and real fleet dry-run 21 eligible /
  2 partial / 0 errors.
- **Round 4 verdict**: final `GO`; no BLOCKER, HIGH, MEDIUM, or LOW findings.
  The audited tree matched the staged Git tree exactly and was published as
  source commit `1d44785e3dbc60b71c475d125f436ba110959e5d`.
- **Round 5 documentation target**: tree
  `a0e2e230821f35e0139f8417dd01ca0a4804957c`, binary diff SHA-256
  `b9445e19b980e72977d037e94934b2c6caf161e04e9b7d04d8753a11aec9ee25`,
  limited to HANDOFF, HISTORY, and this review registry.
- **Round 5 validation packet**: markers 9/9, DocKit 10/10, and
  `git diff --check` PASS.
- **Round 5 verdict**: `GO`; it confirmed the release identities and authority
  boundary, then raised two NOTES that v4.14.1 closes before adopter rollout.
- **Round 6 patch target**: tree
  `80906357030fd225131cc7578c6941038cf823e6`, binary diff SHA-256
  `1f2b1111aa8537345aa49ab8d6ea4e5ed2ccbc95b88a7e979c20872bfaa0b48d`,
  VERSION 4.14.1 over published `1d44785`.
- **Round 6 validation packet**: markers 9/9, DocKit 10/10, smoke 78/78,
  `git diff --check` PASS, and fleet dry-run 21 eligible / 2 partial / 0 errors.
- **Round 6 verdict**: `GO`; E1/E2 were closed. Opus raised three wording NOTES
  distinguishing tree IDs from commits, extending the rule to HANDOFF Trace
  Anchors, and documenting why this registry can retain formatted tree hashes.
- **Round 7 release target**: tree
  `c8845704726f0572a67d5287102e0470814794b1`, binary diff SHA-256
  `204c7fc0813f30872fe95146ecf4dc9b2bcf12f7b37c2f44ed711c9c4f67bdbf`,
  VERSION 4.14.1 over published `1d44785`.
- **Round 7 validation packet**: markers 9/9, DocKit 10/10, smoke 78/78,
  `git diff --check` PASS, and fleet dry-run 21 eligible / 2 partial / 0 errors.
- **Round 7 verdict**: final `GO`; F1/F2/F3 were closed with no
  BLOCKER/HIGH/MEDIUM/LOW findings. The exact audited tree was committed and
  pushed as `3d380250bdd88851cf26a74c3091ccc483810a42`.

Tree and other non-commit candidate IDs may remain backtick-formatted in this
review registry because durable Trace does not scan it. HISTORY and HANDOFF
Trace Anchors follow D-020 instead; commit provenance follows D-019.

### Findings and executor reconciliation

- **A1 BLOCKER - AGREED**: selective apply preserved full template identity by
  skipping state writes entirely, which also discarded the delivered section's
  conflict baseline. The correction merges delivered section hashes while
  preserving prior `template_version`/`template_ref`; a regression proves a
  later local edit conflicts and survives rollback byte-for-byte.
- **A2 HIGH - AGREED**: partial and excluded adopters looked indistinguishable
  from current. Selected sections now report explicit current, partial,
  excluded, updated, conflict, and error outcomes in text and JSON.
- **A3 HIGH - AGREED**: 62/62 overstated new-feature coverage. The first
  correction reached 71/71; the final matrix reaches 78/78 and exercises state
  merge/conflict, whole-file and repeated selectors, partial/excluded/current,
  invalid combinations and selector forms, missing file, pre-existing
  validation failure, branch collision, lock failures, and attributable
  `--all --json` output.
- **A4-A12 - AGREED WITH MODIFICATION**: quota-exhaustion wording and evidence
  destination were tightened; fleet JSON, literal selector matching,
  prevalidation, whole-file unknown-section checks, selective branch naming,
  skip-path rejection, and change-only warnings were addressed. Pre-existing
  validation failure is classified without mutation rather than treated as a
  new sync failure.
- **A13-A14 - NOTE**: helper duplication and historical insertion-before-footer
  ordering do not affect correctness and are deferred.
- **A15 - DISPUTED AS A CHANGE, ACCEPTED AS A DOCUMENTED CHOICE**: the
  SessionStart payload already mandates reading `LLM_START_HERE.md`; duplicating
  exact model IDs in the bootstrap would create a second fleet value that can
  drift. D-020 records the single-source choice.
- **A16 - AGREED**: D-020 now disambiguates the older, qualified MED D-020.

### Round 2 findings and executor reconciliation

- **B1 HIGH - AGREED**: the section-hash code had landed in `sync_copy` rather
  than the `section-merge` file-creation branch. It now records every template
  section only on the correct path; regressions prove all baselines exist and a
  later local policy edit conflicts and survives rollback.
- **B2/B9 MEDIUM/NOTE - AGREED**: a live lock used `die`, aborted fleet JSON,
  and the EXIT trap could delete the other process's lock. Lock acquisition now
  returns a project error, preserves the holder's lock, and continues `--all`;
  a heterogeneous fleet regression verifies all three project entries remain.
- **B3 MEDIUM - AGREED**: the round-1 diff hash was copied incorrectly despite
  the correct tree. It is corrected above from the retained round-1 snapshot.
- **B4/B8 MEDIUM/LOW - AGREED**: selective state parsing now rejects malformed
  `section_hashes` with a precise reason and rolls back both state and files;
  it cannot silently discard untouched baselines.
- **B5 MEDIUM - AGREED**: each apply rollback now adds an attributable
  project-level error entry; prior `UPDATED` entries no longer stand alone.
- **B6/B7/B10/B11 - AGREED WITH MODIFICATION**: coverage is now heterogeneous
  and 78/78, branch collision retains `-selective`, the path/section no-space
  contract remains valid, and CHANGELOG names the expanded scope.
- **B12 - CLOSED FOR ROUND 3**: this registry records the round-3 candidate,
  validation packet, and `GO`. The executor voluntarily hardened the remaining
  LOW/NOTE cases, so that replacement tree receives one final same-session
  audit before release.

### Round 3 findings and executor reconciliation

- **C1 LOW - AGREED**: non-holder lock failures now carry explicit directory or
  file diagnostics, and the caller retains a non-empty fallback. A regression
  forces lock-directory failure and verifies the attributable message.
- **C2 LOW - AGREED**: selective state validation now accepts only a non-empty
  lowercase 64-character SHA-256 value, quoted or unquoted. An empty quoted
  baseline fails and preserves state byte-for-byte.
- **C3 NOTE - AGREED**: the A3 narrative now separates the historical 71/71
  round from the final 78/78 suite instead of leaving an apparently stale
  count.
- **C4/C6 NOTE - ACCEPTED AS BOUNDARIES**: conflict plus project rollback are
  intentionally two report entries for one event, and a real adopter apply is
  still a downstream gate rather than source-release evidence.
- **C5 NOTE - AGREED**: a real selective `--git-branch` collision regression
  now verifies that the timestamp fallback retains the `-selective` suffix.

### Round 4 findings and executor reconciliation

- **D1 NOTE - AGREED**: the round-3 summary now states two LOW findings and
  four NOTES, distinguishing the four closures from two accepted boundaries.
- **D2 NOTE - AGREED**: the round-4 release identity and final `GO` are recorded
  by the immediate post-release documentation vehicle rather than by trying to
  embed a self-referential tree hash in the audited tree.
- **D3 NOTE - ACCEPTED**: the branch-collision case is regression lock-in, not
  proof of a round-3-to-round-4 fix; the two other added cases discriminate.

### Round 5 findings and executor reconciliation

- **E1 NOTE - AGREED**: the missing round-4 reconciliation is now explicit
  above instead of recoverable only from the summary verdict.
- **E2 NOTE - AGREED**: D-020 and the managed policy now reserve backtick-quoted
  HISTORY and HANDOFF Trace Anchor hashes for commits under durable Trace.
  Candidate tree hashes go in this registry when it exists, otherwise remain
  plain text on those surfaces; D-019 commit classification remains intact.

### Round 6 findings and executor reconciliation

- **F1 NOTE - AGREED**: D-019 and D-020 now cross-reference the object-type
  boundary. Only non-commit IDs become plain text; commits remain backticked,
  and cross-repository commits use `external=repo@hash`.
- **F2 NOTE - AGREED**: the managed policy and D-020 apply the same rule to
  HISTORY and HANDOFF Trace Anchors, the two surfaces durable Trace validates.
- **F3 NOTE - AGREED**: this registry now states why candidate tree IDs can
  remain formatted here without colliding with durable Trace.

### Round 7 finding and executor reconciliation

- **G1 NOTE - ACCEPTED**: the fleet policy references D-019's Trace
  `external=repo@hash` field, while the separately excludable trace-protocol
  section documents its syntax. The clause applies only when durable Trace is
  enabled and is self-explanatory; no source change is required before the
  single-adopter pilot.

### Corrected-candidate fleet preview

The real read-only command `dockit-sync.sh --dry-run --all --json --only
LLM_START_HERE.md:independent-review-policy` produced one parseable 23-project
array: 21 full adopters would insert the section, while `med` and
`msgvault-lab` were explicitly reported as partial adopters without markers;
there were no errors. No downstream file or state was changed.

### Release boundary

The final 78-case implementation tree received exact same-session Opus `GO` and
was published as `1d44785`. The v4.14.1 evidence correction then received final
Opus `GO` on its exact tree and was published as `3d38025`. Neither release
authorizes downstream apply, commits in adopters, global configuration, runtime,
or infrastructure changes. One reviewed full-adopter selective apply remains
the next independent rollout gate.

## 2026-07-16 - Post-ship audit of the v4.13.0 session-aware Stop gate

- **Auditor**: Claude
- **Audit target**: `b718d23` (`feat(hooks): cut v4.13.0 session-aware Stop gate`)
- **Outcome**: blocked; one lifecycle regression reproduced
- **Recovered**: 2026-07-18 from the `dev_claude_LLM-DocKit` tmux pane before
  VM/NAS shutdown
- **Operator decision**: correction explicitly authorized in the pane; no code
  changes were made there

### Finding

Claude Code Stop runs after turns. The implementation treated successful Stop
as permanent session termination and called `cleanup_baseline` after both a
normal PASS and `stop_hook_active: true`. In an inherited-dirty read-only
fixture, turn one passed and deleted the baseline; turn two in the same session
then failed stale date checks because attribution state no longer existed.

This is blocking for home-infra, the adopter that originally demonstrated the
dirty-inherited case. The 56-case v4.13.0 matrix did not include two successful
Stop events under one `session_id`, so it could not expose the regression.

### Accepted correction

- Remove baseline cleanup from every Stop path.
- Keep seven-day pruning as eventual cleanup for abandoned sessions.
- Refresh the baseline slot mtime on Stop so long-lived active sessions are not
  pruned by another SessionStart.
- Add a multi-turn regression proving two successful inherited-dirty Stops and
  an active Stop all retain the same baseline.
- Cut the fix as v4.13.2 because v4.13.1 was subsequently assigned to the
  separate DF-053 Codex installer safety patch.

### Scope that remains valid

The audit accepted the rest of v4.13.0: per-`session_id` isolation, HEAD plus
tracked-diff fingerprinting, resume/compact no-overwrite, fail-closed state,
real validator reasons, limited date-check skip, untracked exclusion,
`stop_hook_active` one-block semantics, and the post-sync warning without
auto-commit. DF-054 isolates the baseline lifetime regression; it does not
reopen those accepted parts of DF-052 or D-017.

---

## 2026-05-03 — Consensus Protocol as a named primitive of LLM-DocKit

> Historical entry. D-011 supersedes the ownership claim: the full proposal now
> lives in `docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md`, and LLM-DocKit keeps
> only the registry/substrate role.

- **Decision**: Adopt the propose / critique / arbitrate pattern as a
  named primitive of LLM-DocKit, with explicit invocation thresholds, a
  structured REVIEWS recording format, defined failure modes, and an
  explicit relationship with the existing `DOWNSTREAM_FEEDBACK.md` + 
  `*_PROPOSAL.md` channels. Implementation is scoped to documentation —
  no code changes in this round. The full proposal lives at
  `docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md`; the original path is now a
  stub.
- **Proposer**: Claude Opus 4.7 (1M context)
- **Critic**: GPT-5
- **Arbiter**: Carlos
- **Rounds**: 5
- **Outcome**: closed-accepted
- **Triggered by**: an audit (Tomatic v0.1.5) surfaced DF-029 (this
  repo) and DF-003 (home-infra-protocol). The same audit revealed that
  the back-and-forth pattern between two LLMs and an arbiter had been
  producing visibly better decisions than any single LLM alone — and
  that the pattern was nameless. Carlos identified that ForgeOS will
  need a "consensus module" and that this pattern is the proof of
  concept.

### Decisions accepted

- **The pattern is consensus, not review**: the back-and-forth is a
  mechanism for *reaching* a decision, not for *gating* one already
  made. Therefore the artefact is named `CONSENSUS_PROTOCOL_PROPOSAL.md`,
  not `CROSS_LLM_REVIEW_PROPOSAL.md`.
  - **Proposed by**: Carlos.
  - **Objection considered**: an earlier Claude formulation framed it
    as "cross-LLM review", which made it sound like a quality gate;
    GPT-5 also accepted the rename without resistance.
  - **Why this resolution**: review is a single pass at the end;
    consensus is N rounds with explicit roles, iteration, arbitration,
    and closure. Calling the latter "review" empequeñece the
    primitive and would cause future sessions to under-invoke it.
  - **Risk accepted**: the word "consensus" is loaded (political
    overtones, conflict-resolution overtones); the proposal hedges
    by stating up-front that "consensus does not certify correctness;
    it certifies that the decision was deliberated".
  - **Implementing artefact**: `docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md`
    (archived by D-011; originally `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`).

- **Densidad sobre brevedad**: REVIEWS entries preserve causal
  reasoning, not bullet summaries. A future reader six months out
  must be able to reconstruct why a decision was correct, not just
  what it was.
  - **Proposed by**: Carlos (correcting an earlier GPT suggestion to
    make REVIEWS compact).
  - **Objection considered**: GPT-5 had argued REVIEWS should be
    compact bullets ("aceptado X, rechazado Y") to avoid prose drift;
    Carlos pointed out that compacting to bullets loses the very
    signal that distinguishes "this system learns" from "this system
    keeps a changelog". GPT-5 then accepted the amended formulation
    ("rico en causalidad, no largo por defecto"), which is the
    resolution.
  - **Why this resolution**: an audit trail without causal reasoning
    is shallow; a future session reading "rejected: prometer no
    volverá a pasar" without knowing the rationale cannot extend the
    lesson to a new context. The now-archived Consensus Protocol
    Proposal codified the structured format that satisfied both objectives:
    causality-rich without verbatim transcript.
  - **Risk accepted**: REVIEWS entries grow longer than other LLM-DocKit
    artefacts; the trade is intentional.
  - **Implementing artefact**: proposal *Recording mechanism* and
    *What to include and what NOT to include* sections.

- **Three roles: proposer, critic, arbiter**: explicit role separation
  with the rule that the same human or model may not occupy two roles
  simultaneously within a single decision.
  - **Proposed by**: Claude (with the original formulation).
  - **Objection considered**: GPT-5 endorsed the structure; raised the
    risk of "critic capture" (the critic agrees with everything),
    which made it into the *Failure modes* section.
  - **Why this resolution**: role separation is what makes the protocol
    different from "ask another LLM to review"; without enforced
    separation the pattern collapses to informal cross-checking.
  - **Risk accepted**: when only one LLM is available, the protocol
    runs with reduced guarantees (same model alternating); the
    proposal documents this as an explicit weaker mode.
  - **Implementing artefact**: proposal *Roles* section.

- **Invocation thresholds as a list, not as discretion**: contract
  changes, multi-repo spans, security/persistence, multi-week
  reversibility, precedent-setting. Routine work explicitly excluded.
  - **Proposed by**: GPT-5.
  - **Objection considered**: Claude had originally suggested
    "important decisions" without enumeration; GPT-5 pointed out that
    without enumeration the protocol either gets invoked for
    everything (ceremony) or for nothing (ignored). Claude conceded.
  - **Why this resolution**: a vague threshold is worse than no
    threshold because it shifts the cost from "deciding to invoke"
    to "deciding what counts as important". An enumerated list
    removes that cost.
  - **Risk accepted**: the enumeration may miss a category that
    becomes important later; the proposal's *SHOULD/SHOULD NOT*
    framing leaves room for explicit operator override.
  - **Implementing artefact**: proposal *Invocation thresholds*
    sections (both directions).

- **Failure modes are part of the contract, not an afterthought**:
  non-convergence, arbiter unavailable, decision later overturned,
  critic capture — all named with mitigations.
  - **Proposed by**: GPT-5 (asking what happens when LLMs disagree
    across multiple rounds).
  - **Objection considered**: Claude initially had not addressed
    failure cases; GPT-5 pushed for explicit failure-mode handling,
    framing it as "the protocol must be honest about its own
    limits". Claude agreed and drafted the *Failure modes and
    recovery* section.
  - **Why this resolution**: a protocol that pretends not to fail is
    untrustworthy. Naming the failure modes lets future sessions
    recognise them and apply the documented mitigations rather than
    invent ad-hoc workarounds.
  - **Risk accepted**: the failure-mode list is non-exhaustive; new
    modes will surface in real use and be added.
  - **Implementing artefact**: proposal *Failure modes and recovery*.

- **Auto-validation: the protocol designed itself**: the proposal was
  produced by the very protocol it describes. This is recorded
  explicitly as evidence that the protocol is at least workable.
  - **Proposed by**: Claude.
  - **Objection considered**: GPT-5 raised the risk that
    self-validation is circular; Claude argued the alternative is
    worse (a protocol designed without using it has no real-world
    test). The agreed framing is "this does not prove the protocol is
    correct; it does suggest it is at least workable".
  - **Why this resolution**: the self-test is a property of the
    artefact, not a claim of correctness. Future sessions reading
    the proposal can verify the property by checking the REVIEWS
    entry against the proposal and confirming the deliberation
    followed the rules it was producing.
  - **Risk accepted**: future readers may misinterpret the self-test
    as a stronger claim than intended; the framing in the proposal
    explicitly defuses that.
  - **Implementing artefact**: proposal closing paragraph.

- **ForgeOS as precedent, not as requirement (mirror of the sibling
  proposal)**: ForgeOS is mentioned in one section as a future
  consumer; no field, role, or rule is motivated by ForgeOS
  speculation.
  - **Proposed by**: GPT-5.
  - **Objection considered**: Carlos affirmed that ForgeOS is part of
    the motivation; Claude argued that motivation has informational
    value even if it is not a constraint; GPT-5 agreed on condition
    that the proposal be useful for any LLM-DocKit project regardless
    of ForgeOS.
  - **Why this resolution**: a primitive that works for any
    DocKit-scaffolded project is a stronger primitive than one
    designed for a specific future product. ForgeOS, when it lands,
    can extend; it should not constrain.
  - **Risk accepted**: same as in the sibling proposal — ForgeOS may
    later need extensions; those go through their own consensus runs.
  - **Implementing artefact**: proposal *Future consumer / precedent*.

### Decisions rejected

- **Compact REVIEWS entries with bullet-list "aceptado/rechazado"**:
  rejected because the bullet form loses causal reasoning and turns
  the audit trail into a changelog. Replaced with the structured
  format above.

- **Renaming the artefact CROSS_LLM_REVIEW_PROPOSAL.md** (Claude's
  earlier name): rejected because "review" empequeñece the primitive.
  See accepted decision above.

- **Implementing the validator check `--check deployed-version` in
  this proposal**: rejected to keep the scope honest. The proposal
  documents the protocol; the check is a future patch, naturally
  triggered by an adopter project asking for it.

- **Forcing a specific number of LLMs**: rejected. Two LLMs + arbiter
  is canonical; one LLM alternating roles is acceptable with reduced
  guarantees and the proposal records this explicitly. Forcing two
  LLMs would block adoption when only one is available.

### Open follow-ups

- A future patch ships the template changes named in the *Acceptance
  criteria*: section in `docs/llm/README.md` template, structured
  example in `docs/llm/REVIEWS.md` template, paragraph in
  `LLM_START_HERE.md` template.
- `--check deployed-version` validator check remains an open follow-up
  (DF-029 stays `partially accepted` until it lands).
- The first project to adopt the protocol formally is Tomatic, which
  is already using it informally; once the template changes ship,
  Tomatic's `LLM_START_HERE.md` should be re-synced from the new
  template.
- ForgeOS, when it lands as a project, can read this proposal and the
  sibling Deployment Evidence Contract as inputs to its own consensus
  subsystem design.

---

## Format reference

Use the structured format above for decisions or audits whose reasoning needs
to remain recoverable. Informal review notes (one-off LLM critiques, operator
notes) may use the looser legacy format below when they do not correspond to a
closed arbitrated decision.

### Legacy informal format (kept for backward compatibility)

```
## YYYY-MM-DD - <Reviewer> - <Scope>

### What is good
- <Strength>

### What to improve
- <Issue / suggestion>

### Risks / open questions
- <Risk>

### Verdict
pass | pass-with-notes | needs-changes
```
