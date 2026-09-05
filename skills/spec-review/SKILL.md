---
name: spec-review
description: >-
  Review an existing specification for correctness, completeness, ambiguity,
  testability, scope, contradictions, constraints, and missing failure cases.
  Use only when explicitly requested.
disable-model-invocation: true
---

# Spec Review

Review **the specification artifact**, not the implementation.

Ask: **Did we define the right thing clearly enough to design or execute?**

Check:
- goal vs source task
- explicit non-goals
- acceptance criteria are observable/testable
- contradictions or ambiguous words
- missing constraints/dependencies
- missing failure/edge cases
- hidden solution decisions masquerading as requirements
- unresolved questions that block the next stage

Output findings by severity: `BLOCKER`, `IMPORTANT`, `NIT`, then a verdict: `READY`, `READY WITH ASSUMPTIONS`, or `NOT READY`.

When the user asks to persist the review, write `discussion/spec-review-<slug>.md` under the existing task folder and reference the reviewed spec. Do not overwrite the spec unless explicitly asked to revise it.

## Context Budget

**Required:** active spec, task record, and `context.md` if present.

**Read only when needed:** source requirements or adjacent contracts used to challenge completeness.

**Avoid loading:** implementation code unless necessary to identify a hard feasibility/compatibility constraint.

**Context update:** on accepted review findings, update only the compact unresolved/resolved state in `context.md`; authoritative changes belong in the spec. See [`../../CONTEXT.md`](../../CONTEXT.md).
