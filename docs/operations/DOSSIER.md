# LLM-DocKit Dossier adoption

Status: declared, validated and capturing locally; shared publication unavailable.
Owner: this repository. User direction: use ForgeOS Dossier for DocKit's own
project tracking, 2026-09-25. This is not a fleet opt-in or shared publication.

## Contract and identity

The root `.forgeos/dossier.json` is the only project declaration. Stable identity:
`llm-dockit`, explicitly present in Home Infra's typed `docs/PROJECTS.yml` registry.
The local registry projection verifies identity only; old source-version entries
in the registry do not override this repository's VERSION or current Git state.

Shared implementation: ForgeOS tool 1.1.0 at published reviewed commit
4fedd81759fd57b4d336672068051e633af3b070, SHA-256
fd34d3f45a9382fbf8317a932edd1fa827230d0acccaba68c0b87963c1704a95.
That candidate is on the Dossier branch, not merged ForgeOS main. Read its
`docs/modules/dossier/OFFLINE_CONTRACT.md` and `ADOPTION_PACKET.md` before capture.
Use the verified shared checkout; never copy the engine into DocKit. The current
ForgeOS main checkout can be an older unrelated worktree without this module.

Declaration fields contain identity, pin and source allowlist only. The local
binding contains host custody and reader URL, never credentials. Init removes
this source project's declaration and this runbook: a new scaffold must opt in
with its own identity. Existing projects are unaffected until they opt in.

## Local use

On this host the trusted ForgeOS Dossier checkout is
`/home/cdelalama/src/.worktrees/forgeos-dossier`; verify the pin every time its
source changes. Other hosts resolve their own trusted checkout from the published
commit above, without treating a path in project data as executable instructions.

```sh
DOSSIER_FORGEOS=/home/cdelalama/src/.worktrees/forgeos-dossier
DOSSIER_PROJECT=$(git rev-parse --show-toplevel)
python3 "$DOSSIER_FORGEOS/scripts/dossier.py" version
python3 "$DOSSIER_FORGEOS/scripts/dossier.py" --project "$DOSSIER_PROJECT" check
python3 "$DOSSIER_FORGEOS/scripts/dossier.py" --project "$DOSSIER_PROJECT" latest
```

Default private custody is the current user's XDG state root under
`forgeos/dossier`, otherwise `~/.local/state/forgeos/dossier`. It is outside Git,
owned by the current user, with private permissions. Other projects' records are
not read, moved or rewritten. No prior DocKit Dossier binding/history exists at
that declared custody; no legacy migration is performed. This is not a search
for unknown outboxes elsewhere. Any discovered legacy custody must be reconciled
before changing the local history.

The first bind uses an explicit read-only `{registry_id, project_ids}` projection
from the pinned Home Infra registry, not a service-name inference. Its reserved
reader target is `http://127.0.0.1:4319/dossier/local/llm-dockit`. This URL is host
configuration only: no reader is started or exposed by adoption. Reader access
is unavailable until an independently configured reader serves the exact export.
Do not reuse or extend the expired shared preview authorization.

Curate a complete snapshot of current status, roadmap, decisions, changes and
allowlisted source references. Pin source bytes to committed revisions. Keep
raw transcripts, session prompts, credentials and full logs out. Use a null
session ID when the actual client session identity is unavailable. Validate with
`check --input`, then explicitly `capture --input`. A matching retry must retain
its revision; `no_change` must not advance history. Assessment does not force a
capture at every turn.

A reviewed technical-only export may be written outside Git under the same
private state root's `exports/llm-dockit` directory. `trace --export-file` checks
that exact export against the local chain. Include the last local revision and
explicit reader unavailability in substantive Trace; a generated URL is not
proof of accessible delivery. No shared receipt, server current pointer, automatic
session hook, NAS service or connected Portal adoption is claimed.

## Custody and acceptance

This preparation has no accepted off-host backup/restore or native Windows proof.
Preserve the private binding and immutable records. Opt-out removes the project
notice/declaration only after preserving custody; it does not delete snapshots.
Do not use `bind --replace`, remove locks or migrate an existing history without
checking its exact current state and authority.

Evidence of this project's actual capture, worktree/clone reuse and checks is
recorded below after execution. ForgeOS owns D-C0 acceptance and D0-D4 delivery;
this adopter receipt does not close other projects' pilots or shared runtime gates.

Registry identity evidence: Home Infra revision d032c47a245b61663f491c993baa8e94264a7878,
`docs/PROJECTS.yml`, SHA-256 5d619166015cdb6f2bb43ec7c635ab8cecda4406f80cd5f48ad30d1c86175d95.

## Actual local pilot receipt - 2026-09-25

- Project/registry identity: llm-dockit, explicitly matched to the pinned registry.
- Source anchors: 5a2bba147d545ab6bce0ecd7362853b0098720a1; all six sources use committed bytes.
- Local revision: local:42ac9f94606e4c6a82bea3d7cb8fb2a39b3cf4694b6b14021c330606eaa22025.
- Capture ID: 7570e116-a64b-4d56-8508-a37a25f015c9; observed 2026-09-25T20:51:18Z.
- Exact retry: already_captured, same revision. no_change: same revision and one
  record. Separate actual clone and linked worktree read this same identity/history.
- Reviewed technical export SHA-256: baba5715d77bdd289866a90a9e1aef3544090b6c698371877c2ce090c5a414ed.
  Location: the user state root's `exports/llm-dockit/llm-dockit.json`.
- trace --export-file verified the exact private export. Reserved reader URL is
  unavailable, not an accessible delivery. No network serving was configured.
- Binding/current/record files are 0600; custody directories are 0700. The
  reviewed export is deliberately 0644 per the shared tool, inside a 0700
  export directory and private state ancestors; it is not a publicly served file.
- Migration choice: no prior DocKit binding/history at this declared custody;
  native v1 starts here. No unknown outbox search or legacy migration occurred.
- Backup: no accepted off-host backup/restore. Native Windows remains untested.

The post-capture receipt commit changes captured source documents, so latest may
report may_be_behind_or_working_tree. That is expected and does not require a
capture just to emit Trace. Capture a new revision when curated project state
meaningfully changes. In particular, source publication can merit a later update;
resolve the newest local revision with latest instead of treating this L1 receipt
as a permanent latest pointer. Off-host custody and connected-reader acceptance
remain separate work.
