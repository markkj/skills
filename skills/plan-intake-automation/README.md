# Plan Intake Automation

**Opt-in only.** The agent loads this skill when the user explicitly names `plan-intake-automation` or asks to plan from an existing task record.

**Harness:** Phases 0–7 in `SKILL.md` — preconditions → load → clarify → artifact choice → write → symlink (Cursor) → ledger → completion report. Do not skip phases.

This skill starts after `work-intake-automation` has created a task record (user must have named that skill for intake):

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

It reads `{{task-generate-name}}.md` and creates planning artifacts at the paths recorded there.

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders. Use real generated filenames. Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

Do not use literal placeholder filenames, `task.md`, or `plan.md`.

## Responsibilities

- Create `{{plan-generate-name}}.md` when the user wants an Obsidian-only task-folder plan.
- Create `~/.cursor/plans/*.plan.md` when the user wants a Cursor plan, and symlink the Obsidian plan path to that canonical file (one plan body, two paths).
- Create `discussion/` notes or ADRs only when supporting context or decisions need separate files.
- Update `{{task-generate-name}}.md` status/path/log fields after planning.

It does not perform original work intake and does not execute implementation changes.

## Typical Flow

```text
work-intake-automation (explicit): source request -> {{task-generate-name}}.md
plan-intake-automation (explicit): {{task-generate-name}}.md -> {{plan-generate-name}}.md / Cursor plan / discussion docs
coding-plan (explicit) or another execution skill: plan -> implementation
```

## Obsidian Plan Example

If `{{task-generate-name}}.md` says:

```markdown
## Planning and Discussion Paths

- **Plan file:** `Projects/my-project/20260525-add-export-button/{{plan-generate-name}}.md`
- **Discussion folder:** `Projects/my-project/20260525-add-export-button/discussion/`
```

Then write the plan to:

```text
Projects/my-project/20260525-add-export-button/{{plan-generate-name}}.md
```

## Cursor Plan Example

When Cursor is the execution owner:

1. Write the canonical Cursor plan to:

```text
~/.cursor/plans/<slug>_<short-id>.plan.md
```

2. Symlink the Obsidian plan path to that file (do not copy the content):

```text
Projects/my-project/20260525-add-export-button/plan-add-export-button.md
  -> /Users/me/.cursor/plans/<slug>_<short-id>.plan.md
```

Cursor plan files use YAML frontmatter with `name`, `overview`, `todos`, and `isProject`. Obsidian MCP cannot create symlinks; use shell `ln -s` after writing the canonical file.

## Discussion Docs

Use `discussion/` only for supporting context:

```text
Projects/my-project/20260525-add-export-button/discussion/
├── notes.md
└── adr-0001-<decision>.md
```

Keep executable todos in `{{plan-generate-name}}.md` or the Cursor plan frontmatter, not in discussion docs.
