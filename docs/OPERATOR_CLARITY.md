# Operator clarity and roadmap continuity

Owner: LLM-DocKit. Accepted by the DocKit owner on 2026-10-01 for every project, not
only the project that exposed the problem. This governs operator-facing status,
roadmaps, Dossiers, reports and questions. Engineering sources remain English;
the operator view uses the configured product language.

## A status must help someone act

Write for an operator returning without the conversation. For each current
milestone explain the useful outcome, what is usable today, what is still
missing, and the next actor and action. Name the place to act and the result to
look for. Start with one immediate step; separate subsequent work.

Completion is an observable example, not internal paperwork. "Transfer complete
and acceptance verified" hides both the task and the result. A useful Spanish
example is: "Abre una transcripción en tu ordenador y en tu móvil, busca una
frase que recuerdes y vuelve a abrirla sin conexión. Terminaremos este paso
cuando puedas hacerlo en ambos dispositivos."

Do not invent the example's outcome, an available button, a working link, an
installed app or an actor's approval. Say what is unknown and who will resolve
it. Read existing operator/device preferences before asking setup questions.
Ask only for missing information that changes the next action, and explain why.
Do not make technical setup, file-hash checks or source review into unexplained
operator chores: the executing agent owns those where it can perform them.

Lead with user outcomes and plain verbs. Explain unavoidable terminology on
first use. Put hashes, schema names, model metadata and implementation detail
in sources or expandable evidence unless needed for the operator's decision.
Keep meaningful limits: prepared, published, deployed and personally tried are
different states. Brevity must not remove the actor, action or useful result.

## Changing priority must preserve the map

Record the previous order, new order, date, reason and decision authority.
For each displaced line say whether it is retained, deferred, superseded or
being executed concurrently. A separate line does not mean work has started.
Preserve milestone IDs, history and unfinished obligations; no silent renumbering
or completion. Distinguish proposed sequencing from accepted execution.

Show separate lines when outcomes or owners differ. Explain their relationship
and actual prerequisites, and identify the current priority. Ordering entries
in an array does not create dependencies or make its first unfinished item the
current task. A reader must not invent a single linear journey from independent
branches. If the format cannot encode branches, explain them visibly in the
current phase and milestone text without inventing machine-readable edges.

## Review before delivery

Read the operator view without the originating chat and answer:

1. What can the operator use now, and what remains unavailable?
2. Who acts next, where, doing what, and what result should they see?
3. What real observation will finish the milestone?
4. If priority changed, why, and where did the former work go?
5. Does the actual reader preserve those meanings and uncertainties?

The independent reviewer must check these questions against primary sources and
the rendered view, not merely approve the executor's checklist. Record findings
and corrections in the normal review record. Structural validators prove shape,
not comprehension; this is an explicit author/reviewer requirement, not a claim
of automatic semantic enforcement. Immutable old publications retain their
original text; corrections are new dated revisions. Adoption of this policy
does not prove that every existing publication has been rewritten or accepted.

## Ownership and distribution

The managed `operator-clarity` section in `LLM_START_HERE.md` is the portable
rule. ForgeOS owns Dossier-specific field guidance; Portal owns faithful
rendering; each project owns its content. Installations may repeat the rule in
operator-wide agent instructions to cover repositories before selective sync.
Record source, installed coverage and exceptions separately. Selective adoption
does not assert a full template upgrade or overwrite project priorities.
