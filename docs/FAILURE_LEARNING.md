# Learning from operator corrections

When an operator corrects an agent's factual or operational claim, the agent
must repair the active task and record the failure in the project's
`docs/llm/FAILURE_LEARNING.json` if it can recur. Do not merely append a warning
to a handoff. Identify the evidence that was used, the evidence that should
have taken precedence, the resulting wrong action or request, and a concrete
change that will catch the same error next time. Keep private incident data out
of this register; link to its governed record.

Before answering from an older incident note, check the current owner decision,
live generation and later superseding record. For MCP capability claims, compare
the app, each client connection's selected tools, the client registration, and
an actual session call. A missing tool in one session does not prove that an app
or another client's grant disappeared. A dirty unrelated checkout does not prove
a competing runtime writer; inspect actual ownership and processes.

The register uses schema 1 with a `cases` array. Each case has a unique `FL-nnn`
ID and these fields: `observed`, `consequence`, `cause_status` (`known`,
`hypothesis`, `unknown`), `cause`, `status` (`open`, `mitigated`, `closed`),
`corrective_action`, `owner`, `verification`, `source_refs`, `prevention_refs`,
`adoption_revision` and `coverage_limit`. References are existing paths within
this repository. `adoption_revision` is null while unpublished and, for a
closed case, the consumer repository commit containing the prevention artifact.
An open case may name pending evidence. A mitigated case has a concrete local
fix but lacks full acceptance. Close only when the cause is established, owner
source and prevention artifacts exist, and `verification` names actual checked
evidence. The checker also confirms each prevention artifact exists in the
adoption commit. Independent review remains required where owner policy says so.

`scripts/dockit-validate-session.sh --check failure-learning` checks the
declared register and refuses a structurally unsupported close. It cannot know
which chats or corrections were omitted, validate the truth of prose, or prove
client runtime behavior. Author and reviewer must compare the conversation and
real operator view with the declared cases. Recheck adoption and current version
in each project; updating DocKit source alone does not install a guard elsewhere.
