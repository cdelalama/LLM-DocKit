# Independent-Review Policy Fleet Rollout - 2026-09-12

## Outcome

The operator-authorized fleet rollout is complete for every primary repository
classified as an existing DocKit adopter under `/home/cdelalama/src`.

- Source policy: LLM-DocKit 4.14.1 at
  `1301ffc55b078693c790167e0ecae9f642dc67f1`.
- Scope: immediate child repositories with a real `.git/` directory. Linked
  worktrees are not separate adopters and third-party repositories are not
  enrolled merely because they exist under the same source root.
- Inventory: 49 primary Git repositories, 38 registered downstream adopters,
  and 11 repositories outside downstream registration.
- Registration: all 38 adopters now carry `.dockit-enabled`; 15 established
  adopters that lacked the marker were registered during this rollout.
- Policy result: 37 active primary worktrees report the selected
  `LLM_START_HERE.md:independent-review-policy` section as current. MED's
  protected dirty primary worktree does not contain that section or its marker
  pair; its separate authoritative `origin/main` policy commit is published and
  verified below.
- Publication: 35 adopter revisions are published on their intended remote
  branches, one overlay is committed locally against a third-party upstream,
  and two protected dirty repositories with no remote retain local additive
  changes only.
- Template identity: this was a selective policy rollout. It did not assert
  that any adopter received the complete 4.14.1 template. Existing
  `template_version` and `template_ref` values were preserved. Newly discovered
  pre-existing adopters with unprovable full-template provenance use
  `pre-registration` / `untracked-existing-adoption` rather than a fabricated
  version. PiHA-Deployer retained its evidenced 4.9.5 / `723afb4` identity.

The delivered rule prefers exact `claude-fable-5-1` at high effort. Exact
`claude-opus-5[1m]` at high effort is permitted only after direct Fable quota
exhaustion evidence. Sonnet, Haiku, aliases, unrecorded substitutes and
self-review cannot clear an independent-review gate.

## Published Adopter Revisions

Every commit below contains both `.dockit-enabled` and the delivered review
policy. The recorded commit is contained by the named remote branch; a later
branch head does not invalidate that ancestry evidence.

| Adopter | Version after rollout | Published branch | Policy commit |
|---|---:|---|---|
| `audio-batch` | 0.1.2 | `origin/main` | `f9f04cde4da1740e4be45748e18b86b1933db32b` |
| `cortex` | 0.4.3 | `origin/main` | `ff8195d9849c144a953de533f3612b928fbb284c` |
| `devenv-bootstrap` | 0.1.2 | `origin/main` | `f44ea10944ff9cd488fdd2547e35f5fa1d7baa67` |
| `devenv-spawner` | 0.1.3 | `origin/main` | `0ee66f367446b32dc18c60374c46f19b35ff8fbd` |
| `forgeos-convergence` | 0.25.0 (no bump) | `origin/codex/converge-2026-08-09` | `fd96d7f3cdd305dc4090699e2e0bc5366f5c74ef` |
| `forumvault-lab` | 0.16.3 | `origin/main` | `d9354cffbad4363f3e1f99b643a9c33d5954d0f4` |
| `hermes-lab` | 0.11.2 | `origin/main` | `5af1d534116a9c7c8d880dee645749aa57710041` |
| `home-infra-protocol` | 0.13.8 | `origin/main` | `9d79f84b471d2532c72b5ccc3473bde1cd42e1ab` |
| `home-infra` | 0.34.11 | `origin/main` | `331b3c879649e08973d648e64107eafee1646214` |
| `infra-portal` | 0.28.1 | `origin/main` | `24d0f69e33e57c444ca4d2dcd9ad625671a6cf6d` |
| `llm-council` | 0.1.3 | `origin/main` | `8b005c214546852da29c774a9b8554bf3aa007bb` |
| `msgvault-panel` | 0.15.7 | `origin/main` | `6a69f2ead2403d1818ab1dbc7d74d3fd2819da0a` |
| `pi-fleet` | 0.4.15 | `origin/main` | `55704bc768d7e7af3b2e9f3f5fbad1a53b86e17f` |
| `plaud-mirror` | 0.15.1 | `origin/main` | `57f1f9b107382750e71f183a02b602aca1a0c6d8` |
| `vaultwarden-deploy` | 0.3.4 | `origin/main` | `40ee536facdc03dd56e8bede265f87d720e77310` |
| `youtube2text` | 0.40.2 | `origin/main` | `1b1a06e1162ed05c12d738ce532a8fc0c5cb0564` |
| `msgvault-lab` | 0.25.3 | `origin/main` | `51dd915a1421b0d64938e9ec119fc4cf74da6256` |
| `nas-backup` | 1.4.4 | `origin/main` | `9976880719b04ce592699c8217fa3619071701dc` |
| `PentAGI-Lab` | 0.2.1 | `origin/master` | `4ef64c0381cf02554fcdf0607984c4fca8d66f49` |
| `buzz-lab` | 0.3.2 | `origin/main` | `fa3a2a80613b6a24d7c4478f879235721539732e` |
| `carlos-brand` | 0.1.2 | `origin/main` | `7f1cfb12092daf82065dd9043c5b236c87e1f9fa` |
| `devenv-android` | 0.2.5 | `origin/main` | `f4ae5c1535cf0b0b075a04e409bba20f741c1a87` |
| `forumlens` | 0.1.43 | `origin/main` | `871ba83751684048456181a04fee5020d79b1067` |
| `house-thermal-monitor` | 0.5.3 (no bump) | `origin/main` | `3a574740d35d344eb2da09a9dbfe6cccab9d7ec7` |
| `qnap-magnet-builder` | 0.4.3 | `origin/main` | `685fd96dbfde26ba83c38aa2187650af41b991c6` |
| `tomatic` | 0.1.8 | `origin/main` | `7ee382f33dfd9ed23ed60587fa4a5be1e2ddce5c` |
| `travel-ledger` | 0.9.14 | `origin/main` | `4a8d9f20882f33e3b903834ba884fd29bcc1ebd4` |
| `unifi-mcp` | 0.4.2 | `origin/main` | `e252686a9942e8305d0d6d99093dfe9dc1ade97b` |
| `x-signal` | 0.1.2 | `origin/main` | `68a3cea44eee60f29b2bed22468ae00e90d8c00d` |
| `med` | 0.27.1 | `origin/main` | `e09de34336c475b9bb2f745009b6178bec54dd96` |
| `devenv` | 0.14.5 | `origin/master` | `2a7713951a8572fb2abbcb33c08549a5b3407b7b` |
| `forgeos` | 0.25.3 | `origin/main` | `29079acb3b90ec00c6288424c877d32f9e73ba88` |
| `devenv-entry` | 0.4.4 | `origin/master` | `c7fc63b3a7daf9603846bd749d2ca41bee408411` |
| `irrigation-portal` | 0.9.0 | `origin/main` | `9d5fa625d78cd0c974adf5b93fe3d839fb7a04f5` |
| `PiHA-Deployer` | component-versioned; no script bump | `origin/main` | `a95972d489c4f290266f95909e507aae2c864f92` |

`home-infra` advanced after its policy commit; that commit remains an ancestor
of the observed later `origin/main`. `forgeos-convergence` is published only on
the named unmerged feature branch, not on `origin/main`. It retained 0.25.0
because its parallel-branch rules defer final version assignment to integration.
`house-thermal-monitor` retained 0.5.3 because its local versioning rules do not
require a version bump for planning/documentation-only updates.

The four protected primary worktrees for `med`, `devenv`, `forgeos`, and
`devenv-entry` were not reset, stashed, checked out, merged, or cleaned. Clean
dedicated worktrees produced the published revisions. The primary `devenv`,
`forgeos`, and `devenv-entry` worktrees also contain additive uncommitted policy
edits among pre-existing work; MED's primary worktree was not locally edited
with the selected policy.

## New Registrations

The following 15 repositories already carried material DocKit structure or
prior DocKit state but lacked the discovery marker. They now carry
`.dockit-enabled`:

`PentAGI-Lab`, `PiHA-Deployer`, `buzz-lab`, `cambio-claro`, `carlos-brand`,
`claude-quest`, `devenv-android`, `forumlens`, `house-thermal-monitor`,
`irrigation-portal`, `qnap-magnet-builder`, `tomatic`, `travel-ledger`,
`unifi-mcp`, and `x-signal`.

Irrigation Portal was therefore not missing DocKit documents; it was missing
the explicit fleet-discovery marker. Version 0.9.0 publishes that marker and
the policy together in the commit recorded above.

## Preserved Exceptions

| Adopter | Durable result | Reason publication was not attempted |
|---|---|---|
| `claude-quest` | Local commit `e99a7038d008dad35148a2dc9d65bf9dd321f43d`, version 1.0.1 | `origin` is the third-party `Michaelliv/claude-quest` repository. The local governance overlay must not be pushed to an upstream the operator does not own. |
| `cambio-claro` | Marker, exact policy and honest selective state are present in its protected dirty worktree | No remote exists and 33 pre-existing worktree paths are active. The rollout stayed additive and did not bundle unrelated work into a synthetic release. |
| `juiced` | Exact policy and existing marker/state are present in its protected dirty worktree | No remote exists and 18 pre-existing worktree paths are active. The rollout did not reset, stash, clean or publish unrelated work. |

The first `travel-ledger` receipt incorrectly classified its 9/10 result as a
timezone false positive. A fresh rerun proved that Travel Ledger already used
the correct UTC conversion and failed only because its HISTORY Trace footer did
not include referenced commit `a075b47`. Travel Ledger 0.9.14 corrects that
footer and passes version 17/17 plus DocKit 10/10. Separately, LLM-DocKit's
central validator did contain the UTC-formatting defect; v4.15.0 fixes it and
adds an offset-commit regression under DF-057.

## Repositories Not Registered

The 11 remaining primary Git directories are not downstream fleet members:

- `LLM-DocKit` is the template/control source, not its own downstream adopter.
- `Plaud_BulkDownloader`, `TradingAgents`, `compound-engineering-plugin`,
  `gstack`, `kenn-msgvault`, `openclaw`, `pentagi`, and `tg-archive` do not
  carry the canonical DocKit document set used for evidence-based enrollment.
- `camofox-browser` and `titus` retain stale `.git/.dockit` state but no longer
  carry the canonical DocKit documents. Runtime state alone is not authority to
  recreate or enroll project documentation.

No repository in this group was edited.

## Verification and Boundaries

- A post-rollout selective dry-run exited zero and enumerated all 38 registered
  primary adopters: 37 selected sections were already current and MED's active
  checkout lacked the selected section and its marker pair. PiHA-Deployer does not
  carry `scripts/check-version-sync.sh`, so the sync tool reported that
  pre/post version validation was unavailable; its exact four-file diff,
  unchanged component scripts, marker, policy, state preservation, clean commit
  and remote containment were verified directly.
- Every one of the 35 published policy commits resolves locally, is contained
  by its recorded remote branch, and contains both the marker and policy.
- The three non-published exceptions retain marker/policy evidence locally and
  are explained above rather than reported as published.
- Shell executable modes were preserved. No reset, stash, merge, destructive
  cleanup, runtime, deployment, secret, network, NAS, Home Assistant, controller
  or Home Infra acceptance mutation was performed by the rollout.

This report records selected-policy fleet convergence. Some recorded adopter
commits also carry independently authorized project changes, most notably the
Irrigation Portal 0.9.0 feature release; those identities are recorded rather
than relabelled as policy-only. Full DocKit upgrades, project-specific validator
remediation, runtime acceptance and deployment remain separate per-project
gates.
