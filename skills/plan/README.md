# Plan

**Opt-in only.** The agent loads this skill when the user names `plan`, asks to plan from an existing task record, or a workflow route reaches this stage.

**Harness:** Phases 0–7 in `SKILL.md` — preconditions → load → clarify → artifact choice → write (vault origin) → symlink (Cursor) → ledger (append to Plans) → completion report. Do not skip phases.

This skill starts after `work-intake-automation` has created a task record (user must have named that skill for intake):

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

It reads `{{task-generate-name}}.md` plus the task’s active spec/design when present, checks planning readiness, and **adds** a planning artifact under that task folder. **One task may have many plans.** Missing requirements or design decisions go back to `grill-me`, `requirement-spec`, or `design`. They do not get buried in the plan. A clear code job hands off to `coding-plan`, which writes the one plan file. Any other job stays in this skill.

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders. Use real generated filenames. Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

Do not use literal placeholder filenames, `task.md`, or `plan.md`.

## Responsibilities

- Create a **new** `plan-*.md` in the vault (origin). Never overwrite an existing plan.
- When Cursor is used, symlink a new `~/.cursor/plans/*.plan.md` to that origin (one body, two paths per plan).
- **Append** each plan to the task’s **Plans** list and set **Active plan**.
- Create `discussion/` notes or ADRs only when supporting context or decisions need separate files.

It does not perform original work intake and does not execute implementation changes.

## Typical Flow

```text
work-intake-automation: source request -> task record
grill-me / requirement-spec / design: optional clarification + definition stages
plan: task + active spec/design
  clear code job -> coding-plan writes the one plan (diagrams, test-first todos, worktree)
  anything else  -> this skill writes plan-*.md / Cursor symlink
```

## Multi-plan example

```text
Projects/my-project/20260525-add-export-button/
├── task-add-export-button.md
├── plan-add-export-button.md      # plan 1
├── plan-add-export-button-2.md    # plan 2
└── discussion/
```

Task ledger:

```markdown
- **Plans:**
  - `plan-add-export-button.md` → Cursor `~/.cursor/plans/…_a1b2.plan.md`
  - `plan-add-export-button-2.md` → Cursor `~/.cursor/plans/…_c3d4.plan.md`
- **Active plan:** `plan-add-export-button-2.md`
```

## Cursor Plan Example

When Cursor is the execution owner:

1. Resolve a free vault origin name (never overwrite). Write the origin plan (Cursor YAML frontmatter + body).
2. Symlink a free Cursor plan path to that vault file (mint a new `<short-id>` if needed).
3. Append both paths to **Plans**; set **Active plan**.

## Discussion Docs

Use `discussion/` only for supporting context. Keep executable todos in each `plan-*.md` (vault origin), not in discussion docs.
