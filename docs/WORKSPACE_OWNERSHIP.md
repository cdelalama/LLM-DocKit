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
The schema records custody/disposition, not approval to delete files. Missing
records are surfaced by ForgeOS adoption/status; the validator cannot enumerate
host worktrees from portable documentation alone.

Export requires a clean adopted/created output checkout containing the exact pinned DocKit helper, before creating any record or index. This prevents incomplete contract adoption from breaking session gates. Fixture tests use native Git within isolated temporary roots and remain runnable with the managed PATH guard installed.
