# LLM-DocKit Roadmap

This roadmap is source-specific. It is not synced to downstream adopters.
Immediate operational state still lives in `docs/llm/HANDOFF.md`; accepted
feedback candidates live in `docs/DOWNSTREAM_FEEDBACK.md`; durable rationale
lives in `docs/llm/DECISIONS.md`.

## Now

Maintain the completed independent-review policy fleet convergence.

- `docs/FLEET_ROLLOUT_2026-09-12.md` is the exact ledger for 49 primary Git
  repositories, 38 registered adopters, 35 published policy revisions, one
  committed third-party overlay, and two protected no-remote worktrees.
- All evidenced existing DocKit adopters now have `.dockit-enabled`, including
  Irrigation Portal and the late-discovered PiHA-Deployer omission.
- Preserve the Fable-preferred, exact-Opus-on-recorded-quota policy and the
  explicit exceptions; do not treat this selected-section convergence as full
  template currency.
- New registration uses D-022's evidence boundary. Stale sync state or a
  directory name alone is not authority to enroll a repository.
- v4.15.0 makes that legacy-registration path executable through
  `--untracked-existing-adoption`, fixes UTC Trace comparison under DF-057,
  and records Travel Ledger's corrected 0.9.14 governance evidence.

## Next

Plan full-template upgrades separately, based on each adopter's own state.

- Use `dockit-sync-check.sh` and per-project dry runs to distinguish complete
  template drift from the already-delivered policy section.
- Before a full sync carries the DF-057 validator correction, repair the false
  UTC Trace-anchor timestamps currently detected in `buzz-lab` and
  `infra-portal`; a red gate must be fixed from Git evidence, never by reverting
  the validator.
- Keep `cambio-claro` and `juiced` local until their broader dirty worktrees and
  lack of remotes have an independently valid publication path.
- Keep `claude-quest` as a local governance overlay unless an operator-owned
  fork or other legitimate publication target is established.
- MED's active dirty checkout lacks the selected section and its marker pair;
  that local exception remains explicit even though its separate authoritative
  policy revision is published.
- Repositories with a stricter local model rule keep it until the operator
  explicitly supersedes that rule in the project.

## Later

Promote semantic checks only when they are opt-in, project-configured, and
backed by real downstream evidence.

Candidates include forbidden-token policy checks, prose-version drift,
doc-freshness, stronger review metadata, and stricter release modes. They
should not become fleet defaults until the false-positive shape is known.

## Out Of Scope

Do not implement consensus/runtime orchestration, LMConsole, ProtocolEngine,
VisualWorkbench, WorkEpisode, AuthorityEngine, or live multi-LLM routing in
LLM-DocKit.

The boundary is:

- LLM-DocKit: scaffold/documentation substrate, Trace, validators, hooks,
  sync, and init.
- ForgeOS: live operator runtime, LMConsole, ProtocolEngine, workbench, and
  orchestration.
- `llm-council`: curated deliberation archive/corpus, examples, fixtures, and
  lessons.
