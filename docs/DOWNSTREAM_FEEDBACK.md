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
- Status: open (validator side only; the earlier DocKit-owned consensus/process path was superseded by D-011 on 2026-06-19)
- Related: DF-016, DF-021, DF-024
- Resolution path: the 2026-05-03 deliberation produced a historical DocKit proposal that is now archived as lineage by D-011. The remaining LLM-DocKit work is narrower: an optional `--check deployed-version` validator surface if an adopter asks for it. Runtime/process orchestration belongs to a future ForgeOS ownership decision, while `llm-council` remains curated corpus.

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
- Status: rejected (not LLM-DocKit scope after D-011; retained as lineage input for a future ForgeOS ownership decision)
- Related: DF-005 (HANDOFF↔LLM_START_HERE drift, the original mirror-pair pattern), DF-015 (policy replicated across docs drifts independently), DF-029 (deployment lag invisibility).

### Observation

The first sustained self-application of the now-archived Consensus Protocol proposal — a session producing two cross-repo proposals + REVIEWS entries + multiple audit passes — surfaced five distinct refinement lessons that the proposal itself did not name. The lessons are real, repeatable, and structurally interesting; capturing them here preserves lineage for the future ForgeOS runtime ownership decision and for `llm-council` corpus curation.

The lessons are listed in increasing structural cost. Each is implementable as a small additive change to the existing protocol artefacts; none require redesign.

**1. The auditor is a fourth role the archived protocol did not name.** The proposer/critic/arbiter triangle handles deliberation but has a structural blind spot: every participant is engaged with the artefact under construction, none reads the closed artefact holistically from outside. Three audit passes over this week's commits found drifts none of the original deliberation participants noticed. The auditor role is post-closure (operates on already-closed artefacts), produces findings (not decisions), and dispatches to either fix-forward (if drift is mechanical) or to a new runtime protocol step (if structural). Where to land after D-011: future ForgeOS ownership decision / ProtocolEngine design, not LLM-DocKit.

**2. Drift findings must be classified mechanical vs structural before responding.** Not every audit finding warrants a new deliberation run. Mechanical drifts — typos, status strings outside legend, missing HISTORY entries, legend-template misalignment — are resolved deterministically by the existing rules; the response is a micro-commit, not new deliberation. Structural drifts — an example contradicting its own ontology, a contract conflicting with another contract — may require deliberation if the resolution is non-obvious. The two responses share form (a fix-forward commit) but differ in process. The archived proposal did not articulate this distinction and risked treating every drift as either trivial (noise) or major (paralysing). Where to land after D-011: future ForgeOS runtime ownership decision / ProtocolEngine design, not LLM-DocKit.

**3. Audit cycles need an explicit termination criterion.** Each audit pass tends to find something. Without a stop rule, "another audit, another fix" can compound into ceremony. A workable termination rule: *"a session is considered closed when two consecutive audit passes by distinct roles produce no new findings, or when the human arbiter explicitly declares 'ship as is, residual drift accepted'."* Without this, the audit-fatigue dynamic erodes the practice the archived proposal was trying to install. Where to land after D-011: future ForgeOS runtime ownership decision / ProtocolEngine design, not LLM-DocKit.

**4. Legend ↔ template drift is generalisable beyond DF-005.** This week's audit caught the DF-NNN status template (line 43) lagging the legend (line 17) — exactly the family that `DF-005 — HANDOFF ↔ LLM_START_HERE Current Focus drift` already names but solves only for that specific pair. The generalised pattern: any document that contains both a definition (legend, rule, schema) and a usage example (template, instance, reference) needs a sync check that diffs the two and warns on divergence. Today the validator solves this for one mirror pair (HANDOFF ↔ LLM_START_HERE); generalising it would catch DF-030's own surface plus, say, schema↔example pairs in `home-infra-protocol`. Where to land: dedicated DF? Or a candidate work item for a future PROPOSAL that extends the validator with a `mirror-pairs` configurable check (akin to how `external_context.update_triggers` works today). Lean toward the latter — keeps the catch generic.

**5. The audit primitive is non-trivially relevant to ForgeOS' consensus subsystem design.** Stated explicitly: ForgeOS' planned runtime should *not* clone the three-role historical proposal. It should include the auditor as a first-class automatable role (a residual agent reading closed artefacts on a schedule and emitting findings). Without an automatable auditor, ForgeOS inherits the same blind spot the original three-role protocol had. Where to land after D-011: future ForgeOS ownership decision.

### Protocol implication summary

Lessons 1, 2, and 3 are no longer LLM-DocKit roadmap items. They are lineage input for the future ForgeOS runtime ownership decision and for any `llm-council` corpus curation notes.

Lesson 4 is its own work item: extending the validator with a generalised mirror-pair check. Cost is moderate (~50-100 lines POSIX shell + per-project config). Filed as a candidate PROPOSAL trigger, not a separate DF, because it is a clear specialisation of an already-named family (DF-005 + DF-015).

Lesson 5 belongs in a future ForgeOS design/decision document. Today it lives here only as historical evidence.

### Why this entry exists without an accompanying Consensus run

This DF is captured as a forward-pointer, not as a triggered work item. The audit cycle that produced these lessons has reached the operator-declared "ship as is" terminus per Lesson 3 above (avant la lettre). Subsequent audit passes on this entry should *not* spawn new commits in this session; Lessons 1-3 belong to the future ForgeOS ownership decision and any `llm-council` corpus curation that follows it.

The five lessons are observable empirically, formally, and consistently across the three audit passes. They are not speculative. They are the protocol's first round of dogfooding feedback on itself — exactly the kind of input the protocol claims to consume but had not yet been tested with at this scope.

### Mitigation in source projects

None — these are protocol-level lessons, not adopter-symptom drifts. The mitigation is the existence of this entry.

## DF-031 — Ecosystem-wide prior-art search is missing before high-blast-radius proposals

- Source: 2026-05-04 — operator audit during the Consensus Protocol self-application session caught that `LLM-DocKit/docs/CONSENSUS_PROTOCOL_PROPOSAL.md` (created 2026-05-03) substantially duplicated `~/src/llm-council/docs/PROTOCOL_PROPOSAL.md` (created 2026-03-01). Same scope, same empirical motivation, two months apart, by the same operator. Three LLM rounds did not catch the duplication; the operator did, by remembering the prior project.
- Date observed: 2026-05-04
- Category: process
- Status: open (prior-art search remains useful; consensus/runtime ownership moved out of LLM-DocKit by D-011)
- Related: DF-030 (audit role surfaces structural drift), DF-018 (LLM personal auto-memory and `docs/llm/` drift as parallel stores)

### Observation

When a session proposes work of high blast radius (contract changes, multi-repo spans, security/persistence implications, multi-week reversibility, precedent-setting decisions), it should first search the ecosystem for prior art. Today there is no canonical, machine-readable list of ecosystem projects with their scopes, so the search is manual, optional, and easily skipped. The gap surfaced visibly in the 2026-05-03 / 2026-05-04 deliberation: the now-archived DocKit Consensus proposal re-discovered substantial portions of `llm-council` two months after the latter had been formalised. None of the LLMs involved (Claude proposer, GPT-5 critic) brought up `llm-council` until the operator did during a post-closure audit.

### Protocol implication

Three layers, low to high cost:

(a) **Convention in `LLM_START_HERE.md` template**: "Before proposing work of high blast radius, read the Ecosystem Map and search the listed repos for prior art. Document the search in your proposal's *Prior art* section." Pure prose; relies on LLM discipline.

(b) **The Ecosystem Map artefact itself**, planned for `~/src/home-infra-protocol/docs/ECOSYSTEM_MAP.md`. Columns: Repo, Scope, Owns, Does not own, Key docs, Consumers, Related protocols, **Prior-art keywords**, Status. The keywords column is the seed for (c).

(c) **Validator check `--check ecosystem-prior-art` (future)**: scan the new proposal's title and first section for keywords matching any registered protocol's prior-art keywords; warn if overlap above a threshold. Cheap to implement once (b) exists.

After D-011, the runtime side of this sequence belongs to the future ForgeOS ownership decision. A future DocKit-only cure should be limited to substrate support, such as a prior-art note in proposal templates or a validator warning if an ecosystem map exists.

### Cross-protocol relationship

This DF complements DF-030: where DF-030 names auditing as a role for *artefacts within a repo*, DF-031 names ecosystem prior-art search as a discipline for *cross-repo scope*. Both are different facets of the same observation: the human arbiter sees things the LLMs don't, because the human carries cross-project memory. ForgeOS' future automation must address both.

### Mitigation in source projects

The old 2026-05-04 Session 4 / Session 5 path is superseded on the LLM-DocKit side by D-011. If ForgeOS needs an ecosystem map, prior-art gate, or runtime convention, implement it there; LLM-DocKit can later consume only substrate-level outputs such as links, registry entries, or validator hooks if a future decision asks for them.

## DF-032 — Cross-LLM deliberation logs are not automatically captured into `llm-council/raw/`

- Source: 2026-05-04 — the very session that surfaced DF-031 (and produced two PROPOSALs + multiple REVIEWS entries + audit cycles) has no automatic mechanism to deposit its log into `~/src/llm-council/raw/`. The deliberation corpus (8500 lines in `raw/` from manual exports done in March 2026) has not received a new session log automatically since. The aspiration in `~/src/llm-council/docs/PROTOCOL_PROPOSAL.md` §3.6 (a session file format under `~/.llm-council/sessions/<session-id>/`) is unimplemented.
- Date observed: 2026-05-04
- Category: gap
- Status: rejected (not LLM-DocKit scope after D-011; retained as lineage input for ForgeOS / `llm-council`)
- Related: DF-018 (auto-memory vs `docs/llm/` drift), DF-030 (auditor role)

### Observation

The deliberation corpus depends on `~/src/llm-council/raw/`. That directory has six logs (~8500 lines) from sessions exported manually by the operator in March 2026. Since then, multiple deliberations have happened (the entire 2026-05-03 / 2026-05-04 work, plus other operator sessions) without depositing new logs. Two consequences:

1. The protocol's empirical base ages — its analysis of "what patterns emerge" is anchored to two-month-old data.
2. New deliberations (this very session is the most recent example) only survive in scattered form: the digest is in REVIEWS, the rationale is in DFs, the implementation is in commits, the conversational flow is in chat scrollback (volatile). No single artefact captures the full session for analysis.

The session that surfaced this DF had to **manually** export a digest to `~/src/llm-council/raw/session-2026-05-04-consensus-self-application/` (done in this session's closing actions). That manual step is exactly the friction the gap names.

### Protocol implication

(a) **A ForgeOS/llm-council export or curation path** — Claude Code transcript + manually-pasted GPT replies + operator arbitration — into a normalised log under `llm-council/raw/session-<id>/`. It could be a ForgeOS workflow, a dedicated `llm-council` tool, or a Claude Code skill that reads the current session's transcript and produces `summary.md` + `sources.yml` + (optionally) raw transcript.

(b) **A ForgeOS workflow convention** once the live runtime exists: "When closing a deliberation run, export or curate the session digest to `~/src/llm-council/raw/session-<id>/` so the corpus grows." This no longer belongs in the generic LLM-DocKit template after D-011.

(c) **A periodic check**: scan `llm-council/raw/` for last-modified date; warn if no new session log in N days while other ecosystem repos show activity that should have produced sessions.

The minimum viable starting point is (a), outside LLM-DocKit. (b) follows naturally once (a) exists. (c) is bonus.

### Cross-protocol relationship

DF-032 sits at the intersection of ForgeOS (which owns live runtime/orchestration) and `llm-council` (which owns the curated archive/corpus). LLM-DocKit may host links or registry entries produced by those systems, but it does not own the export runtime or the generic convention after D-011.

### Mitigation in source projects

The 2026-05-04 session deposits its digest manually at `~/src/llm-council/raw/session-2026-05-04-consensus-self-application/`. That is the proof-of-concept input format and the empirical evidence that the manual step adds friction. Future ForgeOS/llm-council sessions should not need to do this manually.

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

Refinement caught and fixed in 4.7.1 (same session): GPT's audit of the smoke test pointed out that the per-repo extraction degraded silently in `home-infra-protocol` — the originally-failing repo. Its `LLM_START_HERE.md` has a blank line after the "Recommended reading order:" header, so the awk regex exited early and emitted a generic 2-item fallback. The smoke test still passed at the protocol level (Codex began with "Onboarding loaded.") but the agent had been instructed on 2 items instead of the 7 real ones (SPEC.md, PROJECT_CONTEXT.md, ARCHITECTURE.md, COMPLETION_RULE.md, HANDOFF.md, DECISIONS.md, this file). GPT correctly framed this as a near-recurrence of DF-024: documenting closure while the originally-failing instance gets degraded onboarding. Fixed in 4.7.1 by tracking a `started` flag in awk so the blank-line-exit only fires after the first numbered item is captured. Post-fix: home-infra-protocol emits the 7 real items; tomatic emits 9; LLM-DocKit emits 7. Lesson recorded in D-007 follow-ups: cross-LLM audit before declaring closure is exactly the discipline that catches this class of slow-creep drift.

---

## DF-034 — Auto-orientation contract is asserted by docs but tested nowhere

- Source: operator-driven cross-repo audit, 2026-05-06. **Honesty note**: this DF was filed by an operator session that already had context from a multi-day meta cleanup. Re-readers should weight the framing accordingly; the observation is anchored in commit SHAs (verifiable evidence), but the prioritisation and option-naming carry operator-context bias.
- Date observed: 2026-05-06
- Category: process
- Status: implemented (4.8.0; refined in 4.8.1) — option (a) static `check_orientation` shipped in `scripts/dockit-validate-session.sh`. Asserts HANDOFF *Open work* section exists (accepts headings `## Open work`, `## Next concrete step`, `## Next Steps`), names ≥1 in-repo file path (backtick-quoted markdown spans), each named in-repo path exists. Cross-repo absolute paths (`~/`, `/`) excluded from existence check. 4.8.1 refined the path detector to ignore backtick-quoted strings containing glob characters (`*`, `?`, `[`) after the 4.8.0 smoke sweep flagged `*_PROPOSAL.md` as a missing literal path in `home-infra-protocol`. `LLM_START_HERE.md` template item 6 + `scripts/dockit-init-project.sh` HANDOFF stub also updated so newly-scaffolded projects start with the canonical heading and a passing orientation check from their first commit. Option (b) dry-run orientation output and (c) headless LLM smoke test remain `open` for future minors; reserve until empirical data from (a) shows where false negatives bite.
- Related: DF-029 (claim-vs-deployment drift), DF-030 (auditor as fourth role; the meta-discipline this DF generalises), DF-033 (passive onboarding rules → mechanical hook; covers the *trigger* axis, this DF covers the *content* axis), D-007.

### Observation

LLM-DocKit's central promise to downstream projects is that **a fresh session opening a scaffolded repo can ship the next concrete step without bespoke context**. `dockit-validate-session.sh` enforces five checks (`handoff-date`, `history-entry`, `decisions-referenced`, `version-sync`, `external-context`, `external-triggers`); none of them assert *"can a fresh session in this repo orient itself to the open work the repo claims is open"*. The contract is aspirational, not testable.

Empirical evidence from the cross-repo chain 2026-05-02 → 2026-05-06:

- `home-infra-protocol`: every DF closure between 0.1.6 and 0.3.0 shipped with a 50–100 line bespoke session prompt. The prompt encoded operator preferences, file-by-file translations of DF prose, and "do/do-not" rules that already lived in the repo. Each prompt was hand-written from chat context that the repo lacked. See commits `8ecec98` (0.2.2 — DEPLOYMENT_EVIDENCE_PROPOSAL filed), `05b5106` (0.3.0 — same proposal implemented from a long bespoke prompt), and the cleanup chain `5dd8301` (0.3.0 meta cleanup: HANDOFF *Open work* + LLM_WORKFLOW *When Changing Field Semantics* + DOWNSTREAM_FEEDBACK template *Implementation hints*) → `home-infra@0519777` → `home-infra@b5e61f0` (no-prompt commitment) → `home-infra@cfbae96` (factual reconciliation). The 2026-05-06 cleanup is the first commit chain in the ecosystem that treated the bespoke-prompt habit as a bug rather than as a workflow.
- After that cleanup, the Session 6 dispatch prompt (DF-004 closure) dropped from ~100 lines to zero. But none of the additions are testable from outside — they live as prose. The next time a session has context that the repo lacks, the bypass is again the path of least resistance, and the cleanup decays.
- LLM-DocKit itself is the natural home for the cure because the contract belongs to the scaffold, not to any single downstream project. `4.7.0`'s `dockit-bootstrap-context.sh` (DF-033 closure) is the closest existing artefact: it enforces *"read `LLM_START_HERE.md` at session start"* mechanically, but it does not assert that `LLM_START_HERE.md` points at HANDOFF *Open work*, that HANDOFF *Open work* exists, or that *Open work* names files that exist. The bootstrap covers the *trigger* axis of orientation; this DF covers the *content* axis.

The pattern this DF attacks is the same one DF-029 and DF-033 attacked at different layers. DF-029: contract asserts deployment but evidence is uncollected. DF-033: contract asserts session-start onboarding but enforcement was prose. DF-034: contract asserts session-orientation-from-open-work but the assertion is untested.

### Protocol implication

A self-orientation check, layered from cheap-and-static to expensive-and-LLM-bound. Three options, each independently shippable; the recommendation is to ship (a) immediately and reserve (b)/(c) for after at least one downstream adopter has tripped on (a)'s false negatives.

(a) **Static orientation check** (cheap, CI-friendly). New validator function (probably `check_orientation` inside `scripts/dockit-validate-session.sh` or a peer script `scripts/dockit-orientation-check.sh`) that asserts:
  1. `docs/llm/HANDOFF.md` contains a recognisable *Open work* (or operator-configurable equivalent) section near the top of the file.
  2. That section names at least one concrete file path inside the repo.
  3. Each named path actually exists at the named location.
  4. (Optional) Each named path is referenced by name from at least one other context-defining doc (`LLM_START_HERE.md`, `DOWNSTREAM_FEEDBACK.md`, the master roadmap if pointed at).

  Catches: HANDOFF saying "Pending Proposals: (none)" without naming the next concrete step, or naming a path that was renamed/deleted. Misses (false-negative): HANDOFF naming a path that exists but contains stale or wrong content; only (b) or (c) catch that.

(b) **Dry-run orientation output** (medium). New `--orientation` mode for `dockit-validate-session.sh` (or a peer script) that prints the next concrete step and the reading order a session should follow, in the same format as the SessionStart hook payload. The operator runs it before closing the session; if the printed output does not match what an actual session would do, the operator catches the drift without invoking an LLM. Builds on (a): (a) asserts the structure exists, (b) asserts the structure renders to what the operator expects.

(c) **Headless LLM smoke test** (expensive, CI-fragile). Script that spawns a Claude (or any LLM) headless session in the repo with no prompt, asks "what is the next concrete step?", and asserts the response matches what HANDOFF *Open work* says. Catches the failure modes (a) and (b) miss — semantic drift between the prose of *Open work* and the actual content of the named files. Worth designing only after (a) and (b) have stabilised; depends on model versioning, prompt-cache effects, cost per CI run, and LLM-vendor availability.

### Implementation hints (option (a) — provisional)

Files to touch:
  - `scripts/dockit-validate-session.sh`: add `check_orientation` function alongside the existing checks; expose via the `--check orientation` flag pattern already in place.
  - `LLM_START_HERE.md`: extend the *Recommended reading order* (or its surrounding prose) to name HANDOFF *Open work* explicitly as the canonical "what is the next concrete step" section. Without this, downstream projects can declare *Open work* in different idioms and the static check has no fixed target.
  - `dockit-sync-manifest.yml`: nothing new — `dockit-validate-session.sh` is already synced via `copy`. The new check ships transparently to all adopters on next sync pass.
  - `docs/llm/HANDOFF.md` (this repo): ensure the *Open work* block exists at the top so LLM-DocKit eats its own dogfood. The check should pass in this very repo before being released downstream.
  - `dockit-init-project.sh`'s HANDOFF stub: add the *Open work* block to the scaffold so new projects start with it in place.
  - `CHANGELOG.md`: under whatever version ships this (likely a minor — additive validator capability + new template field).
  - `docs/DOWNSTREAM_FEEDBACK.md`: this DF's status → `implemented (X.Y.Z)`.

Version bump: minor per `docs/VERSIONING_RULES.md` (additive validator capability + new optional template field). Use `scripts/bump-version.sh`; do not edit `<!-- doc-version: -->` markers manually.

Cross-repo touches required: read-only smoke pass against at least two downstream adopters that already use the bootstrap hook (`tomatic`, `home-infra-protocol`) to verify the check would pass on their current HANDOFFs. Halt and report drift; do not edit cross-repo from the implementing session.

### Mitigation in source projects

As of 2026-05-06, the `home-infra-protocol` cleanup chain (`5dd8301`) and the `home-infra` reconciliation commits (`0519777` → `b5e61f0` → `cfbae96`) are the manual analogue of (a). They work for one project, by hand. The DocKit-level cure shipped under this DF is the same idea automated and propagated to every downstream adopter via `dockit-sync`.

This DF is **not** a Consensus Protocol artefact. It does not change a contract or alter cross-repo scope; it adds a small enforcement primitive to an existing convention. Capture as DF + ship under a future minor; no `*_PROPOSAL.md` needed (compare to DF-031 which *does* warrant a PROPOSAL — different blast radius).

## DF-035 — Scaffold ships template-residue in entry/optional docs that survives `dockit-init-project.sh`

- Source: pi-fleet (0.1.1, 2026-05-08) — first homelab-profile project scaffolded via `home-infra-protocol/integrations/dockit/new-homelab-project.sh`. **Honesty note**: this DF was filed by an arbiter session in `home-infra` with multi-repo context, after a Codex audit of pi-fleet 0.1.1 surfaced 4 concurrent template-residue findings in one pass. Re-readers should weight that the *aggregation* of the 4 into a single systemic DF carries arbiter bias — the individual findings are anchored in `pi-fleet@a3eaf8d` (verifiable evidence) and were independently cazadas by the Codex audit.
- Date observed: 2026-05-08
- Category: gap, drift
- Status: implemented (4.10.0) — option (a) static `check_template_residue` shipped in 4.8.0; option (b.ii) strip-at-scaffold-time shipped in 4.10.0. `scripts/dockit-init-project.sh` now removes scaffold-author voice from `LLM_START_HERE.md`, rewrites the starter `docs/STRUCTURE.md` opening into project voice, demotes optional `docs/ARCHITECTURE.md` to `docs/ARCHITECTURE.md.example`, and rewrites the new project's version-sync manifest / README links so the example remains available without masquerading as live architecture. The validator smoke suite now executes a real scaffold and asserts no live `docs/ARCHITECTURE.md`, a present `.example`, a synced manifest, and PASS for `orientation` + `template-residue` + `version-sync`. Option (c) mandatory DECISIONS gate remains open for v5 or later.
- Related: DF-033 (SessionStart hook makes residue worse — LLM_START_HERE.md is now the *first* doc every LLM reads, so any scaffold-author voice there is the first thing seen as authoritative), DF-034 (orientation contract checks structure exists and paths are valid; does NOT check that the docs the orientation routes the LLM through are real content vs template — a project can pass DF-034's option (a) check and still poison fresh-session orientation with template residue).

### Observation

Codex audit of pi-fleet 0.1.1 on 2026-05-08 cazó four concurrent template-residue findings, all surviving the scaffold + populate-docs commit chain (`da954f8` initial scaffold → `97c85ee` apply homelab profile → `a3eaf8d` fill 0.1.1 scaffold per brainstorm):

1. **`docs/ARCHITECTURE.md`** ships with `<Names>`, `<Invariant>`, `<Step>`, `<Phase 0>` placeholders in body content (lines 7, 19–20, 31–37, 64–65 of pi-fleet `a3eaf8d`). Marked "(Optional)" in title but README links it as "Technical architecture details" — a fresh LLM treats it as canonical architecture documentation. The optional flag is invisible to the consumer.
2. **`docs/STRUCTURE.md`** ships with the literal sentence *"Use this template to document how the repository is organized"* (line 1) and a generic project tree (lines 7–46) that never gets project-shaped during scaffold or populate. Template-shaped content survives indefinitely.
3. **`LLM_START_HERE.md`** retains scaffold-author voice surfaced in the Mandatory section that DF-033's SessionStart hook routes every LLM to read first: *"Replace angle-bracket placeholders (<...>) with real values and share this file with every LLM agent"* (line 6), *"Replace pi-fleet with the actual project name"* + *"Customization Notes for Maintainers"* (lines 95–99). The first words an LLM reads in any new project carry the author voice of the scaffold's writer talking to a hypothetical adopter, not the project speaking to its own future contributors.
4. **`docs/llm/DECISIONS.md`** ships with the stub *"(No decisions recorded yet. Add the first entry as `## D-001 - <title>` when the first durable choice is made.)"* and stays empty. Real durable decisions accumulate inline in HANDOFF (pi-fleet 0.1.1 had 6: Mosquitto-on-zigbee, TimescaleDB-recorder, data-local-NAS-backup-only, CIFS-for-NAS, HAOS-before-roles, no-install-scripts-in-0.1.x); the migration to DECISIONS.md only happens when an LLM remembers to extract — not by default. The orientation contract DF-034 implements points the next session at HANDOFF *Open work*, but durable rationale is supposed to live in DECISIONS — when DECISIONS is empty the next session reads HANDOFF inline decisions and treats them as operational scratch, not durable fact.

DF-033's enforcement worsens (1)+(3): the SessionStart hook (`scripts/dockit-bootstrap-context.sh`) now mandates LLM_START_HERE.md as the first doc any LLM reads in any DocKit-adopting repo. Any scaffold residue in that file is the FIRST thing an LLM sees and treats as authoritative — exactly the failure mode DF-033 was meant to prevent for orientation routing, recurring on a different axis (content quality of the doc routed to).

The four findings share a single root cause: the scaffold step ships template content as *content*, not as *placeholders to be replaced*. There is no enforcement that template placeholder content has been removed before a project crosses any threshold (first commit after scaffold, first version > 0.1.0, first release tag, etc.). The check passes because the validator only inspects markers, dates, and cross-file pairings — it does not read content.

### Protocol implication

Three options, increasing in mechanical strictness; the recommendation is to ship (a) immediately and (b) in the same minor if scope allows.

(a) **Static template-residue check (cheap, CI-friendly).** New validator function (probably `check_template_residue` inside `scripts/dockit-validate-session.sh`) that regex-sweeps the canonical scaffold-shipped docs for known residue patterns:

  - `LLM_START_HERE.md`: must NOT contain `Replace angle-bracket placeholders`, `Replace pi-fleet with`, `Customization Notes for Maintainers`, or any `<[A-Za-z][^>]*>` outside `<!-- -->` HTML comments and `<...>` placeholder examples explicitly nested inside fenced code blocks.
  - `docs/STRUCTURE.md`: must NOT contain `Use this template to document` or `<PROJECT_ROOT>` (the literal placeholder used in the template tree).
  - `docs/ARCHITECTURE.md` (when present): must NOT contain `<Names>`, `<Invariant`, `<Step>`, `<Phase 0>`, or the literal phrase `Authors: <Names>`.
  - `docs/llm/DECISIONS.md`: a WARN (not ERROR) if no `## D-NNN` heading exists after a configurable threshold (default: 5 commits OR 7 days from `dockit-init-project.sh` run, whichever first). Threshold lives in `dockit-validate-session.sh` constants; tuning is per-project via env override.

  Catches the exact pi-fleet 0.1.1 case. Misses semantic drift (template-shaped content where placeholders were replaced with project names but the structure remained generic) — only (b) or (c) catch that. Acceptable trade-off: covers the recurring 90% case mechanically.

(b) **Scaffold-time strip / removal (medium).** Modify `dockit-init-project.sh` (and homelab profile's `apply-profile.sh` where applicable) to strip scaffold-author voice and template-only content during init. Concretely:

  - Strip the *Customization Notes for Maintainers* section + the *"Replace angle-bracket placeholders"* sentence from `LLM_START_HERE.md` post-init. These are author voice, not project voice.
  - `docs/ARCHITECTURE.md`: revisit whether default scaffold should include this at all. It's marked optional, but mere presence with template content signals "fill me in" without enforcement. Options: (b.i) delete from default scaffold; create on demand via a hypothetical `dockit-add-architecture.sh`; (b.ii) keep but rename to `ARCHITECTURE.md.example` until the project replaces it. Either eliminates (1) above structurally.
  - `docs/STRUCTURE.md`: rewrite opening sentence from *"Use this template to document"* to *"Document the repository structure here. Replace this paragraph and the example tree below with project-specific layout once the tree stabilises."*. Project voice, not author voice. Or: remove the example tree from default scaffold and require the populate step to write one — same pattern as PROJECT_CONTEXT.md.
  - `docs/llm/DECISIONS.md`: stub stays (the file must exist for HANDOFF cross-references); the (a) WARN handles the empty-after-N-commits case.

  Pairs naturally with (a): (b) reduces residue at source for what we know to remove; (a) catches what we missed plus the configurable threshold cases.

(c) **Mandatory DECISIONS.md content gate (expensive, philosophical).** Require `docs/llm/DECISIONS.md` to have ≥1 `## D-NNN` entry before the project crosses 0.x → 1.0 (or before `bump-version.sh` accepts a non-patch bump, configurable). Forces extraction of durable decisions from HANDOFF inline accumulation. Less mechanical than (a)+(b) — the question *"did you actually record the decisions?"* is real and not regex-catchable. Reserve for v5 or after (a)+(b) are stable.

### Implementation hints (option (a))

Files to touch:
  - `scripts/dockit-validate-session.sh`: add `check_template_residue` function alongside existing checks; expose via `--check template-residue` flag pattern. Threshold for DECISIONS.md emptiness as an env-overridable constant (`DOCKIT_DECISIONS_EMPTY_THRESHOLD_COMMITS`, default 5).
  - `scripts/dockit-init-project.sh`: review template files copied during init for known residue patterns; strip per option (b) where the residue is unambiguous author voice (the `Customization Notes` section is the lowest-risk candidate).
  - `LLM_START_HERE.md` template: extend the *Recommended reading order* note with explicit guidance that scaffold-author lines must be removed before first commit. Without this, downstream projects can disagree on what counts as residue and the static check has no fixed target.
  - `docs/STRUCTURE.md` template: rewrite opening per (b).
  - `docs/ARCHITECTURE.md` template: decide (b.i) vs (b.ii) before shipping.
  - `dockit-sync-manifest.yml`: ensure new check function ships to all adopters via `dockit-sync.sh`. The new validator capability is additive, no migration needed in adopters' configs.
  - `CHANGELOG.md`: minor bump (additive validator capability + template edits — no breaking change).
  - `docs/DOWNSTREAM_FEEDBACK.md`: this DF's status → `implemented (X.Y.Z)` when shipped.

Version bump: minor per `docs/VERSIONING_RULES.md` (additive validator + template edits, no breaking change). Use `scripts/bump-version.sh`; do not edit `<!-- doc-version: -->` markers manually.

Cross-repo touches required: read-only sweep of existing downstream adopters (`home-infra-protocol`, `tomatic`, `plaud-mirror`, `infra-portal`, `forgeos`, `pi-fleet`) to see how many would currently fail the new `check_template_residue`. Many likely will (historical residue from earlier scaffold versions). Halt and report drift; do **not** edit cross-repo from the implementing session — file local follow-ups per project so each adopter chooses its own remediation pace.

### Mitigation in source project

pi-fleet 0.1.1 → 0.2.0 cleanup commit (in flight as of 2026-05-08, bundled with the pre-installer-backup runbook) addresses the four symptoms locally: ARCHITECTURE.md deleted, STRUCTURE.md rewritten with the real `roles/`/`shared/`/`legacy/`/`docs/runbooks/` tree, LLM_START_HERE.md stripped of scaffold-author voice, DECISIONS.md populated with 6 D-NNN entries extracted from HANDOFF. That is one project, by hand, after the residue had already shipped to GitHub. The DocKit-level cure shipped under this DF is the same idea automated and propagated to every downstream adopter via `dockit-sync`.

Note on protocol-recognition: this DF aggregates four concurrent findings into one systemic entry because they share a single root cause (template content as content, not placeholder). The aggregation step — recognising that four local findings in a single audit are facets of one upstream gap — is itself missing from the proto-`/consensus` flow today; without an arbiter session with multi-repo context, the four findings would have been fixed in pi-fleet 0.2.0 and the systemic root would not have surfaced. See `forgeos/docs/llm/HANDOFF.md` *Open work* item #8 (cross-LLM protocol gap, upstream-recognition step). That gap is recorded in ForgeOS rather than here because the missing step belongs to the operator-toolbox layer (D-008), not to LLM-DocKit's scaffold layer.

## DF-036 — Codex CLI SessionStart hook installed with `--json` mode designed for Claude Code

- Source: operator homelab (`~/.codex/config.toml`); observed from a `hermes-lab` session on 2026-05-17
- Date observed: 2026-05-17
- Category: usability
- Status: open
- Related: DF-033, DF-037, DF-038

Observation: `~/.codex/config.toml` registers the SessionStart hook with the command:

```toml
command = "sh -lc '... dockit-bootstrap-context.sh --json --project \"$root\"'"
```

`--json` emits Claude Code-specific JSON shaped as `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}`. Codex CLI does not parse this envelope; it appears to inject the raw JSON string into the prompt as text. The script's own docstring (`scripts/dockit-bootstrap-context.sh:23-25`) documents that `--json` is for Claude Code and `--human` is for non-Claude LLMs (Codex CLI, Cursor, web ChatGPT). The configuration is a flag mismatch at install time, not a script bug.

Symptom in the operator's session: Codex prepends "Onboarding loaded." to every reply, instead of only the first substantive reply as DF-033 protocol prescribes. With Claude Code the marker fires exactly once per session, confirming the protocol works there.

Protocol implication:
- Ship a documented operator-facing instruction in LLM-DocKit (`docs/integrations/CODEX.md` or equivalent) stating that the Codex CLI hook must invoke the script with `--human`, never `--json`.
- The docstring of `dockit-bootstrap-context.sh` already says this; promote it from inline comment to a visible integration document so operators editing `~/.codex/config.toml` pick the right flag.
- Long-term resolution lives in DF-038 (a real installer script), but the flag-choice rule must be discoverable independently of the installer.

Mitigation in source project: edit `~/.codex/config.toml` to replace `--json` with `--human`. Trivial, no script changes.

## DF-037 — Codex CLI re-emits onboarding marker on every turn (suspected per-turn SessionStart firing)

- Source: operator homelab Codex CLI; observed from a `hermes-lab` session on 2026-05-17
- Date observed: 2026-05-17
- Category: gap
- Status: open (requires verification after DF-036 mitigation)
- Related: DF-033, DF-036

Observation: Operator reports that Codex CLI prepends "Onboarding loaded." to every reply within a single session, not only to the first substantive reply as the DF-033 protocol specifies. Claude Code, running the same script via its SessionStart hook, only emits the marker once per session. The divergence implicates either Codex CLI hook lifecycle semantics or the way Codex CLI handles the SessionStart output. Hypothesised causes:

1. Codex CLI fires `SessionStart` hooks on every turn rather than once per session (semantic divergence from Claude Code).
2. Codex CLI fires SessionStart once but re-injects the resulting context into every turn's system prompt, causing the LLM to re-evaluate the "first substantive reply" rule each turn.
3. Combined: the LLM's session-level memory of "I already onboarded" is shorter than the persistence of the SessionStart context in the prompt, so the LLM repeatedly applies the protocol.

The `[hooks.state]` section of `~/.codex/config.toml` only tracks `enabled` and `trusted_hash`. No per-session firing tracker exists in the config, so the config alone cannot disambiguate.

Empirical test required: apply the DF-036 mitigation (`--json` → `--human`), open a fresh Codex CLI session, observe whether the marker still appears in turn 2+. If yes, the cause is upstream Codex behaviour, not the flag choice.

Protocol implication:
- If verified that Codex re-fires or re-injects per turn, `dockit-bootstrap-context.sh` should grow a Codex-specific output mode that short-circuits subsequent invocations within a single session via a marker file (e.g., `/tmp/dockit-onboarding-marker-${session_id}` or equivalent). The script already has the structure to support multiple output modes; add `--codex` as a third mode tracking state via filesystem.
- LLM-DocKit should publish a short table of supported LLMs vs hook lifecycle behaviour (Claude Code, Codex CLI, Cursor, etc.) in `docs/integrations/`, so future protocol additions know the cross-LLM contract.
- This DF is gated on DF-036 being applied first — without the `--human` fix, the diagnosis can't isolate whether the per-turn behaviour is the script's JSON output being misparsed every turn or genuinely Codex semantics.

Mitigation in source project: pending DF-036 fix + empirical verification.

## DF-038 — No installer script registers the Codex CLI integration of the DF-033 onboarding hook

- Source: operator homelab; observed from a `hermes-lab` session on 2026-05-17
- Date observed: 2026-05-17
- Category: process
- Status: open
- Related: DF-033, DF-036

Observation: A grep across `~/src/LLM-DocKit/`, `~/src/forgeos/`, `~/src/home-infra/`, `~/src/devenv-bootstrap/` for any script that touches `~/.codex/config.toml` or installs the Codex SessionStart hook returns no matches. The hook stanza in `~/.codex/config.toml` was installed manually or by a script that has since been removed. Consequences:

- Reproducing the hook on a new operator machine requires remembering the TOML stanza by hand.
- Updates to the recommended invocation (e.g., DF-036's `--json` → `--human` migration) cannot be propagated via "re-run the installer".
- ForgeOS `bootstrap-operator.sh` installs the Claude Code SessionStart hook in `~/.claude/settings.json` but does nothing for Codex CLI. The ecosystem coverage of DF-033 across LLMs is therefore asymmetric: Claude Code is provisioned and tracked, Codex CLI is implicit and untracked.

Protocol implication:
- Add `scripts/dockit-install-codex-hook.sh` to LLM-DocKit. Idempotent. Writes the correct TOML stanza (using `--human`) to `~/.codex/config.toml`, with backup of any prior config. Mirror the shape of the existing Claude Code installer in ForgeOS.
- ForgeOS `bootstrap-operator.sh` should call this installer during operator bootstrap, parallel to the Claude Code hook install, so a new machine gets DF-033 coverage across both LLMs in a single `bootstrap-operator.sh` invocation.
- The two installer scripts together (Claude Code via ForgeOS, Codex CLI via LLM-DocKit) constitute the canonical operator-side installation surface for DF-033. Document the division explicitly in LLM-DocKit's README so downstream consumers know where each piece lives.

Mitigation in source project: none yet; operator maintains `~/.codex/config.toml` by hand. After DF-036 mitigation lands, until DF-038 ships the installer, document the manual TOML stanza in `docs/integrations/CODEX.md`.

## DF-039 — Validator forces bookkeeping mini-update on read-only sessions, and the cure becomes the next session's cause

- Source: LLM-DocKit itself (v4.8.0); observed across three `/brief` sessions on 2026-05-08, 2026-05-13, 2026-05-17
- Date observed: 2026-05-17
- Category: usability
- Status: implemented (4.8.1; hardened in 4.8.2) — option (a) shipped in `scripts/dockit-validate-session.sh` plus `.claude/settings.json` Stop hook wiring. `check_handoff_date` and `check_history_entry` early-PASS only when BOTH gates are true: caller opts in via `DOCKIT_ALLOW_READ_ONLY_SKIP=1` and the repo has no staged or unstaged tracked-file diff (`git diff HEAD --quiet` and `git diff --cached --quiet`). Claude Code Stop hook opts in; CI and pre-commit do not. 4.8.2 moves the skip after target-file existence checks so clean malformed repos without HANDOFF/HISTORY still fail, and adds `scripts/test-validator.sh` to make the smoke matrix reproducible. Closes Case B (clean-start read-only session). Case C remains operator commit discipline.
- Related: DF-024, DF-034

Observation: `scripts/dockit-validate-session.sh` enforces `check_handoff_date` (HANDOFF `Last Updated` matches today) and `check_history_entry` (HISTORY has an entry dated today) at Stop. These checks fire regardless of whether the session produced any tracked-file diff. The `/brief` skill is explicitly read-only on the project's docs (see `~/.claude/skills/brief/SKILL.md` *What NOT to do*: "Do not write update-HANDOFF-style bookkeeping just because this skill ran"), but the Stop hook does not know that. Result: a read-only `/brief` session is forced into a bookkeeping mini-update — refresh HANDOFF `Last Updated` to today and append a HISTORY entry that itself documents that this mini-update exists only to satisfy the validator.

The pattern self-perpetuates: the mini-update produces a tracked-file diff in `docs/llm/HANDOFF.md` and `docs/llm/HISTORY.md`. If the operator commits, that commit lands at today's date. If the operator does NOT commit (as happened on 2026-05-13), the diff sits in the working tree dated to the prior session's date. The next read-only session re-triggers the same checks against the stale date and the same mini-update is required again, this time updating the stale dates of the previous mini-update. The 2026-05-13 HISTORY entry explicitly anticipated this: *"A future patch could add a validator escape for sessions with zero tracked-file diffs (...) — candidate input for a future DF if the pattern recurs."* It recurred on 2026-05-17. Three recurrences in 9 days.

This is a specialised case of DF-024 ("documenting drift is not fixing drift") at the validator-design layer: the validator's design assumption is that every session is a writing session, which is contradicted by the operator's explicit use of `/brief`, `/adopt-dockit` dry-runs, and other read-only flows that legitimately produce no diff. The class also matches the empirical pattern that DF-033 names: "passive instructions in repo docs are skipped when the LLM is given a narrow scope" — here the narrow scope is "just brief me" and the bookkeeping rule does not apply, but the validator fires anyway.

### Two distinct cases worth separating before designing the fix

Cross-LLM review of the original DF-039 (commit `ca264eb`, 2026-05-17) flagged that the recurrence has two cases the original write-up conflated:

- **Case B (clean-start read-only session)** — Session opens with a clean worktree. `/brief` produces no diff. Stop hook fires on stale `Last Updated`. Operator is forced into a mini-update. This is the case `git diff HEAD --quiet` correctly identifies, and where the proposed escape applies.

- **Case C (dirty-start session inheriting uncommitted bookkeeping)** — Session opens with a stale diff from a prior session whose bookkeeping was never committed (2026-05-17 was exactly this — the 2026-05-13 mini-update sat in the working tree for 4 days). Stop hook fires on stale `Last Updated`. `git diff HEAD --quiet` is FALSE because the inherited diff exists, so a zero-diff escape would NOT trigger. The original DF-039 write-up implied the escape covered this case; it does not.

The two cases interact: if Case B is solved cleanly (escape fires, no mini-update generated, no diff at session close, no commit needed), Case C never materialises in subsequent sessions. The chain breaks at B. Case C only persists if either (i) the escape is not implemented and the bookkeeping is generated, OR (ii) the escape IS implemented but the operator runs a session that legitimately produces a HANDOFF/HISTORY edit and then exits without committing (covered by the operator-side push policy in `~/.claude/CLAUDE.md` *Push Policy* — commits go up immediately).

Case C therefore does NOT need a separate validator-side fix; it needs commit discipline, which exists as a global rule. Documenting it explicitly in this DF avoids the trap of designing a more invasive fix for a symptom that disappears when the upstream case is closed.

Protocol implication:

- **Option (a) — opt-in zero-diff short-circuit (recommended)**: add an opt-in escape to `check_handoff_date` and `check_history_entry` that early-PASSes when (i) the caller opts in via env var `DOCKIT_ALLOW_READ_ONLY_SKIP=1` AND (ii) `git diff HEAD --quiet` AND `git diff --cached --quiet` both succeed (no staged or unstaged tracked changes). Both conditions required: the env var alone is not enough (a session that legitimately edited code MUST still document it), and the clean worktree alone is not enough (CI on a clean checkout would otherwise silently skip the check on a stale PR). Untracked files (do-not-touch drafts) do not count toward "tracked changes" — they are excluded by `git diff` semantics. The Stop-hook invocation in `.claude/settings.json` opts in by setting the env var inline; CI (`.github/workflows/doc-validation.yml:9`) does NOT opt in, so behaviour on PRs is preserved. Pre-commit (`scripts/pre-commit-hook.sh`) does NOT opt in either, and is safe regardless because at commit time the staged files produce a non-quiet diff.

- **Option (b) — auto-detect interactive mode**: use heuristics like `[ -t 0 ]` (stdin is a TTY) or env-var sniffing (`CI=true`, `GITHUB_ACTIONS=true` ⇒ disable escape; otherwise enable). Rejected vs (a) because env-var coverage across CI platforms varies (GitLab uses `GITLAB_CI`, Jenkins uses `JENKINS_URL`, etc.), and Claude Code's Stop hook does not allocate a TTY. The opt-in flag is explicit and predictable.

- **Option (c) — do nothing, accept the false-positive**: rejected if (a) is judged low-risk. The bookkeeping cost (~5 line diff per session) is small in absolute terms but compounds: each mini-update is a verbose self-referential HISTORY entry, and the entries pollute the project history with bookkeeping noise that the project's own audit-trail tooling (`git log --diff-filter=A docs/llm/HISTORY.md`) does not distinguish from substantive entries.

Recommended: option (a) with both gating conditions (opt-in env var AND clean worktree). The semantic is precise: "the caller has declared this is an interactive session where read-only is legitimate" AND "the session in fact produced no tracked work". Bundles naturally with the `check_orientation` glob-char refinement currently declared in HANDOFF *Open work* (both are validator-side refinements to the same script).

Implementation hints:

- `scripts/dockit-validate-session.sh` `check_handoff_date()`: at function entry,
  ```sh
  if [ "${DOCKIT_ALLOW_READ_ONLY_SKIP:-0}" = "1" ] \
     && git diff HEAD --quiet 2>/dev/null \
     && git diff --cached --quiet 2>/dev/null; then
      add_result "handoff-date" "PASS" "Skipped (DOCKIT_ALLOW_READ_ONLY_SKIP=1, zero-diff session)"
      return
  fi
  ```
  Same insertion in `check_history_entry()`. The wording mirrors the existing `DOCKIT_SKIP_EXTERNAL=1` convention (lines 310, 369) for consistency.
- `.claude/settings.json` Stop hook: change the command to `sh -c 'DOCKIT_ALLOW_READ_ONLY_SKIP=1 ...'` so Claude Code sessions opt in. PostToolUse and PreCompact hooks do NOT opt in (PostToolUse only fires after a Write/Edit, which by definition produces a diff; PreCompact is a reminder, not a check).
- `.github/workflows/doc-validation.yml:9`: leave untouched. CI runs without the env var, so the escape never fires in CI. PRs with stale HANDOFF/HISTORY still fail validation.
- `scripts/pre-commit-hook.sh`: leave untouched. At commit time the staged changes are non-empty, so `git diff --cached --quiet` fails regardless of the env var. Pre-commit behaviour preserved.
- Test cases (automated in `scripts/test-validator.sh` as of 4.8.2):
  1. **Clean worktree + stale HANDOFF + `DOCKIT_ALLOW_READ_ONLY_SKIP=1`** → PASS with skip reason (Case B closed).
  2. **Clean worktree + stale HANDOFF + no env var** → FAIL (CI behaviour preserved on a fresh checkout).
  3. **Modified HANDOFF + stale date + env var set** → FAIL (the session produced tracked work, escape does not fire because diff exists).
  4. **Modified unrelated file (e.g., `scripts/foo.sh`) + stale date + env var set** → FAIL (real work exists, must be documented).
  5. **Only untracked files (do-not-touch drafts) + stale date + env var set** → PASS (`git diff` ignores untracked).
  6. **Staged changes + stale date + env var set** → FAIL (`git diff --cached --quiet` fails).
- CHANGELOG entry under `### Changed`: "Validator: `check_handoff_date` and `check_history_entry` skip on opt-in (`DOCKIT_ALLOW_READ_ONLY_SKIP=1`) zero-diff sessions. Claude Code Stop hook opts in; CI and pre-commit do not. Closes DF-039 Case B; Case C remains operator commit discipline."

Mitigation in source project: none yet. Operator currently absorbs the bookkeeping cost on every read-only `/brief` session. The 2026-05-13 and 2026-05-17 HISTORY entries are themselves evidence of the cost (verbose self-referential entries that exist only to satisfy the validator). Until option (a) ships, the operator-side mitigation for Case C specifically is to always commit + push the mini-update before closing the session (already enforced by `~/.claude/CLAUDE.md` *Push Policy*); the 2026-05-13 case violated that and produced the 2026-05-17 recurrence.

## DF-040 — Multi-LLM executor/auditor sessions need a Trace Protocol

- Source: operator workflow; generalized from MED D-020 (ratified 2026-06-16)
- Date observed: 2026-06-17
- Category: process
- Status: implemented (4.9.0; hardened in 4.9.1) — accepted and shipped in the same session. LLM-DocKit now carries a default-on chat Trace convention through `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh`, plus an opt-in durable validator check (`trace-protocol`) for HANDOFF/HISTORY when `.dockit-config.yml` sets `trace_protocol.enabled: true` and `trace_protocol.since: YYYY-MM-DD`. v4.9.1 fixed a shell precedence bug in commit existence validation and added invalid-hash regression coverage.
- Related: DF-019, DF-024, DF-033, DF-034

Observation: The operator now commonly opens two LLM windows for the same project: one executor and one auditor. After hours or days, it is easy to lose which window is the latest meaningful state, which role the model was playing, which commit was being implemented or audited, whether the report described local state or pushed state, and which validation result was real.

MED ratified this discipline as D-020 on 2026-06-16. The MED implementation proved the core idea but covered only a HANDOFF Trace Anchor; HISTORY entries after D-020 kept the older one-line format. Promoting the practice to LLM-DocKit must therefore cover both the human-visible chat surface and the durable repo log without pretending both can be enforced the same way.

Protocol implication:

- **Chat half (default-on, onboarding-enforced)**: execution reports and audit verdicts begin with a compact `Trace` header: `Role`, `Sent`, `Subject`, `Repo state`, `Validation`, `Next gate`. The message then continues in normal prose. This is not validator-enforceable because chat messages are not repo artifacts, so the cure is SessionStart loading via `scripts/dockit-bootstrap-context.sh`, following D-007.
- **Durable half (config-gated, validator-enforced)**: projects that explicitly set `trace_protocol.enabled: true` and `trace_protocol.since: YYYY-MM-DD` in `.dockit-config.yml` must maintain a `## Trace Anchor` section in `docs/llm/HANDOFF.md`. `docs/llm/HISTORY.md` entries dated on or after `since` that reference backtick-quoted commit hashes must carry an inline `Trace:` footer.
- **Default posture**: chat Trace is default-on because it matches the operator's actual multi-LLM workflow. Projects can disable it with `trace_protocol.enabled: false`. Durable validation does not hard-fail existing adopters merely from `dockit-sync`; it activates only when config says `enabled: true`. New projects scaffolded by `scripts/dockit-init-project.sh` are created with Trace enabled and `since` set to the scaffold date.
- **HISTORY format**: one-line footer, not a multiline block:
  ```text
  Trace: role=executor|auditor; commits=hash1,hash2; state=...; validation=...; next=...
  ```
  The footer uses five fields (`role`, `commits`, `state`, `validation`, `next`). `message_sent` is already represented by the HISTORY entry date; commit times are obtained from git when hashes are present.
- **Hash detection**: only backtick-quoted 7-40 character hex strings count as commit references. This avoids false positives from prose, filenames, or unrelated digest strings.
- **History cutoff**: `trace_protocol.since` is the activation boundary. Entries before it are ignored. If `enabled: true` appears without `since`, the validator may infer the activation date from git history; if it cannot, it fails with an explicit "declare trace_protocol.since" message.
- **Migration posture**: no grace period. If a project activates durable Trace, missing HANDOFF Trace Anchor is a FAIL. Activation is explicit and the migration step is small.
- **Branch handling**: the validator detects `origin/HEAD`, falls back to `main`, and allows `trace_protocol.upstream_branch`. Commits not on the upstream branch but present on another `origin/*` ref produce WARN; commits not present on any remote ref produce FAIL when remote refs exist. Repos without origin refs skip the remote ancestry part.
- **Commit time format**: HANDOFF Trace Anchor commit times may use either `YYYY-MM-DD HH:MM:SS UTC` or `YYYY-MM-DD HH:MM UTC`; the validator accepts both.

Implementation hints:

- `LLM_START_HERE.md`: add a `DOCKIT-TEMPLATE` section named `trace-protocol`. It documents the chat header, states that prose must follow the header, and shows the HISTORY footer.
- `scripts/dockit-bootstrap-context.sh`: read `.dockit-config.yml` enough to honor `trace_protocol.enabled: false`. Otherwise append a compact Trace instruction to the SessionStart additionalContext payload. Do not concatenate full docs; stay under hook size limits.
- `scripts/dockit-validate-session.sh`: add parser helpers for `trace_protocol`, a `check_trace_protocol` function, `--check trace-protocol` support, and a main-loop call. The check must skip when no config exists or enabled is not true; fail on enabled-without-since unless activation date can be inferred; require HANDOFF Trace Anchor; scan only HISTORY entries with date >= since; require footer only when a qualifying entry contains backticked commit hashes.
- `scripts/dockit-init-project.sh`: create `.dockit-config.yml` with `trace_protocol.enabled: true` and `since: <scaffold date>`, add a starter HANDOFF Trace Anchor, and include the HISTORY Trace footer in the stub format.
- `scripts/test-validator.sh`: add smoke cases for no-config skip, valid Trace pass, missing HISTORY footer fail, pre-since skip, missing HANDOFF anchor fail, invalid anchor hash fail, minute-level commit time pass, and enabled-without-since fail.
- `dockit-sync-manifest.yml`: no new strategy required. Existing `copy` entries propagate the validator and bootstrap script; existing `section-merge` propagates the LLM_START_HERE section. `.dockit-config.yml` remains project-owned.

Mitigation in source project: shipped in v4.9.0 and hardened in v4.9.1 after audit caught that invalid HANDOFF Trace Anchor hashes passed silently. Existing downstream projects should run `dockit-sync`, then either use the default chat Trace immediately or explicitly migrate durable enforcement by adding `trace_protocol.enabled: true`, `trace_protocol.since: YYYY-MM-DD`, and a HANDOFF Trace Anchor. No downstream project was edited from this LLM-DocKit session.

## DF-041 — Trace chat header needs Resulting state to distinguish latest message from latest repo state

- Source: LLM-DocKit itself; operator review of parallel executor/auditor windows after v4.9.1
- Date observed: 2026-06-18
- Category: usability
- Status: implemented (4.9.2) — Trace Protocol v1.1 adds `Resulting state` to the chat header in `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh`. Durable HANDOFF Trace Anchor and HISTORY footer remain unchanged.
- Related: DF-040, DF-033, DF-024

Observation: The v4.9.0/v4.9.1 Trace header still left one real orientation ambiguity. The auditor message sent at 2026-06-17 22:34 UTC discussed `d6fc816` / v4.9.0 and requested a v4.9.1 executor patch. The executor message sent at 2026-06-17 22:24 UTC reported `01f90bb` / v4.9.1 pushed. A human returning the next morning sees the auditor message as later by `Sent`, but semantically the executor message leaves the repo in the newer state. `Sent` answers when the message was written; it does not answer whether the message advances HEAD.

Protocol implication:

- Add a required chat-only field: `Resulting state`. The three axes become explicit:
  - `Sent`: when this message was sent.
  - `Subject`: what this message is about.
  - `Resulting state`: what this message leaves true after it is sent.
- Recommended field shape:
  ```text
  Resulting state: HEAD=<hash|unchanged (hash)>; version=<version|none>; gate=<opened|cleared|blocked|superseded|next-slice>; <short note>
  ```
- Examples:
  - Executor patch: `HEAD=01f90bb; version=4.9.1; gate=cleared; supersedes audit of d6fc816`
  - Auditor with no findings: `HEAD=unchanged (01f90bb); version=none; gate=cleared; ready for next slice`
  - Auditor with findings: `HEAD=unchanged (d6fc816); version=none; gate=blocked; requires executor patch v4.9.1`
- Do NOT add `Resulting state` to HANDOFF Trace Anchor. HANDOFF is already the collapsed current state by convention.
- Do NOT change the HISTORY Trace footer. HISTORY's `commits`, `state`, `validation`, and `next` fields already serve the durable one-line equivalent.
- Treat this as LLM-DocKit Trace Protocol v1.1, evolving MED D-020. MED can re-ratify/adopt the new field when convenient; it is not a blocker for DocKit.

Mitigation in source project: shipped in v4.9.2. `LLM_START_HERE.md` section-merge propagates the template wording; `scripts/dockit-bootstrap-context.sh` copy propagation ensures SessionStart hooks emit the new field immediately after downstream sync. No validator change required because chat headers are not repo artifacts.

## DF-042 — Trace Sent timestamp must verify timezone and use one fixed order

- Source: LLM-DocKit itself; operator review of Trace v1.1 auditor/executor messages after v4.9.2
- Date observed: 2026-06-18
- Category: usability / auditability
- Status: implemented (4.9.3) — Trace Protocol v1.2 changes chat `Sent` to local-first dual time, adds verification guidance, and exposes `trace_protocol.local_timezone`.
- Related: DF-040, DF-041, DF-033, DF-024

Observation: Trace v1.1 still allowed a real clock-orientation error. One auditor message wrote `Sent: 2026-06-18 11:02 UTC` while the actual UTC clock in the execution environment was approximately 09:55 and the operator's Madrid clock was approximately 11:55 CEST. The likely failure was Madrid wall-clock time labelled as UTC. That makes a Trace header look precise while giving the operator a false ordering cue between parallel LLM windows.

Protocol implication:

- `Sent` must use one mandatory order:
  ```text
  Sent: YYYY-MM-DD HH:MM <local-tz> (HH:MM UTC)
  ```
- Local time is first because the operator resumes by local wall clock. UTC stays second as the technical audit anchor. Reversing the order is not allowed.
- Agents with shell access must verify time before writing it, for example:
  ```sh
  date -u '+%Y-%m-%d %H:%M UTC'
  TZ=Europe/Madrid date '+%Y-%m-%d %H:%M %Z'
  ```
- Projects can override the local zone with `.dockit-config.yml`:
  ```yaml
  trace_protocol:
    local_timezone: Europe/Madrid
  ```
- Agents without clock access must not fabricate UTC. They should write:
  ```text
  Sent: unverified client time YYYY-MM-DD HH:MM <claimed-tz>
  ```
- Do NOT change HANDOFF Trace Anchor commit-time handling. That timestamp comes from git and remains UTC.
- Do NOT change HISTORY Trace footer. It has no `Sent` field.

Implementation hints:

- `LLM_START_HERE.md`: update the Trace Protocol section with the dual-time `Sent` shape, mandatory order, verification commands, config override, and unverified fallback.
- `scripts/dockit-bootstrap-context.sh`: keep the hook payload compact but include the same local-first/UTC-second rule. Read `trace_protocol.local_timezone` with the existing flat parser; default to `Europe/Madrid` for this operator scaffold. Optional config reads must tolerate missing `.dockit-config.yml` under `set -e`; absence of config must not suppress the SessionStart payload.
- `scripts/dockit-init-project.sh`: include `trace_protocol.local_timezone: Europe/Madrid` in new `.dockit-config.yml` stubs.
- `docs/llm/DECISIONS.md`: add a D-008 v1.2 refinement explaining why this is chat-side only.
- No validator change required; chat headers are not repo artifacts.

Mitigation in source project: shipped in v4.9.3. Downstream projects receive the new chat-side convention through `dockit-sync` section-merge of `LLM_START_HERE.md` and copy propagation of `scripts/dockit-bootstrap-context.sh`; new scaffolds also get the local timezone config by default.

## DF-043 — section-merge cannot propagate newly-added template sections to full adopters

- Source: LLM-DocKit itself; downstream sync attempt after v4.9.3
- Date observed: 2026-06-18
- Category: sync tooling / migration
- Status: implemented (4.9.4) — `scripts/dockit-sync.sh` now inserts fully-missing template sections for `adoption_mode: full` projects.
- Related: DF-040, DF-041, DF-042, DF-024

Observation: Attempting to sync adopters after Trace Protocol v1.2 exposed a structural sync gap. Existing full adopters such as `devenv` and `plaud-mirror` did not have the newly-added `trace-protocol` markers in `LLM_START_HERE.md`, so `dockit-sync.sh --dry-run` failed with `missing markers for section: trace-protocol`. Older adopters such as `nas-backup` could also lack earlier marked sections such as `doc-update-rules`. That meant a new synchronized section could not reach full adopters without manual edits, undermining the purpose of section-merge.

Protocol implication:

- For `adoption_mode: full`, a template section that is completely absent downstream (`START` and `END` markers both missing) should be treated as a new template section to insert, not an error.
- If only one marker is missing, keep failing: that is malformed downstream markup, not a normal new-section migration.
- For `adoption_mode: partial`, keep the previous behavior: missing sections warn and skip, because partial adopters intentionally opt into only the sections they carry.
- Insert new sections before the downstream `footer` template section when present; otherwise append at EOF. Record the new section hash in sync state so future local/template conflicts are tracked normally.

Mitigation in source project: shipped in v4.9.4. Dry-runs that previously failed for `devenv`, `plaud-mirror`, and `nas-backup` now complete with `LLM_START_HERE.md UPDATED sections merged` and zero errors.

## DF-044 — Trace Sent needs seconds and receivers must reverify stale reports

- Source: LLM-DocKit/youtube2text parallel executor/auditor sessions
- Date observed: 2026-06-18/19
- Category: usability / auditability
- Status: implemented (4.9.5) — Trace Protocol v1.3 requires seconds in chat `Sent` and adds stale-read re-verification guidance to `LLM_START_HERE.md` and `scripts/dockit-bootstrap-context.sh`.
- Related: DF-040, DF-041, DF-042, DF-024

Observation: Trace v1.2 still allowed two real ordering failures.

First, minute-level `Sent` precision is insufficient. Two executor/auditor
messages can land in the same minute. If they also discuss the same commit,
gate, or repo state, `YYYY-MM-DD HH:MM` gives the operator no deterministic
ordering cue.

Second, a Trace report can be correct when written but stale when read. During
the `youtube2text` audit, a message reported `HEAD=adb6664` and a large dirty
worktree. By the time the auditor read and verified state, `youtube2text` had
advanced to `47c4083` and the worktree had only one untracked file. `Sent` tells
when a message was written; it does not make the embedded `Repo state`
current at read time.

Protocol implication:

- Chat `Sent` must include seconds on both local and UTC sides:
  ```text
  Sent: YYYY-MM-DD HH:MM:SS <local-tz> (HH:MM:SS UTC)
  ```
- Agents with shell access must verify second-level time before writing:
  ```sh
  date -u '+%Y-%m-%d %H:%M:%S UTC'
  TZ=Europe/Madrid date '+%Y-%m-%d %H:%M:%S %Z'
  ```
- Agents without clock access must not fabricate precision. They should write:
  ```text
  Sent: unverified client time YYYY-MM-DD HH:MM:SS <claimed-tz>
  ```
- Receivers must reverify before acting on stale reports. If a Trace block is
  older than a few minutes, or if another LLM/operator may have acted since it
  was written, run `git status`, `git log -1`, and current time checks before
  treating its `Repo state` as current.
- No durable validator change is appropriate. Chat messages are not repo
  artifacts; the enforceable half remains HANDOFF/HISTORY Trace validation.

Mitigation in source project: shipped in v4.9.5. Downstream projects receive
the updated chat-side convention through `dockit-sync` section-merge of
`LLM_START_HERE.md` and copy propagation of `scripts/dockit-bootstrap-context.sh`.

## DF-045 — Local version/HISTORY guardrails should not stay forked downstream

- Source: `youtube2text` D-019
- Date observed: 2026-06-19
- Category: sync tooling / validator configurability
- Status: implemented (4.9.6) — upstreamed additive JSON/YAML/package-lock
  version marker handlers and configurable HISTORY format validation.
- Related: DF-024, DF-039, DF-040

Observation: `youtube2text` carried local edits to DocKit scripts because
`dockit-sync` clobbered them twice:

- `scripts/check-version-sync.sh` and `scripts/bump-version.sh` had local marker
  support for JSON/YAML/package-lock manifests.
- `scripts/dockit-validate-session.sh` had local no-dash/newest-first HISTORY
  enforcement.

Those are not really product-specific concerns. They are scaffold guardrails
that other projects can need too. But promoting the exact `youtube2text` rule
would break part of the fleet: some adopters use dash HISTORY entries
(`plaud-mirror`, `msgvault-lab`, `forumvault-lab`), while others use no-dash
entries (`cortex`, `youtube2text`).

Protocol implication:

- HISTORY validation must be configurable, not hardcoded to one punctuation
  style. Default should be fleet-safe (`any`), with strict `dash` or `no-dash`
  available through `.dockit-config.yml`.
- HISTORY parsing should detect only real dated entries:
  `YYYY-MM-DD - ...` and `- YYYY-MM-DD - ...`. Literal template/example
  `YYYY-MM-DD` lines are not entries.
- New version marker types must be supported symmetrically by check and bump.
  A manifest marker that check cannot understand is not validation; it must
  fail instead of warning/skipping.
- `package-lock-version` must inspect both top-level `version` and
  `packages[""].version`, because npm lockfiles carry both.

Mitigation in source project: shipped in v4.9.6. `history-entry` defaults to
`history_format: any` and supports strict `dash` / `no-dash` through
`.dockit-config.yml`. Durable Trace HISTORY scanning now handles both dated
entry shapes. `json-version`, `yaml-info-version`, and
`package-lock-version` are implemented in both version scripts with regression
coverage in `scripts/test-validator.sh`; unknown marker types now fail.

Downstream status note: this reduces local fork pressure for `youtube2text`
D-019, but does not close D-019. Close it only after a later `youtube2text`
session re-syncs from LLM-DocKit, verifies behavior against the real manifest
and HISTORY style, and removes or explicitly supersedes its local forked script
behavior.

## DF-046 — Wall-clock bookkeeping makes clean committed repos go red every day

- Source: `med` rollover after `3b98425` (`chore: adopt LLM-DocKit 4.9.4 sync`)
- Date observed: 2026-06-19
- Category: validator / process ergonomics
- Status: implemented (4.10.1)
- Related: DF-024, DF-039, DF-040

Observation: MED was clean and content-valid after `a42f8ec` / `3b98425`, but
on 2026-06-19 `dockit-validate-session.sh` went red because `handoff-date` and
`history-entry` compared `HANDOFF.md` / `HISTORY.md` against the wall-clock
date rather than the last committed work date. The result was pure rollover
hygiene pressure: each new calendar day with no content change required another
HANDOFF/HISTORY edit just to make the hook green.

This is distinct from DF-039's read-only-session skip. DF-039 lets a zero-diff
Stop hook opt out with `DOCKIT_ALLOW_READ_ONLY_SKIP=1`; it does not solve CI,
manual validation, clean clones, or sessions where the hook is run without that
environment flag. The bug is the reference date itself: clean committed repos
should be judged against the date of the commit being validated, not against
"today".

Protocol implication:

- When the tracked tree is clean, `handoff-date` and `history-entry` should use
  the `HEAD` commit date as the expected date.
- When tracked files are dirty or staged, the expected date should remain the
  wall-clock date. A write session still needs current HANDOFF/HISTORY
  bookkeeping.
- Untracked scratch files should not force a rollover requirement; they are not
  part of the committed state being validated.

Mitigation in source project: shipped in v4.10.1. The validator now derives a
reference date from `HEAD` for clean tracked trees and falls back to `TODAY`
when tracked files are dirty. `scripts/test-validator.sh` includes regression
coverage for a clean repo with an old commit date passing without rollover
edits, and for the same repo failing once a tracked file is dirtied.
