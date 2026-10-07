# Idea continuity

Owner: LLM-DocKit. Operator-authorized implementation on 2026-10-07.
Each project owns its content; ForgeOS owns conversation capture and projections.

## Everyday use

At session start and before brainstorming, read `docs/llm/IDEA_INDEX.json`, the
relevant registered decisions and retained work. Search with
`python3 scripts/dockit-ideas.py --grep "topic" --project .`. Read the linked
original sources before interpreting a result. The index is a recall aid, not
a ranked backlog or an authorization engine. HANDOFF and ROADMAP retain priority.

During the session, preserve each material operator request, agent suggestion,
constraint and unresolved question. Reuse an existing identity when it already
represents the same idea, retaining all origins; never silently merge meanings.
If it is already in a D/ADR/UP register, reference that authority. Only untracked
requests/suggestions need native entries. An accepted suggestion is not a grant
to deploy, spend, publish private sources or bypass a required review.

Before closing, compare the conversation's material ideas with the index and
owner registers. Explain additions, changes and any intentionally omitted
non-material discussion. Reconcile displaced work when priorities change.
Newly closed task records require a `task_reconciliations` entry containing the
related idea IDs or a substantive `no_ideas_reason`. A closed documentation task
does not implement its recorded idea. The agent and independent reviewer must
inspect semantic coverage; mechanical PASS cannot discover unrecorded thoughts.

## One authority per idea

`docs/llm/IDEA_INDEX.json` schema 1 contains `project`, `validator_sha256`, `registers`, `batches`,
`entries` and `task_reconciliations`. The validator is the executable shape
contract. It rejects unknown top-level/entry fields, including priority.

Native entries are `operator_request` or `agent_suggestion`, with identity,
title, owner, origin (date, attribution and source references), batch and recall
trigger. States: `captured`, `proposed`, `accepted`, `in_progress`, `deferred`,
`rejected`, `superseded`, `transferred`, `implemented`. Acceptance/progress,
rejection and implementation require authority and rationale. Deferral retains
a concrete recall trigger. Transfer/supersession retains a resolvable successor.
Implementation needs pinned implementation evidence and separately stated
acceptance: `verified`, `pending`, or `not_applicable` with a reason. Merely
documenting a product idea is not implementation. Documentation-only deliveries
belong in task/decision records, not fabricated product implementation evidence.

Reference entries can also identify `accepted_decision`, but cannot carry a
state: the linked register remains authoritative. Registers declare a relative
file and a regex with one identity capture group; amendment headings sharing an
ID are not duplicate decisions. The existing ForgeOS UP lifecycle is preserved.
Idea records never become Home Infra Protocol operational obligations by default.
When promoting an idea into an existing authoritative register, preserve its
native identity with a superseded/transferred disposition and link the successor.
Adoption pins the exact helper hash; update it only with reviewed source adoption.

References are objects with `path`, optional `contains` (an exact source anchor),
optional `revision` (a Git commit), and optional `project`. Paths stay inside the
owner checkout. Cross-project references need an explicit private `--projects`
mapping to be verified; unresolved owners produce warnings, not a verified link.
Private conversation content stays outside Git and Dossier disclosure scope.
Use a source-controlled, attributed summary to retain its useful project intent.

## Coverage and baseline

Each immutable batch names its actual sources/date, exclusions, unknown sources,
remaining historical work and next cursor. `coverage_claim` is always
`declared_corpus_only`. Add a new batch when coverage advances; do not rewrite
past observations. Listing files/commits is not semantic review of their content.
Initial adoption covers the declared audit batch, not months of every chat.

Run `python3 scripts/dockit-ideas.py --project . --baseline REV` before publication.
Use the reviewed start commit, or the PR merge base, and a full Git history.
The local default compares against HEAD for dirty trees and HEAD's first parent for
clean just-committed trees. An invalid explicit baseline fails; unavailable
automatic history warns and cannot count as completed continuity verification.
Inferred baselines also return an explicit warning; publication requires the
explicit reviewed start revision, especially for sessions spanning many commits.
This is a change/closeout guard, not a trusted append-only archive or a guarantee
against an earlier deletion already accepted as baseline.

The guard rejects disappearing entries, origins, batches, task records, register declarations
or registered IDs; deleting the whole index is also failure when adoption is
present in the baseline or HEAD. A terminal-state change needs a reopen reason.
Register relocation uses `moved_to` while retaining the original path/pattern;
every old identity must survive at the new location. Stable identity is never
reused for a different idea. Source-control review must
also examine textual changes under preserved IDs and evidence/authority meaning.

Exit codes: 0 valid/not adopted; 1 invalid; 3 explicit verification warning.
The session validator invokes this check when an index exists now or in recent
history. Missing Python/helper in an adopting project fails. Projects without
adoption remain explicit skips; no automatic broad fleet adoption is implied.

## Delivery and recovery

Publishing rules, installing clients, capturing sessions, sharing a Dossier and
verifying restoration are separate observations. ForgeOS strict review capture
must preserve exact parent/session/round provenance and actual model metadata.
Hook success must not hide capture errors. Check recoverable copies explicitly;
unknown coverage and physical independence remain visible. Preserve originals.

For meaningful state changes use the existing Dossier assessment, curation,
review, publication and actual reader readback. Its approved source allowlist is
not a whole-project search index. No new source disclosure/admission is implied.
Existing product work remains in its recorded state and order.

Reference targets and their anchors are checked in the current owner tree as well as any historical pin; origin references retain immutable provenance. A missing live authority fails until the owner reference is explicitly reconciled. CI fails closed if a force-push makes its event baseline unavailable; recover the reviewed baseline rather than silently choosing a new one.
