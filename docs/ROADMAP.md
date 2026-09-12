# LLM-DocKit Roadmap

This roadmap is source-specific. It is not synced to downstream adopters.
Immediate operational state still lives in `docs/llm/HANDOFF.md`; accepted
feedback candidates live in `docs/DOWNSTREAM_FEEDBACK.md`; durable rationale
lives in `docs/llm/DECISIONS.md`.

## Now

Publish the independent-review fleet default and make its rollout selective.

- Prefer exact Fable `claude-fable-5-1` at high effort; permit exact Opus
  `claude-opus-5[1m]` at high effort only after direct Fable quota evidence.
- Use `dockit-sync.sh --only` to preview or apply this managed section without
  claiming that an adopter received the rest of the current template.
- Preserve project-local stricter review contracts and partial-adopter gaps as
  explicit exceptions instead of forcing them away.

## Next

Run the operator-controlled selective fleet preview and classify each adopter.

- The 2026-09-12 real dry-run scanned 23 registered adopters: 21 full adopters
  would insert only `LLM_START_HERE.md:independent-review-policy`; `med` and
  `msgvault-lab` were classified as partial with no markers; zero errors.
- Those 21 full adopters may receive only the selected section after a separate
  apply authorization. The two partial adopters need an intentional
  marker/adoption decision.
- Repositories with a stricter local model rule keep it until the operator
  explicitly supersedes that rule in the project.
- Full DocKit upgrades remain separate and should be performed when each
  adopter's unrelated conflicts can be reviewed.

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
