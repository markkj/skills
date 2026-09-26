---
name: spec
description: >-
  Write a durable specification for a task: goals, non-goals, expected behavior,
  acceptance criteria, constraints, edge cases, and open questions. Uses the
  existing Obsidian task folder and never performs solution design or coding.
  Use only when the user explicitly names spec or asks to create a specification.
disable-model-invocation: true
---

# Spec

A spec defines **what should be true**, not how to implement it.

## Same folder as the task

Write **only** into the folder that already has `task-*.md`:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
├── task-<slug>.md
├── spec-<slug>.md
└── discussion/questions-spec-<slug>.md
```

Never write `discussion/` at the git repo root or vault root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

## Harness

| Phase | Do | Verify | STOP if |
|---|---|---|---|
| **0 — Preconditions** | Locate the task folder/task file via `$OBSIDIAN_BASE_VAULT_PATH` when one exists | Source facts readable | Required vault path is unavailable |
| **1 — Load** | Read task + relevant discussion; list assumptions/open questions | Goal and source facts captured | — |
| **2 — Readiness** | Confirm behavior/scope are clear enough; use `grill-me` first when not. If blocking questions remain, write `discussion/questions-spec-<slug>.md` (user fills **A:**) | Blockers are in the questions file (or none remain) | Cannot write the questions file |
| **3 — Write** | Create a new `spec-<slug>.md`; never overwrite an existing spec. Point **Open questions** at the discussion file — do not put fill-in answers in the spec | File exists and reads back correctly | Write cannot be verified |
| **4 — Ledger** | Add the spec path to the task **Specs** / **Active spec** / execution log. Do **not** put `status` on the spec | Task points to current spec; only the task has work status | Task update fails |
| **5 — Handoff** | Recommend `spec-review`, `design`, or execution depending on complexity | Next stage stated | — |

## File location

Prefer the existing task folder:

```text
$OBSIDIAN_BASE_VAULT_PATH/Projects/<PROJECT_NAME>/<WORK_ID>/spec-<slug>.md
```

On collision use `spec-<slug>-2.md`, `-3`, … — never overwrite unless the user explicitly asks to revise that exact file.

## Spec template

```markdown
---
artifact: spec
date: YYYY-MM-DD
task: <vault-relative task path>
---

# Spec: <Title>

## Problem
<What problem exists and for whom?>

## Goal
<Outcome that should be true when complete.>

## Non-goals
- <Explicitly excluded scope>

## Expected Behavior
- <Behavior / contract / workflow>

## Acceptance Criteria
- <Observable, verifiable condition>

## Constraints
- <Compatibility, policy, performance, deadline, dependency, etc.>

## Edge Cases / Failure Cases
- <Important case>

## Assumptions
- <Assumption being accepted>

## Open Questions
- *(none)* **or** `discussion/questions-spec-<slug>.md` — fill each **A:** line
```

## Boundary

Do not choose components, APIs, schema, algorithms, or implementation steps unless they are already fixed requirements. Those belong in `design` or `coding-plan`.

Do **not** put `status` on the spec. Work status and which spec is current live on `task-*.md` (**Active spec** + execution log).

Blocking questions belong in `discussion/questions-spec-<slug>.md` (fill **A:**), not as a hard-to-edit list in the spec body. List that file on the task **Open questions**.

## Context Budget

**Required:** `task-*.md`, `context.md` if present, and clarified user intent.

**Read only when needed:** existing contracts/docs required to state externally observable behavior correctly.

**Avoid loading:** implementation internals unless they impose a real constraint on the spec.

**Context update:** after the spec stabilizes, rewrite `context.md` with the goal, active spec path, confirmed constraints/non-goals, and unresolved questions. Do not duplicate the spec body. See [`../../CONTEXT.md`](../../CONTEXT.md).
