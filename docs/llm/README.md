# LLM Docs Index

This folder contains the "LLM-to-LLM" working memory for this repository.

Goals:
- Keep the current operational state easy to resume (HANDOFF).
- Keep an append-only log of sessions and changes (HISTORY).
- Keep stable decision rationale in one place (DECISIONS).

## Files

- `docs/llm/HANDOFF.md`
  - The current operational snapshot.
  - Keep short (target: 1-2 screens).
  - Contains: Current Status, numbered Next Steps, Key Decisions (links), Open Questions, Testing Notes.

- `docs/llm/HISTORY.md`
  - Append-only change log (newest entries at top).
  - Every session that changes code/docs should add one entry.

- `docs/llm/DECISIONS.md`
  - Stable decision rationale (the "why").
  - Put long context here (tradeoffs, rejected options, pitfalls).
  - HANDOFF should link here instead of duplicating long sections.

- `docs/llm/REVIEWS.md` (optional)
  - Notes from human/LLM reviews (quality gates, feedback, follow-ups).

## Rules of thumb

- If it is "what to do next": HANDOFF.
- If it is "what changed in this session": HISTORY.
- If it is "why we chose this approach": DECISIONS.

## Encoding

To avoid Windows encoding issues, keep `docs/llm/*` ASCII-only when possible.

