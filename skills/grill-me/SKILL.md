---
name: grill-me
description: >-
  Requirement and intent interrogation — challenge ambiguity, assumptions,
  constraints, scope, success criteria, and edge cases before creating a spec,
  design, or plan. Use only when the user explicitly says grill me, names
  grill-me, or asks to pressure-test/clarify a task. Does not design or plan.
disable-model-invocation: true
---

# Grill Me

**Opt-in only.** This skill replaces the old `socratic` workflow skill for work clarification. General conversational Socratic behavior may still live in `CLAUDE.md`; this skill is specifically a **work-clarity gate**.

## Boundary

`grill-me` answers: **What are we missing or assuming?**

It may clarify:
- goal and desired outcome
- scope and non-goals
- success / acceptance criteria
- constraints and dependencies
- examples and edge cases
- unknowns and unresolved decisions
- evidence needed to consider the work complete

It must **not**:
- choose architecture or implementation details
- write an implementation plan
- create product code
- silently invent requirements

## Harness

| Phase | Do | Verify | STOP if |
|---|---|---|---|
| **0 — Load context** | Read the task/spec/context the user names | Goal and known facts identified | Source/context cannot be located |
| **1 — Find uncertainty** | Separate known facts, assumptions, unknowns, decisions | No important uncertainty is hidden inside prose | — |
| **2 — Grill** | Ask focused questions, 1–3 at a time; follow answers rather than a fixed script | Blocking unknowns are resolved or explicitly accepted as assumptions | User cannot answer a critical blocker |
| **3 — Synthesize** | Restate clarified goal, scope, criteria, constraints, remaining assumptions | User agrees or corrects the synthesis | User rejects synthesis → continue phase 2 |
| **4 — Handoff** | Recommend the next artifact: direct execution, `spec`, `design`, research, or planning | Next stage matches the work | — |

## Question lenses

Use only the lenses that matter:

- **Outcome:** What changes when this is done?
- **Scope:** What is explicitly in/out?
- **Behavior:** What should happen in normal and failure cases?
- **Evidence:** How will we know it works?
- **Constraints:** Compatibility, deadline, policy, performance, ownership, dependencies?
- **Assumptions:** What are we treating as true without proof?
- **Edge cases:** What would make the obvious solution wrong?
- **Priority:** If constraints conflict, what wins?

## Handoff rule

Do not force every task through every stage.

```text
unclear task -> grill-me -> clear task

clear small task            -> execute / domain workflow
clear requirement-heavy task -> spec
clear architecture-heavy task -> design (or spec first when behavior is not yet fixed)
clear coding task             -> plan-intake-automation / coding-plan when planning is requested
```

## Context Budget

**Required:** `task-*.md`; `context.md` if present; the user's current answers.

**Read only when needed:** exact source snippets or repository facts needed to ask a high-value question.

**Avoid loading:** whole repo scans, implementation details unrelated to ambiguity, archived discussions/plans.

**Context update:** create or rewrite `context.md` when clarification produces stable facts, constraints, decisions, or unresolved questions. Do not copy the Q&A transcript. See [`../../CONTEXT.md`](../../CONTEXT.md).
