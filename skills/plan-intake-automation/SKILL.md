---
name: plan-intake-automation
description: >-
  Turns an existing Obsidian {{task-generate-name}}.md from work-intake-automation into planning artifacts such as {{plan-generate-name}}.md, Cursor ~/.cursor/plans/*.plan.md files, and discussion docs. Use only when the user explicitly names plan-intake-automation, asks to plan from a saved task record, convert task facts into executable todos, or create Cursor plan files after intake.
disable-model-invocation: true
---

# Plan Intake Automation

**Do not auto-apply.** Load this skill only when the user explicitly names `plan-intake-automation`, asks to plan from a saved task record, or requests plan files / Cursor plans from an existing `{{task-generate-name}}.md`.

Use this skill only after a task record exists. The input is `{{task-generate-name}}.md`; the output is planning artifacts at the paths recorded in that task file.

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent fallbacks, no product code changes.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named this skill; locate `{{task-generate-name}}.md` (vault path from user or task index) | File exists and is readable | No task file → tell user to name [`work-intake-automation`](../work-intake-automation/SKILL.md) first |
| **1 — Load** | Read task file; restate goal, acceptance criteria, assumptions, unknowns, recorded paths | Restatement matches task file; gaps listed | — |
| **2 — Clarify** | If scope or acceptance criteria unclear, ask **1–3** focused questions | User answered or explicitly said proceed with stated assumptions | Unresolved blocker → STOP; do not write plan |
| **3 — Artifact choice** | Pick one primary output: Obsidian-only plan, Cursor plan (+ symlink), or discussion doc only | Choice matches execution owner in task file or user stated preference | Ambiguous and user did not choose → ask; STOP until chosen |
| **4 — Write** | Create plan / Cursor plan / discussion per templates below | Each artifact exists at recorded path; no literal `{{…}}` placeholders in filenames | MCP/shell write failed or path conflict → STOP; ask before overwrite |
| **5 — Link** (Cursor only) | Write canonical `~/.cursor/plans/<slug>_<short-id>.plan.md`; symlink Obsidian plan path | `readlink` + `realpath` show same file | Symlink wrong or Obsidian path is a duplicate copy → fix or STOP |
| **6 — Ledger** | Update `{{task-generate-name}}.md`: `status: Planned`, paths, execution log | Task file reflects new artifacts | Task update failed → STOP and report |
| **7 — Handoff** | Emit [completion report](#completion-report) | User can resume from task + plan paths alone | — |

**Forbidden during any phase:** create a new task file, change product code, auto-apply [`coding-plan`](../coding-plan/SKILL.md) unless user names it.

## Completion report

After phase 7, output this block in chat:

```markdown
## Plan intake complete

- **Task:** `<vault-relative path to task file>`
- **Plan:** `<path>` (Obsidian markdown | Cursor canonical | symlink → canonical)
- **Discussion:** `<path or none>`
- **Status:** Planned
- **Next:** Name `coding-plan` for diagram-backed implementation, or execute from the plan directly.
- **Blockers:** <none | list>
```

## Boundary

- [`work-intake-automation`](../work-intake-automation/SKILL.md): source request -> `{{task-generate-name}}.md` (explicit opt-in only).
- `plan-intake-automation` (this skill): `{{task-generate-name}}.md` -> `{{plan-generate-name}}.md`, optional Cursor plan (symlinked to the Obsidian plan path when both are used), optional `discussion/` docs.
- Execution happens later; do not change product code while planning.

If `{{task-generate-name}}.md` does not exist, tell the user to name [`work-intake-automation`](../work-intake-automation/SKILL.md) first — do not auto-apply intake.

## Filename Generation

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders from `work-intake-automation`. Resolve them to the concrete filenames recorded in the task file.

Rules:

- Prefer the exact task and plan paths already recorded under `## Planning and Discussion Paths`.
- If the task file still contains placeholders, generate real filenames before writing the plan:
  - task file: `task-<short-slug>.md`
  - plan file: `plan-<short-slug>.md`
- Use the same short slug for the matching task and plan files.
- Include an issue key only when it helps uniqueness.
- Do not use source names like `manual` or `jira`.
- Never write literal placeholder filenames like `{{plan-generate-name}}.md`.
- Never fall back to generic names like `task.md` or `plan.md`.

Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

## Planning Workflow

Follow [Harness phases](#harness-phases). The steps below are phase details — not a separate optional list.

**Phase 1 — Load** fields:
   - goal
   - acceptance criteria
   - assumptions
   - unknowns/blockers
   - recorded paths for `{{plan-generate-name}}.md`, `discussion/`, and optional Cursor plan

**Phase 2 — Clarify:** If acceptance criteria or scope are unclear, ask 1-3 focused questions before writing a plan.

**Phase 3 — Artifact choice:**
   - **Obsidian-only plan:** write `{{plan-generate-name}}.md` at the path recorded in `{{task-generate-name}}.md` (markdown template below; no `~/.cursor/plans/` file).
   - **Cursor plan:** one canonical file plus a symlink in Obsidian — see [Cursor plan with Obsidian symlink](#cursor-plan-with-obsidian-symlink).
   - **Discussion doc:** write `discussion/<topic>.md` or `discussion/adr-0001-<decision>.md` only for decisions, research, or context that would make `{{plan-generate-name}}.md` noisy.

**Phase 6 — Ledger** updates to `{{task-generate-name}}.md` only:
   - `status: Planned`
   - changed planning/discussion paths
   - execution log entry with the created artifact path

## Obsidian Writes

When an Obsidian MCP server is available, prefer it for **Obsidian-only** `{{plan-generate-name}}.md` and `discussion/` files in the vault. Use vault-relative paths. If MCP cannot verify the write, report the blocker rather than silently creating a local copy.

Obsidian MCP cannot create symlinks. For **Cursor plans**, write the canonical file under `~/.cursor/plans/`, then create the vault symlink with shell `ln -s` (see below). Verify both paths resolve to the same file.

Use shell writes for `~/.cursor/plans/*.plan.md`, symlinks, and manual terminal workflows.

## Cursor plan with Obsidian symlink

When the user asks for a Cursor plan or the execution owner is Cursor, use **one canonical plan file** linked from both locations. Do not maintain two copies of the plan body.

### Canonical file (write content here)

```text
~/.cursor/plans/<slug>_<short-id>.plan.md
```

Use the [Cursor Plan Template](#cursor-plan-template) below. This path is what Cursor Plan UI reads.

### Obsidian path (symlink only)

```text
<vault>/Projects/<PROJECT_NAME>/<WORK_ID>/{{plan-generate-name}}.md
```

Create this path as a **symlink** to the canonical `~/.cursor/plans/*.plan.md` file — not a separate markdown document.

### Symlink rules

1. Write the canonical plan first under `~/.cursor/plans/`.
2. Ensure the task folder exists in the vault (create parents if needed).
3. Create the Obsidian plan path with `ln -s`:
   - Use an **absolute** target to `~/.cursor/plans/<slug>_<short-id>.plan.md` (canonical lives outside the vault).
   - Expand `~` when writing the symlink if the shell requires it.
4. If `{{plan-generate-name}}.md` already exists, ask before overwriting. Replace a regular file or stale symlink only after confirmation.
5. **Verify:** `readlink` (or `ls -l`) on the Obsidian path and `realpath` (or equivalent) on both paths show the same inode/file.
6. Record both paths in `{{task-generate-name}}.md`. Note on the Obsidian plan line that it is a symlink to the Cursor plan (example: `plan-add-export.md` → symlink → `~/.cursor/plans/add-export_a1b2.plan.md`).

### Layout example

```text
<vault>/Projects/my-app/WORK-123/plan-add-export.md
  -> /Users/me/.cursor/plans/add-export_a1b2.plan.md

~/.cursor/plans/add-export_a1b2.plan.md   # canonical content (Cursor Plan UI)
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

Start by reading `{{task-generate-name}}.md`, this `{{plan-generate-name}}.md`, and any relevant `discussion/` docs. Track implementation todo progress here unless a Cursor plan file is the active execution plan.
```

## Cursor Plan Template

Use this when the user asks for a Cursor plan or when the execution owner is Cursor. Write content only to the canonical path under `~/.cursor/plans/`; link the Obsidian `{{plan-generate-name}}.md` path with a symlink ([Cursor plan with Obsidian symlink](#cursor-plan-with-obsidian-symlink)).

Canonical file path:

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
- Keep `{{task-generate-name}}.md` as status/source/path ledger; keep executable todos in the active plan file (Obsidian markdown or Cursor plan YAML frontmatter).
- For Cursor plans: one canonical file under `~/.cursor/plans/`; Obsidian `{{plan-generate-name}}.md` must be a symlink to it — never duplicate plan content in both places.
- Ask before overwriting an existing plan file or symlink.
- Update `{{task-generate-name}}.md` after planning so future sessions can find the active plan and symlink target.
