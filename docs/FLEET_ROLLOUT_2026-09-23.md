# Selective fleet rollout - 2026-09-23

## Scope and status

Operator-authorized selective rollout completed: 34 owned remotes published and
read back, three local-only updates retained in Git, and one old convergence
checkout deferred as a private integration patch. The source published first
through [PR #4](https://github.com/cdelalama/LLM-DocKit/pull/4). No runtime was deployed.

29 clean primary checkouts advanced; eight dirty primary checkouts were preserved
without file, index or HEAD changes. Their updates are on branch
`dockit-fleet-4.16.3-20260923`; the published remote also carries six of those eight.
Selected managed-section baselines were refreshed in the 29 clean checkouts;
historical full-template identities remain unchanged.

The durable [machine-readable ledger](archive/FLEET_ROLLOUT_2026-09-23.json)
records publication readbacks, reviewed/final trees, receipt deltas and CI results.

The final 4.16.3 CI-only adjustment validates the exact authored PR candidate
instead of a synthetic merge timestamp. Portable runtime helper bytes are unchanged
from the reviewed 4.16.2 packet; the devenv test-fixture adaptation is noted below.

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
- All 37 committed adoptions contain byte-identical runtime delivery helpers,
  verified by hashes; convergence retains its reviewed patch.
  Devenv 0.14.7 quotes one equivalent empty CDPATH assignment in its copied test
  fixture to satisfy its existing ShellCheck gate; that bounded adaptation is reviewed.
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

## Hosted checks and remaining project work

Riego 1.0.15 passes all four hosted jobs (source, governance, browser, container),
both clean-commit delivery fixtures, and version synchronization. The low-storage
negative fixture consumes zero attempts. This development host's real five-GiB
prerequisite remains unsatisfied; no disk cleanup or real packaging retry occurred.

Devenv's initial imported fixture failed SC1007; 0.14.7 corrects its empty CDPATH
assignment without suppressing lint. Exact Opus reviewed this fifth bounded delta.
The delivery suite passes 84 tests and its existing validator suite passes 55.

Three unrelated CI failures remain visible:

- Infra Portal: npm audit reports two high and two moderate dependency findings.
  Dependency graph, resolved versions and integrity match its pre-rollout base.
- YouTube2Text: npm audit reports three high dependency findings; both lockfile
  dependency graphs match the pre-rollout base. No audit gate was weakened.
- Travel Ledger: four wrapper/acceptance-contract failures also reproduce on the
  isolated pre-rollout 0.9.14 baseline (86 tests, four identical failure modes).
  Its dirty primary and runtime acceptance records remain untouched.

These findings need project-specific remediation and are not a universal CI PASS.
Individual current run URLs and outcomes are retained in the ledger below.

## Publication ledger

| Project | Source version | Publication | Commit / retained artifact | Primary |
|---|---|---|---|---|
| PentAGI-Lab | 0.2.2 | remote verified | de87ca60da08 | fast-forward |
| PiHA-Deployer | component-versioned | remote verified | fe86e097a561 | fast-forward |
| audio-batch | 0.1.3 | remote verified | 60483cd956fc | fast-forward |
| buzz-lab | 0.3.3 | remote verified | 2572defda352 | fast-forward |
| cambio-claro | 0.2.1 | local only | 5dc8f4a1da04 | protected-primary |
| carlos-brand | 0.1.3 | remote verified | 916ba3b2afa6 | fast-forward |
| claude-quest | 1.0.2 | local only | 5bedfac9d85a | fast-forward |
| cortex | 0.4.4 | remote verified | c62c6e334903 | fast-forward |
| devenv | 0.14.7 | remote verified | efc744c31859 | protected-primary |
| devenv-android | 0.2.6 | remote verified | f128889e2196 | fast-forward |
| devenv-bootstrap | 0.1.3 | remote verified | 81fcbce96591 | fast-forward |
| devenv-entry | 0.4.5 | remote verified | 18b5c2d8e29d | protected-primary |
| devenv-spawner | 0.1.4 | remote verified | 6ea33ee9eb4a | fast-forward |
| forgeos | 0.25.7 | remote verified | d38f34cef575 | protected-primary |
| forgeos-convergence | 0.25.0 | deferred | private integration patch | deferred-integration |
| forumlens | 0.1.44 | remote verified | 48f1049a845a | fast-forward |
| forumvault-lab | 0.16.4 | remote verified | dd30c48b9c33 | fast-forward |
| hermes-lab | 0.13.1 | remote verified | 204a52521d20 | fast-forward |
| home-infra | 0.42.1 | remote verified | 16cd48b7d310 | fast-forward |
| home-infra-protocol | 0.13.9 | remote verified | 5eed98396596 | fast-forward |
| house-thermal-monitor | 0.5.4 | remote verified | 5ac32a61d201 | fast-forward |
| infra-portal | 0.29.1 | remote verified | ee8712ba26c5 | fast-forward |
| irrigation-portal | 1.0.15 | remote verified | a5698e62ab6e | fast-forward |
| juiced | 0.1.3 | local only | 9bd224485732 | protected-primary |
| llm-council | 0.1.4 | remote verified | 8d76674ed2c8 | fast-forward |
| med | 1.10.1 | remote verified | c4f7d1b20046 | protected-primary |
| msgvault-lab | 0.25.4 | remote verified | 05d432f7e795 | fast-forward |
| msgvault-panel | 0.15.8 | remote verified | 86d1b274bdeb | fast-forward |
| nas-backup | 1.5.3 | remote verified | 87b78a131493 | protected-primary |
| pi-fleet | 0.4.16 | remote verified | 963a9801b156 | fast-forward |
| plaud-mirror | 0.16.4 | remote verified | 85f624f94e4b | fast-forward |
| qnap-magnet-builder | 0.4.4 | remote verified | 5c28033c8ea5 | fast-forward |
| tomatic | 0.1.9 | remote verified | e056c824266a | fast-forward |
| travel-ledger | 0.9.15 | remote verified | eb60131139f7 | protected-primary |
| unifi-mcp | 0.4.3 | remote verified | 9d09733c3258 | fast-forward |
| vaultwarden-deploy | 0.3.5 | remote verified | ce7ac54fb9bd | fast-forward |
| x-signal | 0.1.3 | remote verified | 1dcf8fa87fbe | fast-forward |
| youtube2text | 0.40.3 | remote verified | 7f97e832271c | fast-forward |

Local-only destinations are cambio-claro, juiced and claude-quest; the latter
was never pushed to its third-party upstream. ForgeOS main is published separately
from the deferred forgeos-convergence checkout. The convergence patch is retained
under that repository Git directory at `dockit/fleet-20260923/integration.patch`.

- devenv: [Windows PowerShell syntax and line endings](https://github.com/cdelalama/devenv/actions/runs/35930831955/job/107416733946) — success.
- devenv: [Linux product and governance](https://github.com/cdelalama/devenv/actions/runs/35930831955/job/107416733773) — success.
- infra-portal: [validate-docs](https://github.com/cdelalama/infra-portal/actions/runs/35929936154/job/107413826160) — success.
- infra-portal: [validate-code](https://github.com/cdelalama/infra-portal/actions/runs/35929936154/job/107413825641) — failure.
- irrigation-portal: [browser](https://github.com/cdelalama/irrigation-portal/actions/runs/35929944546/job/107413854050) — success.
- irrigation-portal: [source](https://github.com/cdelalama/irrigation-portal/actions/runs/35929944546/job/107413854043) — success.
- irrigation-portal: [container](https://github.com/cdelalama/irrigation-portal/actions/runs/35929944546/job/107413854020) — success.
- irrigation-portal: [governance](https://github.com/cdelalama/irrigation-portal/actions/runs/35929944546/job/107413853804) — success.
- med: [validate](https://github.com/cdelalama/med/actions/runs/35929961294/job/107413903362) — success.
- plaud-mirror: [test](https://github.com/cdelalama/plaud-mirror/actions/runs/35929999645/job/107414029970) — success.
- qnap-magnet-builder: [test](https://github.com/cdelalama/qnap-magnet-builder/actions/runs/35930007365/job/107414056266) — success.
- travel-ledger: [validate](https://github.com/cdelalama/travel-ledger/actions/runs/35930020708/job/107414099503) — failure.
- youtube2text: [Dependabot](https://github.com/cdelalama/Youtube2Text/actions/runs/35930176200/job/107414602703) — success.
- youtube2text: [validate](https://github.com/cdelalama/Youtube2Text/actions/runs/35930057533/job/107414213613) — failure.
