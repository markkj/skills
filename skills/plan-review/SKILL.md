---
name: plan-review
description: >-
  Review an implementation plan before execution. Checks that plan steps trace
  to the spec/design, are ordered safely, use small end-to-end feedback loops,
  include tests and verification, and cover migrations/rollback/observability.
  Explicit opt-in only.
disable-model-invocation: true
---

# Plan Review

Ask: **Can this design/spec be implemented safely from this plan?**

## Same folder as the task

Write the report **only** here:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/discussion/plan-review-<slug>.md
```

That `discussion/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Load the task, active/chosen plan, and spec/design when present.

Check:
- every required behavior has a plan step
- no plan step contradicts design/spec
- todo order respects dependencies
- todos are small end-to-end increments, not layer-only batches
- behavior changes have failing-test-first steps unless explicitly waived
- each todo has concrete verification
- migrations, compatibility, rollout/rollback and observability are covered where relevant
- repo/worktree assumptions are correct
- no implementation-critical decision is left vague

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `discussion/plan-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map `READY TO EXECUTE` → `READY`).

List the file on the task. Do **not** put `status` on the plan or the review file. Log the verdict on `task-*.md`. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** active plan plus task/spec/design contract and `context.md`.

**Read only when needed:** exact repo files/symbols needed to validate risky plan assumptions.

**Avoid loading:** broad repo exploration already completed by `coding-plan` unless review discovers a specific gap.

**Context update:** keep only accepted plan-review decisions and unresolved blockers; corrections belong in the plan. See [`../../CONTEXT.md`](../../CONTEXT.md).
