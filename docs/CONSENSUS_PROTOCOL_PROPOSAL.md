---
name: Consensus Protocol Proposal
description: |
  A proposal for adding a structured deliberation primitive to LLM-DocKit:
  named roles (proposer / critic / arbiter), invocation thresholds,
  a structured recording format in REVIEWS.md, and a defined relationship
  with the existing DF + PROPOSAL feedback channel. Designed so future
  sessions can invoke a "consensus run" predictably and so the
  resulting decisions remain auditable.
status: draft
authors:
  - Claude Opus 4.7 (1M context) — proposer
  - GPT-5 — critic
  - Carlos — arbiter
date: 2026-05-03
triggers:
  - DOWNSTREAM_FEEDBACK.md DF-029 (this repo) — generic gap "repo VERSION ≠ deployed"
  - home-infra-protocol DF-003 — concrete instance in the consumer support matrix
implementer: |
  A future session — this proposal is intentionally self-contained so the
  next agent can read, decide, and ship without needing the deliberation
  that produced it. The causal trail is in docs/llm/REVIEWS.md.
---

# Proposal: Consensus Protocol for LLM-Assisted Decisions

## Why this proposal exists

Decisions of high blast radius — protocol changes, multi-repo migrations,
deployments with multi-week reversibility horizons, security boundaries,
hardware bring-up — benefit from being deliberated rather than authored
unilaterally. Today LLM-DocKit has no first-class mechanism for that.
Sessions either run as a single LLM acting alone (with the operator
arbitrating after the fact), or as informal back-and-forth between an
LLM and the operator (without a recorded structure). Both modes work for
small decisions and degrade silently as decisions get larger.

The deliberation that produced this proposal and its sibling
(`~/src/home-infra-protocol/docs/DEPLOYMENT_EVIDENCE_PROPOSAL.md`) used
an informal cross-LLM pattern: one LLM proposed, a different model
critiqued, the operator arbitrated and decided when to close. The
process produced visibly better results than any single voice would
have on its own (every iteration corrected an over-reach in one
direction or another). It is documented in detail in
`docs/llm/REVIEWS.md` for both repos.

This proposal turns that informal pattern into a named primitive of
LLM-DocKit so that any project scaffolded from the kit can invoke it
predictably. The pattern is currently in use during the construction of
the operator's `tomatic` project, which is acting as a real-world
proving ground for the homelab ecosystem; ForgeOS, the operator's
planned agentic infrastructure system, is expected to inherit the
pattern as one of its consensus primitives. Both relationships are
recorded as precedent, not as design constraints (see "Future consumer
/ precedent" below).

## What this proposal does NOT do

To keep the scope honest:

- It does not specify the prompts each role uses. Prompts are a
  consumer concern, not a protocol concern, and they will evolve.
- It does not require a specific number of LLMs. Two LLMs + arbiter is
  the canonical form; one LLM alternating between proposer and critic
  is acceptable when only one model is available, with reduced
  guarantees.
- It does not provide automation. Today the protocol is invoked by the
  operator manually opening sessions and routing critiques. A future
  ForgeOS module may automate it; that automation is downstream.
- It does not certify correctness. Consensus does not mean a decision
  is right. It means the decision was deliberated, the dissents are
  recorded, and the rationale is recoverable.

## The protocol

### Roles

Three roles are defined. The same human or model may not occupy two
roles simultaneously within a single decision.

- **Proposer**: produces an initial concrete proposal in response to
  a problem statement. Output: a draft that is specific enough to
  critique (file paths, field shapes, acceptance criteria, not just
  intent).
- **Critic**: reads the proposer's draft and returns a structured
  critique. Output: explicit acceptance, rejection, or amendment of
  each load-bearing decision in the proposal, with reasoning. A
  critic may not silently accept; "I have no objection" is itself a
  recorded position.
- **Arbiter**: a human (today; potentially an LLM with elevated
  scope in a future ForgeOS) who reads both sides and decides what
  closes the round. The arbiter may choose: accept the proposal as
  amended; reject; request another round; defer.

The protocol assumes the proposer and critic are different LLM models
when both are available. Same-family models (e.g. two Claude variants)
provide weaker critique than cross-family models (Claude + GPT) because
the latter are less likely to share systematic biases. This is an
empirical observation, not a hard rule.

### Mechanics

A consensus run consists of N >= 1 rounds. Each round:

1. The proposer produces or updates a proposal.
2. The critic responds with a structured critique (acceptances,
   rejections, amendments, each with rationale).
3. The arbiter classifies the round outcome:
   - **Closed (accepted)**: proposal stands as last amended; no
     further round.
   - **Closed (rejected)**: proposal abandoned; root concern remains
     open; new proposer attempt or new direction.
   - **Open (next round)**: proposer must address one or more critic
     concerns and resubmit.
   - **Deferred**: arbiter pauses the run; reasons recorded.

A run terminates when the arbiter classifies a round as Closed
(accepted) or Closed (rejected), or when the arbiter explicitly
declares the run terminated for other reasons (time, scope creep,
external decision rendering it moot).

### Invocation thresholds — when consensus SHOULD be invoked

A consensus run SHOULD be invoked when ANY of the following are true:

- The decision changes a contract: schema field, SPEC requirement,
  protocol-level vocabulary.
- The decision spans 2+ repositories in the ecosystem.
- The decision has security, persistence, or irreversibility
  implications that cannot be cleanly rolled back.
- The decision has a multi-week reversibility horizon: deployments,
  migrations, hardware bring-up, soak periods, things that take time
  to fail and longer to undo.
- The decision establishes a precedent that subsequent decisions are
  expected to follow.

### Invocation thresholds — when consensus SHOULD NOT be invoked

Routine work does not warrant consensus and forcing it produces
ceremony, which in turn erodes the practice. Consensus SHOULD NOT be
invoked for:

- Typo fixes, doc reformatting, single-file refactors.
- Dependency bumps without API changes.
- Bug fixes whose blast radius is contained to a single file or
  function.
- Mechanical chores (rename, sync, manifest update) where the
  decision was already made elsewhere.

When in doubt, an LLM may explicitly raise the question to the
operator: "this looks like it might cross a threshold; do you want a
consensus run?" That meta-check is cheap and reduces both false
positives and false negatives.

## Recording mechanism — REVIEWS.md format

Each closed consensus run produces one structured entry in
`docs/llm/REVIEWS.md` of the repo that owns the resulting artefact.
If the artefact spans multiple repos (a contract change is the most
common case), the entry is duplicated, each pointing to the other.

The entry uses this shape:

```markdown
## YYYY-MM-DD — <short slug describing the decision>

- **Decision**: one-sentence statement of what was decided.
- **Proposer**: <model name + version>
- **Critic**: <model name + version>
- **Arbiter**: <human name>
- **Rounds**: <N>
- **Outcome**: closed-accepted | closed-rejected | deferred

### Decisions accepted

For each load-bearing decision (typically 5–10 per run):
- **<short name>**: what the decision is, in one sentence.
  - **Proposed by**: <role>
  - **Objection considered**: <one or two lines summarising any
    serious objection raised>
  - **Why this resolution**: <one or two lines on why the resolved
    direction is correct for this moment>
  - **Risk accepted**: <one line, if any>
  - **Implementing artefact**: <path to the proposal, ADR, schema,
    or commit that materialises the decision>

### Decisions rejected

(Same shape as above; the rejection rationale is the load-bearing
content.)

### Open follow-ups

(Things the run did not close. May be DF entries, future proposals,
or deferred decisions.)
```

The entry format is normative: a session producing a REVIEWS entry
that omits the structural fields fails to record an auditable
decision and the run is treated as informal. This is the entry
format that makes the difference between "memorising the
conversation" and "extracting the lesson to contract".

### What to include and what NOT to include

The REVIEWS entry preserves **causality**, not transcript. It
captures:

- What each side proposed.
- Which objection changed the resolution.
- Why the resolved direction is correct for the current moment.
- What risks were knowingly accepted.
- Which artefact implements the decision (or will).

It does not capture:

- Verbatim quotes.
- Every micro-acceptance (typically 30+ in a real run; the
  load-bearing 5–10 are what matter).
- Aspirational statements without committed direction.

The discipline is: a future reader six months out should be able to
reconstruct the **reasoning** of the run from the REVIEWS entry, not
just its outcomes. If a reader could substitute "we decided to ship
X" for "we decided to ship X because Y objected on grounds Z and
this resolution accepts risk W", the entry is too thin.

## Outputs of a consensus run

Each closed run produces, at minimum:

1. **The decision** (recorded in REVIEWS).
2. **The artefacts** the decision implies. Typically one or more of:
   - A new or updated `docs/*_PROPOSAL.md` document.
   - An ADR / `DECISIONS.md` entry.
   - A new DF entry in `DOWNSTREAM_FEEDBACK.md` (if the run
     identified a new gap).
   - A schema or SPEC change (only when the run was scoped to ship
     the change, not just decide it).
3. **Cross-references**. The REVIEWS entry points at the artefacts
   it produced; the artefacts point back at the REVIEWS entry as the
   source of their decisions. This bidirectional link is what makes
   the audit trail navigable.

## Failure modes and recovery

The protocol can fail in predictable ways. Each is acknowledged so
that future sessions don't pretend they did not happen:

- **Non-convergence.** Proposer and critic disagree across multiple
  rounds with no resolution. The arbiter SHOULD declare the run
  Deferred and either re-scope (smaller decision next time) or invite
  a third LLM as second critic to break the deadlock. Recording the
  non-convergence is mandatory.
- **Arbiter unavailable.** If the human arbiter is not present, the
  run cannot close as accepted. It may close as rejected (proposer
  withdraws) or be marked Deferred. An LLM acting alone MUST NOT
  arbitrate its own consensus run; that defeats the purpose.
- **Decision later overturned.** A subsequent decision contradicts a
  closed run. The new run records the supersession explicitly: the
  new REVIEWS entry references the old entry by date+slug; the old
  entry is annotated `Superseded by YYYY-MM-DD-slug`. The old entry
  is never deleted — the audit trail of why-we-changed-our-mind is
  precisely the value of REVIEWS.
- **Critic capture.** The critic agrees with everything the proposer
  says, possibly because they share systematic biases or because the
  critic is the same model as the proposer in disguise. Hard to
  detect inside the run. The mitigation is empirical: cross-family
  models for important decisions, and arbiter awareness of the risk.

## Relationship with the DF + PROPOSAL pattern

The Consensus Protocol does not replace `DOWNSTREAM_FEEDBACK.md`. It
*consumes* DF entries and *produces* proposals.

- A DF entry names a gap observed in real adopter use.
- A consensus run, triggered when a DF reaches a structural decision
  point, produces a `*_PROPOSAL.md` document and the REVIEWS entry
  that records its rationale.
- A subsequent implementation session reads the proposal cold and
  ships it, marking the DF status to `implemented (X.Y.Z)` when done.

This is the pattern as it operated to produce this proposal:
`DF-029` (LLM-DocKit) and `DF-003` (home-infra-protocol) were filed
on 2026-05-03 after an audit surfaced a gap. A consensus run
deliberated the resolution. Two proposals
(`DEPLOYMENT_EVIDENCE_PROPOSAL.md` in home-infra-protocol; this one
in LLM-DocKit) emerged. A future session ships them. The DF entries
move to `implemented` when the schema and template changes land.

## Acceptance criteria

A future session has shipped this proposal when ALL of the following
are true:

- [ ] `docs/llm/README.md` template gains a section "Consensus
      Protocol for high-impact decisions" that references this proposal
      and names the invocation thresholds.
- [ ] `docs/llm/REVIEWS.md` template gains the structured entry
      format described in *Recording mechanism* above (as a template
      example, not as a real entry).
- [ ] `LLM_START_HERE.md` template adds a one-paragraph mention of
      the protocol under "Project-Specific Rules", with a pointer to
      the full proposal. The paragraph names the invocation
      thresholds in one sentence and the no-go zones in another.
- [ ] `docs/DOWNSTREAM_FEEDBACK.md` DF-029 status moves from
      `accepted` to `partially implemented (X.Y.Z)` *only* once a
      template change actually ships (the LLM_START_HERE block,
      REVIEWS template, and README pointer named in the bullets
      above). Until then it stays `accepted`. The validator side
      ("no `deployed` claim without evidence" via `--check
      deployed-version`) is a separate future patch and does not
      gate this status transition.
- [ ] `CHANGELOG.md` records the addition.
- [ ] Version bump per the manifest.

## Migration path — projects already scaffolded

Projects scaffolded from previous LLM-DocKit versions:

- Continue to work without change. The Consensus Protocol is opt-in;
  no existing artefact references it implicitly.
- Can adopt it by adding a `docs/llm/REVIEWS.md` (most already have
  one as a stub from the scaffold) and following the structured
  entry format the next time a load-bearing decision is taken.
- Should NOT retroactively reformat past REVIEWS entries to the new
  shape. The new shape applies forward; old entries stay as they are
  with their original prose.

## Future consumer / precedent (ForgeOS)

ForgeOS — the operator's planned system for agentic management of
real infrastructure — is expected to absorb the Consensus Protocol as
its consensus subsystem. The roles, mechanics, recording format, and
failure modes are direct candidates for that subsystem.

This is recorded as **precedent, not requirement**. The proposal must
stand on its own as useful for any LLM-DocKit-scaffolded project; if
ForgeOS later picks up the pattern with extensions or constraints,
those are downstream additions, not constraints on this design.
Sessions implementing this proposal SHOULD NOT add fields, roles, or
rules motivated only by ForgeOS speculation. The rule is the same as
in the sibling proposal: solve the current need first, let ForgeOS
ratify.

## How to use this proposal in a fresh session

A future session that has not seen the deliberation that produced
this document can ship the proposal by reading, in order:

1. This file end to end.
2. `docs/DOWNSTREAM_FEEDBACK.md` DF-029 for context.
3. `~/src/home-infra-protocol/docs/DEPLOYMENT_EVIDENCE_PROPOSAL.md`
   as the sibling proposal (it cites this one and vice versa).
4. `docs/llm/REVIEWS.md` entry dated 2026-05-03 for the causal trail
   that produced this proposal (the protocol applied to itself).
5. Then execute the Acceptance criteria checklist above.

The fact that this proposal was produced by the very protocol it
describes is a useful self-test: if the protocol could not produce a
coherent proposal about itself, it would be evidence the protocol
needs more work. It produced a coherent one. That does not prove the
protocol is correct; it does suggest it is at least workable.
