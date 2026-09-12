# Reviews

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
