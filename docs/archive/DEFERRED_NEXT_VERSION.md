# Deferred for Next Version

> Archived: 2026-06-18
> Status: superseded by ForgeOS control-plane architecture.
> Kept as historical lineage for the early "LLM Control-Plane + Arbiter +
> Dashboard" idea. Do not implement this draft inside LLM-DocKit. The live
> direction belongs in ForgeOS, which now owns WorkEpisode, ArtifactBus,
> CaptureLog, AuthorityEngine, future ProtocolEngine, and future
> VisualWorkbench.

Date: 2026-03-01
Status: Deferred (do not implement now)

## Idea: LLM Control-Plane + Arbiter + Dashboard

Goal:
- Reduce manual handoff reminders and token overhead.
- Coordinate multiple LLMs automatically.
- Prevent documentation drift without user micromanagement.

Proposed direction:
1. Add hook-driven event reporting (and/or HTTP callbacks) from LLM sessions.
2. Send structured events to a local orchestrator service.
3. Maintain session state in a central store (journal).
4. Auto-generate/update `docs/llm/HANDOFF.md` and `docs/llm/HISTORY.md` from events.
5. Add a web dashboard to monitor LLM state, diffs, blockers, and arbitration decisions.
6. Add a third "arbiter" agent/service for:
   - stop/continue decisions
   - overengineering detection
   - consensus policy execution (configurable consensus models)

Constraints for this item:
- Keep pending for next version.
- Do not implement in current workstream.
- Revisit after current priorities are completed.
