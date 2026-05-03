# Reviews

Audit trail of consensus runs that produced load-bearing artefacts in this
repo. Each entry captures the **causal reasoning** that produced a decision,
not the transcript of the deliberation. The format is normative — see
`docs/CONSENSUS_PROTOCOL_PROPOSAL.md` *Recording mechanism*.

A consensus run is invoked when a decision crosses one of the thresholds
named in the Consensus Protocol Proposal (contract changes, multi-repo
spans, security/persistence, multi-week reversibility, precedent-setting).
Routine work does not produce REVIEWS entries.

---

## 2026-05-03 — Consensus Protocol as a named primitive of LLM-DocKit

- **Decision**: Adopt the propose / critique / arbitrate pattern as a
  named primitive of LLM-DocKit, with explicit invocation thresholds, a
  structured REVIEWS recording format, defined failure modes, and an
  explicit relationship with the existing `DOWNSTREAM_FEEDBACK.md` + 
  `*_PROPOSAL.md` channels. Implementation is scoped to documentation —
  no code changes in this round. The full proposal lives at
  `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`.
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
  - **Implementing artefact**: `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`.

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
    lesson to a new context. The Consensus Protocol Proposal codifies
    the structured format that satisfies both objectives:
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

This file uses the structured entry format from
`docs/CONSENSUS_PROTOCOL_PROPOSAL.md`. The format is normative for
audit-trail entries; informal review notes (one-off LLM critiques,
operator notes) may use the looser legacy format below if they do not
correspond to a closed consensus run.

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
