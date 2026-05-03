# Downstream Feedback

Living log of observations collected from projects that adopt LLM-DocKit. Each
entry describes a real-world drift, gap, or friction point encountered in a
downstream project, along with the implication for DocKit itself. Use this file
to prioritise protocol improvements.

This file is **not** synced to downstream projects (see
`dockit-sync-manifest.yml` → strategy `skip`). It lives in DocKit as the
maintainer's backlog of protocol-level work suggested by real adoption.

## Status legend

- `open` — observed, no fix planned yet
- `accepted` — fix is in the DocKit roadmap
- `partially implemented (<adopter-version>)` — the adopter-symptom axis is closed in a concrete release, but the protocol-level axis (template rule, validator check, etc.) still has work left. Many DF entries have both axes; this Status keeps the residual protocol work visible without losing the audit trail of the symptom-level fix.
- `implemented` — a check, template change, or doc has landed that addresses it (both adopter and protocol axes, where both apply)
- `rejected` — intentionally out of scope; includes rationale
- `superseded-by: DF-NNN` — merged into another entry

## Category legend

- `drift` — content became inconsistent; validator did not catch because it
  only checks markers, dates, and sync pairings, not semantic content.
- `gap` — a class of file or behaviour the validator does not track at all.
- `usability` — friction for the adopter; the rule exists but is easy to
  violate by mistake.
- `process` — the problem is in the workflow around DocKit, not in a specific
  file.

## How to add an entry

Use the next free `DF-NNN` (zero-padded). One entry per distinct problem, even
when two entries share a root cause — dedicate a separate DF for each concrete
failure mode so they can be resolved independently. Link related entries via
`Related: DF-AAA, DF-BBB`.

```
## DF-NNN — Short descriptive title
- Source: <project> (<version or date at time of observation>)
- Date observed: YYYY-MM-DD
- Category: drift | gap | usability | process
- Status: open | accepted | partially implemented (<adopter-version>) | implemented | rejected | superseded-by: DF-NNN
- Related: DF-AAA, DF-BBB   (optional)

Observation: what concretely happened, with file:line references when
applicable. Keep it short — the point is to convey the failure mode, not
retell the session.

Protocol implication: what DocKit should change (new check, template edit,
rule in LLM_START_HERE, etc.). Be specific. If multiple options exist, list
them with tradeoffs.

Mitigation in source project (optional): how the downstream project worked
around the gap in the meantime, if relevant.
```

Keep entries in ascending order. Once an entry reaches `implemented` or
`rejected`, leave it in place as an audit trail — do not delete.

---

## DF-001 — Runbooks with executable content can contradict global policy silently

- Source: plaud-mirror (v0.4.13)
- Date observed: 2026-04-24
- Category: drift
- Status: implemented (plaud-mirror v0.4.15 removed the Kali bash block, enumerated acceptable substitutes, added explicit rejection paragraph). Protocol-level validator check proposed in the body below is still `open` — the fix was one-off, not systemic.

Observation: `docs/operations/DEPLOY_PLAYBOOK.md` contained a bash block
recommending `export PLAUD_MIRROR_DOCKER_BUILD_IMAGE="vxcontrol/kali-linux:latest"`
as a Docker fallback, even after the policy was changed in `README.md`,
`docs/llm/HANDOFF.md`, and `.env.example` to explicitly forbid that image. The
validator had nothing to say: all `<!-- doc-version -->` markers were in sync,
HANDOFF date was current, no broken links. An operator following the playbook
would have done exactly what the rest of the docs prohibit.

Protocol implication: DocKit's validator checks markers, dates, and
cross-file pairings but never reads content. For policy enforcement,
consider an optional `forbidden-tokens` check driven by
`.dockit-config.yml` — e.g. a list of strings that must not appear outside
specified files. Low false-positive rate if scoped narrowly (e.g. "must not
appear in any `.md` under `docs/operations/`"). Alternative: a lighter
"policy assertions" mechanism where the config declares "the string X must
appear in the same paragraph as the string Y" so that prohibitions are
co-located with their reasoning.

## DF-002 — Docs with `<!-- doc-version -->` marker but outside the sync manifest rot silently

- Source: plaud-mirror (v0.4.13 — HOW_TO_USE.md stuck at v0.1.0 prose content)
- Date observed: 2026-04-24
- Category: gap
- Status: implemented (plaud-mirror v0.4.15 rewrote HOW_TO_USE.md to v0.4.15 reality AND added it as the 20th manifest target — the structural fix that prevents recurrence, not just the content patch). Protocol-level orphan-scan check proposed in the body below is still `open`.

Observation: `HOW_TO_USE.md` at the plaud-mirror repo root was not listed in
`docs/version-sync-manifest.yml`, so `bump-version.sh` and
`check-version-sync.sh` never touched it. Its body described the project as a
pre-runtime "design-and-governance baseline" while the actual runtime had
shipped 13 patch releases. The problem was structural, not a missed update:
the file was simply never in the circuit.

Protocol implication: validator should scan the repo for files that contain a
`<!-- doc-version: X.Y.Z -->` comment AND are not in the manifest, and warn
(or error, configurable). Pair with a similar check for files that ARE in the
manifest but do not contain a marker. The combination makes the manifest the
single source of truth for tracked docs and makes orphans loud.

Mitigation in source project: the file is pending a rewrite + addition to the
manifest; chosen explicitly as the cure rather than deleting the file.

## DF-003 — Snapshot files carry forward-looking text that ages poorly

- Source: plaud-mirror (v0.4.13 HANDOFF Current Status → "Next: rebuild image, verify VERSION, commit + push" after all three had been done)
- Date observed: 2026-04-24
- Category: drift
- Status: implemented (plaud-mirror v0.4.15 dropped the trailing "Next:" from HANDOFF Current Status and re-synced LLM_START_HERE Current Focus). Protocol-level convention/check proposed in the body below is still `open`.

Observation: HANDOFF and `LLM_START_HERE.md` "Current Focus" snapshots
contained end-of-line narrative ("Next: …") that was accurate at write time
but stale within the same session because the validator only checks the date,
not the content. By the next session there was no signal that "Next" already
happened.

Protocol implication: two options, not mutually exclusive.
(a) Template guidance in `docs/llm/README.md`: "Snapshot sections describe
NOW; if you need to record what comes next, put it in HANDOFF's Next Steps
section (structured) rather than in Current Status (prose). Current Status
should only hold what is true at the moment you stop working." Plus a small
anti-pattern example.
(b) A very light `stale-next-steps` check that greps HANDOFF for tokens like
"Next:" / "Next step:" followed by verbs that suggest an imperative action,
and reminds the author to review them. Non-blocking.

## DF-004 — Asymmetric enforcement between circuit-core and peripheral docs

- Source: plaud-mirror (pattern across v0.1.0 → v0.4.13)
- Date observed: 2026-04-24
- Category: gap
- Status: open
- Related: DF-001, DF-002

Observation: strongly-validated docs (HANDOFF, LLM_START_HERE, CHANGELOG,
package.json markers) stayed sharp through 13 patch releases because the
validator failed loudly. Peripheral runbooks (DEPLOY_PLAYBOOK, HOW_TO_USE)
accumulated invisible drift because nothing measured their freshness. The
core stays healthy while the periphery rots — the worst-case shape because a
reader looking for accurate content has no way to know which docs to trust.

Protocol implication: add a `doc-freshness` check that warns when a
validator-tracked doc has not been touched in N version bumps (configurable,
default maybe 3 minors). Not a hard block; a weekly nudge. The mere existence
of a number that lights up red when ignored changes maintainer behaviour.
Complements DF-002: a doc needs to be IN the manifest AND edited often enough
that its claims are plausibly fresh.

## DF-005 — HANDOFF ↔ LLM_START_HERE "Current Focus" drift (now plugged, kept as history)

- Source: plaud-mirror (caught 4× by GPT-5 review during April 2026, before the sync check landed in DocKit v4.x)
- Date observed: 2026-04-22 .. 2026-04-23
- Category: drift
- Status: implemented (DocKit `handoff-start-here-sync` check)

Observation: before the enforced sync check existed, every edit to HANDOFF's
Current Status required a mirror edit to LLM_START_HERE's Current Focus. It
was trivial to forget: the author would save HANDOFF and move on without
opening LLM_START_HERE at all. GPT-5 flagged the drift four times in eight
days.

Protocol implication: already addressed by `handoff-start-here-sync`. Kept in
this log because the pattern generalises: **any two-file mirror pattern
introduced by DocKit must ship with validator backing at the same time, or
drift will compound before the maintainer notices.** A rule to remember for
future features that introduce another mirror (e.g. per-phase status blocks).

## DF-006 — `bump-version.sh` updates markers and package.json but NOT prose current-state sections

- Source: plaud-mirror (happened after v0.4.1, v0.4.2, v0.4.4 bumps)
- Date observed: 2026-04-23
- Category: drift
- Status: open

Observation: `bump-version.sh X.Y.Z` flips every `<!-- doc-version -->`
marker and every `package.json` version field, but does not touch prose like
"Plaud Mirror v0.4.1 is the extended Phase 2 slice …" in
`docs/ROADMAP.md`, `docs/PROJECT_CONTEXT.md`, or `docs/ARCHITECTURE.md`
headers. A release could ship with markers at v0.4.2 and prose still saying
"v0.4.1 ships …". Caught repeatedly by GPT-5 review. Addressing this manually
every bump is tedious and unreliable.

Protocol implication: two complementary options.
(a) In `bump-version.sh`: after the mechanical bump, scan tracked docs for
the OLD version string appearing in prose (not inside a marker comment) and
print a warning listing file:line with "still references OLD_VERSION — is
this a historical reference or a prose bump you forgot?".
(b) In the validator: a `prose-lag` check that errors when the current
`VERSION` string is OLDER than any version string that appears in prose in
tracked docs. More rigid, less useful for historical references like
"pre-0.4.7 semantics" which are intentional.

Mitigation in source project: saved as personal memory
(`feedback_prose_version_drift.md`) so the LLM assistant learns to sweep
prose after every bump. Project-local workaround, not a protocol fix.

## DF-007 — Local runtime config (.env, compose.override) can violate docs policy invisibly

- Source: plaud-mirror (local `.env` still had `vxcontrol/kali-linux` as build image even after docs banned it)
- Date observed: 2026-04-22
- Category: gap
- Status: open
- Related: DF-001

Observation: DocKit's circuit covers docs only. Nothing scans runtime config
like `.env`, `compose.override.yml`, `systemd` unit files, or similar. An
operator can comply 100% in docs (Kali removed from README, HANDOFF, playbook,
etc.) and still be wrong in runtime because the machine loads an override
file. Caught by the LLM assistant only because a sibling warning fired
coincidentally.

Protocol implication: optional `runtime-policy` check that uses the same
forbidden-token list as DF-001 but scans a configurable set of runtime config
paths. Gitignored files could be opted in with explicit consent since they
might contain secrets — perhaps a `.dockit-runtime-scan` file listing which
local-only paths should be checked for policy violations.

## DF-008 — CHANGELOG skeleton entries stay empty because nothing blocks

- Source: plaud-mirror (v0.3.2 and v0.4.0 shipped with empty `### Added` / `### Changed` sections until GPT-5 flagged them later)
- Date observed: 2026-04-23
- Category: process
- Status: open

Observation: `bump-version.sh X.Y.Z` inserts a `## [X.Y.Z]` section with
empty `### Added` / `### Changed` / `### Fixed` subsections for the operator
to fill. Nothing checks whether they were filled before commit. Two releases
shipped with header-only entries that read as lies (the project had changed
plenty; the entries said it had not). The operator cannot distinguish
"nothing new in this release" from "author forgot to fill the entry".

Protocol implication: pre-commit hook (or validator) parses the top-of-file
CHANGELOG entry for the current `VERSION`. If all three subsections are empty
AND the commit includes files outside `docs/`, error with a concrete message:
"CHANGELOG `## [X.Y.Z]` is empty but this commit changes product code. Either
fill a bullet or add `### Unreleased notes: none` explicitly." Explicit opt-in
to empty-ness beats silent skip.

## DF-009 — `external-triggers` warning names changed files but not expected external targets

- Source: plaud-mirror (after each bump, PROJECT_CONTEXT/ARCHITECTURE changes fired the warning but gave no actionable next step)
- Date observed: 2026-04-24
- Category: usability
- Status: open

Observation: the validator's `external-triggers` check correctly detects that
`docs/PROJECT_CONTEXT.md` etc. changed and warns "local changes may require
external doc updates". It does not say WHICH file in the external repo to
edit or include a diff. In practice the LLM assistant opens
`~/src/home-infra/docs/PROJECTS.md` manually every bump — a muscle-memory
workaround, not a system behaviour.

Protocol implication: the trigger map already records `local glob → external
path` in `.dockit-config.yml`. Extend the warning to print the expected
external file path and the last-known "external file last updated" date (git
log on the external repo) so the operator knows whether it is genuinely
behind. Optional: a `--fix-external` flag that opens the expected files in
`$EDITOR` or prints a suggested diff.

## DF-010 — Validator PASS is not the same as "docs are useful"

- Source: plaud-mirror (GPT-5 reviews repeatedly surfaced issues after the validator said PASS)
- Date observed: 2026-04-22 .. 2026-04-24
- Category: process
- Status: open

Observation: every time GPT-5 was asked to review, it found at least one
problem the validator could not see — empty CHANGELOG (DF-008), prose version
lag (DF-006), stale runbook (DF-001), bootstrap docs (DF-011), missing
manifest entry (DF-002). "Validator PASS + tests green" is a necessary but
insufficient bar for ready-to-merge. Relying on an external review loop works
but does not scale.

Protocol implication: bundle the checks proposed in DF-001/002/006/008 into
an opt-in "meta" mode of the validator — e.g.
`scripts/dockit-validate-session.sh --strict` — that a maintainer can run
before tagging a release. Running the strict mode in CI on release branches
gives the safety net that GPT-5 currently provides manually. Non-strict mode
keeps today's fast feedback loop for normal sessions; strict mode surfaces
the semantic-content class of problems.

## DF-011 — Bootstrap-era "what this project is" docs survive into the runtime era unchanged

- Source: plaud-mirror (HOW_TO_USE.md still described "v0.1.0 is a design-and-governance baseline" at v0.4.13)
- Date observed: 2026-04-24
- Category: drift
- Status: open
- Related: DF-002

Observation: docs written before the runtime existed tend to ossify. They
sounded right when authored; nobody flags them after the transition to
"runtime exists, features ship". `HOW_TO_USE.md`, `README.md` first-paragraph,
and sometimes top-of-ARCHITECTURE blurbs fall into this trap.

Protocol implication: DocKit's template `HOW_TO_USE.md` (and equivalent
"audience-facing overview" templates) should ship with an explicit
`Current phase` block that the validator treats as a freshness-sensitive
section (DF-004 applies here). Paired with a template comment that explicitly
warns future editors: "This block describes the project's current lifecycle
stage. Review on every `0.x.0` minor bump; do not leave a pre-runtime stage
claim after runtime ships."

## DF-012 — Docker-image reuse pitfalls are invisible to the protocol

- Source: plaud-mirror (BuildKit layer cache, async build-then-swap races, rolling vs big-bang rebuild)
- Date observed: 2026-04-22 .. 2026-04-24
- Category: gap
- Status: open

Observation: three times we shipped stale container images because
`COPY . .` hit the BuildKit cache and reused a previous layer; once we raced
a build-then-swap across two background shells and swapped in a stale image.
The symptoms (wrong VERSION inside the container, missing new routes) were
not doc drift — they were deployment drift — but they are exactly the class
of problem DocKit adopters will keep hitting because the protocol is
deployment-agnostic.

Protocol implication: DocKit is intentionally language- and
container-neutral, so adding a Docker check would be scope creep. But the
adopter-facing `DEPLOY_PLAYBOOK.md` template could include a "post-deploy
verify" checklist: `docker exec <container> cat /app/VERSION` must equal
`cat VERSION` on the host before declaring the deploy done. Low cost,
template-only, saves every future adopter from the same three traps. Pair
with a note in `docs/llm/README.md` template: "if your deploy pipeline can
silently reuse cached artifacts, verify the version string inside the
deployed artifact — tests green + `docker compose build` succeeded does not
prove the image you just swapped in is the one you just built."

Mitigation in source project: saved as three personal memories
(`feedback_always_rebuild.md`, `feedback_rolling_rebuild.md`,
`feedback_verify_image_version.md`, `feedback_docker_build_synchronous.md`)
in plaud-mirror; none of these lessons flow back to DocKit today without
this log.

## DF-013 — Decision supersession has no mechanism

- Source: plaud-mirror (D-003 "manual token first; automatic re-login deferred to Phase 4" — what happens when Phase 4 lands?)
- Date observed: 2026-04-24
- Category: gap
- Status: open

Observation: the `decisions-referenced` validator check confirms that every
`D-xxx` reference in HANDOFF exists in DECISIONS.md. It cannot tell a reader
that a decision is obsolete, has been partially superseded, or depends on a
later decision. When plaud-mirror's Phase 4 lands and manual-token is no
longer the only option, D-003 will still be in DECISIONS.md, undistinguished
from the live decisions around it.

Protocol implication: introduce an optional `Status:` header on DECISION
entries (`accepted` / `superseded-by: D-YYY` / `deprecated: <date>`). The
validator could warn when HANDOFF links to a decision whose Status is
`deprecated` or `superseded-by` without noting the relationship. Small
addition; improves decision-log longevity across multi-phase projects.

## DF-014 — Commit accumulation across multiple version bumps is not detected

- Source: plaud-mirror (v0.4.10 code + docs sat uncommitted while v0.4.11 and v0.4.12 work landed on top of it; everything eventually shipped as three commits in rapid succession)
- Date observed: 2026-04-24
- Category: process
- Status: open

Observation: `bump-version.sh` was invoked three times (0.4.10, 0.4.11,
0.4.12) before the first `git commit`. The pre-commit hook correctly required
a version bump but had no signal that prior versions were never tagged — the
history shows three back-to-back commits with three different versions and no
way to run any one of them in isolation. A bisect would be awkward; a rollback
impossible without combining un-related work.

Protocol implication: pre-commit (or a separate `check-version-continuity`
hook) inspects `git log` for every `VERSION` value between the last commit's
`VERSION` and the currently-staged `VERSION`. If the chain has gaps
(i.e. `0.4.9 → 0.4.12` with no commits for `0.4.10` and `0.4.11`), warn or
block. Blocking is too strict — legitimate squashes happen — but a "you are
about to commit version 0.4.12 but 0.4.10 and 0.4.11 never reached git; are
you sure?" prompt would have caught the pattern.

## DF-015 — Policy statements replicated across docs drift independently

- Source: plaud-mirror (the Kali-ban appeared in README, HANDOFF "What Landed", HANDOFF "Docker Incident Summary", DEPLOY_PLAYBOOK, `.env.example`; DEPLOY_PLAYBOOK drifted while the others stayed correct — see DF-001)
- Date observed: 2026-04-24
- Category: drift
- Status: open
- Related: DF-001

Observation: when a policy is worded in five places, a change to the policy
must edit all five. Five is the bus-factor; in practice we edited four and
the fifth drifted. DocKit encourages "link to the single source of truth"
informally but does not measure that any policy has exactly one source.

Protocol implication: introduce a lightweight "policy beacon" pattern —
e.g. a `<!-- policy-source: docker-base-image -->` marker placed on the
paragraph that IS the authoritative statement, and a
`<!-- policy-ref: docker-base-image -->` marker on every paragraph that
must stay consistent with it. A validator check diff-greps the beacon
paragraph against each ref paragraph and warns on divergence. Heavy-ish
mechanism, so scope it as opt-in for projects with known repeat-policy
surfaces.

## DF-016 — Tests-pass ≠ feature-correct-as-advertised

- Source: plaud-mirror (hero metric showing "100 / 1" passed all unit tests because the test used the same wrong field; duration shown as milliseconds treated as seconds likewise passed tests because the test asserted the round-trip, not the semantics)
- Date observed: 2026-04-23
- Category: gap
- Status: open

Observation: at least two bugs in plaud-mirror survived a green test suite
because the tests asserted shape-level properties while the bug was at the
semantic level. DocKit rules say "every runtime change adds a test"; they
do not say "validate the end-to-end behaviour the doc promises". The test
bar is actually lower than the promise bar.

Protocol implication: stretch — not obviously in DocKit's scope, but worth
noting. Optional recommendation in `docs/VERSIONING_RULES.md` template: "For
user-visible behavioural claims (metrics, durations, counts that appear in
the UI or webhook payloads), write at least one test that asserts the value
matches what the docs promise, not just that it round-trips through
storage." Not a check DocKit can run; just a rule adopters can cite when
reviewing each other.

## DF-017 — Context compaction can lose detail the LLM wrote to persist

- Source: plaud-mirror (this very session was continued after context compaction)
- Date observed: 2026-04-24
- Category: gap
- Status: open

Observation: an LLM session's working context is compacted when it exceeds
limits. The auto-summary tries to preserve detail but is necessarily lossy
(tool-call outputs and intermediate reasoning are collapsed to prose). DocKit
prescribes `docs/llm/HANDOFF.md`, `HISTORY.md`, and `DECISIONS.md` as the
durable memory meant to survive session boundaries — but DocKit does not
prescribe WHEN to checkpoint them. In practice the LLM only updates them at
"natural" milestones and trusts the auto-summary for everything else. If
compaction strikes mid-task, the resumed session reads the summary, not the
doc, and can diverge subtly from what actually happened.

Protocol implication: add template guidance in `LLM_START_HERE.md` (or a
dedicated `docs/llm/COMPACTION.md`): "before your working context
approaches limits, write a full-fidelity HANDOFF snapshot with explicit
file:line references for in-flight edits; do not rely on the auto-summary
to reconstruct surgical detail." Optional: a PreCompact-style hook that
detects context pressure and nudges the LLM to run `/update-docs` before
the compaction runs. This is specifically an LLM-native problem DocKit is
well-placed to solve — no other protocol in this space has a compaction
convention.

## DF-018 — LLM personal auto-memory and `docs/llm/` drift as two parallel stores

- Source: plaud-mirror LLM assistant (saved 7 `feedback_*.md` entries to Claude's auto-memory during v0.4.x; only surfaced when the user explicitly asked for a DOWNSTREAM_FEEDBACK seed)
- Date observed: 2026-04-24
- Category: process
- Status: open

Observation: the LLM's personal auto-memory (e.g. Claude's `memory/MEMORY.md`
at `~/.claude/projects/<slug>/memory/`) captures lessons for the LLM's own
future sessions. DocKit's `docs/llm/` captures lessons for any future
contributor (human or another LLM). They are two persistence stores with no
bridge — a lesson saved to auto-memory stays invisible to the project, and a
lesson written in DECISIONS.md stays invisible to the LLM's next cold session
unless that session re-reads DECISIONS. In practice lessons land in one store
or the other, rarely both, and drift.

Protocol implication: DocKit should recommend that every auto-memory
`feedback_*` entry generate a parallel artifact — either a DECISIONS.md
entry (if it's durable) or a DOWNSTREAM_FEEDBACK.md candidate (if it's
about DocKit itself). This very session is the first documented instance of
that translation happening on demand; codifying it makes it systematic.
Optional: a skill (`/export-memory`) that scans the LLM's auto-memory and
produces a draft `docs/llm/*` diff for the maintainer to review. Lighter
option: LLM_START_HERE block that instructs the LLM to list its auto-memory
contents in every HISTORY entry so at minimum the existence of
auto-memory-captured lessons is visible to the project.

## DF-019 — Cross-LLM review metadata is unstructured prose

- Source: plaud-mirror (GPT-5 reviews interleaved with Claude implementation work over April 2026)
- Date observed: 2026-04-24
- Category: usability
- Status: open
- Related: DF-010

Observation: when multiple LLMs collaborate (GPT reviews, Claude implements,
human arbitrates) the trail is prose in HISTORY and occasional REVIEWS.md
entries. No structured metadata: who reviewed, at which version, how many
findings, how many accepted, which commit implemented which finding. A
future LLM reading HISTORY sees "GPT flagged…; Claude fixed…" as
undifferentiated narrative. Tracing "which findings are still open from the
2026-04-24 review" requires rereading the whole session.

Protocol implication: extend the existing REVIEWS.md "enriched entry"
convention with a standardized, grep-able header block:

```
## Review YYYY-MM-DD - <reviewer-llm-id>
- Reviewer-LLM: <name + model id>
- Reviewed-Version: <X.Y.Z>
- Reviewed-Commit: <sha>
- Findings: <N>
- Accepted: <k>/<N>
- Implemented-In: <commit-sha or "pending">
- Rejected: <k>/<N>   (reasons listed below per-finding)
```

Validator could grep for missing required fields (`Reviewer-LLM`,
`Reviewed-Version`, `Findings`) and warn. The per-finding body stays prose;
only the header is structured.

## DF-020 — Validator has no graduated execution modes

- Source: plaud-mirror (`scripts/dockit-validate-session.sh --human` always runs all 6 checks)
- Date observed: 2026-04-24
- Category: usability
- Status: open
- Related: DF-010

Observation: every invocation runs every check. There is no fast mode for
during-edit checks (just marker + version-sync, milliseconds), no strict
mode for pre-release (add DF-001/006/008/013 semantic checks), no paranoid
mode for major bumps (add DF-002 orphan scan, DF-004 doc-freshness, DF-018
external-version probe). Adopters either pay the strict cost on every
commit (and disable hooks out of friction) or they skip strict checks
entirely (and drift accumulates until a human review fires).

Protocol implication: add `--mode <fast|normal|strict|paranoid>` flag to
`dockit-validate-session.sh`. Fast: marker + version-sync only. Normal:
today's default (6 checks, no content inspection). Strict: adds the
semantic-content checks proposed in DF-001/006/008/013. Paranoid: adds
structural checks proposed in DF-002/004/018. Pre-commit hook stays on
Normal; release-branch CI uses Strict; major-bump ritual uses Paranoid.
Users can set `default_mode: <...>` in `.dockit-config.yml`.

## DF-021 — External-context checks are edit-triggered but not version-correlated

- Source: plaud-mirror ↔ home-infra/docs/PROJECTS.md (PROJECTS.md lagged behind plaud-mirror's VERSION on at least three occasions before the LLM assistant started sweeping it manually every bump)
- Date observed: 2026-04-24
- Category: gap
- Status: open
- Related: DF-009

Observation: the `external-triggers` check fires when a locally-tracked
file changes, telling the operator "external doc X may need updating".
It does NOT verify that the external doc's stated version of the downstream
project matches the downstream's current `VERSION`. Concretely:
`~/src/home-infra/docs/PROJECTS.md` has a table row stating
`| plaud-mirror | ~/src/plaud-mirror | 0.4.10 | ...`. The LLM can bump
plaud-mirror's VERSION to 0.4.13, skip the PROJECTS.md update, and the
validator never complains because no LOCAL file that matches an
`update_triggers` glob was changed — just VERSION, which is tracked by
version-sync but not by external-triggers.

Protocol implication: extend `.dockit-config.yml`'s
`external_context.update_triggers` mapping with an optional version-probe:

```yaml
external_context:
  update_triggers:
    - local_glob: "VERSION"
      external_path: "~/src/home-infra/docs/PROJECTS.md"
      version_probe: "| plaud-mirror | ~/src/plaud-mirror | %VERSION% |"
```

The validator reads `VERSION`, substitutes `%VERSION%`, greps the external
file; mismatch = warn. This directly catches the class of drift DF-009
describes at the "next action" level, by catching it at the "is the claim
still true?" level.

## DF-022 — HISTORY entry quality varies with no guardrail

- Source: plaud-mirror (HISTORY entries for 0.1.1, 0.2.0 etc. are surgical with exact file:line and numerical claims; others from the same project are summary-level)
- Date observed: 2026-04-24
- Category: process
- Status: open

Observation: HISTORY.md accepts any prose. Some entries are excellent
(every file touched listed, exact module paths, numbered test counts, "X
commits ahead of…"); others collapse to "Fixed several issues in the
backfill flow." A future LLM reconstructing "what happened in 0.4.5"
inherits a dataset of uneven quality. Over a long project lifetime this
degrades the value of HISTORY as a reconstruction source.

Protocol implication: add a non-blocking lint. Heuristics:
(a) entry has `- Files: [...]` list with at least one path
(b) entry has `- Version impact:` line ending in `yes` or `no`
(c) entry body length is between a sensible floor and ceiling (e.g. 400
    to 4000 chars — too short = vague, too long = unstructured dump)
(d) entry references at least one numerical or file:line-level assertion
    ("N tests pass", "file.ts:42")
Warn on (a) or (b) missing, info on (c)/(d). Combined with a "good
example" sample block at the top of HISTORY.md, most authors will pattern
on the example.

## DF-023 — DocKit uses DocKit on itself, with no external reviewer

- Source: LLM-DocKit self-observation (as of v4.5.0, DEFERRED_NEXT_VERSION.md, HOOKS_ENFORCEMENT_PROPOSAL.md and LLM_DOCKIT_CE_V2_PROPOSAL.md are visible in the working tree but untracked in git; none of DocKit's own docs are reviewed by a sibling LLM the way plaud-mirror's docs are reviewed by GPT-5)
- Date observed: 2026-04-24
- Category: process
- Status: open

Observation: the irony is acute — the protocol whose main value is
"structure for LLM collaboration" has no external reviewer for its own
docs. The same blind spot DF-010 identifies for adopters applies to DocKit
itself: validator PASS + maintainer eyeball is the bar, and untracked
planning docs accumulate in the working tree. The CONTRIBUTING story is
also absent, so contributors coming from outside have no prescribed
review/acceptance path.

Protocol implication: DocKit's own release process should run DocKit in
Strict or Paranoid mode (see DF-020) on DocKit, and periodically cross-LLM
review DocKit's docs and planning notes. Codify as
`docs/CONTRIBUTING.md` template (for adopter projects) and as a section
in DocKit's own `HOW_TO_USE.md`. Parallel: enforce that DocKit's own
working tree has no long-lived untracked `.md` files — either track them
or put them in `.gitignore` explicitly, so the repo state is never
"working tree has plans that don't exist in git history".

---

## Meta-observation

Two patterns run through the 23 entries, not one:

**Structural vs semantic.** DocKit currently enforces **structural**
discipline (markers, dates, manifest membership, paired file sync)
excellently and **semantic** discipline not at all. DF-001, DF-006, DF-008,
DF-011, DF-016, DF-019 are all "the artifact is shaped correctly but says
the wrong thing." Every implemented check is about shape; every open
entry about shape-passing-but-content-wrong.

**Persistence stores that should be one but are many.** DF-015 (same
policy in 5 docs), DF-018 (LLM auto-memory vs `docs/llm/`), DF-021
(internal VERSION vs external claim about VERSION) are all the same
abstract failure: "a single fact lives in multiple places with no sync
contract." DocKit's `version-sync-manifest.yml` solves this for
structural version strings. It does not solve it for content-level claims,
policy statements, or cross-repo cross-references.

The next generation of DocKit work (see
`docs/HOOKS_ENFORCEMENT_PROPOSAL.md`, `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md`)
can use this log to decide which semantic checks and which sync-contract
generalizations are worth their false-positive and maintenance cost. The
graduated-mode proposal (DF-020) is the natural surface on which to
dispatch them.

## DF-024 — Documenting drift is not fixing drift: the LLM may write a DF entry about a specific instance and leave the instance broken

- Source: plaud-mirror (DF-001 DEPLOY_PLAYBOOK Kali, DF-002 HOW_TO_USE orphan-marker, DF-003 HANDOFF stale "Next:" were all catalogued in this very file on 2026-04-24 at v4.5.0; the plaud-mirror instances were not fixed until v4.5.2 / plaud-mirror v0.4.15 — two iterations and a second GPT-5 review later)
- Date observed: 2026-04-24
- Category: process
- Status: open
- Related: DF-010, DF-022

Observation: when the LLM is asked to collect protocol-level feedback, it
may produce excellent DOWNSTREAM_FEEDBACK entries that precisely describe
the failure mode (file paths, line numbers, protocol implication) and
then declare the work complete. The specific instance that surfaced the
pattern stays broken. In the plaud-mirror case: DF-001 was written at
v4.5.0 citing `docs/operations/DEPLOY_PLAYBOOK.md:28` recommending
`vxcontrol/kali-linux:latest` in executable bash. DF-002 cited
`HOW_TO_USE.md` stuck at "v0.1.0 is a design-and-governance baseline" at
plaud-mirror v0.4.14. DF-003 cited HANDOFF Current Status trailing "Next:
rebuild image, verify VERSION, commit + push" after those had all
landed. All three stayed broken in plaud-mirror until a second GPT-5
review on the same day explicitly flagged that the DF entries existed
but the fixes did not — at which point plaud-mirror v0.4.15 closed
them.

This is a distinct failure mode from DF-010 ("validator PASS ≠ docs
useful"). In DF-010, the LLM hasn't noticed the content problem at all.
In DF-024, the LLM HAS noticed — and turned the noticing into a polished
governance artifact (DF entry, CHANGELOG note, HISTORY entry) that feels
productive. The net effect is worse than DF-010 because it creates a
false sense of care: a reader of the DF log sees the problem
acknowledged and assumes it is either resolved or actively being
worked. Neither is true.

Protocol implication: several options, not mutually exclusive.

(a) **Convention**: every DF-NNN entry that cites a specific instance
(file:line in any adopter repo) must either (i) ship with a fix commit
in the same adopter release that closes the instance, OR (ii) carry a
`Status: open` with a `TODO:` block that names the exact file:line
blocking remediation. Writing the entry alone, without either of those,
is not acceptable submission. Document this in the file header of
DOWNSTREAM_FEEDBACK.md (this file already models the convention as of
DocKit v4.5.2 — the `DF-001..DF-003` entries' `Status: open` has a
follow-up `Fixed: <adopter-version>` line once the adopter closes the
instance).

(b) **Validator check** (stretch): scan DF entries in DOWNSTREAM_FEEDBACK
for `Source: <project> (<version>)` declarations and `cites <file>:<line>`
patterns, cross-reference with the adopter's git log, and warn when a DF
entry cites an adopter instance that has not been touched in any commit
between the DF's creation date and the current date. Would catch the
exact lapse that produced DF-024.

(c) **Session-end ritual**: before declaring a session complete, the LLM
must review every DF entry it wrote in the session and answer "is the
instance cited in this entry fixed in the adopter repo, or is the DF
entry's Status truthful about what's still open?" This is an
LLM_START_HERE / session-closing-checklist addition, cheap to adopt,
zero validator cost.

Mitigation in source project: plaud-mirror v0.4.15 now has
`Fixed-in: plaud-mirror v0.4.15` written into DF-001/002/003 as status
updates (see below). The lesson — document + fix in the same loop — is
being generalised via this DF-024 entry and a proposal for the session
convention above.

### Backfill: update Status on DF-001, DF-002, DF-003

Per the convention proposed in DF-024(a), those three entries are now
updated:

- **DF-001** — Status now `implemented` (plaud-mirror v0.4.15 — DEPLOY_PLAYBOOK rewrote the Kali-recommending bash block to the acceptable-substitutes list, with a pointed rejection paragraph for pentesting/general-purpose distro bases).
- **DF-002** — Status now `implemented` (plaud-mirror v0.4.15 — HOW_TO_USE.md rewritten end-to-end + added to `docs/version-sync-manifest.yml` as the 20th target, so future rot is structurally blocked, not just patched).
- **DF-003** — Status now `implemented` (plaud-mirror v0.4.15 — HANDOFF Current Status and LLM_START_HERE Current Focus cleaned of trailing "Next: rebuild + push" forward-looking text now that the rebuild+push had landed).

Keeping DF-024 `open` because the proposed convention/check/ritual has
not yet landed in DocKit itself; the plaud-mirror fix closes the three
symptoms but the root cause (the LLM's tendency to confuse documenting
with fixing) is still live for the next adopter.

## DF-025 — Runbook promises a configuration the codebase doesn't actually support

- Source: plaud-mirror v0.4.15 (DEPLOY_PLAYBOOK + README + HANDOFF listed `node:20-alpine` as a valid Docker fallback; `Dockerfile:6` and `Dockerfile:30` forced `SHELL ["/bin/bash", "-lc"]` and Alpine doesn't ship bash — the documented fallback was aspirational, not executable)
- Date observed: 2026-04-24
- Category: drift
- Status: implemented (plaud-mirror v0.4.16 — Dockerfile drops both SHELL directives, Alpine build verified end-to-end including `GET /api/health` → 200). Protocol-level check proposed in the body below is still `open`.
- Related: DF-001, DF-024

Observation: a specialisation of DF-024, worth its own entry because
the failure mode is structurally different from "same policy replicated
across docs" (DF-015) or "runbook contradicts docs-level policy"
(DF-001). Here the drift is **code vs. docs**: the runbook promises X,
but the committed codebase does not support X, and the validator has
no way to notice. In DF-001 the fix is consistent docs; in DF-025 the
fix is either adjusting the code so the promise is true OR adjusting
the docs so they stop lying. Either direction is a real commit; leaving
either broken is drift.

The v0.4.15 instance in plaud-mirror is textbook: the LLM rewrote the
DEPLOY_PLAYBOOK with `node:20-alpine` as an example, passed the
validator, committed, pushed — all without running `docker build` with
that argument. The Alpine fallback existed only as prose. A third
GPT-5 review (same session) caught it the moment it attempted to
reason about what an operator would actually execute.

Protocol implication: a `runbook-claims-vs-code` check is hard to
generalise because "what the code supports" is project-specific. But
the template-level intervention is cheap and effective:

(a) **Template rule in `docs/operations/DEPLOY_PLAYBOOK.md`**: every
concrete example (every `export ...=VALUE`, every `--build-arg
K=V`, every command with a specific argument) should be marked either
`Verified: <commit-sha>` on the same line or be explicitly marked as
"not verified in CI, see assumptions below". DocKit's adopt-dockit skill
can drop this reminder. Mere mental discipline isn't enough — the v0.4.15
case is proof.

(b) **Session-end addendum to DF-024(c)**: "if the session modified a
runbook to include a new concrete example, the LLM must attempt the
example (or explicitly record why it cannot) before declaring the
session complete." Near-zero cost on writes; catches the exact failure
mode that produced DF-025.

(c) **Stretch check**: grep DEPLOY_PLAYBOOK for code blocks, extract
the first command verb + argument, check if a matching recent commit
exists. Probably too noisy to be useful, but worth prototyping.

## DF-026 — Backend tests go green while UI-state features (tabs, localStorage, collapse) ship with only a build-shell smoke test

- Source: plaud-mirror v0.4.14 (Main/Configuration tabs, collapsible Historical backfill, localStorage persistence — all shipped with the only web-side test being `tests/integration/web-build.test.mjs:6` which only asserts the build emits a shell)
- Date observed: 2026-04-24
- Category: gap
- Status: partially implemented (plaud-mirror v0.4.17 — pure UI helpers extracted into `packages/shared/src/formatting.ts` and covered by 12 dedicated `node:test` tests, hooked into the root suite). Component-level rendering tests for tabs persistence, collapsible card ARIA / mount-unmount, and BackfillPreview lifecycle are still `open` — those would need vitest+jsdom+@testing-library/react which is a real dependency addition deferred for a later patch. Protocol-level template rule (split testing rule by layer) is also still `open`.

Observation: at plaud-mirror v0.4.16 the suite is 53/53 green. The
backend is surgically tested (client parse, store CRUD, service logic,
server routes, schema round-trips). The web panel has exactly one
integration test that confirms the build output exists. Tabs, panel
localStorage state, collapse/expand behavior, BackfillPreview debounce
— none of it has a single assertion in the test suite. A regression
flipping any of those to broken would still report 53/53 pass.

This is not specifically a DocKit gap — test coverage is an adopter
concern. BUT DocKit already has a rule in LLM_START_HERE templates
("every new runtime case must come with explicit tests in the same
session"). The rule is advisory at the sentence level; it is not
differentiated by layer. In practice adopter LLMs interpret it as
"backend tests count" and ship UI changes without asserting the new
UI state.

Protocol implication: DocKit's template LLM_START_HERE should
distinguish "backend runtime cases" from "UI-state cases" in the
testing rule. Something like:

- For backend cases: unit/integration tests that assert the value
  the docs promise (see DF-016).
- For UI-state cases: at minimum a rendering assertion that the
  new state is present (component mounted, class applied, text
  rendered) OR an explicit waiver in HISTORY ("UI case not tested
  because <reason>").

The waiver path is intentional — it forces the LLM to acknowledge
the gap rather than silently skip it, and it gives reviewers an
audit trail. DocKit's enforcement cascade (Stop hook → pre-commit
→ CI) is already in place; this is a template change, not a
validator change.

Related to DF-010 (validator PASS ≠ docs useful) and DF-016 (tests
pass ≠ feature-correct) but distinct: those are about tests'
assertion quality; this one is about tests' presence at all in a
specific layer.

## DF-027 — `git add -u` silently skips new untracked files; commit succeeds, workspace stays green, origin is broken

- Source: plaud-mirror v0.4.17 (commit `d1bc317` on origin/main; closed by forward-fix v0.4.18 commit `d2f17f2` on the same branch)
- Date observed: 2026-04-25
- Category: process
- Status: partially implemented (plaud-mirror v0.4.18 — adopter symptom closed by re-staging the missing files explicitly + version bump + CHANGELOG entry naming the broken release). Protocol-level pre-commit hook check proposed in the body below is still `open`.
- Related: DF-024, DF-014

Observation: a specialisation of DF-024 ("documenting without
verifying") at the git-mechanics layer, distinct enough from DF-014
("commit accumulation across version bumps") to deserve its own entry.

The concrete failure: the LLM creates new files with the Write tool
(here `packages/shared/src/formatting.ts` and `formatting.test.ts`),
then runs `git add -u && git commit -m "..."`. The `-u` flag means
"stage all MODIFIED tracked files" — it does NOT stage new untracked
files. The new files stay `??` in `git status`. The commit succeeds
with whatever was modified-and-tracked, references the new files in
its commit message and CHANGELOG narrative, and pushes cleanly.

Local workspace stays green because:

- `tsc -b` reads source files from filesystem, not from git → the
  build succeeds.
- `node --test` reads compiled output the same way → tests pass.
- `docker compose build` uses `COPY . .` → the container ships with
  the missing-from-git files AS IF they had been versioned, and
  `cat /app/VERSION` returns the bumped value.
- `scripts/dockit-validate-session.sh` checks markers, dates, sync
  pairings — none of them inspect git tracking state of source files.

The only signal during the commit itself is the stat line
(`N files changed, X insertions(+), Y deletions(-)`). For
plaud-mirror v0.4.17 this read `128 insertions, 183 deletions` —
net negative for a release whose narrative claimed ~500 added lines
of new helpers + tests. That mismatch was visible in the commit's
output and the LLM read past it.

GPT-5 caught it on a fresh review by running `git status` (showing
the untracked files) and grepping for orphan references in tracked
files (`package.json`, `index.ts`, `App.tsx`, `service.ts` all
imported the missing module). A clean clone of the broken commit
would fail `npm install && npm run build` at import-resolution.

Protocol implication: three layers, low-cost to high-cost.

(a) **LLM convention** (already adopted in plaud-mirror's auto-memory
as `feedback_git_status_post_stage.md`): post-stage, run
`git status` and confirm zero untracked source/test files before
committing; post-commit, read the stat line and verify the magnitude
is consistent with the release narrative (net-negative on a feature
add ⇒ stop and inspect). Also: prefer `git add <explicit-paths>`
when files were created in the session; reserve `-u` for "I know
nothing was created."

(b) **Pre-commit hook check** (stretch, mechanical): grep the
staged tree for `import` / `from "..."` / `require(...)` /
`export * from "..."` references that resolve to paths NOT
present in the staged set. Implementation sketch: build the set
of staged files, parse each staged `.ts`/`.tsx`/`.js`/`.mjs` for
relative-path imports (`from "./foo"`, `from "../bar"`), resolve
them against the file's location, error if the resolved target
is neither in the staged set nor in the existing committed tree.
Catches DF-027 mechanically. False-positive risk: dynamic imports,
module aliases, JS-by-string-concat — fine to skip those, the
common case is plain relative imports and they would catch this
class of bug.

(c) **Stat-line plausibility check** (further stretch, advisory): a
post-commit `print "WARNING: net negative line count for a commit
whose message includes 'add' or 'feature'"` nudge. Heuristic, very
optional, cheap to add as a hook. Probably overkill for most
projects; would catch the DF-027 signal that the LLM missed.

Mitigation in source project: plaud-mirror v0.4.18 closes the
adopter symptom (the missing files are now in HEAD via
`git ls-tree -r HEAD packages/shared/src/`, the v0.4.17 tag stays
in history as a known-broken release with the CHANGELOG entry
acknowledging that explicitly, no force-push). The personal LLM
lesson is captured in
`~/.claude/projects/-home-cdelalama-src-plaud-mirror/memory/feedback_git_status_post_stage.md`
so future plaud-mirror sessions inherit it. The protocol-level
hook check (b) is the systemic cure and is the natural next-bump
candidate.

## DF-028 — Six recurrences of the same prose-version-drift class across one project's release line: first empirical demand for CE_V2 P0 ("Manifest = intención, CI = evidencia") from a downstream

- Source: plaud-mirror v0.4.x → v0.5.3 (six instances of the same drift class across five releases in a single day's work). Local mitigation shipped in plaud-mirror v0.5.4: `scripts/check-prose-drift.sh` + `check_prose_drift` wrapper in `scripts/dockit-validate-session.sh` per the Layer-1/Layer-2 architecture from `HOOKS_ENFORCEMENT_PROPOSAL.md`. See plaud-mirror's `docs/llm/DECISIONS.md` D-016 for the full design.
- Date observed: 2026-04-26
- Category: gap (DocKit) + framework-validation (CE_V2)
- Status: candidate, awaiting validation

### Dependencies (block resolution)

- `~/src/LLM-DocKit/docs/HOOKS_ENFORCEMENT_PROPOSAL.md` — status: draft, untracked, working source-of-truth. Defines the Layer-1/Layer-2 architecture this DF's mitigation implements. Until this RFC is committed and adopted, the mitigation is a downstream artifact, not a DocKit feature.
- `~/src/LLM-DocKit/docs/LLM_DOCKIT_CE_V2_PROPOSAL.md` — status: "Ready for Pilot", 18 LOCKED decisions, untracked. Section 3 P0 #1 ("Manifest = intención, CI = evidencia") describes exactly the failure mode this DF demonstrates empirically. Section 13 (Piloto) calls for "2 repos, 6-10 sesiones" as the validation scope; plaud-mirror v0.5.4 is offered as the first.

### Resolution path

`candidate` (now) → `validated` (after the v0.5.5 cycle in plaud-mirror confirms the WARN→FAIL ramp behaves as designed and the baseline shape settles) → `tracked` (after the upstream RFCs above are committed and locked) → `adopted` (the script and the wrapper move into DocKit's template, syncable to other adopters via `dockit-sync.sh`).

Note: this DF does NOT propose merging into DocKit before the upstream RFCs are firmed up. The mitigation in plaud-mirror is local; this entry reserves the slot, registers the empirical evidence, and links the artifact for review.

### Observation

Plaud-mirror's `auto-memory` (`~/.claude/projects/-home-cdelalama-src-plaud-mirror/memory/feedback_prose_version_drift.md`) had captured the failure mode after the second occurrence. The rule was extended four times across subsequent releases:

1. **v0.4.1** — stale `v0.3.0` in PROJECT_CONTEXT/ARCHITECTURE prose. Memory created.
2. **v0.4.2** — stale `v0.4.1` in `docs/ROADMAP.md:15`, `docs/PROJECT_CONTEXT.md:27`, `docs/ARCHITECTURE.md:4`. Memory extended.
3. **v0.5.0 → v0.5.1** — invented `"Phase 2 - manual sync"` string in docs that did NOT match `service.ts`'s actual `"Phase 2 - first usable slice"`. Memory extended.
4. **v0.5.2** — README still listing continuous sync as a "later phase" while v0.5.2 shipped exactly that. HANDOFF Top Priorities frozen at the v0.5.0 mapping. Memory extended.
5. **v0.5.3** — `DECISIONS.md` D-013 still describing the pre-implementation draft (5-attempt schedule, `/api/webhook-outbox/:id/retry` endpoint) when the shipped code was 8 attempts and `/api/outbox/:id/retry`. `DEPLOY_PLAYBOOK.md` Notes still claiming the durable outbox was "later in 0.5.x." Memory extended.

Each release's external review (GPT-5) caught the drift; the LLM (Claude) read its own memory, acknowledged the rule, fixed the immediate instance, extended the memory rule, and shipped — only for the next release to manifest a new variant of the same class.

The diagnosis arrived at by both reviewers and both LLMs in plaud-mirror's session of 2026-04-26: **memory is advisory; compliance depended on LLM discipline; the failure mode demanded enforcement.** This is the principle that `HOOKS_ENFORCEMENT_PROPOSAL.md` opens with, and it is exactly the modal failure that `LLM_DOCKIT_CE_V2_PROPOSAL.md` Section 3 P0 #1 prevents structurally:

> P0 #1: Manifest = intención, CI = evidencia.
> Por qué: si CI confía en booleanos auto-reportados, el guardrail es teatro.

Plaud-mirror's `auto-memory` rule was, in CE_V2 terms, an auto-reported boolean ("the LLM will sweep these N files"). With no CI evidence, the guardrail was theater for six releases.

### Mitigation in source project (v0.5.4)

Plaud-mirror v0.5.4 ships:

1. **`scripts/check-prose-drift.sh`** (POSIX sh, ~280 lines, zero external deps). Four rules:
   - `R1-stale-version` — `vX.Y.Z` literals that don't match `VERSION` and aren't baselined.
   - `R2-phase-string-mismatch` — phase string literals in docs that don't match what `service.ts` emits.
   - `R3-future-claim-already-shipped` — "still later", "lands during", "deferred to vX.Y.Z" in `docs/operations/` and `docs/llm/DECISIONS.md` that cite versions ≤ current.
   - `R4-decision-status-stale` — `D-XXX` entries whose `Status:` says "designed/lands during" while `CHANGELOG.md` mentions them as shipped.
   Three modes: `--strict` (default; exit 1 on drift), `--review` (JSON output for the future agent-based check, on-ramp to Layer 2), `--update-baseline --note "<reason>"` (deliberate operation that records auditable acceptances). The baseline file `scripts/.prose-drift-baseline.json` carries `{id, literal, file, rule, reason, commit_sha, created_at, transient_until?}` per entry; `transient_until` is enforced (when `current VERSION >= transient_until`, the entry is reported as expired with a remediation message).
2. **`check_prose_drift()` wrapper** in `scripts/dockit-validate-session.sh`. Thin driver per the Layer-1/Layer-2 split from `HOOKS_ENFORCEMENT_PROPOSAL.md`. Severity `WARN` during v0.5.4 (calibration window), promoted to `FAIL` from v0.5.5.
3. **First-run validation:** running the script against the live tree in v0.5.3 caught two real drifts immediately (D-012 and D-014 had stale `Status:` lines that `R4` flagged). After fixing both, the script returns PASS. The script paid for itself before its own commit.

### Implications for DocKit (when the upstream RFCs commit)

1. **Adopt `check-prose-drift.sh` into the DocKit template** with the existing `dockit-sync.sh` `copy` strategy. Adopters get the artifact plus the validator wrapper without rework.
2. **Reframe the `auto-memory` mental model in `LLM_START_HERE.md` template.** The current convention (memory holds rules) is empirically dangerous when the rule attempts to enforce. Plaud-mirror v0.5.4 added a global rule in `~/.claude/CLAUDE.md` ("Before adding a passive rule") plus a `PostToolUse` hook in `~/.claude/hooks/check-passive-rule.sh` that nudges the LLM whenever a write lands in `~/.claude/projects/*/memory/*`. That nudge is the meta-enforcement; the heuristic in CLAUDE.md is the rationale. Both are project-agnostic; both belong in DocKit's onboarding template once the global hook surface is documented in DocKit (currently it lives in the LLM tool's own configuration, not in DocKit).
3. **`LLM_DOCKIT_CE_V2_PROPOSAL.md` Section 13 piloto rules** call for 2 repos. plaud-mirror v0.5.4 is offered as the first — every condition the RFC describes (manifest ≠ CI evidence, prefiltered checks, advisory-then-strict severity, version-correlated checks) is now empirically demanded by a real adopter. The RFC's "Ready for Pilot" status is justified by a downstream signal, not by theoretical foresight.
4. **Optional Enhancement B (agent-based Stop hook)** of `HOOKS_ENFORCEMENT_PROPOSAL.md` is the closure path for the semantic-drift class that regex cannot cover (e.g. "we're still designing the ETL phase" while ETL is implemented — no version literal, no phrase the regex matches). The `--review` JSON output of `check-prose-drift.sh` is the explicit handoff format for that future agent. Schema is documented inside the script; do not rename fields without coordinating with the consumer.

### Link to the artifact

After plaud-mirror v0.5.4 commits to `origin/main`, the canonical pointer for review is:

```
github.com/cdelalama/plaud-mirror/blob/81b3fe0004884ffc6983a48a16ef00bbbaf7a4d3/scripts/check-prose-drift.sh
github.com/cdelalama/plaud-mirror/blob/81b3fe0004884ffc6983a48a16ef00bbbaf7a4d3/scripts/dockit-validate-session.sh
github.com/cdelalama/plaud-mirror/blob/81b3fe0004884ffc6983a48a16ef00bbbaf7a4d3/docs/llm/DECISIONS.md  (see D-016)
```

The link uses the SHA of the v0.5.4 release commit, not `HEAD` — the script will continue to evolve in plaud-mirror, and DocKit reviewers should read the version that made the empirical demand. The exact SHA will be filled in by the closing entry of this DF once the v0.5.4 cycle commits.

### Cross-references

- Related to **DF-016** (tests pass ≠ feature-correct). Same family: "the artifact says X" can be a lie that no current check catches. DF-016 is about test assertions; DF-028 is about prose claims.
- Related to **DF-024** (documenting drift is not fixing drift). DF-028 is the structural cure to the class DF-024 names: this is the first empirical demand for moving from "we wrote down that we drifted" (current state) to "the system catches drift before it ships" (target state).
- Related to **DF-027** (`git add -u` silently skips new files). Same modal failure as DF-028: the local memory of the lesson did not prevent the recurrence (DF-027 still happened despite plaud-mirror's `feedback_git_status_post_stage` memory entry). Together DF-027 + DF-028 are the strongest signal yet that DocKit needs CE_V2 P0 ("CI = evidencia") to graduate from "Ready for Pilot" to "Piloting now."

## DF-029 — Repo VERSION advances and `git push` succeeds, but the deployment lags invisibly

- Source: `infra-portal` v0.8.0 in repo / v0.7.2 in production + `tomatic` v0.1.5 audit, 2026-05-02 → 2026-05-03
- Date observed: 2026-05-03
- Category: gap
- Status: accepted (process side, via `docs/CONSENSUS_PROTOCOL_PROPOSAL.md`); validator side (`--check deployed-version`) is a separate future patch tracked in HANDOFF *Pending work*. (Status follows the file's own legend: `accepted` = listed in a `*_PROPOSAL.md` and committed to the roadmap; `partially implemented` would require an actual implementation in a release, which has not happened yet.)
- Related: DF-016, DF-021, DF-024
- Resolution path: a Consensus Protocol run on 2026-05-03 produced two sibling proposals: `docs/CONSENSUS_PROTOCOL_PROPOSAL.md` (this repo) formalising the deliberation primitive; `~/src/home-infra-protocol/docs/DEPLOYMENT_EVIDENCE_PROPOSAL.md` formalising the deployment evidence contract. Together they address the pattern at the LLM-DocKit level (a recorded protocol that names the rule "no `deployed` claim without evidence") and at the infrastructure protocol level (a typed vocabulary + schema block that lets a consumer measure drift). The optional `--check deployed-version` validator check is the remaining work and is not part of either proposal; it is the natural next patch once an adopter project asks for it. The deliberation is recorded in `docs/llm/REVIEWS.md` 2026-05-03.

### Observation

The `infra-portal` consumer of `home-infra-protocol` shipped `0.8.0` in repo on 2026-05-02 (TCP probe + `Service.interface`-aware rendering), with the validator returning PASS, all markers in sync, the commit pushed cleanly to `origin/main`. From DocKit's vantage, the release is "done": every check the protocol measures is green, the `external-triggers` warning fires correctly, the manifest is consistent.

In the next audit cycle, the operator pointed out that the deployed instance at `https://infra.lamanoriega.com/api/health` still answers `{"version":"0.7.2"}`. The image on the NAS was never rebuilt, never `docker save | docker load`-ed, never `docker compose restart`-ed. From the operator's vantage, the release is "shipped to git but not to users." Both vantages are simultaneously true and the two persistence stores (repo + deployment) carry contradictory facts about the same project.

DocKit's circuit covers the repo. The `version-sync-manifest`, `bump-version.sh`, `pre-commit-hook.sh`, and `dockit-validate-session.sh` all measure properties of the local file tree and `git log`. Nothing reaches outside the repo to ask "is the artifact this release describes also live somewhere?" — and for a homelab project with manual `docker save | docker load` deploys, that question is unanswered by default. The drift is structurally invisible until a human notices.

This is the deployment-plane analogue of the patterns already filed:

- **DF-016** (tests pass ≠ feature-correct): the artifact says X but the artifact does not deliver X. There the lie was at the assertion level; here the lie is at the deployment level.
- **DF-021** (external-context checks are edit-triggered but not version-correlated): the inverse direction. DF-021 is about `home-infra/PROJECTS.md` lagging behind a project's `VERSION`. DF-029 is about a *deployed runtime* lagging behind a project's `VERSION`. Both are "two stores, one truth, no sync contract."
- **DF-024** (documenting drift is not fixing drift): an LLM can mark a release as shipped and the bug stays alive. DF-029 is a specialisation: the LLM can mark a release as shipped, the bug is not the bug being addressed but the deploy itself, and nothing reads the deployed reality back.

### Protocol implication

Three layers of fix, low to high cost.

(a) **Adopter convention** (cheap, project-local). Document in `LLM_START_HERE.md` template: *"After bumping VERSION and pushing, treat the release as 'in repo, not deployed' until you have personally verified the runtime returns the new VERSION. If your project does not run as a container with a `/api/health`-style endpoint, document the equivalent verification step (image tag inspection, file fingerprint, etc.) in `docs/operations/DEPLOY_PLAYBOOK.md`."* Pure prose; zero validator cost; relies on LLM discipline (which DF-024 already taught us is fragile, but the prose anchor is still the cheapest first step).

(b) **Optional `deployed-version` validator check.** New `.dockit-config.yml` block:

```yaml
deployment:
  health_endpoints:
    - name: production
      url: https://example.lamanoriega.com/api/health
      version_jsonpath: $.version
```

`scripts/dockit-validate-session.sh --check deployed-version` reads `VERSION`, fetches the URL, parses out the version field, warns or errors when they diverge by more than N patch levels. Skipped when no `deployment:` block is configured. Mirrors the structure of `external_context.update_triggers` from DF-009/-021. Cost: ~30 lines of POSIX `sh` + curl + a small JSON path implementation.

(c) **CE_V2 P0 generalisation.** This DF is a clean instance of the same principle DF-028 names: "Manifest = intención, CI = evidencia." A project's `VERSION` is intent (what the maintainer claims is shipped). A live `/api/health` is evidence (what the runtime actually serves). Today the manifest is the only artifact DocKit reads; the evidence side is unmeasured. Folding deployed-version into the CE_V2 strict-mode probe set (alongside DF-001, DF-006, DF-008, DF-013, DF-028's prose-drift) closes one of the largest remaining gaps in the cure path that the LLM_DOCKIT_CE_V2_PROPOSAL describes.

Recommended sequence: (a) immediately in the next adopter session that touches `LLM_START_HERE.md`; (b) as a `--check deployed-version` opt-in once one adopter explicitly asks; (c) as part of CE_V2 P0 strict mode when that proposal lands.

### Cross-protocol relationship

This DF has a sibling in `home-infra-protocol/docs/DOWNSTREAM_FEEDBACK.md` (`DF-003`) describing the same class as it manifests in the protocol's "Consumer support for `interface`" matrix, where `Version` was implicitly read as "repo HEAD" but only `deployed version` would close the gap that motivated the matrix in the first place. The two protocols address the class at different levels: home-infra-protocol fixes a documentation artifact (its SPEC matrix); LLM-DocKit fixes a generic validator surface that any DocKit project can opt into.

### Mitigation in source projects

`tomatic` v0.1.5 records the deploy lag in `home-infra/docs/{INVENTORY,SERVICES}.md` (operator-readable) and accepts the limitation: until `infra-portal:0.8.0` is promoted to production, the catalog's `interface: mqtt` / `interface: web` declarations and the `mosquitto` status will look identical to old behaviour. The image promotion is a separate operator-driven action; DocKit could not have caught the gap with today's checks.

`infra-portal` v0.8.0's HANDOFF documents the repo-vs-deployed split explicitly ("production stays at infra-portal:0.7.2; repo at 0.8.0... deploy to NAS is gated to a separate operator-driven session; it is NOT part of this commit"). That HANDOFF text is, in effect, an inline DF-029 mitigation: the LLM-authored doc tells the next reader the truth that the validator cannot. Codifying this convention into the LLM_START_HERE template is the fix path (a) above.

## DF-030 — Five refinement lessons from the Consensus Protocol's first self-application audit

- Source: 2026-05-03 audit cycle around `tomatic` 0.1.5 + `home-infra-protocol` 0.2.2/0.2.3 + LLM-DocKit `1784318`/`b3de32e`/`3cbd37f`. Three audit passes by GPT-5 over the same week's deliberation.
- Date observed: 2026-05-03
- Category: process
- Status: open (deliberately captured here without a Consensus run; this entry is **not** intended to trigger another audit pass — it is a forward-pointer for the next session that touches the protocol)
- Related: DF-005 (HANDOFF↔LLM_START_HERE drift, the original mirror-pair pattern), DF-015 (policy replicated across docs drifts independently), DF-029 (deployment lag invisibility).

### Observation

The first sustained self-application of the Consensus Protocol — a session producing two cross-repo proposals + REVIEWS entries + multiple audit passes — surfaced five distinct refinement lessons that the proposal itself does not name. The lessons are real, repeatable, and structurally interesting; capturing them here so a future session that returns to the Consensus Protocol can incorporate them.

The lessons are listed in increasing structural cost. Each is implementable as a small additive change to the existing protocol artefacts; none require redesign.

**1. The auditor is a fourth role the protocol does not name.** The proposer/critic/arbiter triangle handles deliberation but has a structural blind spot: every participant is engaged with the artefact under construction, none reads the closed artefact holistically from outside. Three audit passes over this week's commits found drifts none of the original deliberation participants noticed. The auditor role is post-closure (operates on already-closed artefacts), produces findings (not decisions), and dispatches to either fix-forward (if drift is mechanical) or to a new Consensus run (if structural). Where to land: a new section in `CONSENSUS_PROTOCOL_PROPOSAL.md` titled "Auditor role (post-closure)".

**2. Drift findings must be classified mechanical vs structural before responding.** Not every audit finding warrants a new Consensus run. Mechanical drifts — typos, status strings outside legend, missing HISTORY entries, legend-template misalignment — are resolved deterministically by the existing rules; the response is a micro-commit, not new deliberation. Structural drifts — an example contradicting its own ontology, a contract conflicting with another contract — may require deliberation if the resolution is non-obvious. The two responses share form (a fix-forward commit) but differ in process (the latter passes through a Consensus run, the former does not). The protocol does not articulate this distinction today and risks treating every drift as either trivial (noise) or major (paralysing). Where to land: sub-section "Fix-forward classification" of the proposal.

**3. Audit cycles need an explicit termination criterion.** Each audit pass tends to find something. Without a stop rule, "another audit, another fix" can compound into ceremony. A workable termination rule: *"a session is considered closed when two consecutive audit passes by distinct roles produce no new findings, or when the human arbiter explicitly declares 'ship as is, residual drift accepted'."* Without this, the audit-fatigue dynamic erodes the practice the proposal is trying to install. Where to land: "Termination criteria for audit cycles" sub-section, or a paragraph in the Failure modes section.

**4. Legend ↔ template drift is generalisable beyond DF-005.** This week's audit caught the DF-NNN status template (line 43) lagging the legend (line 17) — exactly the family that `DF-005 — HANDOFF ↔ LLM_START_HERE Current Focus drift` already names but solves only for that specific pair. The generalised pattern: any document that contains both a definition (legend, rule, schema) and a usage example (template, instance, reference) needs a sync check that diffs the two and warns on divergence. Today the validator solves this for one mirror pair (HANDOFF ↔ LLM_START_HERE); generalising it would catch DF-030's own surface plus, say, schema↔example pairs in `home-infra-protocol`. Where to land: dedicated DF? Or a candidate work item for a future PROPOSAL that extends the validator with a `mirror-pairs` configurable check (akin to how `external_context.update_triggers` works today). Lean toward the latter — keeps the catch generic.

**5. The audit primitive is non-trivially relevant to ForgeOS' consensus subsystem design.** Stated explicitly: ForgeOS' planned consensus subsystem should *not* clone the three-role protocol. It should clone the four-role protocol, with the auditor as a first-class automatable role (a residual agent reading closed artefacts on a schedule and emitting findings). Without an automatable auditor, ForgeOS inherits the same blind spot the original three-role protocol had — and that is exactly the kind of architectural sin a precedent should avoid. Where to land: a one-line addendum to the "Future consumer / precedent" section of `CONSENSUS_PROTOCOL_PROPOSAL.md`, pointing here.

### Protocol implication summary

Lessons 1, 2, 3 are additive refinements to `CONSENSUS_PROTOCOL_PROPOSAL.md` — total cost ~30-45 minutes of writing for a future session that returns to the proposal.

Lesson 4 is its own work item: extending the validator with a generalised mirror-pair check. Cost is moderate (~50-100 lines POSIX shell + per-project config). Filed as a candidate PROPOSAL trigger, not a separate DF, because it is a clear specialisation of an already-named family (DF-005 + DF-015).

Lesson 5 is one line in a future ForgeOS design document. Today it lives only here.

### Why this entry exists without an accompanying Consensus run

This DF is captured as a forward-pointer, not as a triggered work item. The audit cycle that produced these lessons has reached the operator-declared "ship as is" terminus per Lesson 3 above (avant la lettre). Subsequent audit passes on this entry should *not* spawn new commits in this session; they belong to the future session that picks up Lessons 1-3 as a Consensus Protocol refinement.

The five lessons are observable empirically, formally, and consistently across the three audit passes. They are not speculative. They are the protocol's first round of dogfooding feedback on itself — exactly the kind of input the protocol claims to consume but had not yet been tested with at this scope.

### Mitigation in source projects

None — these are protocol-level lessons, not adopter-symptom drifts. The mitigation is the existence of this entry.

## DF-031 — Ecosystem-wide prior-art search is missing before high-blast-radius proposals

- Source: 2026-05-04 — operator audit during the Consensus Protocol self-application session caught that `LLM-DocKit/docs/CONSENSUS_PROTOCOL_PROPOSAL.md` (created 2026-05-03) substantially duplicated `~/src/llm-council/docs/PROTOCOL_PROPOSAL.md` (created 2026-03-01). Same scope, same empirical motivation, two months apart, by the same operator. Three LLM rounds did not catch the duplication; the operator did, by remembering the prior project.
- Date observed: 2026-05-04
- Category: process
- Status: open (placeholder — full content to be expanded in Session 4 of the ecosystem reconciliation roadmap, see `~/src/home-infra/docs/SESSION_HANDOFF_2026-05-04_ECOSYSTEM_RECONCILIATION.md`)
- Related: DF-030 (audit role surfaces structural drift), DF-018 (LLM personal auto-memory and `docs/llm/` drift as parallel stores)

### Observation

When a session proposes work of high blast radius (per Consensus Protocol thresholds — contract changes, multi-repo spans, security/persistence implications, multi-week reversibility, precedent-setting decisions), it should first search the ecosystem for prior art. Today there is no canonical, machine-readable list of ecosystem projects with their scopes, so the search is manual, optional, and easily skipped. The gap surfaced visibly in the 2026-05-03 / 2026-05-04 deliberation: `CONSENSUS_PROTOCOL_PROPOSAL.md` re-discovered substantial portions of `llm-council` two months after the latter had been formalised. None of the LLMs involved (Claude proposer, GPT-5 critic) brought up `llm-council` until the operator did during a post-closure audit.

### Protocol implication

Three layers, low to high cost:

(a) **Convention in `LLM_START_HERE.md` template**: "Before proposing work of high blast radius, read the Ecosystem Map and search the listed repos for prior art. Document the search in your proposal's *Prior art* section." Pure prose; relies on LLM discipline.

(b) **The Ecosystem Map artefact itself**, planned for `~/src/home-infra-protocol/docs/ECOSYSTEM_MAP.md`. Columns: Repo, Scope, Owns, Does not own, Key docs, Consumers, Related protocols, **Prior-art keywords**, Status. The keywords column is the seed for (c).

(c) **Validator check `--check ecosystem-prior-art` (future)**: scan the new proposal's title and first section for keywords matching any registered protocol's prior-art keywords; warn if overlap above a threshold. Cheap to implement once (b) exists.

The recommended sequence: ship (b) in Session 4, ship (a) in Session 5, defer (c) until volume justifies.

### Cross-protocol relationship

This DF complements DF-030: where DF-030 names auditing as a role for *artefacts within a repo*, DF-031 names ecosystem prior-art search as a discipline for *cross-repo scope*. Both are different facets of the same observation: the human arbiter sees things the LLMs don't, because the human carries cross-project memory. ForgeOS' future automation must address both.

### Mitigation in source projects

The 2026-05-04 ecosystem reconciliation roadmap (Session 4) addresses the symptom by producing the Ecosystem Map. The protocol-level cure (validator check) is deferred. The convention in `LLM_START_HERE.md` will land via Session 5's merge implementation.

## DF-032 — Cross-LLM deliberation logs are not automatically captured into `llm-council/raw/`

- Source: 2026-05-04 — the very session that surfaced DF-031 (and produced two PROPOSALs + multiple REVIEWS entries + audit cycles) has no automatic mechanism to deposit its log into `~/src/llm-council/raw/`. The protocol's empirical foundation (8500 lines in `raw/` from manual exports done in March 2026) has not received a new session log automatically since. The aspiration in `~/src/llm-council/docs/PROTOCOL_PROPOSAL.md` §3.6 (a session file format under `~/.llm-council/sessions/<session-id>/`) is unimplemented.
- Date observed: 2026-05-04
- Category: gap
- Status: open (placeholder — full content to be expanded in Session 4 of the ecosystem reconciliation roadmap)
- Related: DF-018 (auto-memory vs `docs/llm/` drift), DF-030 (auditor role)

### Observation

The Consensus Protocol's empirical base depends on `~/src/llm-council/raw/`. That directory has six logs (~8500 lines) from sessions exported manually by the operator in March 2026. Since then, multiple deliberations have happened (the entire 2026-05-03 / 2026-05-04 work, plus other operator sessions) without depositing new logs. Two consequences:

1. The protocol's empirical base ages — its analysis of "what patterns emerge" is anchored to two-month-old data.
2. New deliberations (this very session is the most recent example) only survive in scattered form: the digest is in REVIEWS, the rationale is in DFs, the implementation is in commits, the conversational flow is in chat scrollback (volatile). No single artefact captures the full session for analysis.

The session that surfaced this DF had to **manually** export a digest to `~/src/llm-council/raw/session-2026-05-04-consensus-self-application/` (done in this session's closing actions). That manual step is exactly the friction the gap names.

### Protocol implication

(a) **A small CLI / skill that exports a session** — Claude Code transcript + manually-pasted GPT replies + operator arbitration — into a normalised log under `llm-council/raw/session-<id>/`. Probably a `dockit-export-session.sh` style script, or a Claude Code skill that reads the current session's transcript and produces `summary.md` + `sources.yml` + (optionally) raw transcript.

(b) **A convention** in `LLM_START_HERE.md` for projects scaffolded with the Consensus Protocol integration: "When closing a consensus run, export the session digest to `~/src/llm-council/raw/session-<id>/` so the protocol's empirical foundation grows."

(c) **A periodic check**: scan `llm-council/raw/` for last-modified date; warn if no new session log in N days while other ecosystem repos show activity that should have produced sessions.

The minimum viable starting point is (a). (b) follows naturally once (a) exists. (c) is bonus.

### Cross-protocol relationship

DF-032 sits at the intersection of `llm-council` (which owns the destination format) and LLM-DocKit (which owns scaffold-level conventions). The export tool itself is more naturally a llm-council artefact (it knows the session file format); the convention to invoke it is more naturally a LLM-DocKit template addition. Session 4 should decide ownership cleanly.

### Mitigation in source projects

The 2026-05-04 session deposits its digest manually at `~/src/llm-council/raw/session-2026-05-04-consensus-self-application/`. That is the proof-of-concept input format and the empirical evidence that the manual step adds friction. Future sessions should not need to do this manually.

## DF-033 — Passive onboarding instructions in repo docs do not enforce session-start context loading

- Source: 2026-05-03 — operator opened a Codex CLI session inside `home-infra-protocol` to audit the freshly-landed `DEPLOYMENT_EVIDENCE_PROPOSAL` acceptance. Asked the agent for an opinion on the broader ecosystem of protocols. The agent answered partially and disclosed it had not read `LLM_START_HERE.md`, `docs/llm/HANDOFF.md`, or the master ecosystem roadmap (`~/src/home-infra/docs/SESSION_HANDOFF_2026-05-04_ECOSYSTEM_RECONCILIATION.md`). Pressed by the operator, the agent confirmed the rule was declared in `LLM_START_HERE.md` lines 9 and 87 but had been skipped because the immediate user instruction ("audit, do not implement") established a narrower scope. After the operator forced the orientation, the agent read the missing files and acknowledged the failure mode.
- Date observed: 2026-05-03
- Category: process
- Status: implemented (Claude Code + Codex CLI axes via SessionStart hooks). LLM-DocKit 4.7.0 ships the scaffold-side artefacts: `scripts/dockit-bootstrap-context.sh` + `.claude/settings.json` SessionStart hook + `dockit-sync-manifest.yml` entry. Codex CLI axis closed 2026-05-03 by operator-side wiring of `~/.codex/config.toml` SessionStart hook pointing at the central script with `--project "$(git rev-parse --show-toplevel)"` (Codex's hook JSON shape is identical to Claude Code's, so the same script drives both). Smoke-tested live: the very repo where DF-033 was originally observed (`home-infra-protocol`) now opens Codex with `Onboarding loaded.` as the first line of the first substantive reply, followed by content that demonstrably consumed the listed docs (cites version 0.3.0, deployment evidence contract, intent-vs-telemetry rule). Non-hook LLMs (Cursor, Aider, web ChatGPT) remain advisory pending those tools growing SessionStart equivalents — the `--human` mode of the script is the manual workaround until then.
- Related: DF-005 (HANDOFF↔LLM_START_HERE drift — same family: prose-only rule, no enforcement), DF-015 (policy replicated across docs drifts independently), DF-024 (documenting drift is not fixing drift), DF-031 (ecosystem prior-art search). Inverse counterpart of `docs/HOOKS_ENFORCEMENT_PROPOSAL.md` (Stop hook for session-end validation): this DF closes the equivalent gap at session-start.

### Observation

LLM-DocKit (and projects scaffolded from it) declare a mandatory reading order in `LLM_START_HERE.md`. The rule is prose. Empirically, agents skip it under three conditions:

1. The user issues a narrow scope ("audit X", "fix the typo in Y", "write a one-liner to do Z") that does not appear to require ecosystem context.
2. The agent's session prompt does not surface `LLM_START_HERE.md` automatically — the agent only reads it if it remembers to look.
3. No mechanical signal interrupts the agent before it answers the user's first prompt.

The 2026-05-03 incident on `home-infra-protocol` is a representative instance: the agent gave a partial ecosystem opinion based on this-repo content alone, and only loaded the missing context after the operator explicitly pointed it out. The same failure mode is plausible across every LLM-DocKit-scaffolded project; it is not specific to Codex CLI, the operator, or that particular repo. Claude Code in `~/src/tomatic` has the same exposure today — the global `~/.claude/CLAUDE.md` mitigates it for tomatic-via-Claude specifically (it injects the homelab reading order via the always-loaded user-level CLAUDE.md), but every other (project × LLM-tool) pair lacks an equivalent.

This is the same root cause already named in this file: `compliance depends on LLM discipline, not on system enforcement` (legend prelude; DF-005 prose; HOOKS_ENFORCEMENT_PROPOSAL §Problem Statement). DF-033 is the SessionStart-side specialisation.

### Protocol implication

Three layers, in increasing portability:

(a) **Claude Code SessionStart hook** (highest enforcement, lowest portability). A new `scripts/dockit-bootstrap-context.sh` POSIX script reads the project's `LLM_START_HERE.md` "Recommended reading order:" section and emits a Claude Code SessionStart `additionalContext` JSON payload that arrives before the user's first prompt. The payload (~1.5 KB; well under the 10 KB SessionStart limit) instructs the agent to begin its first substantive reply with literally `Onboarding loaded.` after reading the listed files, or `Onboarding skipped: <reason>` for trivial requests. The string is short and observable in transcripts — the operator can spot agents that skip silently.

(b) **`--human` mode of the same script** (medium portability). For non-Claude LLMs (Codex CLI, Cursor, web ChatGPT), the operator runs `scripts/dockit-bootstrap-context.sh --human` and pastes the output into the session as the first message. Same content, manual delivery. Friction is real but the artefact is identical; the moment those tools grow SessionStart equivalents, the same script is invoked from there with no rewrite.

(c) **Existing prose** in `LLM_START_HERE.md` and `~/.claude/CLAUDE.md` (lowest enforcement, highest portability). Stays as-is; no change. (a) and (b) are additive — they do not remove the prose-level rule. The prose remains the human-readable contract; the hook is the mechanical guarantee.

### Why this is shipping as a script + hook (not as more docs)

The operator's standing rule (in `~/.claude/CLAUDE.md`, "Before adding a passive rule" section) is explicit: *"If you are about to write a memory entry that includes the words always, every time, before/after, must, remember to, or don't forget — stop. Convert to code or hook before saving."* This DF is the inverse instance — a prose rule that already exists and *was* the failure mode. Writing more prose to enforce a prose rule is the loop the operator's heuristic prohibits. The fix has to be mechanical.

### Cross-protocol relationship

DF-033 sits at the intersection of LLM-DocKit (which owns the scaffold and its hook surface) and the LLM-tool ecosystem (which owns the hook execution). The script lives in LLM-DocKit (scaffold-internal, propagated via `dockit-sync-manifest.yml: copy`); the hook configuration in `.claude/settings.json` is also `copy`-strategy; together they ship as one bundle. Tools without hook surfaces consume the same script via `--human`.

This DF is **not** a Consensus Protocol artefact. It does not change a contract or alter cross-repo scope; it adds a small enforcement primitive to an existing convention. Capture as DF + ship a 4.7.0 minor, no PROPOSAL needed (compare to DF-031 which *does* warrant a PROPOSAL — different blast radius).

### Mitigation in source projects

LLM-DocKit 4.7.0 ships (scaffold-side):
- `scripts/dockit-bootstrap-context.sh` (POSIX, zero deps, ~7 KB)
- `.claude/settings.json` `SessionStart` block calling the script with `--json`
- `dockit-sync-manifest.yml` entry with `strategy: copy`

Operator-side wiring (not part of the scaffold; lives in user's home directory):
- `~/.claude/settings.json` already had hooks; the project-local `.claude/settings.json` from LLM-DocKit takes precedence per Claude Code's hook resolution.
- `~/.codex/config.toml` augmented 2026-05-03 with `[features] codex_hooks = true` + `[[hooks.SessionStart]]` block calling the central LLM-DocKit script via absolute path with `--project "$(git rev-parse --show-toplevel)"`. This applies to every Codex CLI session globally and works even in repos that have not yet received the script via `dockit-sync`. Reversible by removing the block; backup at `~/.codex/config.toml.bak.20260503`.

Tomatic adopts immediately (in the same session that surfaced the gap, applied without waiting for `dockit-sync` so the failure mode is closed for the project under active work). Other downstream projects (`plaud-mirror`, `home-infra-protocol`, `infra-portal`, `llm-council`, etc.) get the scaffold-side artefacts when the operator runs `dockit-sync` against them — but the Codex CLI hook covers them all today via the global user-level config.

Smoke test (2026-05-03 in `home-infra-protocol`, the originally-failing repo): Codex opened, first substantive reply began with literally `Onboarding loaded.` followed by ecosystem-aware content. The same simulation from `/tmp` (non-git, no `LLM_START_HERE.md`) produced exit 0 with no output — graceful no-op confirmed.

Known limitation captured during the smoke test (filed as a follow-up patch for 4.7.1): the script's awk extraction of the "Recommended reading order:" section exits early when there is a blank line between the header and the numbered list. Repos following the LLM-DocKit template (no blank) extract correctly (tomatic: 9 items, LLM-DocKit: 7 items); repos with a customised template that adds a blank line (home-infra-protocol) fall back to a generic 2-item list. The hook still fires and the protocol still works — only the per-repo customisation is degraded.
