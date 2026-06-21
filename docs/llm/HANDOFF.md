<!-- doc-version: 4.12.2 -->
# LLM Work Handoff

This file is the current operational snapshot. Long-form rationale lives in `docs/llm/DECISIONS.md`.

## Open work — next concrete step

**Primary candidate closed in this session; operator chooses follow-up scope at next session open:**

1. **Closed: DF-050 / v4.12.2 session-start onboarding wording** — `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh` now state that the mandatory full reading order is session-start scoped, not per-turn. Later turns use stale-read re-verification instead: current clock before writing Trace, `git status`, current HEAD, and files directly relevant to the new request. D-015 records the rule. The D-007 mid-session escape remains: when scope widens or onboarding files change, reload onboarding and declare `Onboarding loaded (mid-session).`
1. **Closed: DF-049 / v4.12.1 copied doc-version normalization** — `scripts/dockit-sync.sh` now normalizes `<!-- doc-version: X.Y.Z -->` markers in copy-strategy files to the downstream project's `VERSION` immediately after copying and before post-sync validation. MED and ForgeOS surfaced the bug during v4.12.0 rollout when new `docs/integrations/CODEX.md` arrived with LLM-DocKit's `4.12.0` marker and triggered downstream `check-version-sync` rollback. D-014 records the rule: copied doc markers are downstream-owned, while sync state `template_version` remains the upstream template version. `scripts/test-validator.sh` now has a regression smoke for this exact case.
1. **Closed: DF-037 / Codex CLI lifecycle verification** — a fresh Codex CLI two-turn observation on 2026-06-21 verified that the v4.12.0 `--human` hook fires once at SessionStart and does not re-emit the onboarding marker per turn. DF-037 is rejected as empirically not reproduced after the implemented fix; the original repeated-marker symptom came from the old `--json` misconfiguration that DF-036 cured. The Codex CLI axis is now closed: DF-036 and DF-038 implemented, DF-037 rejected after observation.
1. **Closed: v4.12.0 Codex CLI integration axis** — `scripts/dockit-install-codex-hook.sh` installs a managed Codex CLI SessionStart hook that calls `scripts/dockit-bootstrap-context.sh --human` instead of Claude Code's `--json` envelope. `docs/integrations/CODEX.md` documents the tool-mode split, `docs/ROADMAP.md` records the remaining semantic-check and out-of-scope runtime boundaries, and D-013 captures the durable decision. Smoke coverage verifies replacing the old `--json` block and installer idempotence.
1. **Closed: DF-048 / v4.11.1 Trace anchor wording and generated-status helper** — `scripts/dockit-validate-session.sh` now supports the .dockit-config.yml key `trace_protocol.reject_current_anchor_label: true`, which fails HANDOFF Trace Anchor labels that imply live currency (`Current target:` / `Current audit target:`) for a committed repo-side anchor. `scripts/dockit-trace-status.sh` prints close-out Trace fields from current git/date state so executor/auditor messages do not reuse stale HEAD/time by hand. Smoke coverage exercises current-label rejection, neutral `Subject:` acceptance, and the helper output.
1. **Closed: DF-047 / v4.11.0 orientation-drift opt-in check** — `scripts/dockit-validate-session.sh` now has an `orientation-drift` check for projects with a phase-based roadmap. It is disabled by default and activates only with .dockit-config.yml `orientation_drift.enabled: true`. When enabled, it parses completed roadmap phases and fails if configured entry docs still describe a completed phase as "next". `scripts/test-validator.sh` covers skip/pass/fail cases. D-012 records why this semantic check is opt-in instead of fleet-default.
1. **Closed: v4.10.3 sync regression smoke** — `scripts/test-validator.sh` now covers DF-043 with a real `scripts/dockit-sync.sh --apply` regression: full adopters missing template sections get those sections inserted before the footer marker when present, or appended when no footer marker exists.
1. **Closed: v4.10.2 adopter-smoke fix** — `scripts/test-validator.sh` now skips the `scripts/dockit-init-project.sh` scaffold smoke with PASS when copied into downstream repos that do not ship the init script. This was caught while syncing MED after v4.10.1; the source repo still runs the scaffold smoke.
1. **Closed: DF-046 / v4.10.1** — `scripts/dockit-validate-session.sh` no longer treats a clean committed repo as stale just because the calendar day changed. `handoff-date` and `history-entry` now use the last commit date when the tracked tree is clean, and use today's date only when tracked files are dirty. MED surfaced the bug during the 2026-06-18 -> 2026-06-19 rollover; the fix has smoke coverage for clean old commits and dirty trees.
1. **Closed: DF-035 option (b.ii)** — `scripts/dockit-init-project.sh` now strips scaffold-author residue at init time and demotes optional `docs/ARCHITECTURE.md` to `docs/ARCHITECTURE.md.example` in freshly-scaffolded projects. New projects keep the architecture starter but do not receive it as a live architecture document. The init script also rewrites the target `docs/version-sync-manifest.yml` and README link to track the `.example` file, removes the LLM_START_HERE customization section, and rewrites the STRUCTURE opening into project voice. `scripts/test-validator.sh` now includes a real scaffold smoke asserting that a fresh project passes orientation/template-residue/version-sync.

**Likely next LLM-DocKit follow-ups:** continue the v4.12.1 adopter sync wave with dedicated sessions for conflict-bearing clean adopters. Start with `llm-council` or `plaud-mirror`; both need semantic resolution of local `LLM_START_HERE.md` sections instead of batch sync. ForgeOS needs its own WIP-aware session before sync. No Codex CLI lifecycle work remains after DF-037, and no consensus/runtime ownership work remains in LLM-DocKit after D-011.

**Closed in this doc-only session:** D-011 clarifies the LLM-DocKit / ForgeOS / `llm-council` boundary. LLM-DocKit owns scaffold/documentation substrate only: HANDOFF/HISTORY/DECISIONS/REVIEWS, Trace, validators, hooks, sync, and init. ForgeOS owns the live runtime and operator-facing surface for LMConsole, ProtocolEngine, VisualWorkbench, WorkEpisode, AuthorityEngine, and orchestration. `llm-council` owns the curated deliberation archive/corpus under `raw/<topic>/`. `docs/CONSENSUS_PROTOCOL_PROPOSAL.md` is now a stub pointing at `docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md`; `docs/llm/REVIEWS.md` remains a generic registry but no longer uses that archived proposal as normative source. No code changed and no version bump is expected.

**Closed in v4.9.6 this session:** DF-045 upstreamed the version/HISTORY guardrails that `youtube2text` had carried as local forks. `scripts/check-version-sync.sh` and `scripts/bump-version.sh` now support `json-version`, `yaml-info-version`, and `package-lock-version`; unknown marker types fail instead of warning/skipping. `scripts/dockit-validate-session.sh` `history-entry` now defaults to `history_format: any` and can enforce `dash` or `no-dash` via .dockit-config.yml; durable Trace HISTORY scanning accepts both dated entry shapes. D-010 records the fleet-safe policy: default lenient, strict by project config. Rollout note: do not force-sync the whole fleet immediately; verify one dash-format repo (for example `plaud-mirror`) and one no-dash-format repo (for example `youtube2text` or `cortex`) before treating this as fleet-safe. youtube2text local decision 019 is not closed until a later youtube2text session re-syncs and removes or supersedes its local fork.

**Closed in v4.9.0, hardened in v4.9.1, refined through v4.9.3, made syncable in v4.9.4, and sharpened in v4.9.5 previously:** DF-040 Trace Protocol shipped across `LLM_START_HERE.md`, `scripts/dockit-bootstrap-context.sh`, `scripts/dockit-validate-session.sh`, and `scripts/dockit-init-project.sh`. Chat-side Trace is default-on through SessionStart onboarding and can be disabled with `trace_protocol.enabled: false`; durable HANDOFF/HISTORY enforcement activates only when a project sets `trace_protocol.enabled: true` and `trace_protocol.since: YYYY-MM-DD`. New scaffolds now start with durable Trace enabled. v4.9.1 fixes the post-ship invalid-hash validation bug found by audit and expands `scripts/test-validator.sh` to 17 cases. v4.9.2 adds DF-041 Trace v1.1 `Resulting state` so message recency no longer masquerades as repo-state recency. v4.9.3 adds DF-042 Trace v1.2 verified dual-time `Sent` so local Madrid/CEST wall-clock time cannot be mislabeled as UTC. v4.9.4 closes DF-043: `scripts/dockit-sync.sh` now inserts newly-added marked sections into `adoption_mode: full` adopters, so the `trace-protocol` section can actually propagate during sync. v4.9.5 closes DF-044: chat `Sent` now includes seconds on local and UTC timestamps, and stale Trace reports must be re-verified before acting on their `Repo state`.

**Closed in v4.8.1 and hardened in v4.8.2 previously:** the `check_orientation` glob-character refinement and DF-039 opt-in zero-diff escape shipped together in `scripts/dockit-validate-session.sh`; `.claude/settings.json` Stop hook now opts into the read-only skip while CI and pre-commit do not. v4.8.2 moved the skip after target-file existence checks and added `scripts/test-validator.sh` so the validator smoke matrix is reproducible.

**Pending ecosystem follow-up:** the old Session 4 / Session 5 reconciliation no longer asks LLM-DocKit to own consensus/runtime design. A future ForgeOS ownership decision should decide how ForgeOS names and exposes the live LMConsole/ProtocolEngine surface and how it consumes `llm-council` as curated corpus. LLM-DocKit participates only as substrate.

## Pending ecosystem follow-up — ForgeOS / llm-council ownership

A multi-day deliberation on 2026-05-02→04 produced cross-repo proposals and surfaced a significant prior-art gap: `~/src/llm-council` (created 2026-03-01) substantially predates the LLM-DocKit Consensus proposal that was added on 2026-05-03. D-011 resolves the DocKit side of that gap: the proposal is lineage, not active DocKit scope.

**Master roadmap**: `~/src/home-infra/docs/SESSION_HANDOFF_2026-05-04_ECOSYSTEM_RECONCILIATION.md`

**For LLM-DocKit specifically**: do not implement consensus/runtime orchestration here. `docs/CONSENSUS_PROTOCOL_PROPOSAL.md` is archived as lineage. ForgeOS owns the live runtime / LMConsole / ProtocolEngine surface; `llm-council` owns the curated deliberation archive/corpus.

DFs whose runtime ownership is now outside DocKit scope: DF-030, DF-031, and DF-032 in `docs/DOWNSTREAM_FEEDBACK.md`. They remain useful evidence for the pending ForgeOS ownership decision and for `llm-council` corpus/curation work, but they no longer drive a DocKit consensus runtime.

## Current Status
- Last Updated: 2026-06-21 - Codex GPT-5
- Session Focus: **Cut v4.12.2 clarifying session-start onboarding scope.** DF-050 records the ForgeOS over-compliance case where an LLM reread full onboarding on a later turn despite no new SessionStart hook payload. D-015 now states that full onboarding is mandatory once per session; later turns re-check volatile state and relevant files, and only widened scope uses `Onboarding loaded (mid-session).`
- Previous (2026-06-21): Closed DF-037 after empirical Codex CLI verification; pushed `715e358`.
- Previous (2026-06-20): Cut v4.12.1 closing DF-049 after MED/ForgeOS exposed copied doc-version rollback during v4.12.0 rollout; pushed `283f9f0`.
- Previous (2026-06-19): Cut v4.12.0 closing the Codex CLI integration axis from DF-036/DF-038; pushed `17c2f50`.
- Previous (2026-06-19): Cut v4.11.1 closing DF-048 from MED Trace feedback; pushed `70e8528`.
- Previous (2026-06-19): Cut v4.11.0 closing DF-047 from MED orientation-drift feedback; pushed `6017866`.
- Previous (2026-06-19): Cut v4.10.3 closing the DF-043 regression-test gap; pushed `1dbbb33`.
- Previous (2026-06-19): Cut v4.10.2 after the MED sync caught a copied-smoke failure; pushed `9cd1a27`.
- Previous (2026-06-19): Cut v4.10.1 closing DF-046 after MED exposed the daily false-red in `handoff-date` / `history-entry`; pushed `f109afb`.
- Previous (2026-06-19): Cut v4.10.0 closing DF-035 option (b.ii); pushed `2d12579`.
- Previous (2026-06-19): Archived the Consensus proposal as lineage and closed the LLM-DocKit / ForgeOS / `llm-council` ownership boundary from the DocKit side; pushed `85b2bad`.
- Previous (2026-06-19): Cut v4.9.5 Trace v1.3 second-level `Sent` precision and stale-read re-verification; pushed `723afb4`, then recorded adopter rollout in `7d52340`.
- Previous (2026-06-18): Archived four long-lived local drafts and documented the LLM-DocKit/ForgeOS scope boundary as D-009; pushed `7cdc219`.
- Previous (2026-06-18): Cut v4.9.4, rolled out Trace v1.2 sync broadly, and closed second-pass sync drift in docs; pushed `a057fd7`.
- Previous (2026-06-18): Cut v4.9.3 verified dual-time `Sent` refinement; pushed `686a96e`.
- Previous (2026-06-18): Cut v4.9.2 Trace `Resulting state` refinement; pushed `d2d7afc`.
- Previous (2026-06-17): Cut v4.9.1 Trace commit validation hardening; pushed `01f90bb`.
- Previous (2026-06-17): Cut v4.9.0 Trace Protocol; pushed `d6fc816`.
- Previous (2026-05-17): Cut v4.8.2 validator polish; pushed `e9c4658`.
- Previous (2026-05-17): Cut v4.8.1 validator refinements; pushed `15ae98c`.
- Previous (2026-05-17): Third briefing-only session via `/brief`; filed and refined DF-039 after cross-LLM audit.
- Previous (2026-05-13): Briefing-only session, mini-update bookkeeping to satisfy Stop hook, no scope opened. Same pattern DF-039 now documents.
- Previous: **Cut v4.8.0 (minor) shipping `check_orientation` + `check_template_residue` in `scripts/dockit-validate-session.sh`, closing DF-034 fully and DF-035 option (a).** `check_orientation` (DF-034) asserts HANDOFF declares the next concrete step in a recognisable section (`## Open work` / `## Next concrete step` / `## Next Steps`), names ≥1 in-repo backtick-quoted file path, each path exists. `check_template_residue` (DF-035 (a)) greps canonical scaffold-shipped docs for the residue patterns DF-035 catalogues; FAIL on hard residue, WARN on empty `docs/llm/DECISIONS.md` after a configurable commit threshold. `LLM_START_HERE.md` template item 6 names *Open work* canonically; `dockit-init-project.sh` HANDOFF stub renamed `## Next Steps` → `## Open work — next concrete step` so newly-scaffolded projects pass orientation from first commit. DF-034 status → `implemented (4.8.0)`; DF-035 status → `partially implemented (4.8.0)` — option (a) shipped, option (b) strip-at-scaffold-time deferred to a future minor (the (b.i)/(b.ii) ARCHITECTURE.md decision is design, not mechanical, and merits a deliberation pass after this minor's empirical data lands). Smoke sweep results below.

- Previous: filed DF-034. **DF-034 filed** — auto-orientation contract is asserted by docs but tested nowhere. Doc-only commit, no version bump. The DF anchors its observation in commit SHAs from `home-infra-protocol` and `home-infra` (the multi-day cleanup chain that surfaced the gap). Three layered options (static check / dry-run / headless LLM); option (a) is the recommended first ship, with *Implementation hints* provided in the DF itself so the closing session can dispatch from this repo's own docs without bespoke context. Closing DF-034 is the test of fire for LLM-DocKit's self-sufficiency contract. The pre-existing 4.7.0/4.7.1 work and the Ecosystem Reconciliation gating remain unchanged.

- Previous: Cut **v4.7.0** (minor) shipping the SessionStart-side enforcement primitive — `scripts/dockit-bootstrap-context.sh` + `.claude/settings.json` SessionStart hook + `dockit-sync-manifest.yml` entry — closing **DF-033** (passive onboarding instructions in repo docs do not enforce session-start context loading). New decision **D-007** records the precedent that future "always read X at session start" rules ship as a hook + script, not as more prose. Counterpart of D-005 (session-end enforcement); together they bracket the session.
- Status: **Mechanical cure shipped on the Claude Code axis.** The new POSIX script reads `LLM_START_HERE.md` dynamically to extract the recommended reading order and emits a Claude Code `additionalContext` JSON payload (~1.5–2.4 KB; under the 10 KB SessionStart limit) with a small protocol the LLM must follow (`Onboarding loaded.` or `Onboarding skipped: <reason>` as the first line of the first substantive reply). `--human` mode of the same script is the manual workaround for non-Claude LLMs (Codex CLI, Cursor, web ChatGPT) until those tools grow equivalent hooks. Smoke-tested in both LLM-DocKit (1905 bytes JSON) and tomatic (9-item reading order, ~2.4 KB JSON), `python3 -m json.tool` validates output. Tomatic adopted directly in this same session (script + settings.json copied without waiting for `dockit-sync`); other downstream projects close on next sync pass. Adopter count of DF entries: 30 (DF-033 marked `implemented` on the Claude axis; rollout to other LLMs remains advisory). The former Consensus proposal was later archived by D-011 and is no longer active DocKit roadmap.
- Pending Proposals: none in LLM-DocKit. Former proposal/draft material is archived under `docs/archive/` with explicit status labels; see D-009 and D-011.

## Patch 4.8.0 Outcome
- `scripts/dockit-validate-session.sh`: two new check functions + `--check` registrations + main-loop additions + help-text update. `check_orientation` (~30 lines) and `check_template_residue` (~50 lines) sit alongside the existing 6 checks; both use the same `add_result` accumulator and same `should_run` filter pattern. Total checks now 8. Synthetic FAIL tests verified each branch: missing section, no paths, missing path, residue patterns all detected as expected.
- `LLM_START_HERE.md`: item 6 of "Recommended reading order:" rewritten to name HANDOFF *Open work — next concrete step* canonically and point at `--check orientation` as the enforcement primitive. The `dockit-bootstrap-context.sh` SessionStart hook reads this section dynamically, so the new wording propagates to every adopter on next session start without an explicit script change.
- `scripts/dockit-init-project.sh`: HANDOFF stub heading renamed `## Next Steps` → `## Open work — next concrete step` with a short paragraph naming the canonical contract. Existing `docs/PROJECT_CONTEXT.md` and `docs/STRUCTURE.md` backtick paths preserved so a fresh scaffold passes orientation from first commit. Smoke-tested: scaffold of `/tmp/smoke-init-*/smoke-test` produces orientation PASS (2 paths, all present), template-residue FAIL (the canonical templates ship with the residue this DF documents — FAIL is the *correct* signal until option (b) ships).
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-034 status `open` → `implemented (4.8.0)` with full closure note. DF-035 status `open` → `partially implemented (4.8.0)` with explicit note that option (b) is deferred and option (c) is reserved for v5+.
- `CHANGELOG.md`: `[4.8.0] - 2026-05-08` section added with Added / Changed / Notes blocks. Honest note in *Notes* about the freshly-scaffolded-fails-template-residue empirical observation.
- `dockit-sync-manifest.yml`: nothing new — the validator script is already synced via `copy`. New checks ship transparently to all adopters on next sync pass.
- VERSION 4.7.1 → 4.8.0; 8 doc-version markers in sync. Validator on this repo: 8/8 PASS (orientation PASS naming 4 paths, template-residue PASS skipped on source repo).

### Smoke sweep (read-only, per DF-034 *Cross-repo touches required*)

Three adopters surveyed: `tomatic`, `home-infra-protocol`, `pi-fleet`. **Per operator instruction, NO cross-repo edits made from this session — findings recorded here as local follow-ups for each adopter to address at its own pace.**

- **`tomatic`**: `template-residue` PASS. `orientation` FAIL — Open work names 7 paths missing in repo: `acceptance-test-pump.sh`, `acceptance-test-retain.sh`, `biome.json`, `.github/workflows/test.yml`, `pnpm-workspace.yaml`, `PROJECT_CONTEXT.md`, `tsconfig.base.json`. Likely cause: the prose names files using bare names where the actual paths include directory prefixes (e.g. `docs/PROJECT_CONTEXT.md`) and/or names files that have been moved/renamed since the prose was written. Real signal — HANDOFF needs reconciliation against current file tree.
- **`home-infra-protocol`**: `template-residue` PASS. `orientation` FAIL — Open work names 4 paths, 3 missing: `docs/HOMELAB_PROFILE_COLLISION_AND_POPULATE_PROPOSAL.md` (real planning-doc reference that may not exist yet), `forgeos/docs/llm/HANDOFF.md` (cross-repo relative path; HANDOFF should use absolute `~/src/forgeos/...`), `*_PROPOSAL.md` (glob, not a path — v4.8.0 limitation: `check_orientation` regex does not exclude glob chars; refinement filed as candidate v4.8.1 patch in the *Open work* block above).
- **`pi-fleet`**: `template-residue` PASS — confirms the 0.2.0 cleanup chain swept the residue catalogued in DF-035 successfully, **empirical positive #1** for `check_template_residue`. `orientation` FAIL — Open work section exists but contains no backtick-quoted paths. Real signal — HANDOFF dispatches no concrete work.

The `template-residue` PASS rate (3/3) was a happy surprise: the ecosystem appears to be cleaner of residue than DF-035's filing implied. The `orientation` FAIL rate (3/3) is the more interesting empirical finding — every surveyed adopter has HANDOFF prose that names paths inaccurately, glob-shaped, or absent. This validates DF-034's central thesis: the orientation contract was unchecked long enough that prose drifted unnoticed across the ecosystem.

## Patch 4.7.0 Outcome
- `scripts/dockit-bootstrap-context.sh` (new, ~7 KB, POSIX sh, zero deps): SessionStart-side counterpart of `dockit-validate-session.sh`. Reads `LLM_START_HERE.md` "Recommended reading order:" section and emits an `additionalContext` JSON payload (`--json`, default) or plain text (`--human`) for the operator to paste into non-Claude LLM sessions. Includes `--quiet` and `--project PATH` options; project root resolution via `git rev-parse --show-toplevel` with script-dir fallback. JSON escaping done with awk (POSIX, no jq dependency). Graceful degradation: emits nothing if `LLM_START_HERE.md` is missing (does not break sessions in non-LLM-DocKit repos).
- `.claude/settings.json`: new SessionStart hook block calling the script with `--json`. Wrapped in `sh -c 'if [ -x scripts/dockit-bootstrap-context.sh ]; then ...; fi'` so downstream copies that arrive before the script no-op gracefully. Stop / PostToolUse / PreCompact hooks unchanged.
- `dockit-sync-manifest.yml`: new entry `- path: scripts/dockit-bootstrap-context.sh strategy: copy` registered immediately after `dockit-validate-session.sh`, so downstream projects pick the script up on next `dockit-sync` pass alongside the matching `.claude/settings.json` (also `copy`).
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-033 added at `Status: implemented` (Claude axis) with full Observation / Protocol implication / Cross-protocol relationship / Mitigation sections. Related: DF-005, DF-015, DF-024, DF-031. Inverse counterpart of `docs/HOOKS_ENFORCEMENT_PROPOSAL.md`.
- `docs/llm/DECISIONS.md`: D-007 added — "Session-start onboarding is enforced mechanically, not by prose." Records the precedent for future "always read X at session start" rules.
- Cross-repo: tomatic gets `scripts/dockit-bootstrap-context.sh` + the matching SessionStart entry in `.claude/settings.json` applied directly in this session (not via `dockit-sync`) so the failure mode is closed for the project under active work; tomatic HANDOFF/HISTORY updated. Other downstream projects (`plaud-mirror`, `home-infra-protocol`, `infra-portal`, `llm-council`) close the scaffold side on next operator-driven `dockit-sync` pass — but the Codex CLI hook covers them all today via the global user-level config (see below).
- Codex CLI axis closed (post-4.7.0, doc-only follow-up). Operator-side wiring in `~/.codex/config.toml` (`[features] codex_hooks = true` + `[[hooks.SessionStart]]` calling the central LLM-DocKit script with `--project "$(git rev-parse --show-toplevel)"`) — Codex's SessionStart hook accepts the exact same `hookSpecificOutput.additionalContext` JSON shape as Claude Code, so the same script drives both LLMs without modification. Smoke-tested 2026-05-03 in `home-infra-protocol` (the originally-failing repo): Codex's first substantive reply began with `Onboarding loaded.` followed by ecosystem-aware content (cited version 0.3.0, deployment evidence contract, intent-vs-telemetry rule). DF-033 status updated to "implemented (Claude Code + Codex CLI axes)"; D-007 follow-ups updated. Cursor / Aider remain pending until they grow SessionStart equivalents. CHANGELOG 4.7.0 not amended — the user-level Codex wiring is operator-side workflow, not a scaffold artefact (the scaffold ships the script + Claude wiring + Codex JSON-shape compatibility; the wiring is operator-owned).
- **Patch 4.7.1 shipped same session**: awk regex in the bootstrap script no longer exits early on a blank line between "Recommended reading order:" and the numbered list. Surfaced during the 4.7.0 smoke test against `home-infra-protocol` (the originally-failing repo): its `LLM_START_HERE.md` has a blank line after the header, so 4.7.0 fell back to a generic 2-item list and the agent in the smoke test was technically protocol-compliant ("Onboarding loaded.") but had not been instructed to read the 7 real items (SPEC.md, PROJECT_CONTEXT.md, ARCHITECTURE.md, COMPLETION_RULE.md, HANDOFF.md, DECISIONS.md). GPT flagged this as exactly the DF-024 pattern the protocol exists to fight — documenting closure while the originally-failing instance receives degraded onboarding. Fix in awk: track a `started` flag so the blank-line-exit only fires after the first numbered item has been captured. Verified post-fix: home-infra-protocol now emits its 7 real items; tomatic and LLM-DocKit regressions clean. Bumped 4.7.0 → 4.7.1 (patch).

## Patch 2026-05-03 Outcome
- `docs/archive/CONSENSUS_PROTOCOL_PROPOSAL.md` (originally `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`): historical self-contained proposal formalising the deliberation primitive that was in informal use across sessions. D-011 later archived it as lineage because LLM-DocKit does not own consensus/runtime orchestration.
- `docs/llm/REVIEWS.md`: rewritten from the legacy stub into a structured audit trail. First entry (2026-05-03) records the run that produced the now-archived proposal. It remains useful historical rationale, but the file itself is now a generic DocKit registry rather than a Consensus Protocol runtime contract.
- `docs/DOWNSTREAM_FEEDBACK.md` DF-029 originally moved to `accepted` with cross-reference to the proposal. D-011 later superseded the process-side DocKit ownership; the remaining DocKit-relevant work is only the optional `--check deployed-version` validator surface if an adopter asks for it.

## Do Not Touch (for parallel sessions)

No active Do Not Touch files are currently declared in this repo after the
2026-06-18 draft cleanup. The former root-level drafts are now archived and
committed under `docs/archive/` with explicit status labels. They are lineage,
not active implementation instructions.

Sessions that need to stage changes should use explicit paths (`git add <path>`), never `git add -A` or `git add .`. The `dockit-init-project.sh` script in this repo is robust against these (uses `git archive HEAD` so untracked files never leak); manual sessions need the same discipline.

## Patch 4.6.1 Outcome (previous session)
- `scripts/dockit-init-project.sh`: added `git symbolic-ref HEAD refs/heads/main` immediately after `git init -q`. Portable to any Git version (no dependency on `git init -b main` from 2.28+). Smoke test confirms `main` from the first commit.
- `CHANGELOG.md`: 4.6.1 section explains the bug and the fix; references the GPT-5 review that surfaced it.

## Patch 4.6.0 Outcome (carried forward from previous session)
- `scripts/dockit-init-project.sh`: new POSIX `sh` script. Inputs: `<project-name>` plus optional `--target-dir`, `--language`, `--source` flags. Outputs a self-contained new project ready for first session. The script:
  1. Validates inputs (slug pattern, target absent, source is a git repo with VERSION).
  2. `git archive HEAD | tar -x` from the source DocKit checkout into the target directory (tracked files only — drafts in the source working tree never leak).
  3. Removes DocKit-internal meta files: `HOW_TO_USE.md`, `docs/DOWNSTREAM_FEEDBACK.md`, `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`, `dockit-sync-manifest.yml`, `scripts/dockit-sync.sh`, `scripts/dockit-sync-check.sh`, `scripts/dockit-init-project.sh` itself.
  4. Resets live operational docs (`CHANGELOG.md`, `docs/llm/HANDOFF.md`, `docs/llm/HISTORY.md`, `docs/llm/DECISIONS.md`) to fresh stubs — so DocKit's own DF entries / D-001..D-006 / session history don't leak into the new project.
  5. Substitutes `<PROJECT_NAME>`, `<CONVERSATION_LANGUAGE>`, `<YYYY-MM-DD>` and similar placeholders in remaining `*.md`/`*.yml`/`*.json`.
  6. Runs `scripts/bump-version.sh 0.1.0` to set VERSION and sync doc-version markers atomically.
  7. Initializes a fresh git repository with a single "chore: initial scaffold from LLM-DocKit X.Y.Z" commit.
- Strict scope respected: no GitHub remote, no push, no ecosystem-profile application, no global config edits. Higher-layer orchestrators (such as a future `home-infra-protocol/integrations/dockit/new-homelab-project.sh`) call this script as their first step and add their own concerns on top.
- `HOW_TO_USE.md` reorganized: the new "Quick Start (one command, recommended)" section is now the canonical path; the previous manual flow remains available as "Quick Start (manual)" for Windows / CI environments without the helper script.
- Smoke test: ran the script three times against `/tmp/smoke-init` while iterating. Two real bugs caught and fixed before commit — (a) `tar` from the working tree leaked five untracked DocKit drafts (`documento.md`, `LLM_DOCKIT_CE_V2_PROPOSAL.md`, `HOOKS_ENFORCEMENT_PROPOSAL.md`, `DEFERRED_NEXT_VERSION.md`, `EXTERNAL_CONTEXT_PLUGIN_PLAN.md`) into the new project; switched to `git archive HEAD` and added a hard-fail when source has no `.git`. (b) The fresh `CHANGELOG.md` had no `## [` anchor for `bump-version.sh` to insert before, leaving the new project's `[0.1.0]` section empty; fixed by emitting the section directly in the stub. Final smoke run: validator 6/6 PASS, 8 doc-version targets in sync at 0.1.0.

### Pre-existing v4.5.x backlog (still relevant, deferred to v4.7.0)

### Feedback intake workflow
- Downstream adopter observes a problem → summarises it into a DF-NNN entry in `docs/DOWNSTREAM_FEEDBACK.md` of this repo (fields: Source, Date, Category, Status, Observation, Protocol implication).
- DocKit maintainer reviews the log when planning a bump; open entries become candidate work.
- When a fix lands, the entry is updated to `Status: implemented` with a pointer to the commit/doc change, NOT deleted.
- Rejected entries also stay in place with rationale.

### Prior session context (v4.4.0, 2026-03-23 - Claude Opus 4.6)
Read-only session — reviewed full project state, summarized completed Phase 1 work, identified pending items (git tags, uncommitted changes, pilot sessions remaining), outlined short/medium/long-term roadmap. Left in place here as the last technical snapshot before v4.5.0.

## Project Summary

**LLM-DocKit** is a documentation scaffold for LLM-assisted projects. It solves the problem of memory loss between LLM sessions by providing:
- `docs/llm/HANDOFF.md` — operational snapshot (this file)
- `docs/llm/HISTORY.md` — append-only change log per session
- `docs/llm/DECISIONS.md` — durable architectural decisions with rationale
- `LLM_START_HERE.md` — mandatory rules for any LLM working on the project
- Version sync tooling (bump-version.sh, check-version-sync.sh, pre-commit hook)
- Downstream template sync (`scripts/dockit-sync.sh`, 1192 lines POSIX sh, 4 strategies)

**Repository:** https://github.com/cdelalama/LLM-DocKit
**Current version:** see `VERSION` (single source of truth — prose strings here drift; the file does not)
**Tech stack:** POSIX shell scripts only, zero external dependencies

## The Core Problem

LLM_START_HERE.md says "update HANDOFF and HISTORY every session" but this is purely advisory. LLMs forget. On 2026-02-28, HANDOFF.md was modified but its own `Last Updated` field was not changed, and HISTORY.md received no entry. The rules existed; they were not followed.

**Root cause:** compliance depends on LLM discipline, not on system enforcement.

---

## Decision Lock (2026-03-01)

Confirmed by human owner after 4 rounds of cross-LLM review (Claude Opus 4.6 + ChatGPT Codex GPT-5). Full review history in `docs/llm/HISTORY.md`.

### Execution Order: A -> B -> C

Three initiatives exist for evolving LLM-DocKit. They are **layers, not alternatives**:

```
Layer 3: Code Factory recs (C) .... improves quality of rules and contracts
Layer 2: CE V2 (B) ................ defines workflows, modes, session structure
Layer 1: Hook Enforcement (A) ..... guarantees rules are followed
Layer 0: LLM-DocKit v4.0.0 ........ the current scaffold base
```

Without Layer 1 (enforcement), Layers 2 and 3 are advisory — the same problem we have today. A is the foundation that makes B and C enforceable.

### Phase 1 Scope (Initiative A — locked)

Implement now, pilot 10 sessions, then decide B/C with real data.

**Components:**
1. `scripts/dockit-validate-session.sh` — portable POSIX validator (checks: handoff-date, history-entry, decisions-referenced, version-sync, external-context, external-triggers)
2. `.claude/settings.json` — Stop hook (blocking), PostToolUse nudge (non-blocking), PreCompact reminder
3. `.claude/rules/require-docs-on-code-change.md` — path-triggered rule
4. `.claude/skills/update-docs/SKILL.md` — convenience `/update-docs` command
5. Extend `scripts/pre-commit-hook.sh` — call validator at commit time
6. `.github/workflows/doc-validation.yml` — CI safety net for PRs

**Enforcement cascade:**
```
Stop hook (Claude Code)     <- Catches drift in real-time (best)
  |
  v  (if LLM tool has no hooks)
Pre-commit hook             <- Catches drift at commit time (good)
  |
  v  (if commit bypasses hooks)
CI validation               <- Catches drift at PR time (safety net)
  |
  v  (if CI skipped)
Manual: run validate script <- Human runs it (last resort)
```

**Blocking semantics:**
- Stop/SubagentStop: block via exit code 2 or JSON `{"decision": "block", "reason": "..."}`
- PostToolUse/PreCompact: non-blocking feedback only

**Acceptance criteria:**
1. Trying to stop with stale HANDOFF/HISTORY is blocked in Claude Code
2. Commit with stale docs is blocked by pre-commit
3. PR with stale docs fails CI
4. Updating HANDOFF+HISTORY in same session unblocks all gates
5. False-positive rate stays low across 10+ sessions

### Design Constraints for Future Compatibility

The validator must be extensible for future B/C integration:
- Check functions are modular (add new checks without modifying existing ones)
- Support optional `--check <name>` flag to run specific checks only
- JSON output format can grow (add fields, never remove)
- If B's monthly HISTORY sharding is adopted later, only the `history-entry` check function changes
- If B's `work_unit_id` or session manifests are adopted, they become new check functions

### Initiative B: CE V2 (deferred, split into subfases)

**Document:** `docs/archive/LLM_DOCKIT_CE_V2_PROPOSAL.md` (archived lineage, 407 lines)
**Status:** Hybrid lineage. Some pieces shipped in LLM-DocKit 4.x; session-manifest / authority / protocol-runtime ideas now map better to ForgeOS. Too large for single pilot — split into:
- B1: Traceability (work_unit_id, session manifests)
- B2: Review discipline (monthly reviews, SHA pinning)
- B3: Solutions library (candidate/canonical lifecycle)

Adopt only parts that solve problems demonstrated during pilot.

### Initiative C: Code Factory Recommendations (deferred)

**Document:** `docs/archive/documento.md` (archived lineage, 264 lines, Spanish)
**Status:** Inspiration source, not accepted roadmap. Key items (risk tiers, CONTRACT.yaml, SHA discipline) require a fresh DF or ForgeOS ticket before adoption.

---

## Files in This Repository

### Committed (in git)
- `VERSION` -> 4.4.0
- `scripts/dockit-sync.sh` -> template propagation (1192 lines)
- `scripts/dockit-sync-check.sh` -> downstream status checker
- `scripts/bump-version.sh` -> atomic version bump
- `scripts/check-version-sync.sh` -> version drift validator
- `scripts/pre-commit-hook.sh` -> git hook template
- `scripts/dockit-validate-session.sh` -> documentation enforcement validator (Phase 1 + external-context)
- `scripts/dockit-generate-external-context.sh` -> External Context section generator
- `.claude/settings.json` -> Claude Code hook configuration (Phase 1)
- `.claude/rules/require-docs-on-code-change.md` -> path-triggered doc reminder
- `.claude/skills/update-docs/SKILL.md` -> /update-docs convenience command
- `.claude/skills/adopt-dockit/SKILL.md` -> /adopt-dockit skill for existing repos
- `.github/workflows/doc-validation.yml` -> CI validation for PRs
- `dockit-sync-manifest.yml` -> sync strategies per file
- `docs/version-sync-manifest.yml` -> version-tracked files
- `LLM_START_HERE.md` -> mandatory LLM rules (9 template sections)
- `HOW_TO_USE.md` -> complete setup guide
- Full docs/ structure (see docs/STRUCTURE.md)

### Archived lineage (committed in git)
- `docs/archive/HOOKS_ENFORCEMENT_PROPOSAL.md` — initial hooks proposal, implemented by LLM-DocKit 4.x
- `docs/archive/DEFERRED_NEXT_VERSION.md` — control-plane / arbiter / dashboard idea, superseded by ForgeOS
- `docs/archive/LLM_DOCKIT_CE_V2_PROPOSAL.md` — RFC for Compound Engineering v2, hybrid lineage
- `docs/archive/documento.md` — LLM-DocKit vs Code Factory comparison, inspiration source

## Current Versions
- LLM-DocKit: 4.4.0
- sync_tool_version: 1.0.0

## Top Priorities
1. Pilot: 10 sessions with enforcement active in LLM-DocKit repo
2. ~~Git tags~~ done (v4.0.0, v4.1.0, v4.2.0 — v4.3.0 pending after commit)
3. Evaluate pilot data and decide B/C adoption
4. Rollout to downstream projects (nas-backup, youtube2text) — after pilot

## Key Decisions (Links)
- D-001: Restricted flat grammar for manifest — see docs/llm/DECISIONS.md
- D-002: Runtime in .git/.dockit/ — see docs/llm/DECISIONS.md
- D-003: CONFLICT without --force triggers full rollback — see docs/llm/DECISIONS.md
- D-004: OUTDATED = template_version string compare, not SemVer — see docs/llm/DECISIONS.md (corrected 2026-03-01)
- D-005: Pre-commit blocks product code commits without VERSION bump — see docs/llm/DECISIONS.md
- D-006: External context uses separate markers (DOCKIT-EXTERNAL-CONTEXT) — see docs/llm/DECISIONS.md

## Do Not Touch
- scripts/bump-version.sh, scripts/check-version-sync.sh (template-managed, synced via copy)
- dockit-sync-manifest.yml schema (schema_version: 1)

## External Context Plugin

Design: `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`

**v1 (implemented, v4.2.0):** Generation script + `check_external_context` in validator. Projects declare external doc repos in `.dockit-config.yml`. Populates `LLM_START_HERE.md` between `DOCKIT-EXTERNAL-CONTEXT` markers. Validates path + file existence. `DOCKIT_SKIP_EXTERNAL=1` skips in CI.

**v1.1 (implemented, v4.3.0):** `check_external_triggers` in validator (WARN when local changes match update_triggers). `--claude-rules` flag generates `.claude/rules/external-context-triggers.md` with glob frontmatter (no absolute paths).

## Claude Code Documentation References (verified 2026-03-01)
- Hooks (17 events): https://docs.anthropic.com/en/docs/claude-code/hooks
- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Memory & rules: https://docs.anthropic.com/en/docs/claude-code/memory
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Subagents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
