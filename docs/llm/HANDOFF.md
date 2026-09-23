<!-- doc-version: 4.17.0 -->
# LLM Work Handoff

## Dossier optional discovery candidate (4.17.0, 2026-09-23)

Isolated `feat/dossier-discovery` worktree adds a filename-only notice to the
existing bootstrap when `.forgeos/dossier.json` exists, including malformed
files. It does not execute/parse project configuration, copy a capture engine,
change hooks, or claim shared publication. Canonical contract and CLI remain
in ForgeOS docs/modules/dossier/OFFLINE_CONTRACT.md and scripts/dossier.py.
Trace instructions link the last checked local revision, without mandatory
recapture. Absent declarations produce byte-identical onboarding output.
Focused regression: scripts/test-dossier-discovery.sh. Exact Opus 5.5 high
source review and final delta are SOURCE_GO; no fleet sync or default hook
activation. Full validation: 96 validator tests, 84 delivery tests and focused
Dossier discovery PASS; four configured DocKit skips remain visible.
Earlier source/release and DF-058 gates below remain historical and independent.

<!-- DOCKIT-STATE:START -->
## Current Status

- Last Updated: 2026-09-23 - Codex
- Current source version: 4.17.0
- Owner: Carlos
- Session focus: optional Dossier onboarding and Trace guidance; D-024 and delivery pilot gates unchanged.
- Previous source: v4.16.1 policy release, exact Opus 5.5 final delta GO;
  validation and candidate provenance are recorded in REVIEWS.md.
  Previous release v4.16.0 was published via PR #2; delivery gates are unchanged.
- Pilot: Riego local container command integrated; adverse controls and one real
  local packaging attempt pass. Gardener/off-LAN acceptance remains open.
- Validation: 84 delivery and 96 validator regressions pass; 10 version targets
  agree. Seven source checks pass; four legitimate skips remain visible.

## Open work -- next concrete step

Current model policy: `LLM_START_HERE.md` independent-review-policy; adoption
instructions: `HOW_TO_USE.md` Claude Model Default. Runtime settings are separate
from selective repository sync. See `docs/CLAUDE_DEFAULT_2026-09-23.md` for actual
surface coverage and limits. Preserve earlier review provenance and dirty adopters.
Open tooling follow-up: `scripts/dockit-sync.sh` rejects linked worktrees as
not a repository. After a separately validated repair, rerun a selective dry-run
against ForgeOS and reconcile its state without force or unrelated updates.

Use `docs/DELIVERY_CONTRACT.md` and `scripts/dockit-delivery-record.sh` to
integrate the next real project delivery command with its own decisive probes.
Record actual outcome acceptance in `docs/archive/DF058_IMPLEMENTATION_2026-09-21.md`
and retain the boundary in `docs/ROADMAP.md`: local packaging is accepted, while
Riego gardener/off-LAN use and broad entrypoint adoption remain open. The 38-project
preview in `docs/archive/DF058_FLEET_PREVIEW_2026-09-21.json` applied no changes.

## Do Not Touch

Preserve unrelated adopter worktrees. The inherited primary planning edits are
incorporated in this release and retained as an exact local Git-directory backup. Do not mutate production, shared networking, NAS, HA or physical
controllers through this source task. Pilot operations must follow that
project's current authority and isolation requirements. Do not change the sync
manifest grammar or bypass independent review/versioning. Stage explicit paths.

## Selected Decisions

- D-009/D-011: DocKit substrate versus ForgeOS runtime/authority.
- D-024 supersedes D-020 model preference: exact Opus 5.5 at high effort by default;
  explicit task selection wins, no silent fallback. Independent review remains required.
- D-021/D-022: selective sync, honest registration and template identity.
- D-023: opted-in command checks, evidence, continuity and recovery boundary.

## Trace Anchor

- Role: executor
- Subject: `f3bd177` Merge pull request #2 from cdelalama/feat/df058-delivery
- Commit time: 2026-09-21 15:48:00 UTC
- Repo state: committed baseline; this anchor is not a live HEAD assertion.
- Validation: 84 delivery tests, 96 validator regressions, exact review and CI PASS.
- Next gate: project-specific delivery integration and real user-path acceptance.
<!-- DOCKIT-STATE:END -->

## Historical Context

The prior long snapshot is preserved in
`docs/archive/HANDOFF_BEFORE_DF058_2026-09-21.md`. Review history is in
`docs/llm/REVIEWS.md`; stable rationale is in `docs/llm/DECISIONS.md`.
`docs/FLEET_ROLLOUT_2026-09-12.md` is historical fleet evidence, not a fresh
inventory. Riego delivery remains independent of this kit update.
