---
name: coding
description: >-
  Coding workflow — understand, Cursor Plan with simple e2e todos, test-first,
  match existing project structure and test style (unit, integration, e2e).
  Use when writing, changing, reviewing, debugging, or testing code,
  implementing features, or fixing bugs.
---

# Coding

Follow [CLAUDE.md](../../CLAUDE.md) for **Understand** and high-level **Plan**. This skill adds coding-specific rules.

**Core rule: test-first.** For behavior changes, write or extend a **failing test first**, then minimal code to pass, then verify e2e. Do not add production logic for new behavior without a failing test (unless the user explicitly opts out).

**Core rule: match the project.** New code and tests must follow the **same structure and conventions** already used in that repo — not a style you prefer or a pattern from another project.

---

## Match the project (before you write)

During **Understand**, inspect how this repo is organized. During **Plan**, state which existing patterns you will follow.

### Production code

- **Layout:** same folder/module boundaries (e.g. `src/features/x`, `internal/pkg`, layered packages).
- **Naming:** files, types, functions, exports — consistent with neighbors.
- **Patterns:** error handling, DI, logging, config, API shapes — copy nearby code, don’t invent a new style.
- **Dependencies:** use libraries already in the project; don’t add new ones unless asked.

### Tests — same structure and level as the project

Discover what the repo already uses, then mirror it:

| Check | Look for |
|-------|----------|
| **Test layout** | `*_test.go`, `tests/`, `__tests__/`, `spec/`, co-located vs separate tree |
| **Unit tests** | fast, isolated, mocks/fixtures used in this repo |
| **Integration tests** | DB, HTTP, containers, test clients — how they’re named and run |
| **E2e / acceptance** | Playwright, Cypress, supertest, etc. — only if the project already has them |
| **Style** | framework (Jest, pytest, Go testing, etc.), assertion style, table-driven tests, snapshots |
| **Fixtures & helpers** | existing factories, `testutil`, `conftest`, seed data — reuse, don’t duplicate |
| **How to run** | `package.json` scripts, `Makefile`, `pytest.ini`, CI config — use the same commands in **verify** |

**Rules:**

- Put new tests in the **same kind** of place as similar features (unit next to code vs `tests/integration/`, etc.).
- Use the **right test level** for the change: unit for pure logic, integration when the repo tests DB/API boundaries that way, e2e only when the project already does e2e for that surface.
- **Do not** introduce a new test framework, folder layout, or naming scheme unless the user asks.
- **Do not** add integration/e2e tests if the project only uses unit tests for that area (and vice versa) without confirming.

**Not sure** which layout, test level, or helper to use — **ask** after you’ve looked at 1–2 similar existing examples.

---

## Plan (coding)

Do not write production code until the plan exists (trivial agreed one-liners excepted).

### Plan todos

| Todo | What “good” looks like |
|------|-------------------------|
| **Simple** | One e2e outcome; no drive-by refactors |
| **E2e** | Observable when done — **tests are the default verify** |
| **Verifiable** | Todo includes **verify:** (usually: failing test → fix → tests green) |

**Bad plan todo:** “Implement auth” · “Add failing test” (micro-step — not its own todo)

**Good plan todo:** “Invalid login returns 401 with tests green — **verify:** failing test → minimal fix → tests pass; happy path OK”

### Cursor Plan

1. **Plan** mode for non-trivial coding work.
2. **One plan todo per e2e slice** — not separate todos for “write test”, “write code”, “smoke”.
3. Test-first steps live in that todo’s work and **verify** line, not as extra plan items.
4. Canonical plan lives in **Cursor Plan**, not a fenced code block in chat.

**Example — one todo:**

| Plan title | Single plan todo |
|------------|------------------|
| `Fix wrong-password login` | Wrong password returns 401, tests green — **verify:** failing test first → minimal fix → all relevant tests pass |

More plan todos only for **multiple independent e2e outcomes** (e.g. fix bug + add separate feature).

### Not in Cursor

Same todo rules as a numbered list in the reply, with **verify** inline.

### Ask during planning

Not sure about scope, API shape, test strategy, or acceptance criteria — **ask** before coding. Update the plan after the answer.

---

## Work a plan todo (test-first)

Inside **one** plan todo, default order:

```
1. Failing test (or extend test) — same file/type/level as peers — verify: fails for the right reason
2. Minimal production change — same structure as peers — verify: test passes
3. Regression check — verify: run project’s usual test command; related tests still pass
```

- **Minimum** code for the current todo only.
- Production + tests **match existing project structure** (see above).
- Do not mark the plan todo **completed** until **verify** passes.
- If scope grows — **stop**, ask, split into another plan todo.

**Bug fix:** repro as failing test first when possible, then fix.

**Refactor:** tests green before and after; no behavior change unless asked.

**Explicit escape hatch:** user says “no test” / “skip TDD” — note it and proceed; still verify e2e another way if cheap.

---

## Trivial work

Obvious one-liner, user already agreed — skip formal plan; add a test first only if it’s quick and valuable.

---

**Working well if:** plans use one e2e todo per slice, behavior changes start with a failing test in the **project’s** test style, and new code looks like it belonged in the repo already.
