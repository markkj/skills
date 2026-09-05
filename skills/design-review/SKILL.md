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

Return severity-tagged findings and verdict: `READY`, `READY WITH CHANGES`, or `NOT READY`.

When persisted, write `discussion/design-review-<slug>.md` in the task folder. Do not silently rewrite the design.

## Context Budget

**Required:** active design, its spec/task contract, and `context.md`.

**Read only when needed:** exact components/contracts needed to validate a claim or risk.

**Avoid loading:** broad implementation context not relevant to the design decisions under review.

**Context update:** compact accepted findings/remaining blockers into `context.md`; actual design corrections belong in `design-*.md`. See [`../../CONTEXT.md`](../../CONTEXT.md).
