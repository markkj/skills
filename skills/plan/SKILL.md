---
name: plan
description: >-
  Turns an existing task record — plus active spec/design when present — into a new executable plan file, {{plan-generate-name}}.md, in the task folder. Chooses coding-plan only when the task clearly asks to write or change code. Use when the user names plan, asks to plan from a saved task record, or a workflow route reaches this stage.
---

# Plan

Load this skill when the user names `plan`, asks to plan from a saved task record, a workflow route reaches this stage, or the work needs a plan before it can start.

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

Use this skill only after a task record exists. Inputs are `{{task-generate-name}}.md` plus the task’s **Active spec** / **Active design** when present. The output is **one new** planning artifact appended to that task (a task may already have other plans). This skill is a planning-entry gate; it does not invent missing requirements or architecture.

## Same folder as the task

Write **only** into the folder that already has `task-*.md`:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/
├── task-<slug>.md
├── plan-<slug>.md
└── discussion/questions-plan-<slug>.md
```

Never write `discussion/` at the git repo root or vault root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent fallbacks, no product code changes. Phase **2b** is the exception: a yes ends this harness and continues in `coding-plan`.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named `plan`, or a workflow route reached this stage; locate `{{task-generate-name}}.md` via `scripts/resolve-project-path.sh` + project-relative path | File exists and is readable | No task file or env unset → tell user to name [`work-intake-automation`](../work-intake-automation/SKILL.md) first |
| **1 — Load** | Read task file; load **Active spec** and **Active design** when present; restate goal/criteria/constraints; list existing **Plans** + **Active plan** | Inputs are internally consistent and gaps listed | — |
| **2 — Planning readiness** | Check whether enough decisions exist to create executable todos. If requirements are unclear → hand off to `grill-me` / `requirement-spec`; if solution architecture is unresolved and needed → hand off to `design`. Write remaining blockers to `discussion/questions-plan-<slug>.md`. If plans already exist, confirm add-new vs explicit revision. | No implementation-critical ambiguity remains, or blockers are in the questions file | Missing requirement/design decision with no questions file → STOP; do not bury it inside the plan |
| **2b — Coding plan or not** | Apply [Coding plan or not](#coding-plan-or-not). If yes, stop this harness and follow `coding-plan`. | The choice is written on the task | You cannot tell and the user has not answered |
| **3 — Artifact choice** | Only when coding-plan is not used. Pick one primary output: a plan file, or a discussion doc only | Choice matches the task or the user's stated preference | Ambiguous and user did not choose → ask; STOP until chosen |
| **4 — Write** | Create a **new** plan in the task folder via `scripts/resolve-project-path.sh`; on name collision use [unique plan names](#unique-plan-names-never-overwrite) | New artifact exists; prior plans untouched; no literal `{{…}}` in filenames | `scripts/resolve-project-path.sh` unset or write failed → STOP |
| **5 — Ledger** | **Append** new plan to **Plans**; set **Active plan** to the new file; `status: Planned`; execution log | Task file lists all plans; Active plan = newest | Task update failed → STOP and report |
| **6 — Handoff** | Emit [completion report](#completion-report) | User can resume from task + active (or chosen) plan | — |

**Forbidden during any phase:** create a new task file, change product code, or open [`coding-plan`](../coding-plan/SKILL.md) when [Coding plan or not](#coding-plan-or-not) says no. When it says yes, follow `coding-plan` and do not write a second plan in this skill.

## Completion report

After phase 6, output this block in chat:

```markdown
## Plan complete

- **Task:** `<project-relative path to task file>`
- **New plan:** `<vault path>`
- **Active plan:** `<same as new plan unless user chose otherwise>`
- **All plans:** `<N total for this task>`
- **Discussion:** `<path or none>`
- **Status:** Planned
- **Next:** Execute from the active plan. Re-run `plan` to add another plan for the same task.
- **Blockers:** <none | list>
```

## Boundary

- [`work-intake-automation`](../work-intake-automation/SKILL.md): source request -> durable task record.
- [`grill-me`](../grill-me/SKILL.md): resolve ambiguity when needed.
- [`requirement-spec`](../requirement-spec/SKILL.md): define what should be true when a durable contract is useful.
- [`design`](../design/SKILL.md): define how to satisfy the requirement spec when solution design is needed.
- `plan` (this skill): task + active spec/design -> one plan. Opens `coding-plan` only for a clear code job. One task → many plans.
- [`coding-plan`](../coding-plan/SKILL.md): the plan body for a clear code job — diagrams, test-first todos, and a git worktree. Not a second plan file.
- Execution happens later; do not change product code while planning.

If `{{task-generate-name}}.md` does not exist, run [`work-intake-automation`](../work-intake-automation/SKILL.md) first to create it.

## Filename Generation

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders from `work-intake-automation`. Resolve them to the concrete filenames recorded in the task file.

Rules:

- Prefer the exact **task** path already recorded under `## Planning and Discussion Paths`.
- Prefer a free `plan-*.md` name in that task folder; do not assume a single plan slot.
- If the task file still contains placeholders, generate real filenames before writing the plan:
  - task file: `task-<short-slug>.md`
  - plan file: `plan-<short-slug>.md` (or `-2`, `-3`, … / purpose suffix when needed)
- Use the same short slug family for the task and its plans.
- Include an issue key only when it helps uniqueness.
- Do not use source names like `manual` or `jira`.
- Never write literal placeholder filenames like `{{plan-generate-name}}.md`.
- Never fall back to generic names like `task.md` or `plan.md`.
- **Never overwrite** an existing plan file — see [Unique plan names](#unique-plan-names-never-overwrite).

Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

## Unique plan names (never overwrite)

**One task → many plans.** Each run of this skill adds a **new** plan file under the task folder. Prior plans stay on disk and stay listed in the task ledger.

If the intended plan path already exists, **do not replace it**. Create a new file with a unique name, **append** it to **Plans**, and set **Active plan** to the new file.

### Plan file names

Preferred base: `plan-<short-slug>.md`. On collision (or when adding another plan for the same task), append `-2`, `-3`, … until free:

```text
plan-add-export.md      # first plan for the task
plan-add-export-2.md    # second plan (revision or alternate approach)
plan-add-export-3.md    # third
```

Optional: if the user names a purpose, use `plan-<short-slug>-<purpose>.md` when that name is free (e.g. `plan-add-export-backend.md`). Still never overwrite.

### Rules

1. Check existence before write: `test -e "$PROJECT_PATH/<project-relative-path>"`.
2. Never `rm`, truncate, or overwrite an existing plan for a new plan.
3. Leave prior plans in place; **append** to **Plans**; set **Active plan** to the newest (unless the user names a different active).
4. Mention the chosen filename in the completion report when it is not the first plan for the task.

## One task, many plans

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/
├── task-<slug>.md          # ledger: Plans list + Active plan
├── plan-<slug>.md          # plan 1
├── plan-<slug>-2.md        # plan 2
└── discussion/
```

- Re-running `plan` on the same task **adds** a plan; it does not replace the only plan.
- Execution / `coding-plan` uses **Active plan** unless the user picks another from **Plans**.

## Planning Workflow

Follow [Harness phases](#harness-phases). The steps below are phase details — not a separate optional list.

**Phase 1 — Load** fields:
   - goal and acceptance criteria from task/spec
   - constraints and assumptions
   - **Active spec** when present
   - **Active design** when present
   - unknowns/blockers
   - existing **Plans** list, **Active plan**, discussion path

**Phase 2 — Planning readiness:** A plan is not the place to resolve foundational ambiguity. If acceptance criteria/scope are unclear, recommend `grill-me` or `requirement-spec`. If architecture/solution decisions are required but unresolved, recommend `design`. Only ask narrow planning-specific questions (execution owner, artifact format, sequencing constraints). If **Plans** is non-empty, confirm the user wants an **additional** plan (default) rather than editing an old one in place.

**Phase 3 — Artifact choice:**
   - **Plan file:** write a **new** `plan-*.md` in the task folder ([template below](#plan-generate-namemd-template)).
   - **Discussion doc:** write `discussion/<topic>.md` or `discussion/adr-0001-<decision>.md` only for decisions, research, or context that would make a plan file noisy.

**Phase 5 — Ledger** updates to `{{task-generate-name}}.md` only:
   - `status: Planned`
   - **Append** the new vault path under **Plans**
   - Set **Active plan** to the new plan
   - execution log entry with the created artifact path

## Project Path writes

Run `scripts/resolve-project-path.sh`. It prints one absolute directory. If it exits non-zero, **STOP**. The script creates that directory from `OBSIDIAN_BASE_VAULT_PATH/Projects` only when no Project Path is saved yet.

1. **Project Path:** Use the printed directory. If the script fails → **STOP** and report.
2. **Absolute path:** `$PROJECT_PATH/<project-relative-path>` (project-relative path has no leading slash).
3. **Create:** `mkdir -p` parent directories, then write plan or `discussion/` files.
4. **Verify:** Read back the file or `test -f` on the absolute path; content must match what was written.
5. **Reads:** Load `{{task-generate-name}}.md` and existing plans from the same vault root + project-relative path.

## `{{plan-generate-name}}.md` Template

Use this for the task folder plan.

```markdown
# Plan: <Title>

## Source

- **Task:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/{{task-generate-name}}.md`
- **Planning owner:** <user or agent>
- **Execution owner:** <user or agent>

## Goal

<One paragraph describing the outcome from {{task-generate-name}}.md.>

## Assumptions and Unknowns

- **Assumption:** <Known working assumption>
- **Open questions:** See `discussion/questions-plan-<slug>.md` — fill each **A:** line. *(none)*

## Approach

1. <Outcome-oriented step>
2. <Outcome-oriented step>

## Todos

- [ ] <Executable outcome> - verify: <test, command, review, or acceptance check>

## Verification

- <How completion is proven>

## Resume Instructions

Start by reading `{{task-generate-name}}.md`, this `{{plan-generate-name}}.md`, and any relevant `discussion/` docs. Track todo progress here.
```

## Coding plan or not

Decide once, after planning readiness. Record the choice on the task.

Use [`coding-plan`](../coding-plan/SKILL.md) when the task clearly asks to write or change code: a bug, a feature in a repo, an API, or a behavior to implement. Stop this harness and follow that skill. It writes the one `plan-*.md` (diagrams, test-first todos, worktree). Do not write a second plan here.

Do not use `coding-plan` when the task is a direction, a question, a doc, a process, or “figure out how.” Continue this harness and use the templates above.

If those two readings would change the work and you cannot tell, ask once.

## Discussion Docs

Use `discussion/` for material that supports the plan but is not the work queue:

- `discussion/questions-plan-<slug>.md` when the user must answer blockers (fill **A:**). Template: [`templates/open-questions.md`](../../templates/open-questions.md).
- `discussion/notes.md` for research notes or copied source context.
- `discussion/adr-0001-<decision>.md` when there are real tradeoffs.

Two other folders sit next to `discussion/`. Do not put these files in `discussion/`:

- `reports/` holds results, such as reviews, verification, and metric reports.
- `docs/` holds lasting reference, such as setup steps, runbooks, and how-to guides.

ADR template:

```markdown
# <Decision Title>

- **Status:** Proposed | Accepted | Superseded
- **Date:** YYYY-MM-DD

## Context

<Why this decision exists.>

## Options

### Option A

- **Pros:** ...
- **Cons:** ...

## Decision

- **Chosen:** <pending or selected option>
- **Consequences:** <What follows>
```

## Rules

- Do not create a new `{{task-generate-name}}.md`; this skill starts from an existing one.
- Do not execute implementation work while planning.
- Keep `{{task-generate-name}}.md` as status/source/path ledger; keep executable todos in plan files. One task may have **many** plans; track them under **Plans** and **Active plan**.
- Do **not** put work `status` on plan / spec / design / grill-me docs. The only work-status field is `status:` on the task file.
- Never overwrite an existing plan file; mint a unique name and append to **Plans** ([Unique plan names](#unique-plan-names-never-overwrite)).
- Update `{{task-generate-name}}.md` after each new plan so future sessions see the full list and the active plan.

## Context Budget

**Required:** task, `context.md` if present, active spec/design when present, and existing plan ledger metadata.

**Read only when needed:** enough artifact metadata to pick a free plan name and pass the readiness gate.

**Avoid loading:** repository implementation details; `coding-plan` owns codebase-oriented planning.

**Context update:** set the active plan path and current stage in `context.md` when a plan artifact is created/selected. Do not duplicate plan contents. See [`../../CONTEXT.md`](../../CONTEXT.md).
