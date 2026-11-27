# LLM-DocKit Dossier adoption

Status (2026-11-27): local L14 capture/export and five-section reader readback
verified. Shared NAS/Portal publication is paused/unavailable; permanent local
reader reachability is unproven. Historical deployment receipts below do not
establish current availability. Physical independent backup placement remains open.
Owner: this repository. User direction: use ForgeOS Dossier for DocKit's own
project tracking, 2026-09-25. This is not a fleet opt-in.


## Operator-facing language (2026-09-30 clarification)

Carlos requires Spanish for every human-readable Dossier field, including
headings, full decision reasons, milestone/acceptance text and source summaries.
English engineering documentation does not determine the reader language.
Follow the complete field-level checklist in ForgeOS docs/modules/dossier/OFFLINE_CONTRACT.md.
Preserve IDs, statuses, technical literals and exact pinned source bytes. Check
all visible fields and the real reader; schema checks do not prove language or
semantic equivalence. Publish corrections as new dated revisions; retain earlier
English revisions as original historical evidence. No schema or engine change.

## Contract and identity

The root `.forgeos/dossier.json` is the only project declaration. Stable identity:
`llm-dockit`, explicitly present in Home Infra's typed `docs/PROJECTS.yml` registry.
The local registry projection verifies identity only; old source-version entries
in the registry do not override this repository's VERSION or current Git state.

Shared implementation: ForgeOS tool 1.1.0 at published reviewed commit
4fedd81759fd57b4d336672068051e633af3b070, SHA-256
fd34d3f45a9382fbf8317a932edd1fa827230d0acccaba68c0b87963c1704a95.
That exact offline engine is now also contained in published ForgeOS main
045b2ebc9d1e12abac276e99d4cd6b0a72f98038; its bytes/pin remain unchanged. Read its
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
not read, moved or rewritten. The initial bind found no prior DocKit history at that declared custody;
existing L1/L2 are now preserved. No legacy migration was performed. This is not a search
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
that exact export against the local chain. Include the last local revision and the separately verified shared reader in
Trace. The reserved local URL remains unavailable. Shared publication has an
independent receipt; local captures never advance it automatically. No new
session hook or automatic capture/publication is installed.

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

## Shared technical delivery - 2026-09-25

Live reader: https://infra.lamanoriega.com/dossier/shared/llm-dockit.
Open Portal's Dossiers entry, then Abrir dossier. LAN/WireGuard access without
user authentication is limited to reviewed technical llm-dockit content.
The reader shows current/history, Roadmap, reports, decisions and source evidence.

Exact deployment, review, native-origin and restore evidence:
DOSSIER_SHARED_DELIVERY_2026-09-25.json. ForgeOS source 045b2ebc9d1e12abac276e99d4cd6b0a72f98038
provides separate scripts/dossier_remote.py and dossier_shared.py; offline 1.1.0
is unchanged. Portal 0.32.2 source c70007fb840044599d597d5ba97d6f2c60fb8d85 serves
the strict read DTO. Existing Portal data and ten mounts remain preserved.

Private NAS custody is /share/ZFS18_DATA/homes/cdelalama/forgeos-dossier, outside
Git, with private ACLs and separate fixed reader/writer SSH identities. The
writer's host binding is in the current user's private Dossier ssh directory.
The project declaration contains no credentials or executable remote destination.
Use the trusted shared client's explicit submit/publish/read/backup commands;
review content for sharing and retain exact UUIDs on retries. No auto-merge or
silent reset of local/shared current pointers is permitted.

L1 and L2 were admitted as native candidates and published separately as S1/S2.
Their original content/observation times are identical; server publication dates
are 2026-09-25T22:30:02Z and 2026-09-25T22:30:52Z. Exact retries retain addresses.
S1: shared:058c04cb094dc7a26d6ccfe0d6f356106b5c7900e4c2f68523743299326521ef.
S2: shared:ab93baac535b5b8459875719e8c61e89d43a52f8a12301769d39deafe4f1fcc0.

49 source tests, 19 tests on final NAS custody, six real Docker process kills,
transport denials, 33 actual browser checks and isolated S1/S2 restore passed.
Process-death tests are not power-loss proof. Physical independent backup is
pending the operator's Pi/encrypted-cloud destination choice: dev-vm and NAS2
share hardware. No recurring backup schedule, off-LAN/phone/golden acceptance,
native Windows parity or full ForgeOS D0/D2/D4 closure is claimed.

## Current shared revision receipt

The reviewed current-state capture is local:d8c725bad2d5ca7c729cd4afb1e32f62f8f45d46e0884aee9b8901950e42eb03 (L3),
anchored to DocKit 1831e82cb6482842e6519a9a8a64a92982ef50e0. It explicitly separates
delivered technical publication/reader/same-NAS restore from the blocked physical
backup milestone. Opus approved the exact corrected unauthenticated-access
wording and recovery split before capture/publication.

S3: shared:f731e1766c4ab7a6d03e3f97dcecea374b25e7e103199ab71c10616112d952c2,
published 2026-09-25T22:46:38Z; original observation 2026-09-25T22:41:59Z.
Current reader: https://infra.lamanoriega.com/dossier/shared/llm-dockit.
S1/S2 remain exact historical links; an already-open S2 tab announced S3 without
changing its selection. All three revisions restored in isolated NAS custody.

The trusted shared client on this host is
/home/cdelalama/src/.worktrees/forgeos-dossier-shared/scripts/dossier_remote.py.
Its explicit private binding is
/home/cdelalama/.local/state/forgeos/dossier/ssh/llm-dockit-binding.json.
Use that reviewed implementation for manual status/read/submit/publish/backup;
the original sibling Dossier worktree is preserved and may lack the remote CLI.
No shell path from a project declaration is executed. Receipt-only commits after
L3 can report source drift without requiring a new capture of identical state.

## House initializer repair capture — 2026-10-19

Exact Opus5.5/high R26 conditional CURATION_GO corrections applied: headline
limits verification to House Docs and states earlier projects were not audited
or modified. Native L8 is local:9d7ecb59e6c5fd591370cf58b32acced0d028dd7c1eb579d3339e68a1f6c4595.
Source is published a010033; full previous content and owner holds retained.
Current shared backup succeeds at229662bytes; this does not replace the prior
shared-publisher recovery acceptance. No shared publication or independent
backup acceptance is claimed. Native reader verification is task-private.

## 2026-11-26 - Local L12 source/workspace closeout

Captured revision `local:b01f3d2661f08d7fb729923da3b46e3b73f9ea612f063bbba019de7a627f1299`
with pinned offline1.1.0; observed22:28:25Z and captured22:29:07Z. Twelve exported
records retain all eleven predecessors exactly. Current source references pin
11e94e0bc093c7edaf995b06ab6e1ec4bdf325dd; historical pins remain intact.
Check/capture/export/trace and the five real local reader sections passed.
The permanent localhost4319 link and shared publication remain unavailable; the
local reader evidence is file-based, with no server/container or NAS invocation.
The engine's aggregate source freshness remains conservative for mixed revisions.
See ORCA_PUBLICATION_CLOSEOUT_2026-11-26.md for review, custody and cleanup evidence.
This receipt does not request another capture or extend sharing/runtime acceptance.


## L13 local closeout (2026-11-27 local date)

Source4.23.1 published at850aeda49cc9fa00643969511bc96cc96f5138a2;
exact Opus5.5/high R2 SOURCE_GO/CURATION_GO captured with manifest
`bd9bb430b8fd2aa45a0418ec25a0730d0f0794e7928dd8e6c73e512b4ee432f5`. Only approved publication/hash substitutions
were applied to the reviewed curation. Observed2026-11-26T23:43:53Z;
captured2026-11-26T23:44:18Z. Revision `local:6c99af3dedf5b5292f0b18e0a4b3568731c88c41460f8ec92fd197eb01cbea13`.
Export SHA-256 `00255c997d1bd118f9f9e1d20d076a9607b317ffb288585e337f20d098a37108`.

All12 prior records and17 historical sources preserved exactly;13 records,
16 milestones,9 decisions,20 sources now. Three new allowlisted sources pin850aeda.
The actual local export passed all five published Portal reader sections with
81 visible assertions, zero external requests and root/agent visual inspection.
Temporary build/reader/profile artifacts were removed; private receipts,
review evidence and screenshots remain under the DocKit custody review2026-12-04.
The aggregate historical-source freshness warning remains; it does not describe
uncommitted current pins. Permanent local4319 and shared Portal remain
unavailable/unproven. No server, container, NAS operation or fleet adoption.
This receipt adds no substantive curation and does not recursively capture.


## L14 visual comparison closeout (2026-11-27)

Carlos rejected the first three Neon appearances; L14 replaces that active
choice set with the published second round while preserving all prior records.
Source64cc5a621c7d9e0748c9521b84239f405c8a4516, exact Opus5.5/high source/curation
GO; final capture manifest `d4c4a1a0a865888078f98448b64c0719b721f4683863b0fbec74a2a1f16f8b96`.
Observed2026-11-27T00:25:48Z, captured2026-11-27T00:26:06Z.
Revision `local:042af7e9e66436cc7df37ada98da680612be5e2a2df38a8f3f085cd6143417c1`; export SHA-256 `e1290ba2bc884fedc596d083cc3c58e56bca4bee8684795842947d257f9db3bb`.

All13 prior revisions and20 historical sources are exact;14 revisions,16
milestones,9 decisions,21 sources. The single new HANDOFF pin and its hash were
checked against published Git bytes. Five actual local reader views passed84
visible assertions with no external requests; root/agent inspected Ahora.
Disposable fixture/profile/browser/script were removed. Retained private
review/design evidence and screenshots: DocKit custody review2026-12-04.
No production-layout selection, version change, NAS/shared publication or
permanent-reader acceptance. This receipt does not trigger recursive capture.
