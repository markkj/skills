---
name: plan-intake-automation
description: >-
  Turns an existing Obsidian {{task-generate-name}}.md from work-intake-automation into planning artifacts such as {{plan-generate-name}}.md, Cursor ~/.cursor/plans/*.plan.md files, and discussion docs. Use only when the user explicitly names plan-intake-automation, asks to plan from a saved task record, convert task facts into executable todos, or create Cursor plan files after intake.
disable-model-invocation: true
---

# Plan Intake Automation

**Do not auto-apply.** Load this skill only when the user explicitly names `plan-intake-automation`, asks to plan from a saved task record, or requests plan files / Cursor plans from an existing `{{task-generate-name}}.md`.

Use this skill only after a task record exists. The input is `{{task-generate-name}}.md`; the output is **one new** planning artifact appended to that task (a task may already have other plans).

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent fallbacks, no product code changes.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named this skill; locate `{{task-generate-name}}.md` (vault path from user or task index) | File exists and is readable | No task file → tell user to name [`work-intake-automation`](../work-intake-automation/SKILL.md) first |
| **1 — Load** | Read task file; restate goal, acceptance criteria, assumptions, unknowns; list existing **Plans** + **Active plan** | Restatement matches task file; gaps listed | — |
| **2 — Clarify** | If scope unclear, ask **1–3** questions. If plans already exist, confirm: **add another plan** vs revise guidance only (never overwrite) | User answered or explicitly said proceed | Unresolved blocker → STOP; do not write plan |
| **3 — Artifact choice** | Pick one primary output: Obsidian-only plan, Cursor plan (+ symlink), or discussion doc only | Choice matches execution owner in task file or user stated preference | Ambiguous and user did not choose → ask; STOP until chosen |
| **4 — Write** | Create a **new** plan at vault origin; on name collision use [unique plan names](#unique-plan-names-never-overwrite) | New artifact exists; prior plans untouched; no literal `{{…}}` in filenames | MCP/shell write failed → STOP |
| **5 — Link** (Cursor only) | Symlink a **new** `~/.cursor/plans/<slug>_<short-id>.plan.md` → this vault origin | `readlink` + `realpath` show same file | Symlink wrong or Cursor path is a duplicate copy → fix or STOP |
| **6 — Ledger** | **Append** new plan to **Plans**; set **Active plan** to the new file; `status: Planned`; execution log | Task file lists all plans; Active plan = newest | Task update failed → STOP and report |
| **7 — Handoff** | Emit [completion report](#completion-report) | User can resume from task + active (or chosen) plan | — |

**Forbidden during any phase:** create a new task file, change product code, auto-apply [`coding-plan`](../coding-plan/SKILL.md) unless user names it.

## Completion report

After phase 7, output this block in chat:

```markdown
## Plan intake complete

- **Task:** `<vault-relative path to task file>`
- **New plan:** `<vault path>` (origin) | Cursor: `~/.cursor/plans/…` → symlink to origin | Obsidian-only
- **Active plan:** `<same as new plan unless user chose otherwise>`
- **All plans:** `<N total for this task>`
- **Discussion:** `<path or none>`
- **Status:** Planned
- **Next:** Name `coding-plan` for diagram-backed implementation, or execute from the active plan. Re-run `plan-intake-automation` to add another plan for the same task.
- **Blockers:** <none | list>
```

## Boundary

- [`work-intake-automation`](../work-intake-automation/SKILL.md): source request -> `{{task-generate-name}}.md` (explicit opt-in only).
- `plan-intake-automation` (this skill): `{{task-generate-name}}.md` -> **another** vault `plan-*.md` (origin), optional Cursor symlink, optional `discussion/` docs. One task → many plans.
- Execution happens later; do not change product code while planning.

If `{{task-generate-name}}.md` does not exist, tell the user to name [`work-intake-automation`](../work-intake-automation/SKILL.md) first — do not auto-apply intake.

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

If the intended plan path already exists (regular file or symlink), **do not replace it**. Create a new file with a unique name, **append** it to **Plans**, and set **Active plan** to the new file.

### Vault origin

Preferred base: `plan-<short-slug>.md`. On collision (or when adding another plan for the same task), append `-2`, `-3`, … until free:

```text
plan-add-export.md      # first plan for the task
plan-add-export-2.md    # second plan (revision or alternate approach)
plan-add-export-3.md    # third
```

Optional: if the user names a purpose, use `plan-<short-slug>-<purpose>.md` when that name is free (e.g. `plan-add-export-backend.md`). Still never overwrite.

### Cursor symlink

Each plan that uses Cursor gets its **own** symlink: `~/.cursor/plans/<slug>_<short-id>.plan.md` → that vault origin. On collision, mint a **new** `<short-id>`.

### Rules

1. Check existence before write (vault MCP/list or shell `test -e`).
2. Never `rm`, truncate, or overwrite an existing plan or Cursor symlink for a new plan.
3. Leave prior plans in place; **append** to **Plans**; set **Active plan** to the newest (unless the user names a different active).
4. Mention the chosen filename in the completion report when it is not the first plan for the task.

## One task, many plans

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
├── task-<slug>.md          # ledger: Plans list + Active plan
├── plan-<slug>.md          # plan 1 (origin)
├── plan-<slug>-2.md        # plan 2 (origin)
└── discussion/
```

- Re-running `plan-intake-automation` on the same task **adds** a plan; it does not replace the only plan.
- Execution / `coding-plan` uses **Active plan** unless the user picks another from **Plans**.
- Obsidian-only and Cursor-linked plans can coexist in the same **Plans** list.

## Planning Workflow

Follow [Harness phases](#harness-phases). The steps below are phase details — not a separate optional list.

**Phase 1 — Load** fields:
   - goal
   - acceptance criteria
   - assumptions
   - unknowns/blockers
   - existing **Plans** list, **Active plan**, discussion path

**Phase 2 — Clarify:** If acceptance criteria or scope are unclear, ask 1-3 focused questions before writing a plan. If **Plans** is non-empty, confirm the user wants an **additional** plan (default) rather than editing an old one in place (editing in place is only when the user explicitly asks to revise that file).

**Phase 3 — Artifact choice:**
   - **Obsidian-only plan:** write a **new** `plan-*.md` in the task folder (markdown template below; no `~/.cursor/plans/` file).
   - **Cursor plan:** write a **new** origin in the vault, then symlink from Cursor — see [Obsidian origin with Cursor symlink](#obsidian-origin-with-cursor-symlink).
   - **Discussion doc:** write `discussion/<topic>.md` or `discussion/adr-0001-<decision>.md` only for decisions, research, or context that would make a plan file noisy.

**Phase 6 — Ledger** updates to `{{task-generate-name}}.md` only:
   - `status: Planned`
   - **Append** the new vault path (and Cursor symlink if any) under **Plans**
   - Set **Active plan** to the new plan
   - execution log entry with the created artifact path

## Obsidian Writes

When an Obsidian MCP server is available, prefer it for vault origin `{{plan-generate-name}}.md` and `discussion/` files. Use vault-relative paths. If MCP cannot verify the write, report the blocker rather than silently creating a local copy.

Obsidian MCP cannot create symlinks. For **Cursor plans**, write the origin under the vault first, then create `~/.cursor/plans/<slug>_<short-id>.plan.md` as a symlink with shell `ln -s` (see below). Verify both paths resolve to the same file.

Use shell only for Cursor-side symlinks and manual terminal workflows — not as a silent fallback for vault content writes.

## Obsidian origin with Cursor symlink

When the user asks for a Cursor plan or the execution owner is Cursor, use **one origin plan file** in the vault, linked from `~/.cursor/plans/`. Do not maintain two copies of the plan body.

### Origin file (write content here)

```text
<vault>/Projects/<PROJECT_NAME>/<WORK_ID>/{{plan-generate-name}}.md
```

Use the [Cursor Plan Template](#cursor-plan-template) below (YAML frontmatter + body) so Cursor Plan UI can read the same file through the symlink.

### Cursor path (symlink only)

```text
~/.cursor/plans/<slug>_<short-id>.plan.md
```

Create this path as a **symlink** to the vault origin — not a separate markdown document.

### Symlink rules

1. Resolve a **free** vault origin name first ([Unique plan names](#unique-plan-names-never-overwrite)); write the origin there (prefer Obsidian MCP).
2. Ensure `~/.cursor/plans/` exists (create if needed).
3. Pick a free Cursor path (`<slug>_<short-id>.plan.md`); if taken, mint a new `<short-id>` — never overwrite.
4. Create the Cursor plan path with `ln -s`:
   - Use an **absolute** target to the vault origin file (origin lives in the vault).
   - Expand `~` and resolve the vault root when writing the symlink if the shell requires it.
5. **Verify:** `readlink` on the Cursor path and `realpath` (or equivalent) on both paths show the same inode/file.
6. **Append** both paths to **Plans** in `{{task-generate-name}}.md` and set **Active plan** to the new vault origin. Example row: `plan-add-export-2.md` → `~/.cursor/plans/add-export_a1b2.plan.md`.

### Layout example

```text
<vault>/Projects/my-app/WORK-123/plan-add-export.md   # origin (write content here)

~/.cursor/plans/add-export_a1b2.plan.md
  -> /Users/me/vault/Projects/my-app/WORK-123/plan-add-export.md
```

### When Obsidian-only is enough

If the execution owner is not Cursor and the user does not want a Cursor plan file, write `{{plan-generate-name}}.md` as normal markdown in the vault only (no `~/.cursor/plans/` file, no symlink).

## `{{plan-generate-name}}.md` Template

Use this for the Obsidian task folder plan.

```markdown
# Plan: <Title>

## Source

- **Task:** `Projects/<PROJECT_NAME>/<WORK_ID>/{{task-generate-name}}.md`
- **Status:** Planned
- **Planning owner:** <user or agent>
- **Execution owner:** <user or agent>

## Goal

<One paragraph describing the outcome from {{task-generate-name}}.md.>

## Assumptions and Unknowns

- **Assumption:** <Known working assumption>
- **Unknown:** <Question or dependency>

## Approach

1. <Outcome-oriented step>
2. <Outcome-oriented step>

## Todos

- [ ] <Executable outcome> - verify: <test, command, review, or acceptance check>

## Verification

- <How completion is proven>

## Resume Instructions

Start by reading `{{task-generate-name}}.md`, this `{{plan-generate-name}}.md`, and any relevant `discussion/` docs. Track implementation todo progress here (when Cursor is linked, this vault file is the origin Cursor reads through the symlink).
```

## Cursor Plan Template

Use this when the user asks for a Cursor plan or when the execution owner is Cursor. Write content to the vault origin `{{plan-generate-name}}.md`; then symlink `~/.cursor/plans/<slug>_<short-id>.plan.md` to that file ([Obsidian origin with Cursor symlink](#obsidian-origin-with-cursor-symlink)).

Origin file path:

```text
<vault>/Projects/<PROJECT_NAME>/<WORK_ID>/{{plan-generate-name}}.md
```

Cursor symlink path:

```text
~/.cursor/plans/<slug>_<short-id>.plan.md
```

Template:

````markdown
---
name: <Short plan name>
overview: <One-sentence outcome and approach.>
todos:
  - id: <stable-kebab-case-id>
    content: <Outcome-oriented todo>
    status: pending
isProject: false
---

# <Title> Plan

## Goals

- <User-visible outcome or acceptance condition>

## Implementation Approach

### 1) <Feature group>

- <What this changes>
- verify: <test, command, or acceptance check>

## Implementation Outline

```mermaid
flowchart LR
  Task[{{task-generate-name}}.md] --> Plan[Cursor plan]
  Plan --> Execute[Execution agent]
```

## Key Files Likely Touched

- `<path>`

## Verification

- <How the agent proves the task is done>

## Resume Instructions

Start by reading `{{task-generate-name}}.md`, this Cursor plan, and any relevant `discussion/` docs. Track executable todo progress in the YAML frontmatter.
````

## Coding plan (explicit opt-in)

Do **not** auto-apply the `coding-plan` skill. Only when the user **explicitly** asks for a coding plan or names `coding-plan`, follow [`coding-plan`](../coding-plan/SKILL.md): include the **quality attributes table** (reliability, scalability, maintainability), implementation diagrams for non-trivial work, one Cursor todo per small e2e feedback-loop iteration, and test-first verification in todo `verify:` lines.

If the user did not request a coding plan, use the templates above without coding-plan diagrams or slice rules.

## Discussion Docs

Use `discussion/` for material that supports the plan but is not the work queue:

- `discussion/notes.md` for research notes or copied source context.
- `discussion/adr-0001-<decision>.md` when there are real tradeoffs.

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
- For Cursor plans: each plan has one vault origin; its `~/.cursor/plans/<slug>_<short-id>.plan.md` must be a symlink to that origin — never duplicate plan content.
- Never overwrite an existing plan file or Cursor symlink; mint a unique name and append to **Plans** ([Unique plan names](#unique-plan-names-never-overwrite)).
- Update `{{task-generate-name}}.md` after each new plan so future sessions see the full list and the active plan.
