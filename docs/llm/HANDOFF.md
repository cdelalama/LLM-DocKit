<!-- doc-version: 4.16.0 -->
# LLM Work Handoff

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-09-21 - Codex
- Current source version: 4.16.0
- Owner: Carlos
- Session focus: implement the complete DF-058 delivery-control loop.
- Source: 4.16.0 candidate; exact Opus source/delta GO; publication pending.
- Pilot: Riego local container command integrated; adverse controls pass.
  Actual local packaging acceptance pending; gardener/off-LAN acceptance remains open.
- Validation: 84 delivery and 96 validator regressions pass; 10 version targets
  agree. Seven source checks pass; four legitimate skips remain visible.

## Open work -- next concrete step

Record the actual local pilot result in
`docs/archive/DF058_IMPLEMENTATION_2026-09-21.md` and `docs/llm/REVIEWS.md`.
Publish the reviewed `scripts/dockit-delivery-record.sh` / `docs/DELIVERY_CONTRACT.md`
candidate. `docs/ROADMAP.md` keeps full incident acceptance separate; the selective
preview in `docs/archive/DF058_FLEET_PREVIEW_2026-09-21.json` is not deployment.

## Do Not Touch

Preserve the primary checkout's inherited planning edits and unrelated adopter
worktrees. Do not mutate production, shared networking, NAS, HA or physical
controllers through this source task. Pilot operations must follow that
project's current authority and isolation requirements. Do not change the sync
manifest grammar or bypass independent review/versioning. Stage explicit paths.

## Selected Decisions

- D-009/D-011: DocKit substrate versus ForgeOS runtime/authority.
- D-020: exact Fable review, exact Opus only on recorded Fable quota exhaustion.
- D-021/D-022: selective sync, honest registration and template identity.
- D-023: opted-in command checks, evidence, continuity and recovery boundary.

## Trace Anchor

- Role: executor
- Subject: `811077a` docs: record Riego delivery postmortem and remediation handoff
- Commit time: 2026-09-19 13:27:15 UTC
- Repo state: committed baseline; this anchor is not a live HEAD assertion.
- Validation: implementation baseline and prior planning context loaded.
- Next gate: actual local pilot outcome, reviewed source publication and CI.
<!-- DOCKIT-STATE:END -->

## Historical Context

The prior long snapshot is preserved in
`docs/archive/HANDOFF_BEFORE_DF058_2026-09-21.md`. Review history is in
`docs/llm/REVIEWS.md`; stable rationale is in `docs/llm/DECISIONS.md`.
`docs/FLEET_ROLLOUT_2026-09-12.md` is historical fleet evidence, not a fresh
inventory. Riego delivery remains independent of this kit update.
