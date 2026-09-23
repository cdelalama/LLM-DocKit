# Claude default change - 2026-09-23

Operator instruction: make newly released Opus 5.5 the default. Model policy is
owned by LLM-DocKit's managed independent-review-policy section. Exact identifier:
claude-opus-5-5; effort: high. D-024 supersedes the previous model preference.

## Evidence and scope

- Official model configuration: https://code.claude.com/docs/en/model-config
- dev-vm Claude Code 2.1.280 supports the model; an explicit minimal request
  returned MODEL_CHECK_OK and modelUsage claude-opus-5-5.
- User settings and instruction updates are verified separately from source sync.
- Windows CLI launch exposed a pre-existing invalid executable; do not claim a
  successful Windows model call from a settings-file check alone.
- Historical Fable/Opus-5 review receipts and design reports remain immutable.
- A fresh global preference does not change running sessions, explicit project
  overrides, or prove that all repository copies received a managed-section sync.

## Applied surfaces

- LLM-DocKit 4.16.1 managed source section and D-024 decision.
- ForgeOS current source section and Dossier active implementation handoff;
  prior Fable design reports and review records were preserved.
- dev-vm and Windows user settings: exact model, high effort; unrelated keys
  preserved with private local backups. Global Codex/Claude instructions record
  the operator preference as explicit operator direction, not as an enforcement mechanism.

The current selective sync implementation rejects linked worktrees as "not a git
repository". The managed block was replaced verbatim after checking the inherited policy.
Additional ForgeOS edits update version markers, Current Focus, HANDOFF, HISTORY
and the active Dossier handoff; no hooks or sync-state files changed.
This is an explicitly bounded adoption, not a claimed native-sync success.
No bulk fleet sync is claimed. Existing copies require their normal safe selective
update; dirty worktrees and local exclusions remain untouched. User defaults
apply to fresh sessions unless an explicit project/environment/CLI override wins.


Effort evidence is the explicit `--effort high` invocation and saved user setting;
modelUsage proves model identity, not the provider's internal reasoning budget.
Follow up the linked-worktree sync limitation through HANDOFF; no force-sync was used.

The independent first review also ran without `--model` and returned modelUsage
claude-opus-5-5. This is the fresh user-default probe, separate from the initial
explicit-model request and the explicit-model second review. The official model
documentation, consulted on 2026-09-23, states: "Opus 5.5 requires Claude Code
v2.1.280 or later." See the linked official source above.

Final source/delta review: GO from exact Opus 5.5 at requested high effort;
model identity verified from metadata. Both repositories pass their documentation
and version checks. See docs/llm/REVIEWS.md for candidate trees and review history.
