# Publication is part of task completion

Authority: Carlos, 2026-11-26. Do not leave finished source work uncommitted or
unpublished. This is the portable closeout rule; each owner retains its remote,
branch, review, signing, disclosure and authorization policy.

1. Inspect the checkout and identify task-owned versus concurrent work before
   editing. Preserve another session's work. Existing authorization to publish
   completed work does not authorize publishing secrets or unreviewed changes.
2. Complete implementation, required documentation, appropriate tests and the
   independent review. Stage explicit task paths and commit. Immediately publish
   through the owner's ordinary workflow; no force push or bypass of safeguards.
3. On a refused push, fetch, reconcile without losing history, revalidate and
   retry. A local commit is not delivery. A published task branch is recoverable
   progress, but completion also requires integration into the default branch
   under the owner's checks. Owner policy decides whether incomplete safe work
   can be published on a task branch; never weaken default-branch checks.
4. After publication run once:

   ```sh
   python3 scripts/dockit-publication.py --project . --require-published
   ```

   It requires a clean checkout (including untracked files and submodule state)
   whose HEAD equals the live default branch advertised by origin. It performs
   no fetch, commit, push, deletion, persistent receipt or recurring poll. An
   unavailable remote is unverified, not success. A concurrent source change
   means repeat the check after reconciliation. This is a point-in-time proof,
   not a lock against future writers or a detector of every task on every host.
   Multiple or differing origin fetch/push destinations require an owner-qualified
   route and fail as unverified. The remote proof covers this repository only;
   publish/verify submodule commits in their owning repositories separately.
   Git receives no interactive stdin; timed-out Git subprocesses are retired as
   an owned process family. Native Windows timeout acceptance remains separate.
5. Close and publish task records, retire disposable workspaces through the
   host owner's guarded tool and verify absence. A known retained item needs
   owner, reason, next action and review date. Preserve evidence and backups.
6. Report the commit, remote publication, checks, remaining blocker, and what
   was created, removed and retained. If closure is genuinely blocked, leave a
   precise handoff and safe durable work; do not label it done.

The session validator runs an **offline advisory** `publication-state` check.
It must allow dirty work before commit, and cannot require a push from a
pre-commit hook: that would make completion impossible. The explicit live
post-push command is the final publication gate. CI validates source; it cannot
inspect a developer's uncommitted checkout. Neither checker grants publication
authority, uploads arbitrary directories or silently commits somebody's work.

DocKit owns this contract/checker and its distribution. ForgeOS owns task
assignment, custody and retirement; its retirement preflight independently
requires the closed owner record and candidate history to be published. The
project owns actual source review, publishing and acceptance. Installing a rule
does not prove every client or existing session adopted it.
