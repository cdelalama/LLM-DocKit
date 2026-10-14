# Economical continuous validation

GitHub stores commits independently of Actions. Actions starts machines to run
the checks declared in `.github/workflows`. Private repositories share their
owner's hosted allowance; repository count is not usage and workflow-run count
is not billable minutes. Public standard runners have a different billing rule.

## Preserve checks while avoiding repeated work

- Run pure validation on pull requests and, where already required, pushes to
  the actual default branch. Verify its name rather than assuming `main`.
  A branch without a PR receives local validation; open a draft PR when hosted
  checks are needed. Tags and other release branches need their own explicit
  release workflow; do not apply this pattern to deployment or release jobs.
- Keep workflow/job names, test commands, event baselines and required checks.
  Do not use path filters, `[skip ci]`, or job skips to manufacture a green gate.
- Cancel superseded PR checks only. Give every default-branch and manual run a
  distinct concurrency group using `github.run_id`; even queued release checks
  must not replace each other. Verify green evidence for the exact release SHA.
- Bound previously unlimited lightweight jobs with a suitable timeout. Retain
  existing limits. Use read-only workflow permissions unless a declared step
  needs more; grant no new token scopes to inspect billing.
- Keep `workflow_dispatch` for a deliberate recovery run. Manual validation uses
  the selected ref; an idea check's existing missing-event-baseline fallback
  compares its immediate parent, not an entire earlier PR.
- Finish and review a coherent change locally before publishing it. Batch
  receipt-only documentation when the owner's closeout allows it. Required
  review, source publication and exact final-commit checks still apply.
- After a quota/billing refusal, retain the failed run and stop unchanged
  retries. Correct the cause or wait for an observed reset before one deliberate
  retry. A published workflow improvement does not reopen the current allowance.

The template workflows implement this pattern. Existing adopters need explicit
reviewed updates; copying this document does not change their remote workflows.
Do not consolidate jobs until required-status and evidence consumers have been
checked. Upstream watches, deployment, releases and remote acceptance have their
own purpose and must not be disabled as a blanket cost measure.

## Cost and recovery boundaries

Do not enable paid usage, raise budgets, make private repositories public, add
self-hosted runners, or delete artifacts/evidence merely to evade a quota error.
Those are separate operator decisions. Local tests can provide useful evidence
only when the execution host permits them; they do not silently replace a
required platform or hosted check.

The account owner can inspect Actions usage by repository in GitHub billing.
If that view is unavailable to the executor, report the missing measurement.
Do not label an estimate as a bill or a generic billing refusal as a debt.
Optimization reduces avoidable demand; it cannot guarantee that a shared free
allowance will never run out as activity changes.

Official references:
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow

Existing unfiltered tag-push validation is retained with `tags: ['**']`;
workflows already restricted to the default branch retain that original scope.
