# Riego delivery postmortem and implementation brief

Status: operator-requested report; remediation belongs to a separate DocKit
session. Date: 2026-09-19. Tracking: https://github.com/cdelalama/LLM-DocKit/issues/1.

## Finding and responsibility

A small private application accumulated disproportionate infrastructure
acceptance machinery. Real security and platform defects existed, but the
executor optimized individual checks before proving the complete user path.
Successful rollback repeatedly became the end of another expensive cycle.
The executor owns sequencing and judgment: neither the operator's demand for
independent review nor the auditor's findings excuses unbounded iteration.
DocKit preserves evidence but does not enforce proportionality or useful progress.

The operator reports approximately three days of continued work with poor
visibility. No reliable breakdown of active coding, model waits, CI waits or
operator waits was reconstructed; do not invent one. Since September 16 at
00:00 +0200, the inspected histories contain 11 Riego and 40 Home Infra commits.
The Home Infra count INCLUDES UNRELATED WORK and cannot be attributed wholly to
Riego or translated into hours. Earlier VPN successes also mean the later WAN
outage cannot explain every historical failure.

## Reproducible evidence

At inspection, Riego main/origin/main were clean at
f258cced100b70d9667ef1e2b4375e723e72b017 (1.0.12); Home Infra was clean at
6f7f12a58a5517290a0ee3d6d54d4cf5d80044b0 (0.38.15). Their published records
agree that runtime 1.0.6 runs on NAS and P12 Stages 1-5 are accepted. Remote,
Android, restart-persistence and first encrypted off-host acceptance remain.
These are published records, not a fresh physical/runtime test in this report.
DocKit baseline is 4.15.0 at 6a08e5ffdeae7e21fb469a7875cde0c74b7e85f5.

Riego source anchors at that revision:

- `docs/PROJECT_CONTEXT.md`, Current Status: accepted application and WAN incident.
- `docs/llm/HANDOFF.md`, Current Status and Open work: chronology and remaining work.
- `docs/llm/DECISIONS.md`, D-008/D-027: WireGuard and dedicated ingress decisions;
  D-029: proportional governance accepted locally; D-030: late ingress prerequisite.
- `docs/audits/2026-09-19-p12-stage6-public-ingress-incident.md`: attempt 6 and cleanup.
- `docs/implementation/ROADMAP.md`: implementation and acceptance lineage.

Home Infra anchors at its revision above:

- `docs/INVENTORY.md`, Barcience Internet uplinks: Orange unavailable and active
  Starlink behind upstream NAT; warning existed before attempt 6.
- `docs/SERVICES.md`, Riego and External Access: accepted runtime and existing
  Cloudflare Tunnel pattern for Vaultwarden.
- `docs/operations/IRRIGATION_PORTAL_P12_DEPLOYMENT_2026-09-14.md`.
- `docs/operations/ORANGE_OUTAGE_STARLINK_TEMPORARY_2026-09-16.md`.

## Incident sequence

1. Application source, Better Auth, roles, bounded writes and hardware
   certification completed. Source completion was communicated separately from
   deployment, but repeated terminal claims remained confusing to the operator.
2. Deployment exposed NAS permission and portable SQLite backup defects.
   Those justified targeted corrections and regression evidence.
3. VPN testing found NAS SSH reachable despite the intended TCP-443 rule.
   Three legacy-rule variants failed and were restored; dedicated ingress
   replaced dependence on the ineffective field.
4. Acceptance encountered listener-family and Docker-resolver mismatches,
   over-strict cosmetic UniFi comparison, QNAP network-creation races, shell
   scope errors and native ACL behavior. Each could produce another source
   candidate, audit, release-truth revision and one-use transaction.
5. Stage 6 attempt 6 tested binding, keys, policy and persistence before fresh
   health proved Orange had no lease and Starlink used upstream NAT. No
   handshake was possible through the assumed ingress. Cleanup was exact.
6. An outbound tunnel was proposed afterwards. It removes dependence on
   incoming public IPv4, but still requires identity controls, origin isolation,
   off-LAN acceptance and explicit provider trust. It does not replace the
   application's physical-write safeguards or backup custody.

## Root causes and required controls

| Failure | Evidence | Required change |
| --- | --- | --- |
| Prerequisites checked late | Peer transaction preceded live-ingress check; outage already documented upstream | Real dependency-chain viability before implementation machinery |
| Architecture inertia | Native ingress attempts continued around missing provider path | Repeated failure requires new evidence or redesign |
| Fragmented completion | Source, deployed, locally accepted and remote usable states confused | One user-facing usable outcome plus distinct state fields |
| Review amplification | Microcorrection, LOW closure and integrity rounds accumulated | One frozen candidate, batched corrections, automated identity verification |
| Unbounded scope | One-use tools and release-truth revisions expanded | Gate, candidate, attempt and active-work budgets |
| Context overload | Riego HANDOFF is 923 lines; DocKit asks for 1-2 screens | Short current snapshot with linked incident archive |
| Semantic drift | Orientation PASS checks five existing paths while next work says publish already-published 1.0.12 | Detect completed work still presented as next; state structural limits honestly |
| Quota delay | Historical Fable waits | Immediate documented exact Opus fallback already in D-020 |
| Ownership ambiguity | DocKit substrate vs ForgeOS runtime | Portable checks here; orchestration runtime remains ForgeOS-owned under D-009/D-011 |

## Proposed remediation for the next session

Classify the product and each infrastructure slice separately. A simple app
does not make a shared-network or physical-system change low risk.

1. Add a small machine-readable declaration using existing configuration:
   profile, usable outcome, at most four simple-project gates, prerequisites,
   one current candidate, budget, attempt history, findings and next action.
   Avoid creating another service or orchestration framework.
2. Require an early vertical viability probe for the actual host/container,
   DNS/TLS, ingress/egress and auth boundary. Prefer read-only evidence;
   mutations retain a bounded authorization envelope and rollback.
3. Review one releasable candidate and corrected deltas in the same session.
   Default two substantive rounds; exceeding the budget triggers reassessment,
   never automatic GO. Security-relevant MEDIUM findings can remain blockers;
   severity alone must not authorize unsafe deferral.
4. Record hypothesis, new evidence and outcome per attempt. A renamed packet,
   new version or fresh peer does not reset the counter. Equivalent failure or
   exhausted budget stops further mutation. Recovery remains mandatory even
   after the delivery budget expires.
5. Apply D-020: exact Fable once, exact Opus after direct quota exhaustion;
   distinguish quota from authentication or configuration faults. Freeze
   dependent work when both unavailable and report the blocker honestly.
6. Consolidate releases and evidence. Do not rebuild an unchanged product image
   to attest to its predecessor. Existing version rules remain binding until
   a reviewed change supersedes them; do not introduce bypass switches.
7. Report working now, remaining, evidence gained, active work vs external wait,
   and next checkpoint. Hashes and gate labels do not replace user explanation.
8. Keep current HANDOFF short; move chronology to linked historical records.
   Warn on size and stale completed work. Follow D-015: no repeated full
   onboarding when context remains current, including after compaction.

Source entry points: `LLM_START_HERE.md`, `scripts/dockit-validate-session.sh`,
`scripts/test-validator.sh`, `scripts/dockit-init-project.sh`,
`dockit-sync-manifest.yml`, `docs/llm/README.md`, `docs/ROADMAP.md`, `HOW_TO_USE.md`.

## Acceptance criteria and fleet delivery

- One private-web-app fixture demonstrates four outcomes from viability to handoff.
- Machine-readable missing prerequisites, excess gates, parallel candidates,
  equivalent retries and stale completed next work are detected; limits explicit.
- Round/time budgets never silently close an unresolved supported finding.
- Failed rollback can be recovered after the ordinary work budget expires.
- Missing profile has documented migration behavior; stricter adopter contracts
  are never silently weakened and managed/local blocks remain preserved.
- One clean pilot receives the selected policy/checks, then selective fleet sync
  records every adopter as current, applied, conflict or excluded. Preserve dirty
  worktrees. Users must not re-explain the same policy project by project.
- Source publication, pilot acceptance and fleet delivery are separate evidence.

## Exact handoff

Issue #1 was OPEN with no comments at inspection. DF-058 and this report are
intake, not implementation or fleet enforcement. Read this report, current
DocKit onboarding and D-009/D-011/D-020/D-021; reverify source; propose one bounded
substrate patch with acceptance fixtures; obtain required independent review,
implement, pilot, then roll out. Keep orchestration runtime work in ForgeOS.
Do not close issue #1 merely because this document exists.

Carlos explicitly requested this report for another session. The current
session must continue Riego's reviewed outbound-access roadmap and execution;
DocKit remediation must not become a prerequisite for delivering Riego.
