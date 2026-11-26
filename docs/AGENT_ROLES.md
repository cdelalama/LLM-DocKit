# Model-independent agent roles and provenance

DocKit provides a common vocabulary, durable records and Trace. It is not an
agent scheduler or credential store (D-009, D-011). Roles describe work:

| Role | Responsibility |
| --- | --- |
| executor | Implements, validates, records and publishes the authorized task. |
| auditor | Independently inspects source/evidence and returns bounded findings. |
| advisor | Advises on options, consequences and decisions without claiming execution. |

One model can perform different roles in separate tasks. A project names its
required roles, scope and acceptance criteria. ForgeOS owns available agents,
account routing, assignment, quota handling and invocation/capture. Credentials
stay in their existing secret custody, never in these documents or Trace.

Do not confuse provider/model family, exact requested model, actual returned
model, client, account alias, session and task. Two accounts of the same model
family do not provide cross-family independent review. Use opaque account
aliases; do not expose email addresses, tokens or account secrets. Unknown
effective model identity remains unknown; a requested CLI argument or a model's
self-description is not returned identity evidence. Existing exact-model and
effort selections, including the managed Claude preference, remain authoritative.

Optional Trace provenance is descriptive. It does not authorize role assignment,
certify independence or replace preserved review metadata. A review verdict never
grants deployment/deletion authority. Required cross-family review follows the
project/operator's existing rule, not a fixed brand-to-role mapping.

Client support must be observed separately: successful Claude/Codex hooks do not
prove hooks for Gemini, Grok or another client. All clients can consume the same
project documents; use the supported bootstrap payload and explicit checks when
the client lacks verified lifecycle hooks. Orca's HTML capability changes only
Trace presentation; terminal text and durable history remain supported.
