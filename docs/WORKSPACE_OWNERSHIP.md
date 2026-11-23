# Portable parent-owned work records

DocKit owns `scripts/dockit-workspace.py` and the `workspace-ownership` onboarding
section. ForgeOS consumes the same validator through an installed content pin.
Devenv admission and Home Infra host policy have separate ownership.

Each `docs/llm/work/ID.json` has exactly: schema (integer 1), id, project, purpose,
state, branch, artifacts, next_step. IDs are bounded portable keys. States are
active, paused, pending-integration, retained, closed. Artifacts contain only
repository-relative POSIX paths; no host absolute paths, traversal or credentials.
The file stem must equal id; records in a checkout have one project owner.
Host worktree paths, process observations and migration custody live outside Git.

`python3 scripts/dockit-workspace.py --project .` is read-only and works in both
primary and linked Git checkouts. The session validator checks work records when
the directory exists. Bootstrap context points agents to the parent's work index.
Existing Stop/session gates therefore inherit record checks where those gates
are installed. This does not claim coverage for clients with no enabled hooks.

The sync manifest includes the validator. The existing dockit-sync linked-worktree
limitation is separate; this rollout copies the exact canonical helper and marked
section into reviewed consumer checkouts and verifies hashes instead of weakening
Git checks or claiming that sync state changed.

Run `python3 scripts/test-work-records.py` and `scripts/test-validator.sh`.
The schema records custody/disposition; a closed record alone is not approval to
delete files. Missing records are surfaced by ForgeOS adoption/status.

## Workspaces clean up behind themselves (2026-11-23)

Authority: Carlos, 2026-11-23 (Home Infra agent resource lifecycle). Agents work
on the default branch in the primary checkout. A task workspace exists only while
another session or its uncommitted state occupies that checkout, and its creating
session retires it at closeout: publish, record the closed disposition, then
`task-workspace retire`. ForgeOS performs the custody checks (clean, published,
unlocked, unused, regenerable ignored caches only) and keeps a ledger receipt.
Merged branches left without a checkout go through `task-workspace retire-branches`.

The `workspace-leftovers` validator check (`scripts/dockit-leftovers.py`) is
read-only and offline. It fails only when the host ForgeOS ledger shows a closed
workspace created under this rule that is still not retired. Git-only evidence (a
linked worktree, local or origin branch already contained in the fetched origin
default branch and not checked out) warns, because Git cannot distinguish a
fresh active workspace from a forgotten one. Legacy closed records warn until
their owner retires them. A session running inside its own closed task checkout
cannot remove it; it warns and the checkout is retired from the primary after
the session ends. Without a ledger the check reports Git candidates only.

Export requires a clean adopted/created output checkout containing the exact pinned DocKit helper, before creating any record or index. This prevents incomplete contract adoption from breaking session gates. Fixture tests use native Git within isolated temporary roots and remain runnable with the managed PATH guard installed.
