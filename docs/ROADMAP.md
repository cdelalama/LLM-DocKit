# LLM-DocKit Roadmap

This roadmap is source-specific. It is not synced to downstream adopters.
Immediate operational state still lives in `docs/llm/HANDOFF.md`; accepted
feedback candidates live in `docs/DOWNSTREAM_FEEDBACK.md`; durable rationale
lives in `docs/llm/DECISIONS.md`.

## Now

Stabilize the v4.11.x line and close adopter sync work opportunistically when
each adopter is opened.

- Keep MED as the reference adopter for `orientation-drift`, durable Trace, and
  neutral Trace Anchor wording.
- Avoid fleet-wide force-sync when adopters have active product work. Sync and
  commit per adopter.
- Prefer small regression tests in `scripts/test-validator.sh` for every
  validator or sync behavior that previously failed in the fleet.

## Next

Close the Codex CLI integration axis from DF-036, DF-037, and DF-038.

- DF-036: Codex CLI must use `dockit-bootstrap-context.sh --human`, not
  Claude Code's `--json` envelope.
- DF-037: after DF-036 is installed, verify whether Codex still repeats
  `Onboarding loaded.` on later turns. If yes, design a stateful Codex-specific
  mode rather than guessing.
- DF-038: keep the Codex hook installer in LLM-DocKit and let ForgeOS call it
  from operator bootstrap when provisioning a machine.

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
