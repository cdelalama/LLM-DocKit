# Template owner-state repair

House Docs exposed a defect in initializer 4.20.1: committed DocKit idea and
workspace records were copied into the new child while its decision log was
reset. The child therefore appeared to own DocKit ideas and failed the ordinary
identity guard when its truthful index was written.

New projects now receive an empty idea index with their own identity, a current
validator pin, and an empty work index. Existing/adopted projects are not reset.
The initializer accepts Git worktrees as source using Git's own repository check.

The validator contains a finite reviewed migration registry for the observed
House Docs root only. There is no CLI/environment switch or identity pattern.
The root scaffold commit is 2f4ba1c91cc2ac0dd49682089bdf0916b6988138;
ForgeOS admission followed at e20ba680d65790e07f0844df1eb064be4f623902.
These are separate facts, correcting the advisory packet's conflation. The
reviewed pre-repair baseline is the admission commit. The repair must be its
immediate child, with one root, an independently pinned creation contract
(retrofit false), and unchanged imported files from root through admission.

A fixed docs/llm/TEMPLATE_IMPORT_REPAIR.json receipt records the exact source
revision, independent review digest and archive map. The previous index, work
index and 13 foreign task records are retained byte for byte under the exact
archive prefix. Only those 13 live foreign task files may be removed. Real child register IDs present at admission remain protected. HISTORY.md prose
is not checked by this helper; ordinary source review preserves its append-only
meaning. The archive and receipt
remain immutable and verified at every later check. The transition commit is
derived from Git history, avoiding a self-referential commit hash in its own
receipt. Multiple transitions fail. After migration the normal anti-deletion
checks compare with the first child-owned index, and report that boundary.

Pre-commit checks accept the working-tree candidate at the exact registered
admission; committed validation checks the actual immutable transition. This is
a source review guard, not an adversarial authorization boundary. A new affected
repository requires a separate reviewed registry addition; none is inferred.

Exact Opus 5.5/high advisory R06 accepted a narrow, audited repair, with native
capture digest 556e13909d3d6a6c9da1864451dbadc6be8c1b01a43eb9c0f595c895ac865f44.
Independent source review remains required. The root/admission correction and
finite registry are explicitly included in that review packet.

Earlier DocKit product work, shared Dossier hold and recovery obligations remain.
This correction is necessary to finish the authorized House Docs installation;
it does not authorize repairing any other project or changing fleet runtimes.

The finite registry entry must remain in future helper versions: removing it
fails closed for the repaired child. The 13 imported task filenames are reserved
and cannot later be reused as child tasks. Reports include requested and effective
baselines. The executor verified all 15 imported blobs against the exact template
revision before publishing. Source-owner prefixes before the generic start guide,
review history and this repair narrative are removed from future births. This
is a bounded cleanup, not proof that every optional template file is neutral.

Follow-up suggestions remain deferred in the idea index: inventory affected
children without repairing them, and inspect remaining optional source-owner
residue before a broader template cleanup. Neither starts a fleet migration.
