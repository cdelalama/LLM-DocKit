# Changelog

All notable changes to this scaffold are documented in this file.

This project follows Semantic Versioning (SemVer): MAJOR.MINOR.PATCH.

## [4.13.0] - 2026-07-10

### Added

- `scripts/dockit-session-gate.sh`: POSIX SessionStart/Stop driver that reads
  Claude Code hook JSON, stores per-`session_id` tracked-state baselines under
  `.git/.dockit/session-baselines/`, reports real validator failures, and
  honors `stop_hook_active`.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-052 records the home-infra inherited-dirty
  incident and supersedes only DF-039 Case C's discipline-only closure.
- `docs/llm/DECISIONS.md`: D-017 records the deliberate one-block Stop
  semantics and the remaining pre-commit/CI enforcement boundary.

### Changed

- `.claude/settings.json`: SessionStart records a session baseline and Stop
  delegates to the testable session gate instead of an inline shell command.
- `scripts/dockit-validate-session.sh`: the opt-in read-only escape accepts an
  unchanged HEAD plus tracked-diff baseline, while retaining the existing
  zero-tracked-diff fallback. Untracked files remain excluded by design.
- `dockit-sync-manifest.yml`: propagates the session gate to adopters via the
  existing `copy` strategy.
- `docs/STRUCTURE.md` and `HOW_TO_USE.md`: identify the session gate as a
  required Claude Code enforcement script that adopters must retain.
- `scripts/test-validator.sh`: expands the smoke matrix to 56 cases, including
  inherited dirt, same-path edits, one-block yielding, compact/resume,
  parallel sessions, fail-closed handling, untracked exclusion, seven-day
  pruning, and the post-sync warning.

### Fixed

- Claude Code Stop no longer repeats the same opaque block when
  `stop_hook_active` is true; modern harnesses can stop after one actionable
  validation message.
- Read-only sessions can inherit tracked dirt without being blamed for it;
  any change to HEAD or the tracked diff still keeps date checks strict.
- `scripts/dockit-sync.sh --apply` now warns operators to review and commit
  successful sync changes before opening unrelated sessions. It does not
  auto-commit or stage files.

## [4.12.3] - 2026-06-22

### Added

- `docs/DOWNSTREAM_FEEDBACK.md`: DF-051 records the Trace scope gap where
  agents could rationalize skipping chat Trace for opinions, recommendations,
  brainstorming, or clarifying questions.
- `docs/llm/DECISIONS.md`: D-016 records Trace Protocol v1.4: every
  substantive assistant turn in a DocKit-governed session starts with Trace,
  and the chat role vocabulary is `executor|auditor|advisor`.

### Changed

- `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh`: expand Trace
  chat-side scope from executor/auditor reports to every substantive turn, with
  a concrete definition of `substantive` for multi-window operator workflows.
- `scripts/dockit-trace-status.sh`: accept the new `advisor` role so the
  generated Trace scaffold matches Trace Protocol v1.4.
- `scripts/dockit-validate-session.sh`: durable Trace role validation now
  accepts the same `executor|auditor|advisor` vocabulary.

### Fixed

- Closed the wording loophole that let agents skip Trace by classifying a
  message as "only opinion", "only design", or "only recommendation".
- `scripts/test-validator.sh`: adds smoke coverage that both durable Trace and
  `dockit-trace-status.sh --role advisor` accept the new role.

## [4.12.2] - 2026-06-21

### Added

- `docs/DOWNSTREAM_FEEDBACK.md`: DF-050 records the ForgeOS-originated
  over-compliance case where an LLM reread full onboarding on a later turn even
  though no new SessionStart hook payload fired.
- `docs/llm/DECISIONS.md`: D-015 records that mandatory onboarding is
  session-start scoped, while later turns use targeted stale-read
  re-verification.

### Changed

- `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh`: clarify that
  the full reading order is mandatory once per session, not per turn. Later
  turns should re-check volatile state and directly relevant files instead of
  rereading every onboarding document.

### Fixed

- Reduced onboarding over-compliance in LLM tools that interpreted "MUST read"
  as "read every turn" after the hook payload had already loaded for the
  session.

## [4.12.1] - 2026-06-20

### Added

- `scripts/test-validator.sh`: regression smoke for copying a new
  doc-versioned template file into a downstream project whose `VERSION` differs
  from LLM-DocKit's template version.

### Changed

- `docs/DOWNSTREAM_FEEDBACK.md`: DF-049 records the MED/ForgeOS rollout
  failure where `docs/integrations/CODEX.md` arrived with the template version
  marker and triggered post-sync rollback.
- `docs/llm/DECISIONS.md`: D-014 records that copied doc-version markers are
  normalized to the downstream project version during sync.

### Fixed

- `scripts/dockit-sync.sh`: copy-strategy files that contain
  `<!-- doc-version: X.Y.Z -->` are normalized to the downstream project's
  `VERSION` before post-sync validation. This prevents new version-tracked docs
  such as `docs/integrations/CODEX.md` from causing immediate rollback in
  adopters with their own SemVer line.

## [4.12.0] - 2026-06-19

### Added

- `scripts/dockit-install-codex-hook.sh`: idempotent installer for the Codex
  CLI SessionStart hook. It writes a managed `~/.codex/config.toml` block that
  invokes `dockit-bootstrap-context.sh --human`, with a timestamped backup.
- `docs/integrations/CODEX.md`: operator-facing Codex CLI integration guide
  documenting the Claude Code `--json` vs Codex CLI `--human` split.
- `docs/ROADMAP.md`: source-only roadmap that keeps semantic-check candidates
  and consensus/runtime boundaries out of transient chat.
- `scripts/test-validator.sh`: smoke coverage for replacing the old `--json`
  Codex hook and for installer idempotence.

### Changed

- `docs/DOWNSTREAM_FEEDBACK.md`: DF-036 and DF-038 are implemented; DF-037 is
  narrowed to a fresh Codex CLI lifecycle verification after the `--human`
  hook is installed.
- `docs/llm/DECISIONS.md`: D-013 records Codex CLI onboarding ownership and the
  tool-mode split.
- `dockit-sync-manifest.yml`: Codex installer and integration docs propagate to
  downstream adopters; `docs/ROADMAP.md` stays source-only.
- `scripts/dockit-init-project.sh`: new scaffolds now remove
  `docs/ROADMAP.md` because that file tracks LLM-DocKit's own roadmap, not a
  downstream project's plan.

### Fixed

- Closes the documented Codex CLI flag mismatch where the operator config used
  Claude Code's JSON envelope for Codex CLI onboarding.

## [4.11.1] - 2026-06-19

### Added

- `scripts/dockit-trace-status.sh`: helper that prints a Trace header scaffold
  from current git/date state (HEAD, upstream, cleanliness, VERSION, local and
  UTC timestamps) so agents do not manually copy stale close-out state.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-048 records the MED-originated stale Trace
  Anchor / stale chat Trace pattern.

### Changed

- `LLM_START_HERE.md`: Trace guidance now recommends generating close-out
  fields with `scripts/dockit-trace-status.sh`.

### Fixed

- `scripts/dockit-validate-session.sh`: projects can set
  `trace_protocol.reject_current_anchor_label: true` to reject HANDOFF Trace
  Anchor labels (`Current target:` / `Current audit target:`) that imply live
  HEAD currency for a committed repo-side anchor.
- `scripts/test-validator.sh`: smoke coverage for stale-anchor rejection,
  HEAD-anchor acceptance, and trace-status output.

## [4.11.0] - 2026-06-19

### Added

- `scripts/dockit-validate-session.sh`: new opt-in `orientation-drift` check.
  Projects can set `orientation_drift.enabled: true` in `.dockit-config.yml`
  to fail when entry docs describe a completed roadmap phase as "next".
- `scripts/test-validator.sh`: smoke coverage for `orientation-drift` skip,
  pass, and fail cases, plus exact `--check` token matching so
  `orientation-drift` no longer also runs `orientation`.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-047 records the MED-originated
  orientation-drift pattern.
- `docs/llm/DECISIONS.md`: D-012 records that semantic roadmap checks are
  opt-in and project-configured, not fleet-default.

### Changed

- `scripts/dockit-validate-session.sh --help`: lists `orientation-drift` as a
  first-class check.

### Fixed

- `scripts/dockit-validate-session.sh`: `--check` filtering now compares exact
  check names instead of substring matches. This prevents `--check
  orientation-drift` from also running `orientation`.

## [4.10.3] - 2026-06-19

### Added

- `scripts/test-validator.sh`: regression smoke for DF-043. It creates
  throwaway full adopters missing template sections and verifies
  `scripts/dockit-sync.sh --apply` inserts those sections before the footer
  marker when present, or appends them when no footer marker exists.

### Changed

### Fixed

## [4.10.2] - 2026-06-19

### Added

### Changed

### Fixed

- `scripts/test-validator.sh`: the `scripts/dockit-init-project.sh` scaffold
  smoke now skips with PASS when copied into downstream repos that do not ship
  the init script. The smoke still runs in LLM-DocKit itself.

## [4.10.1] - 2026-06-19

### Added

- `docs/DOWNSTREAM_FEEDBACK.md`: DF-046 records the daily false-red surfaced by
  MED when `handoff-date` / `history-entry` used wall-clock time for clean
  committed repos.

### Changed

- `scripts/dockit-validate-session.sh`: `handoff-date` and `history-entry`
  now validate against the last commit date when the tracked tree is clean, and
  against today's date when tracked files are dirty.

### Fixed

- Closes DF-046: clean committed repos no longer go red the next day solely
  because the wall clock advanced.

## [4.10.0] - 2026-06-19

### Added

- `scripts/test-validator.sh`: real `dockit-init-project.sh` scaffold smoke for
  DF-035 option (b.ii). The smoke creates a throwaway project and asserts that
  `docs/ARCHITECTURE.md` is absent, `docs/ARCHITECTURE.md.example` is present,
  the target version manifest tracks the example file, and orientation /
  template-residue / version-sync validation passes.

### Changed

- `scripts/dockit-init-project.sh`: freshly-scaffolded projects now demote the
  optional architecture starter to `docs/ARCHITECTURE.md.example` instead of
  shipping it as live `docs/ARCHITECTURE.md`.
- New scaffolds now rewrite their version manifest and README architecture link
  to the `.example` file, remove LLM_START_HERE scaffold-author customization
  prose, and rewrite the STRUCTURE starter sentence into project voice.
- `LLM_START_HERE.md` now tells agents to read `docs/ARCHITECTURE.md` only when
  a project has materialized it; otherwise `docs/ARCHITECTURE.md.example` is a
  starter template.

### Fixed

- Closes DF-035 option (b.ii): template-residue no longer survives initial
  project creation merely because the optional architecture template exists.

## [4.9.6] - 2026-06-19

### Added

- Version sync marker support for `json-version`, `yaml-info-version`, and
  `package-lock-version` in both `scripts/check-version-sync.sh` and
  `scripts/bump-version.sh`.
- Validator smoke coverage for configurable HISTORY formats, no-dash Trace
  HISTORY footers, new version markers, package-lock dual-field drift, and
  unknown marker types.

### Changed

- `history-entry` validation now defaults to `history_format: any`, accepting
  both `- YYYY-MM-DD - ...` and `YYYY-MM-DD - ...` dated entries. Projects can
  enforce `dash` or `no-dash` with a top-level `.dockit-config.yml` key.
- Durable Trace HISTORY scanning now recognizes both dash and no-dash dated
  entries when `trace_protocol.enabled: true`.
- `docs/version-sync-manifest.yml` and `docs/VERSIONING_RULES.md` document the
  expanded marker contract.

### Fixed

- Unknown version marker types now fail in both check and bump paths instead of
  warning/skipping, preventing silent false-green manifest entries.
- `package-lock-version` validates and updates both top-level `version` and
  `packages[""].version`.

## [4.9.5] - 2026-06-19

### Added

- Trace Protocol v1.3 (DF-044): chat Trace `Sent` now requires seconds on both
  the local and UTC timestamps, e.g.
  `YYYY-MM-DD HH:MM:SS Europe/Madrid (HH:MM:SS UTC)`.
- Trace guidance now tells receivers to re-check `git status`, `git log -1`,
  and the current clock before acting on an older Trace block's `Repo state`.

### Changed

- `LLM_START_HERE.md`: Trace guidance now uses second-level date commands and
  the unverified fallback includes seconds.
- `scripts/dockit-bootstrap-context.sh`: SessionStart payload now emits the
  second-level `Sent` shape and stale-read re-verification rule.
- `docs/llm/DECISIONS.md`: D-008 records the v1.3 refinement and why it remains
  chat-side only.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-044 filed and closed as implemented in this
  release.

### Fixed

- Fixed the remaining Trace ordering ambiguity where two executor/auditor
  messages in the same minute could be indistinguishable by `Sent`.
- Fixed stale-on-arrival ambiguity by making the receiver-side re-verification
  expectation explicit in the loaded onboarding.

## [4.9.4] - 2026-06-18

### Changed

- `scripts/dockit-sync.sh`: `section-merge` now inserts template sections that
  are completely missing from `adoption_mode: full` downstream files. This lets
  existing adopters receive newly-added marked sections such as
  `trace-protocol` instead of failing sync with "missing markers".

### Fixed

- Fixed downstream sync blockage introduced by adding new template sections:
  older full adopters can now migrate forward without hand-editing
  `LLM_START_HERE.md` first. Partially-adopted projects still skip missing
  sections, preserving their existing opt-in behavior.

## [4.9.3] - 2026-06-18

### Added

- Trace Protocol v1.2 (DF-042): chat Trace `Sent` now uses a fixed dual-time
  format: local time first, UTC second in parentheses. The local side defaults
  to `Europe/Madrid` for this operator scaffold and can be overridden with
  `trace_protocol.local_timezone`.

### Changed

- `LLM_START_HERE.md`: Trace guidance now requires clock verification before
  writing `Sent`, documents the exact local-then-UTC order, and defines
  `Sent: unverified client time ...` for agents without clock access.
- `scripts/dockit-bootstrap-context.sh`: SessionStart payload now includes the
  same time-order and verification rule, using `trace_protocol.local_timezone`
  when configured.
- `scripts/dockit-init-project.sh`: new scaffolds include
  `trace_protocol.local_timezone: Europe/Madrid` next to the existing Trace
  durable settings.
- `docs/llm/DECISIONS.md`: D-008 records the v1.2 time-verification
  refinement.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-042 filed and closed as implemented in
  this release.

### Fixed

- Fixed a Trace orientation failure where LLM windows could label Madrid/CEST
  wall-clock time as UTC, making later/earlier messages appear inconsistent.
- `scripts/dockit-bootstrap-context.sh`: optional Trace config reads stay
  non-fatal when `.dockit-config.yml` is absent, preserving default-on chat
  Trace guidance in existing adopters.

## [4.9.2] - 2026-06-18

### Added

- Trace Protocol v1.1 (DF-041): chat Trace headers now include required
  `Resulting state` between `Subject` and `Repo state`. The field distinguishes
  message time from repo effect, so a later auditor message about an older
  commit is not mistaken for the latest project state.

### Changed

- `LLM_START_HERE.md`: Trace guidance now documents the recommended
  `Resulting state` shape (`HEAD=...; version=...; gate=...`) and examples for
  executor patches, auditors with no findings, and auditors with findings.
- `scripts/dockit-bootstrap-context.sh`: SessionStart payload now emits the
  `Resulting state` field, so synced adopters receive the v1.1 convention
  mechanically at session open.
- `docs/llm/DECISIONS.md`: D-008 records the v1.1 refinement and why HANDOFF
  Trace Anchor and HISTORY footer do not gain this chat-only field.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-041 filed and closed as implemented in
  this release.

## [4.9.1] - 2026-06-17

### Added

- `scripts/test-validator.sh`: two Trace Protocol regression cases:
  invalid HANDOFF Trace Anchor hash must fail, and commit time without seconds
  (`YYYY-MM-DD HH:MM UTC`) must be accepted.

### Changed

- `scripts/dockit-validate-session.sh`: Trace commit validation now uses
  `git -C "$PROJECT_ROOT"` consistently instead of `cd "$PROJECT_ROOT" && git`
  command chains. HANDOFF Trace Anchor commit-time matching accepts both
  `YYYY-MM-DD HH:MM:SS UTC` and `YYYY-MM-DD HH:MM UTC`.

### Fixed

- `scripts/dockit-validate-session.sh`: fixed a shell precedence bug in
  `check_trace_protocol` that made invalid commit hashes in HANDOFF Trace
  Anchors pass silently. The broken expression `! cd "$PROJECT_ROOT" && git ...`
  negated only `cd`, so `git cat-file -e` never ran in the normal successful
  `cd` case.

## [4.9.0] - 2026-06-17

### Added

- Trace Protocol (DF-040): `LLM_START_HERE.md` now carries a synchronized
  `trace-protocol` section for executor/auditor workflows. Substantive
  execution reports and audit verdicts should begin with a compact Trace
  header, then continue in normal prose.
- `scripts/dockit-bootstrap-context.sh`: SessionStart output now appends the
  Trace instruction by default, unless a project sets
  `trace_protocol.enabled: false` in `.dockit-config.yml`.
- `scripts/dockit-validate-session.sh`: new `trace-protocol` check. When a
  project sets `trace_protocol.enabled: true` and
  `trace_protocol.since: YYYY-MM-DD`, the validator requires a HANDOFF
  `## Trace Anchor` and inline HISTORY `Trace:` footers for post-activation
  entries that reference backtick-quoted commit hashes.
- `scripts/dockit-init-project.sh`: new projects now start with
  `.dockit-config.yml` containing `trace_protocol.enabled: true` and
  `since: <scaffold date>`, plus a starter HANDOFF Trace Anchor and HISTORY
  footer format.
- `docs/llm/DECISIONS.md`: D-008 records the split between chat orientation
  and durable validation, including the default-on chat posture and
  config-gated validator posture.

### Changed

- `scripts/test-validator.sh`: smoke coverage now includes Trace Protocol
  cases for no-config skip, valid anchor/footer pass, missing HISTORY footer
  fail, pre-since history skip, missing HANDOFF anchor fail, and
  enabled-without-since fail.
- `docs/DOWNSTREAM_FEEDBACK.md`: DF-040 filed and closed as implemented in
  this release, with implementation hints for future audits and downstream
  migration.

## [4.8.2] - 2026-05-17

### Added

- `scripts/test-validator.sh`: new POSIX smoke test runner for
  `dockit-validate-session.sh`. It builds throwaway git repos under `/tmp` and
  verifies the DF-039 read-only skip matrix, the orientation glob filter, and
  malformed clean repos missing HANDOFF/HISTORY. Registered in
  `dockit-sync-manifest.yml` with `strategy: copy` so adopters receive the
  validator and its smoke tests together.

### Fixed

- `scripts/dockit-validate-session.sh`: `check_handoff_date` and
  `check_history_entry` now verify the target file exists before applying the
  `DOCKIT_ALLOW_READ_ONLY_SKIP=1` zero-diff escape. Clean but malformed repos
  without `docs/llm/HANDOFF.md` or `docs/llm/HISTORY.md` now fail explicitly
  even when the Claude Stop hook opt-in is present.

## [4.8.1] - 2026-05-17

### Changed

- `scripts/dockit-validate-session.sh`: `check_handoff_date` and
  `check_history_entry` now skip only when the caller opts in with
  `DOCKIT_ALLOW_READ_ONLY_SKIP=1` and the repo has no staged or unstaged
  tracked-file diff. Claude Code's Stop hook opts in; CI and pre-commit do
  not. Closes DF-039 Case B (clean-start read-only sessions such as `/brief`);
  Case C remains operator commit discipline.

### Fixed

- `scripts/dockit-validate-session.sh`: `check_orientation` now ignores
  backtick-quoted strings containing glob characters (`*`, `?`, `[`) instead
  of treating them as literal paths. This prevents false missing-path reports
  for prose such as `*_PROPOSAL.md`.

## [4.8.0] - 2026-05-08

### Added

- `scripts/dockit-validate-session.sh`: new `check_orientation` function (DF-034
  closure, option (a)). Asserts `docs/llm/HANDOFF.md` declares the next concrete
  step in a recognisable section (`## Open work`, `## Next concrete step`, or
  `## Next Steps`), that the section names at least one in-repo file path
  (backtick-quoted markdown spans matching `*.md`/`*.sh`/`*.yml`/`*.yaml`/
  `*.json`/`*.txt`/`*.py`/`*.js`/`*.ts`/`*.toml` extensions), and that each
  named in-repo path actually exists. Cross-repo absolute paths (`~/`, `/`)
  are excluded from the existence check. Exposed via `--check orientation`.
  Closes `docs/DOWNSTREAM_FEEDBACK.md` DF-034 ("auto-orientation contract is
  asserted by docs but tested nowhere"). The contract was the central promise
  LLM-DocKit makes downstream — that a fresh session can ship the next concrete
  step without bespoke prompting — but no check enforced it before this
  release. Counterpart of v4.7.0's `dockit-bootstrap-context.sh`: 4.7.0 covers
  the *trigger* axis of orientation (LLM reads `LLM_START_HERE.md` at session
  start), 4.8.0 covers the *content* axis (HANDOFF *Open work* names real
  paths that exist).
- `scripts/dockit-validate-session.sh`: new `check_template_residue` function
  (DF-035 closure, option (a)). Greps canonical scaffold-shipped docs for known
  scaffold-author voice / template placeholder patterns that survive
  `dockit-init-project.sh` and poison fresh-session orientation:
  `LLM_START_HERE.md` ("Replace angle-bracket placeholders", "Customization
  Notes for Maintainers", "Replace `<project>` with the actual project name"),
  `docs/STRUCTURE.md` ("Use this template to document", `<PROJECT_ROOT>`),
  `docs/ARCHITECTURE.md` (`<Names>`, `<Invariant`, `<Step>`, `<Phase 0>`,
  "Authors: `<Names>`"). Reports as FAIL on hard residue. Reports `WARN` if
  `docs/llm/DECISIONS.md` has no `## D-NNN` heading after a configurable
  commit threshold (`DOCKIT_DECISIONS_EMPTY_THRESHOLD_COMMITS`, default 5).
  Skips on the LLM-DocKit source repo itself (presence of
  `dockit-sync-manifest.yml` is the source-repo marker — that file is
  intentionally stripped from downstream by `dockit-init-project.sh`).
  Exposed via `--check template-residue`. Closes
  `docs/DOWNSTREAM_FEEDBACK.md` DF-035 option (a) ("scaffold ships
  template-residue in entry/optional docs that survives
  `dockit-init-project.sh`"). Option (b) — strip-at-scaffold-time inside
  `dockit-init-project.sh` — is deliberately deferred to a future minor;
  the (b.i) vs (b.ii) decision (delete `docs/ARCHITECTURE.md` from default
  scaffold vs rename to `.example`) is design, not mechanical, and merits
  its own deliberation pass after this minor's smoke sweep produces empirical
  data on adopter residue rates.

### Changed

- `LLM_START_HERE.md`: item 6 of the "Recommended reading order:" section
  now names HANDOFF *Open work — next concrete step* explicitly as the
  canonical declaration of "what to do next" and points at
  `scripts/dockit-validate-session.sh --check orientation` as the
  enforcement primitive. Without this, downstream projects could declare
  *Open work* in arbitrary idioms and the static check would have no
  fixed target.
- `scripts/dockit-init-project.sh`: HANDOFF stub renamed from `## Next Steps`
  to `## Open work — next concrete step`. The stub's three bullets now name
  `docs/PROJECT_CONTEXT.md` and `docs/STRUCTURE.md` as backtick-quoted
  paths (already present in the previous stub via the same idiom), so a
  freshly-scaffolded project passes the new orientation check from its
  first commit. The check expects this exact heading name as the
  preferred form, but accepts `Next concrete step` and `Next Steps` for
  back-compat with already-deployed projects that have not yet adopted
  the new heading.

### Notes

- Empirical observation from this release's smoke test of
  `dockit-init-project.sh`: a freshly-scaffolded project PASSES
  `check_orientation` (the new HANDOFF stub names two existing paths) but
  FAILS `check_template_residue` (the canonical templates ship with all
  the residue patterns DF-035 catalogues). This is the *correct* signal:
  downstream adopters scaffolding with v4.8.0 will see the FAIL on first
  validator run and know to clean residue before first commit. Option (b)
  in a future minor will make the strip happen at scaffold time so the
  cleanup is mechanical rather than manual.
- Cross-repo smoke read-only sweep performed on `tomatic`,
  `home-infra-protocol`, and `pi-fleet` adopters; results recorded in
  `docs/llm/HANDOFF.md`. Per DF-034 *Cross-repo touches required* and
  operator instruction, NO cross-repo edits made from this session — any
  adopter findings are filed as local follow-ups for each adopter to
  adopt at its own pace.

## [4.7.1] - 2026-05-03

### Fixed

- `scripts/dockit-bootstrap-context.sh`: awk regex for extracting the
  "Recommended reading order:" section no longer exits early when there
  is a blank line between the header and the first numbered item.
  Repos that customise the LLM-DocKit template with a blank-line gap
  (e.g. `home-infra-protocol`'s `LLM_START_HERE.md`) were falling back
  to a generic 2-item list instead of extracting the full per-repo
  reading order. Surfaced during the 2026-05-03 smoke test of the v4.7.0
  primitive against the originally-failing repo. Fix: track a `started`
  flag in awk so the blank-line-exit only fires after the first numbered
  item has been captured. Verified post-fix: home-infra-protocol now
  emits its 7 real items (SPEC.md, PROJECT_CONTEXT.md, ARCHITECTURE.md,
  COMPLETION_RULE.md, HANDOFF.md, DECISIONS.md, this file); tomatic
  still emits 9 items; LLM-DocKit still emits 7 items (regression-clean).

## [4.7.0] - 2026-05-03

### Added

- `scripts/dockit-bootstrap-context.sh`: new POSIX shell script that emits the
  project's mandatory onboarding context as a Claude Code SessionStart
  `additionalContext` JSON payload (`--json`, default) or as plain text for
  pasting into non-Claude LLM sessions (`--human`). Reads
  `LLM_START_HERE.md` dynamically to extract the "Recommended reading order:"
  list, so updates to that section flow through without changing the script.
  Output is short (~1.5 KB at default project) — points the LLM at the docs
  to read rather than concatenating them, staying well under the 10 KB
  SessionStart hook limit. Closes `docs/DOWNSTREAM_FEEDBACK.md` DF-033.
- `.claude/settings.json` `SessionStart` hook entry calling
  `scripts/dockit-bootstrap-context.sh --json`. Wrapped in
  `sh -c 'if [ -x ... ]; then ... ; fi'` so downstream copies of
  `settings.json` that arrive before the script gracefully degrade to a
  no-op rather than break sessions. Inverse counterpart of the existing
  `Stop` hook (which guards session end via
  `dockit-validate-session.sh`); together they bracket the session.
- `dockit-sync-manifest.yml`: new entry registering
  `scripts/dockit-bootstrap-context.sh` with `strategy: copy` so downstream
  projects pick it up on the next `dockit-sync` pass.
- `docs/DOWNSTREAM_FEEDBACK.md` DF-033: "Passive onboarding instructions in
  repo docs do not enforce session-start context loading." Captures the
  failure mode observed in a 2026-05-03 Codex CLI session inside
  `home-infra-protocol`, where the agent gave a partial ecosystem opinion
  because it had not read `LLM_START_HERE.md` despite the rule being
  declared at lines 9 and 87. Status: implemented (this release ships
  the cure for Claude Code; non-Claude LLMs use `--human` mode manually
  until they grow equivalent hooks).

### Changed

- `docs/llm/DECISIONS.md`: D-007 added — "Session-start onboarding is
  enforced mechanically, not by prose." Records the precedent that future
  rules of the form "always read X before doing Y" should ship as a hook
  + script, not as another prose paragraph.


## [4.6.1] - 2026-05-01

### Fixed

- `scripts/dockit-init-project.sh`: new projects were being created
  on the `master` branch instead of `main` (depended on the host
  system's `init.defaultBranch`). The orchestrator and skill in
  `home-infra-protocol` document `git push origin main` and the
  whole ecosystem standardises on `main`. Fixed by adding
  `git symbolic-ref HEAD refs/heads/main` immediately after
  `git init -q`. Portable to Git < 2.28 (no dependency on the
  `-b main` flag). Found by GPT-5 review during smoke testing of
  the orchestrator.

## [4.6.0] - 2026-05-01

### Added

- `scripts/dockit-init-project.sh`: from-scratch project initializer.
  Closes the gap between `/adopt-dockit` (which bolts the scaffold
  onto an existing repo) and the manual instructions in `HOW_TO_USE.md`
  (clone + strip + sed + git init). One command produces a clean,
  validator-green project at `0.1.0`. Behavior:
  - Copies tracked files only via `git archive HEAD` (drafts and
    untracked notes in the source LLM-DocKit checkout never leak
    into the new project — addresses the same risk class as DF-027).
  - Strips DocKit-internal meta files: `HOW_TO_USE.md`,
    `docs/DOWNSTREAM_FEEDBACK.md`, `docs/EXTERNAL_CONTEXT_PLUGIN_PLAN.md`,
    `dockit-sync-manifest.yml`, `scripts/dockit-sync.sh`,
    `scripts/dockit-sync-check.sh`, and `scripts/dockit-init-project.sh`
    itself (template-only utilities).
  - Resets live operational docs (`CHANGELOG.md`,
    `docs/llm/HANDOFF.md`, `docs/llm/HISTORY.md`,
    `docs/llm/DECISIONS.md`) to fresh stubs so DocKit's own DF-027 /
    plaud-mirror / D-001..D-006 content does not leak.
  - Substitutes `<PROJECT_NAME>`, `<CONVERSATION_LANGUAGE>`,
    `<YYYY-MM-DD>` placeholders in remaining `*.md`/`*.yml`/`*.json`.
  - Runs `scripts/bump-version.sh 0.1.0` to set VERSION and sync
    doc-version markers atomically.
  - Initializes a fresh git repo with a single
    "chore: initial scaffold from LLM-DocKit X.Y.Z" commit.
  - Refuses to overwrite an existing target directory; exits with a
    clear error if the source is not a git repository (no working-
    tree fallback — that path was the source of leaks during early
    smoke-testing).
- Strict scope: no GitHub remote creation, no push, no
  ecosystem-specific profile application, no `~/.claude/` edits.
  Those concerns belong to higher layers (orchestrator scripts in
  consumer repositories such as `home-infra-protocol`).
- `HOW_TO_USE.md` rewritten so the new "Quick Start (one command,
  recommended)" section ships above the existing manual flow, which
  is preserved as "Quick Start (manual)" for Windows / CI cases.

### Changed

- `docs/llm/HANDOFF.md`: Current Status, Session Focus, and
  Patch 4.6.0 Outcome blocks reflect the new feature. The previously
  speculated "next 4.6.0 = pre-commit checks for DF-027(b) +
  DF-002 + DF-008" plan is acknowledged and explicitly deferred to a
  future v4.7.0 — that work is unrelated to from-scratch
  initialization and is not bundled here.

### Fixed

## [4.5.5] - 2026-04-25

### Added
- DF-027 in `docs/DOWNSTREAM_FEEDBACK.md`: "`git add -u` silently skips new untracked files; commit succeeds, workspace stays green, origin is broken." A specialisation of DF-024 ("documenting without verifying") at the git-mechanics layer, distinct enough from DF-014 ("commit accumulation across version bumps") to deserve its own entry. The plaud-mirror v0.4.17 commit (`d1bc317`) was published broken to `origin/main`: the LLM created two new source files with the Write tool, used `git add -u && git commit`, and the new files stayed `??`-untracked while the commit succeeded with the modified-only changes. Local workspace stayed green because tsc/node read from filesystem; a fresh clone would have failed `npm install && npm run build` at import-resolution. Closed in plaud-mirror v0.4.18 (commit `d2f17f2`) by re-staging the missing files explicitly + version bump + CHANGELOG entry naming the broken release. DF-027 ships as `partially implemented (plaud-mirror v0.4.18)` on the adopter-symptom axis; the protocol-level pre-commit hook check is `open` and proposed in detail (grep the staged tree for relative-path imports that resolve to files NOT present in the staged set, error if any are missing).

### Notes
- Adopter count: 27 entries, 5 `implemented`, 2 `partially implemented` (DF-026, DF-027), 20 `open`. The `partially implemented` count is now plural — exactly the case the v4.5.4 legend extension was anticipating.
- The most actionable next bump is the pre-commit hook proposed by DF-027(b). It's mechanical, false-positive risk is low (skip dynamic imports / module aliases), and it would have prevented the v0.4.17 → v0.4.18 cycle entirely. Pair it naturally with DF-002 (orphan-marker scan) and DF-008 (empty-CHANGELOG guard) — three pre-commit checks that target concrete failure modes already observed in the field. That would be a meaningful v4.6.0 (minor: new validator capabilities) rather than another DF entry release.

## [4.5.4] - 2026-04-24

### Changed
- DF-026 Status updated from `open` to `partially implemented (plaud-mirror v0.4.17)`. The adopter (plaud-mirror v0.4.17) extracted the previously local-to-App.tsx pure UI helpers (`formatDuration`, `formatBytes`, `formatRecordingsMetric`, `computeMissing`, `formatDeviceLabel`, `formatDeviceShortName`, `coerceNonNegativeInteger`, `summarizeRun`, `describeBusy`) into `packages/shared/src/formatting.ts` and added 12 dedicated `node:test` tests hooked into the root suite. That closes the helper-level half of DF-026 — a regression in any of those would now actually fail the suite. Component-level rendering tests (tabs persistence + switch, collapsible card ARIA + mount/unmount of BackfillPreview, debounced fetch behaviour) remain `open` because they would require introducing vitest+jsdom+@testing-library/react as new dependencies, which is a non-trivial scope addition deferred for a later patch. Protocol-level template change (split DocKit's "every new runtime case must come with tests" rule by layer, with explicit waiver path in HISTORY for UI cases) also still `open`.

### Notes
- Adopter count: 26 entries, 5 `implemented`, 1 `partially implemented` (DF-026), 20 `open`.
- The partial-implementation pattern is itself worth tracking. DF-024's convention requires every entry citing `<file>:<line>` to ship with a fix-commit OR a `TODO:` block. Adding `partially implemented (<adopter-version>)` as a third valid Status value extends that convention naturally — the adopter half of the work is closed in a concrete release while the protocol half stays visible as ongoing. If this pattern recurs (likely; many DF entries have an adopter-symptom axis and a protocol-level axis), the file's "Status legend" header should grow this value formally. Watch for it on the next pass.

## [4.5.3] - 2026-04-24

### Added
- DF-025 in `docs/DOWNSTREAM_FEEDBACK.md`: "Runbook promises a configuration the codebase doesn't actually support." Specialisation of DF-024: the drift is code-vs-docs, not doc-vs-doc. The plaud-mirror instance is textbook — v0.4.15 rewrote DEPLOY_PLAYBOOK with `node:20-alpine` as an acceptable Docker fallback example, but the committed Dockerfile forced `SHELL ["/bin/bash", "-lc"]` and Alpine ships no bash. An operator would have hit a build error. Closed in plaud-mirror v0.4.16 by dropping both SHELL directives and verifying an Alpine build end-to-end. Proposed mitigations: template rule adding a `Verified:` annotation convention to concrete runbook examples; session-end addendum to DF-024(c) requiring the LLM to attempt any new runbook example before declaring the session done.
- DF-026: "Backend tests go green while UI-state features (tabs, localStorage, collapse) ship with only a build-shell smoke test." Observed in plaud-mirror v0.4.14 — the tabs + collapsible-backfill + localStorage-persistence feature set shipped with 53/53 passing, but the only web-side test is a build-shell smoke check. A regression flipping any of those to broken would still report PASS. Not a validator concern (test coverage is adopter-owned), but DocKit's template LLM_START_HERE rule "every new runtime case must come with explicit tests" is not layer-differentiated; adopter LLMs interpret it as "backend tests count" and ship UI changes without asserting the new state. Proposed: template rule distinguishing backend-runtime vs UI-state cases, with an explicit waiver path in HISTORY for UI cases left untested (so the gap is acknowledged, not silently skipped).

### Changed
- DF-025 Status: `implemented (plaud-mirror v0.4.16)` on the concrete symptom (Alpine build now works), but the protocol-level `Verified:` annotation convention is `open`. Same pattern as DF-001/002/003: adopter symptom fixed, systemic cure pending.

### Notes
- Adopter count: 26 entries now, 4 implemented (DF-005, 001, 002, 003 — the last three from v0.4.15 adopter fixes, noted in v4.5.2 — and now DF-025 joins as 5 `implemented` on the adopter-symptom axis). 21 open. DF-024 and DF-026 remain `open` — those are protocol-level not adopter-level and the fix is template/validator work, not just a downstream patch.

## [4.5.2] - 2026-04-24

### Added
- DF-024 in `docs/DOWNSTREAM_FEEDBACK.md`: "Documenting drift is not fixing drift." Distinct failure mode from DF-010: the LLM HAS noticed the content problem and turned the noticing into a polished DF entry — then declared the work complete while the underlying instance stays broken. Observed directly on 2026-04-24: DF-001/002/003 were written at v4.5.0 with precise file:line citations in plaud-mirror, and the plaud-mirror instances remained broken until a second GPT-5 review at v4.5.2/plaud-mirror v0.4.15 forced the actual fix. Proposed mitigations: (a) convention that every DF citing `<file>:<line>` in an adopter must either ship with a fix-commit OR carry explicit `TODO:` remediation block, (b) stretch validator check that cross-references DF entries against adopter git log, (c) session-end ritual requiring review of every DF written in session for "fix vs Status truthfulness".

### Changed
- DF-001, DF-002, DF-003 Status lines updated from `open` to `implemented (plaud-mirror v0.4.15)` with a pointer to the concrete fix that closed each instance. The protocol-level checks proposed in each entry's body remain `open` — the adopter-specific symptom is gone but the systemic cure is still ahead.
- Meta-observation at the bottom of the file unchanged in wording; DF-024 is the new through-line of this release, threaded in below the last entry.

### Notes
- This release's value is primarily epistemic: it names a failure mode the LLM had been performing without realising it. No validator or template change ships. The three concrete adopter symptoms (DEPLOY_PLAYBOOK Kali, HOW_TO_USE orphan, HANDOFF stale "Next:") were fixed in plaud-mirror v0.4.15 and carry `Fixed-in:` pointers in their Status lines so future readers of DOWNSTREAM_FEEDBACK see the full audit trail — entry, fix, residual protocol work.

## [4.5.1] - 2026-04-24

### Added
- Seven more seed entries in `docs/DOWNSTREAM_FEEDBACK.md` (DF-017..DF-023) after a second pass over the plaud-mirror adoption experience focused on LLM-native workflow patterns the first 16 entries missed. Categories: context compaction checkpoint discipline (DF-017), parallel persistence stores with no bridge — LLM personal auto-memory vs `docs/llm/*` (DF-018), cross-LLM review metadata (DF-019), graduated validator execution modes — fast/normal/strict/paranoid (DF-020), external-context version correlation not just edit-trigger (DF-021), HISTORY entry quality lint (DF-022), DocKit self-application without external reviewer (DF-023).
- Extended meta-observation at the bottom of `DOWNSTREAM_FEEDBACK.md` now names two distinct patterns instead of one: "structural vs semantic" (DF-001, DF-006, DF-008, DF-011, DF-016, DF-019) and "single-fact-in-multiple-places-with-no-sync-contract" (DF-015, DF-018, DF-021) — the latter is a generalization of what `version-sync-manifest.yml` already solves for version strings.

### Changed
- `docs/llm/HANDOFF.md`: Current Status refreshed to point at all 23 entries (not just the first 16) and flags DF-023 as DocKit's own blind spot. Also corrects a pre-existing drift: the "Project Summary" block still said `Current version: 4.4.0` at v4.5.0 — now cites `VERSION` file as the single source of truth instead of carrying a prose version string.

### Notes
- Still no validator or template change. The content of the log is the deliverable. The three most actionable next steps implied by the 23 entries are: (a) implement DF-002 (orphan marker scan) and DF-008 (empty CHANGELOG guard) first — they are low-cost and high-signal; (b) adopt the graduated-mode framing from DF-020 as the surface on which DF-001/006/013/018/021 attach; (c) codify DF-018 by publishing a small `/export-memory` skill so adopters stop losing auto-memory lessons to the protocol.

## [4.5.0] - 2026-04-24

### Added
- `docs/DOWNSTREAM_FEEDBACK.md`: living log of drift, gap, usability and process issues observed when DocKit is adopted by real projects. Each entry (`DF-NNN`) records source project + version, category, observation with file:line references, and the protocol-level implication (what DocKit should change to address it). The doc opens with 16 seed entries collected from `plaud-mirror`'s v0.1.0 → v0.4.13 experience — four flagged explicitly by a GPT-5 review (DEPLOY_PLAYBOOK Kali drift, orphan HOW_TO_USE, stale "Next:" snapshots, asymmetric enforcement) and the rest distilled from personal-memory feedback the downstream LLM assistant had saved to itself.
- `dockit-sync-manifest.yml`: explicit `skip` entry for `docs/DOWNSTREAM_FEEDBACK.md` so the feedback log stays DocKit-only and is never propagated to adopters.

### Changed
- `docs/llm/HANDOFF.md`: Current Status updated to reference the new feedback-intake workflow and points at the 16 seeded entries for anyone picking up protocol work next.

### Notes
- No code or validator change ships in this minor. The feedback log is intentionally a preparatory artifact — the entries in it are the prioritised backlog for the next round of validator / template work (semantic-content checks, orphan-marker detection, prose-version lag, CHANGELOG emptiness guard, deploy-verify playbook snippet, decision supersession syntax).
- Follow-up items DF-001..DF-004 correspond directly to the four concrete drifts a sibling LLM found in the plaud-mirror repo on 2026-04-24; DF-005 is an already-implemented check documented here for audit trail; DF-006..DF-016 extend the log into adjacent problem classes observed across the same project over the preceding week.

## [4.4.0] - 2026-03-01

### Added
- `.claude/skills/adopt-dockit/SKILL.md`: `/adopt-dockit` skill for adding LLM-DocKit scaffold to existing repositories (7-step guided process: analyze project, copy templates, replace placeholders, personalize with intelligence, technical setup, validate, optional external context)

## [4.3.0] - 2026-03-01

### Added
- `check_external_triggers` check in `dockit-validate-session.sh`: detects local file changes matching `update_triggers` globs and produces WARN (non-blocking)
- WARN status support in validator (non-blocking, shown in output, does not affect exit code)
- `--claude-rules` flag in `dockit-generate-external-context.sh`: generates `.claude/rules/external-context-triggers.md` with glob frontmatter (no absolute paths)
- `warnings` field in validator JSON output

## [4.2.0] - 2026-03-01

### Added
- `scripts/dockit-generate-external-context.sh`: generates External Context section in LLM_START_HERE.md from `.dockit-config.yml` configuration (--dry-run/--apply, idempotent)
- `check_external_context` check in `dockit-validate-session.sh`: validates external doc path and read files exist (opt-in, skippable via `DOCKIT_SKIP_EXTERNAL=1`)
- `DOCKIT-EXTERNAL-CONTEXT:START/END` markers in `LLM_START_HERE.md` template
- D-006: External context uses separate markers to avoid sync interference

## [4.1.0] - 2026-03-01

### Added
- Pre-commit hook Check 2: BLOCKS commits when code/config files are staged without VERSION (enforcement, not just warning)
- `.ps1` added to code file extensions pattern in pre-commit hook

### Changed
- `LLM_START_HERE.md`: version management section now requires per-commit versioning (not per-session)
- Pre-commit hook checks renumbered (5 checks total, was 4)

## [4.0.0] - 2026-02-22

### Added
- `dockit-sync-manifest.yml`: sync strategy manifest (copy/skip/section-merge/yaml-merge per file)
- `scripts/dockit-sync.sh`: template sync tool with dry-run, apply, backup/rollback, conflict detection, lock, JSON output, git-branch support (~1200 lines, POSIX sh)
- `scripts/dockit-sync-check.sh`: downstream project status checker (CURRENT/OUTDATED/NO_STATE)
- `<!-- DOCKIT-TEMPLATE:START/END -->` section markers in `LLM_START_HERE.md` for 9 syncable sections
- `.dockit-enabled` opt-in marker file concept for downstream projects
- `.dockit-config.yml` human-managed config (adoption_mode, exclude_sections) for downstream projects
- `.git/.dockit/` runtime directory (state, lock, backups) -- auto-ignored by git

### Changed
- `LLM_START_HERE.md`: 9 sections now wrapped in DOCKIT-TEMPLATE markers for automated sync

### Breaking
- Downstream projects must add DOCKIT-TEMPLATE markers to their `LLM_START_HERE.md` for section-merge to work
- Downstream projects must create `.dockit-enabled` to opt in to sync
- Downstream projects must run `--init-state` to establish baseline before first sync

## [3.0.0] - 2026-02-20

### Added
- `docs/version-sync-manifest.yml`: single source of truth for version-synced files
- `scripts/bump-version.sh`: automated version bump across all tracked files (POSIX sh)
- `scripts/check-version-sync.sh`: drift validator with `--staged` mode (POSIX sh)
- `scripts/pre-commit-hook.sh`: git hook template enforcing version sync and HISTORY updates
- `<!-- doc-version: X.Y.Z -->` HTML comment markers in all tracked documentation files
- Documentation sync rules in `LLM_START_HERE.md` (snapshot <-> HANDOFF, STRUCTURE <-> filesystem)
- Pre-commit hook installation step in Getting Started Checklist

### Changed
- `LLM_START_HERE.md`: version management now references bump script instead of manual edits
- `docs/VERSIONING_RULES.md`: rewritten with manifest-based workflow, concrete 6-step process
- `README.md`: converted from scaffold description to downstream project template with placeholders
- `docs/STRUCTURE.md`: updated tree and table with new scripts and manifest
- `HOW_TO_USE.md`: version management, doc maintenance, and troubleshooting sections updated

### Breaking
- Version markers (`<!-- doc-version: X.Y.Z -->`) are now required on line 1 of all tracked docs
- `README.md` is no longer a scaffold description (that content lives in `HOW_TO_USE.md`)
- Manual version editing is replaced by `scripts/bump-version.sh`

## [2.0.0] - 2025-12-17

### Added
- LLM working-memory index: `docs/llm/README.md`
- Decision log template: `docs/llm/DECISIONS.md`
- Optional reviews template: `docs/llm/REVIEWS.md`
- Optional architecture template: `docs/ARCHITECTURE.md`
- Optional operations runbooks: `docs/operations/API_CONTRACT.md`, `docs/operations/DEPLOY_PLAYBOOK.md`
- Operations index in `docs/operations/README.md`
- Generated/runtime dirs section in `docs/STRUCTURE.md`

### Changed
- `docs/llm/HANDOFF.md` emphasizes brevity and linking to DECISIONS
- `LLM_START_HERE.md`, `README.md`, and `HOW_TO_USE.md` updated to reference the new docs
