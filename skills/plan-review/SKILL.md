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

Return findings and verdict: `READY TO EXECUTE`, `READY WITH CHANGES`, or `NOT READY`.

## Context Budget

**Required:** active plan plus task/spec/design contract and `context.md`.

**Read only when needed:** exact repo files/symbols needed to validate risky plan assumptions.

**Avoid loading:** broad repo exploration already completed by `coding-plan` unless review discovers a specific gap.

**Context update:** keep only accepted plan-review decisions and unresolved blockers; corrections belong in the plan. See [`../../CONTEXT.md`](../../CONTEXT.md).
