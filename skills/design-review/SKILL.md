---
name: design-review
description: >-
  Adversarially review an existing design against its task/spec for correctness,
  unnecessary complexity, failure modes, compatibility, operability,
  observability, scaling, migration, and missing tradeoffs. Explicit opt-in only.
disable-model-invocation: true
---

# Design Review

Ask: **Is this a sound way to satisfy the spec?**

## Same folder as the task

Write the report **only** here:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/discussion/design-review-<slug>.md
```

That `discussion/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Review:
- traceability to every important requirement
- correctness and invariants
- failure/retry/concurrency behavior
- reliability and scaling assumptions
- data/API/event compatibility
- security boundaries when relevant
- observability and operations
- rollout, migration, rollback
- complexity / simpler alternatives
- decisions hidden or deferred into implementation

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `discussion/design-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY`.

List the file on the task. Do **not** put `status` on the design or the review file. Log the verdict on `task-*.md`. Do not silently rewrite the design. Extra questions (if any) go in **Questions for you** in the same report — do not create a second questions file unless the user asks.

## Context Budget

**Required:** active design, its spec/task contract, and `context.md`.

**Read only when needed:** exact components/contracts needed to validate a claim or risk.

**Avoid loading:** broad implementation context not relevant to the design decisions under review.

**Context update:** compact accepted findings/remaining blockers into `context.md`; actual design corrections belong in `design-*.md`. See [`../../CONTEXT.md`](../../CONTEXT.md).
