# CLAUDE.md

**Mental model:** Capture → Understand → Define → Design → Plan → Execute → Verify → Review.

These are **stages, not mandatory ceremony**. Use the minimum rigor needed for the work. Small, obvious tasks may skip directly from understanding to execution; larger or riskier work should produce durable artifacts before implementation.

Cursor and Claude Code read this at the project root. Workflow skills load when the user names them. Install/link them with `./scripts/link-skills.sh cursor`.

Shared context discipline: [`CONTEXT.md`](CONTEXT.md).

---

## Always: Short by default

Default to **short and complete** — answer the question fully in as few words as practical.

| Default (short) | On request (long) |
|-----------------|-------------------|
| Direct answer, decision, or next step | Tradeoffs, alternatives, architecture |
| One grounding reference/example/pattern when useful | Implementation detail, code walkthrough, diagrams |
| Assumptions only when they change the answer | Full technical rationale and edge cases |

**Complete, not shallow.** Short means no filler — not a teaser, and not “it depends” without naming the dependency.

Expand when the user asks, e.g. “long version”, “deep dive”, “more technical”, “explain why”, “show tradeoffs”. Match the requested depth.

Stay longer without asking when a loaded skill defines its own artifact format, correctness/safety requires it, or implementation work needs a concrete change summary.

---

## Always: Ground substantive answers

For substantive technical or decision-oriented replies, ground the answer in at least one of:

- **Reference** — named framework, documentation, standard, concept, or repo convention (+ why it fits),
- **Example** — concrete scenario, or
- **Pattern** — a short reusable template.

Never invent citations, quotes, repository behavior, or tool output.

---

## Always: Context discipline

Treat context as a budget. Follow [`CONTEXT.md`](CONTEXT.md).

Core rule:

> Carry forward durable artifacts and compact active context — not the whole conversation or repository.

Read progressively:

1. current task artifact,
2. `context.md` when present,
3. active stage artifact (`spec`, `design`, `plan`),
4. directly referenced files/symbols,
5. direct callers/callees and nearby tests,
6. broader repository search only when blocked.

Do not repeatedly load resolved discussions, archived plans, unrelated services, or full repository trees.

`context.md` is a **bounded handoff cache**, not a source of truth and not a running log. Keep authoritative decisions in the stage artifact that owns them.

---

## 1. Capture / Understand

First understand what kind of work exists and what is actually known.

- Restate the goal in one sentence when useful.
- Separate known facts, assumptions, constraints, and unknowns.
- Read only what is needed to answer or choose the next stage.
- Do not guess unchecked repository or runtime behavior.
- Do not force software-planning ceremony onto non-coding work.

For durable work intake, use [`skills/work-intake-automation/SKILL.md`](skills/work-intake-automation/SKILL.md) when requested.

### If the work is unclear

Do **not** automatically design or plan around hidden assumptions.

When the user explicitly wants interrogation / Socratic clarification (“grill me”, “question me”, “challenge this”), use [`skills/grill-me/SKILL.md`](skills/grill-me/SKILL.md).

`grill-me` exists to expose:

- unclear goals,
- hidden assumptions,
- missing constraints,
- scope / non-goals,
- success criteria,
- edge cases,
- unresolved decisions.

It does **not** own solution design or implementation planning.

---

## 2. Define — Spec (when needed)

Use a spec when the work needs an explicit definition of **what should be true** before choosing how to implement it.

Typical signals:

- behavior is non-trivial,
- acceptance criteria need to be explicit,
- several people/agents must share the same understanding,
- the task is likely to outlive the current conversation,
- correctness depends on edge cases or non-goals.

Use [`skills/spec/SKILL.md`](skills/spec/SKILL.md) when requested.

A spec owns the problem/behavior contract, not architecture.

For important specs, use [`skills/spec-review/SKILL.md`](skills/spec-review/SKILL.md) to ask:

> Did we define the right thing clearly enough to design or execute?

Skip spec/spec-review for trivial, already-explicit work.

---

## 3. Design (when needed)

Use design when there are meaningful choices about **how the spec should be satisfied**.

Typical signals:

- multiple viable approaches,
- API/data-model changes,
- architecture or component boundaries,
- compatibility/migration concerns,
- concurrency, reliability, scaling, or operational tradeoffs,
- high blast radius.

Use [`skills/design/SKILL.md`](skills/design/SKILL.md) when requested.

For important designs, use [`skills/design-review/SKILL.md`](skills/design-review/SKILL.md) to ask:

> Is this a sound solution to the approved spec, with acceptable tradeoffs and failure modes?

### ADRs

Use an ADR when a durable architectural decision with real alternatives should be recorded.

Do **not** create an ADR merely because a task is non-trivial. If the approach is obvious and reversible, a design/plan may be enough.

If an ADR is needed, match the repository's existing ADR location and format. If none exists, use `docs/adr/NNNN-short-title.md`.

Minimum ADR shape:

```markdown
# [Title]

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** What problem / constraint drives this decision?

## Options

### Option A: [name]
- **Pros:** …
- **Cons:** …
- **Best when:** …

### Option B: [name]
- **Pros:** …
- **Cons:** …
- **Best when:** …

## Recommendation

Which option and why.

## Decision

- **Chosen:** pending
- **Consequences:** accepted tradeoffs / follow-up work
```

---

## 4. Plan

Planning converts an understood/defined/designed task into executable work.

Use [`skills/plan-intake-automation/SKILL.md`](skills/plan-intake-automation/SKILL.md) when requested to enter the planning workflow from a durable task record.

`plan-intake-automation` is a **planning-readiness gate**. It should consume active task/spec/design artifacts when present; it should not silently redo requirements or architecture inside the plan.

### Software implementation plans

For diagram-backed, test-first software plans with Obsidian/Cursor integration and worktree conventions, use [`skills/coding-plan/SKILL.md`](skills/coding-plan/SKILL.md).

A coding plan should:

- be derived from the active task/spec/design,
- use small end-to-end outcomes,
- include verification with each outcome,
- preserve the existing git worktree / branch conventions defined by the skill,
- prefer the simplest approach consistent with the approved design,
- avoid reopening settled decisions unless new evidence invalidates them.

For non-trivial plans, use [`skills/plan-review/SKILL.md`](skills/plan-review/SKILL.md) to ask:

> Is this plan complete, correctly ordered, executable, and verifiable?

Skip formal planning for trivial, agreed one-liners.

---

## 5. Execute

Work the approved plan or the direct task when no formal plan is necessary.

- Keep scope bounded to the active artifact.
- Follow repository conventions before introducing new patterns.
- Verify each meaningful outcome before considering it complete.
- If a prerequisite/assumption proves false, stop following that part of the plan and update the authoritative artifact/context instead of improvising silently.
- Do not reread broad context when the current artifacts already answer the question.

For coding-plan execution, preserve the skill's existing worktree, branch, Cursor todo, test-first, and verification rules.

---

## 6. Verify

Verification asks:

> Did the result actually satisfy the intended behavior — not merely “did the command exit 0?”

Use [`skills/verify/SKILL.md`](skills/verify/SKILL.md) when requested.

Verify against the strongest available contract:

1. spec / acceptance criteria,
2. design invariants,
3. plan outcomes,
4. tests/build/lint/runtime signals.

Prefer targeted evidence first, then broader validation when risk warrants it.

---

## 7. Review

Review the **artifact appropriate to the stage**. Avoid a vague generic “review”.

| Skill | Reviews | Main question |
|------|---------|---------------|
| [`spec-review`](skills/spec-review/SKILL.md) | spec | Did we define the right thing? |
| [`design-review`](skills/design-review/SKILL.md) | design | Is this a sound solution? |
| [`plan-review`](skills/plan-review/SKILL.md) | implementation plan | Can this be executed safely and completely? |
| [`code-review`](skills/code-review/SKILL.md) | actual code/diff/tests | Does the implementation satisfy the earlier artifacts correctly? |

For code review, use the smallest sufficient evidence set: active spec/design/plan + diff + relevant tests, not the entire task history.

---

## Workflow routing

Use the **minimum necessary rigor**.

### Small / obvious software change

```text
Understand → Execute → Verify → Code Review (if useful)
```

### Normal feature

```text
Work Intake
  → Grill Me (only if unclear)
  → Spec
  → Design (if needed)
  → Plan Intake
  → Coding Plan
  → Plan Review
  → Execute
  → Verify
  → Code Review
```

### High-risk / architectural work

```text
Work Intake
  → Grill Me
  → Spec
  → Spec Review
  → Design / ADR
  → Design Review
  → Plan Intake
  → Coding Plan
  → Plan Review
  → Execute
  → Verify
  → Code Review
```

### Non-coding work

```text
Work Intake
  → Grill Me (if unclear)
  → Spec / Research / other domain workflow as needed
  → Execute
  → Verify / Review as appropriate
```

Do not force `coding-plan` into non-coding work.

---

## Skills

| Skill | When |
|-------|------|
| [`skills/work-intake-automation/SKILL.md`](skills/work-intake-automation/SKILL.md) | Durable generic work intake → Obsidian task record + route recommendation |
| [`skills/grill-me/SKILL.md`](skills/grill-me/SKILL.md) | Explicit interrogation / ambiguity reduction; no design or planning |
| [`skills/spec/SKILL.md`](skills/spec/SKILL.md) | Define what must be true: behavior, scope, constraints, acceptance criteria |
| [`skills/spec-review/SKILL.md`](skills/spec-review/SKILL.md) | Adversarial review of the spec |
| [`skills/design/SKILL.md`](skills/design/SKILL.md) | Choose how to satisfy the spec; architecture/tradeoffs/ADRs when warranted |
| [`skills/design-review/SKILL.md`](skills/design-review/SKILL.md) | Review design quality, risks, tradeoffs, and spec fit |
| [`skills/plan-intake-automation/SKILL.md`](skills/plan-intake-automation/SKILL.md) | Planning-readiness gate from durable task/spec/design artifacts |
| [`skills/coding-plan/SKILL.md`](skills/coding-plan/SKILL.md) | Software coding plan + Obsidian/Cursor/worktree/test-first execution harness |
| [`skills/plan-review/SKILL.md`](skills/plan-review/SKILL.md) | Review plan completeness, sequencing, risk, and verification |
| [`skills/verify/SKILL.md`](skills/verify/SKILL.md) | Verify implementation/result against authoritative artifacts |
| [`skills/code-review/SKILL.md`](skills/code-review/SKILL.md) | Review actual code/diff/tests against spec/design/plan |

Install/link: `./scripts/link-skills.sh cursor`

---

## Project-specific

<!-- Stack, conventions -->

-
