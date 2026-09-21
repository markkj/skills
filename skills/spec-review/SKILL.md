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

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `discussion/spec-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map old `READY WITH ASSUMPTIONS` → `READY WITH CHANGES`).

List the file on the task. Do **not** put `status` on the spec or the review file. Log the verdict on `task-*.md`. Do not overwrite the spec unless explicitly asked to revise it. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** active spec, task record, and `context.md` if present.

**Read only when needed:** source requirements or adjacent contracts used to challenge completeness.

**Avoid loading:** implementation code unless necessary to identify a hard feasibility/compatibility constraint.

**Context update:** on accepted review findings, update only the compact unresolved/resolved state in `context.md`; authoritative changes belong in the spec. See [`../../CONTEXT.md`](../../CONTEXT.md).
