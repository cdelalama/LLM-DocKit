# Selective fleet rollout - 2026-09-23

## Scope and status

Operator authorized updating all registered projects. This report initially records
reviewed source candidates; the publication ledger below is filled after remote
readback. A prepared candidate is not a published update.

The final 4.16.3 CI-only adjustment validates the exact authored PR candidate
instead of a synthetic merge timestamp. Portable adopter bytes are unchanged
from the reviewed 4.16.2 packet.

Release: LLM-DocKit 4.16.3, based on 4.16.1 revision 361b393. The patch corrects
two sync tests that attempted to alter removed Fable wording instead of creating
a real conflict. Fixtures now insert a model-independent local constraint.
The portable delivery behavior is unchanged from 4.16.0.

All 38 registered primary repositories are accounted for. This is selective
distribution of delivery helpers, the session validator, DELIVERY_CONTRACT, and
the delivery-evidence/independent-review-policy sections. Full-template identities
are preserved. Local hooks, settings, version scripts, excluded sections and tests
are preserved; copying helpers does not integrate deployment entrypoints.

## Validation and review

- Central source: 84 delivery tests and 96 validator regressions pass after repair.
- Every adopter receives byte-identical portable delivery code, verified by hashes.
- Project version/session outputs, local regression results and exact candidate
  identities are retained in /tmp/dockit-fleet-20260923 and the final ledger.
- Independent auditor: exact claude-opus-5-5, high effort; effective model
  verified from modelUsage. First review required concrete fixes; final verdict
  is recorded in docs/llm/REVIEWS.md. Executor outputs are not independent runs.

## Compatibility and preserved authority

Plaud retains its three project-specific checks, with explicit skip accounting
and nonzero subprocess handling under set -e. Its local regression suite covers
these boundaries. QNAP retains its transactional versioning and all local hooks.
PiHA keeps component versions and uses a read-only component-header checker
(tool version 1.0.0); no shared project VERSION is invented. House Thermal Monitor
receives the missing bump helper and executable permission on its strict checker.
Historical missing/incorrect Trace times are corrected from Git, without changing
old verdicts. MED's duplicate identical managed policy is consolidated. Carlos's
2026-09-23 operator-wide instruction supersedes the inherited model preference in
MED D-045 and Riego D-021; other review/authority requirements remain.

Dirty primary worktrees are never edited, reset, stashed or advanced underneath local work.
Their updated source is available on the published branch or an isolated local
side branch; the owner integrates it with pending work.
Remote publication uses plain fast-forward pushes only. Repositories without a
remote receive isolated local side branches; claude-quest is never pushed to its
third-party upstream. The old ForgeOS convergence branch receives a retained integration patch artifact;
its active worktree is untouched and publication waits for its existing guard.
ForgeOS main is the separate published adoption surface.

## Riego

Riego's source update is 1.0.15; no runtime deployment is included. Its historical
1.0.13 local pilot and append-only journal remain intact. Bound version inputs
changed: the next guarded begin needs fresh review, integration and prerequisites.
No journal events are appended and no init/restore side effects are published.

The documented outstanding user outcome is still external gardener access:
gardener-compatible identity/assurance, final connector listener isolation and
image-specific TLS proof, followed by bounded deployment and off-LAN/mobile
acceptance. Second-WAN and off-host custody evidence remain separately explicit.
These are document-backed pending gates, not a fresh runtime diagnosis.

## Publication ledger

| Project | Candidate version | Publication method | Result |
|---|---|---|---|
| PentAGI-Lab | 0.2.2 | fast-forward-remote | pending final review |
| PiHA-Deployer | component-versioned | fast-forward-remote | pending final review |
| audio-batch | 0.1.3 | fast-forward-remote | pending final review |
| buzz-lab | 0.3.3 | fast-forward-remote | pending final review |
| cambio-claro | 0.2.1 | local-side-branch | pending final review |
| carlos-brand | 0.1.3 | fast-forward-remote | pending final review |
| claude-quest | 1.0.2 | local-only-third-party | pending final review |
| cortex | 0.4.4 | fast-forward-remote | pending final review |
| devenv | 0.14.6 | fast-forward-remote | pending final review |
| devenv-android | 0.2.6 | fast-forward-remote | pending final review |
| devenv-bootstrap | 0.1.3 | fast-forward-remote | pending final review |
| devenv-entry | 0.4.5 | fast-forward-remote | pending final review |
| devenv-spawner | 0.1.4 | fast-forward-remote | pending final review |
| forgeos | 0.25.7 | fast-forward-remote | pending final review |
| forgeos-convergence | 0.25.0 | deferred-integration | pending final review |
| forumlens | 0.1.44 | fast-forward-remote | pending final review |
| forumvault-lab | 0.16.4 | fast-forward-remote | pending final review |
| hermes-lab | 0.13.1 | fast-forward-remote | pending final review |
| home-infra | 0.42.1 | fast-forward-remote | pending final review |
| home-infra-protocol | 0.13.9 | fast-forward-remote | pending final review |
| house-thermal-monitor | 0.5.4 | fast-forward-remote | pending final review |
| infra-portal | 0.29.1 | fast-forward-remote | pending final review |
| irrigation-portal | 1.0.14 | fast-forward-remote | pending final review |
| juiced | 0.1.3 | local-side-branch | pending final review |
| llm-council | 0.1.4 | fast-forward-remote | pending final review |
| med | 1.10.1 | fast-forward-remote | pending final review |
| msgvault-lab | 0.25.4 | fast-forward-remote | pending final review |
| msgvault-panel | 0.15.8 | fast-forward-remote | pending final review |
| nas-backup | 1.5.3 | fast-forward-remote | pending final review |
| pi-fleet | 0.4.16 | fast-forward-remote | pending final review |
| plaud-mirror | 0.16.4 | fast-forward-remote | pending final review |
| qnap-magnet-builder | 0.4.4 | fast-forward-remote | pending final review |
| tomatic | 0.1.9 | fast-forward-remote | pending final review |
| travel-ledger | 0.9.15 | fast-forward-remote | pending final review |
| unifi-mcp | 0.4.3 | fast-forward-remote | pending final review |
| vaultwarden-deploy | 0.3.5 | fast-forward-remote | pending final review |
| x-signal | 0.1.3 | fast-forward-remote | pending final review |
| youtube2text | 0.40.3 | fast-forward-remote | pending final review |
