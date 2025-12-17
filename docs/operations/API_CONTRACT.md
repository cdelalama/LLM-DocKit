# API Contract (Optional)

Use this runbook when the project exposes an API and you want to prevent drift between:
- the API implementation
- OpenAPI/spec files
- generated clients/types (if any)
- consumers (UI, integrations, SDKs)

## When to use this
- You ship an HTTP API.
- You maintain an OpenAPI spec (or equivalent).
- You generate clients/types, or you have multiple consumers that must stay aligned.

## Contract Sources
- Spec location: <e.g., openapi.yaml>
- Generated outputs (if any): <e.g., web/src/api/generated/*>
- Contract-check command (if any): <e.g., npm run api:contract:check>

## Change Workflow
1. Decide whether the change is breaking (SemVer impact).
2. Update the spec and the implementation in the same session.
3. Regenerate types/clients (if applicable).
4. Run contract checks and tests.
5. Document the change:
   - `docs/llm/HISTORY.md` (what changed)
   - `docs/llm/HANDOFF.md` (what to do next)
   - `docs/VERSIONING_RULES.md` if version policy needs adjustment

## Checklist
- [ ] Spec updated
- [ ] Implementation updated
- [ ] Generated artifacts updated (if any)
- [ ] Contract checks passing
- [ ] Backwards compatibility reviewed (or version bumped)

