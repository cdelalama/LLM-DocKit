# Leave no residue

Authority: Carlos, 2026-11-26; D-034. Applies to every adopted project and every
kind of task: runtime, files, backups, documentation and records. This is the
general principle. Two narrower contracts apply it and stay authoritative for
their subject: `docs/RUNTIME_LIFECYCLE.md` (disposable runtime, D-033) and the
`workspace-ownership` section of `LLM_START_HERE.md` (task workspaces; detailed
in LLM-DocKit's `docs/WORKSPACE_OWNERSHIP.md`).

Review status: this is revision 2. An independent review (Codex, gpt-6.2-astra)
rejected revision 1: it told agents to expire copies, remove versions older than
N-1 and reduce evidence to a summary, which can destroy a rollback or the
original that proves an incident, and it contradicted its own "remove only what
this task created". Revision 2 limits removal to the task's own disposable
things and puts custody, backup, rollback and history above the rule. The
review record of this text and its checker is in LLM-DocKit's
`docs/llm/REVIEWS.md`.

## Origin

A week-long NAS storage incident in November 2026 (owner record: Home Infra's
incident journal) combined resource accumulation with repeated creation and
destruction that spent filesystem metadata even when containers used `--rm`.
The owner inventory included: 740 test and
qualification containers; 1,126 image IDs (about 70 old versions each of two
applications); 11 unused volumes; 29 copies of a 342 MB database, one taken
"before" each release; 18 GB of restore rehearsals and qualification folders; a
7.9 GB rolling archive of derivable transport files; and one reader that created
and destroyed a container for every read, about 16,000 a day. Carlos ordered a
rule high in the hierarchy: any task or action that generates garbage cleans it
up, because it had also happened in documentation, in records and elsewhere.
That list is what accumulated, not a list of what an agent may now delete.

## The rule

**A task is not done while something it created only in order to do the work
still exists.**

1. Residue is what a task makes on the way and nobody will use afterwards: test
   and qualification containers, images built or pulled for a test, scratch and
   staging folders, temporary files, restore rehearsals, the task's own copies
   taken before a change, task branches and worktrees, superseded drafts, raw
   logs and transport archives.
2. Know what removes a disposable thing before creating it. Prefer forms that
   remove themselves (`--rm`, a temporary directory the command deletes, a
   stream instead of a file).
3. Nothing that runs repeatedly may create and destroy a resource per request,
   poll or read (a container, a clone, a snapshot, a file). Use a long-lived
   process, a native tool or a cache.
4. Remove only what this task created and is authorized to remove, and verify
   that it is gone. A copy the task took before a change goes when the change is
   verified, unless the project's rollback or retention rule keeps it.
5. Anything kept is written down: what, why, who owns it and until when.
6. Custody, backup, rollback and history obligations prevail over this rule.
   Never delete or shrink evidence, backups, data volumes, other sessions' work,
   user data or objects of unknown origin in order to tidy up: report them. An
   unreferenced volume may hold data.
7. Closeout states what the task created, what it removed and what it kept under
   point 5. "Created nothing disposable" is a valid statement.

## What counts as residue

Always the task's own things, in every kind of work:

| Where | Examples |
|-------|----------|
| Runtime | test and qualification containers, images built or pulled for a test, helper containers, clones and snapshots the task started |
| Files | scratch and staging folders, temporary files, `*.bak` / `*.orig` / `*.before-*` copies the task made, its task branches and worktrees |
| Backups | the task's own copy taken before a change, once the change is verified and no rollback or retention rule keeps it; restore rehearsals |
| Documentation | superseded drafts, duplicates and "v2" / "final" siblings the task produced on the way to the published text |
| Records | raw logs and transport archives the task generated as working material; duplicate entries it wrote for one event |

Not residue: the deliverable (including immutable HTML delivered into a chat);
evidence, backups and history under a custody,
rollback or retention obligation; append-only history the project requires
(HISTORY, DECISIONS, CHANGELOG, named archives); required receipts; anything
kept under point 5.

## Closeout statement

One line in the session's closeout record (the HISTORY entry or final report):

    Residue: created <what>; removed <what>; kept <what, why, owner, until when>.
    Residue: created nothing disposable.

## Not part of the general rule

Removing superseded image versions from a host after a verified deployment. It
deletes things earlier tasks created, so it belongs to each host's deploy
procedure, with stated preconditions: the registry holds the version, no
container in any state uses it, removal is ordinary and not forced, and the
previous version stays for rollback. For the home NAS that procedure is owned by
Home Infra. The same holds for any clean-up of what earlier work left behind:
age, a clean Git status, a merged branch or a closed task never prove ownership,
and installing this rule authorizes none of it. The owner orders that work.

## Mechanical side and its limits

Prose does not enforce itself. What exists:

- `workspace-leftovers` (`scripts/dockit-leftovers.py`, synced; read-only and
  offline; run by `scripts/dockit-validate-session.sh`). FAIL: a closed task
  workspace created under the new rule in the host ledger that is not retired.
  Legacy closed records and merged worktree/branch candidates remain WARN. WARN, never FAIL: files in the checkout, tracked or untracked and
  not git-ignored, named `*.bak`, `*.orig`, `*.rej`, `*.tmp`, `*~`, `*.swp`,
  `*.before`, `*.before-*` or `*.incomplete-*`, with a count and the first five.
  A name does not say who made the file: check origin and authorization first,
  remove only what the task created, report the rest. A file kept on purpose is
  allow-listed by exact path, with its reason, in the project's
  `.dockit-config.yml`:

      residue_allow:
        - fixtures/legacy.orig   # parser input fixture; owner: project

- `runtime-lifecycle` (`scripts/dockit-runtime.py`): declared per-run receipts;
  `--strict` at runtime closeout. It does not contact hosts.
- Counting residue on hosts, alerting and refusing new disposable creation over
  a limit belong to the host owner (Home Infra). DocKit neither provides nor
  verifies them.

Limits: the file check matches names in one checkout and nothing else; ignored
files, directories and other hosts are invisible to it. No check reads
documentation or records for duplicates. A PASS means the patterns matched
nothing, not that the task left nothing. Every other point depends on the author
and the independent reviewer. A warning does not block closeout.

## Rollout

Source: LLM-DocKit 4.23.0. A downstream project receives the `leave-no-residue`
section, this document and the updated checker on its next `dockit-sync`. A full
adopter gets the section directly under its `## Critical Rules (Non-Negotiable)`
heading when that placement is unambiguous (the heading occurs once, after a
blank line, with no code fence, literal-text HTML, open comment or managed
section in doubt before it), otherwise before the footer with a warning that
names the reason. If that fallback point is inside an unclosed code fence, HTML
comment or literal element, the sync fails without retaining source changes;
the owner must repair the context. A file that already has
its own unmarked `### Leave no residue` section is not changed: the sync reports
an error until the owner merges, removes or excludes it. A partial adopter
without the markers is skipped with a warning. Nothing here claims that any
other project already carries the rule.

## Sync rollback custody

`dockit-sync --apply` uses a unique backup directory for each invocation, even
within the same second. A run that changes nothing removes its own empty backup
scaffold. A run with rollback material retains it and reports its exact path;
the adopter owns review at acceptance of that sync. Older backups are preserved
unchanged, including failed-attempt evidence. The former automatic five-backup
rotation is removed: a count or age is not a custody decision. Retire retained
material only through the adopter's authorized rollback and retention policy.
