---
name: coding
description: >-
  Coding workflow — understand, ask whether to split plan todos by architecture
  layer (controller, service, repo, db), Cursor Plan with small e2e todos per
  slice, test-first, match project structure and test style. Use when writing,
  changing, reviewing, debugging, implementing features, or fixing bugs.
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

### Ask: split by component?

After **Understand**, map how this repo layers features (read a similar flow end-to-end). Example chain:

```text
controller / handler / route  →  service / use-case  →  repository / client  →  db / external API
```

**Ask the user:**

> Do you want this split into **small plan todos per component** (following the codebase layers), or **one todo** for the full feature end-to-end?

| User choice | Plan shape |
|-------------|------------|
| **Split by component** | One **Cursor Plan todo per layer** (small, bottom-up or repo order) |
| **One todo** | Single plan todo — full feature verified e2e at the boundary the project uses (HTTP test, CLI, etc.) |
| **Unsure** | Recommend split when the feature crosses **3+ layers**; one todo when it’s a single-file or localized change |

Do not assume split — **always ask** for non-trivial features that cross layers.

### Split by component (when user says yes)

**Rules:**

- **Follow the repo’s real stack** — don’t invent layers the codebase doesn’t have (e.g. no separate “service” folder if logic lives in handlers).
- **One plan todo = one component/layer** for this feature — not “write test” vs “write code” as separate todos.
- **Order:** default **bottom-up** (db/repository → service → controller/API) so each step has a real foundation; match order if the project always builds top-down in similar PRs.
- **Each todo is still small + e2e** for *that layer* — verify with the test level that layer uses (repo unit test → service test with mocks → API integration test).
- **Test-first inside each todo** — failing test for that layer → minimal code → verify before the next layer.

**Example — “Create API to get user info”** (stack: controller → service → repository → db):

| # | Plan todo | Verify (e2e for that layer) |
|---|-----------|-----------------------------|
| 1 | Repository: load user by id | Repo/data test passes (or migration + query check) |
| 2 | Service: get user info use-case | Service unit test passes (mock repo) |
| 3 | Controller: `GET /user/:id` | HTTP/integration test returns 200 + expected body |

Plan title: `Add GET user info API`

**Bad splits:** “Write all tests” · “Implement backend” · “Do controller” without layer-level verify  
**Good splits:** one outcome per component, test-first within the todo

### Plan todos (every todo)

| Todo | What “good” looks like |
|------|-------------------------|
| **Simple** | One component **or** one full feature (if not splitting); no drive-by refactors |
| **E2e** | Observable when done — **tests are the default verify** at that layer or boundary |
| **Verifiable** | **verify:** names the test/command for this slice |

**Bad plan todo:** “Implement auth” (whole feature, no verify) · “Add failing test” (micro-step — lives inside a component todo)

**Good plan todo (no split):** “GET user info works end-to-end — **verify:** API integration test green”

### Cursor Plan

1. **Plan** mode for non-trivial coding work.
2. After user chooses split or not → create todos accordingly (per layer **or** one e2e todo).
3. Test-first steps live **inside** each todo — not as separate plan items.
4. Canonical plan lives in **Cursor Plan**, not a fenced code block in chat.

### Not in Cursor

Same todo rules as a numbered list in the reply, with **verify** inline.

### Ask during planning

Not sure about scope, API shape, **layer map**, test strategy, or acceptance criteria — **ask** before coding. Update the plan after the answer.

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
- If scope grows — **stop**, ask, split into another plan todo (or add a layer todo if splitting).

**Bug fix:** repro as failing test first when possible, then fix.

**Refactor:** tests green before and after; no behavior change unless asked.

**Explicit escape hatch:** user says “no test” / “skip TDD” — note it and proceed; still verify e2e another way if cheap.

---

## Trivial work

Obvious one-liner, user already agreed — skip formal plan; add a test first only if it’s quick and valuable.

---

**Working well if:** you asked about component split, todos match the repo’s layers when split, each slice verifies with tests at the right level, and new code looks like it belonged in the repo already.
