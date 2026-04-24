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
- `implemented` — a check, template change, or doc has landed that addresses it
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
- Status: open | accepted | implemented | rejected | superseded-by: DF-NNN
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
- Status: open

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
- Status: open

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
- Status: open

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

---

## Meta-observation

A pattern running through the entries: DocKit currently enforces
**structural** discipline (markers, dates, manifest membership, paired file
sync) excellently, and **semantic** discipline not at all. Every
implemented check is about the shape of the artifact; every open entry above
is about the content inside the artifact. The next generation of DocKit work
(see `docs/HOOKS_ENFORCEMENT_PROPOSAL.md`, `docs/LLM_DOCKIT_CE_V2_PROPOSAL.md`)
can use this log to decide which semantic checks are worth their
false-positive cost.
