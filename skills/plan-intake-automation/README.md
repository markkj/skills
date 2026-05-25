# Plan Intake Automation

This skill starts after `work-intake-automation` has created a task record:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

It reads `{{task-generate-name}}.md` and creates planning artifacts at the paths recorded there.

## Responsibilities

- Create `{{plan-generate-name}}.md` when the user wants an Obsidian task-folder plan.
- Create `.cursor/plans/*.plan.md` when the user wants a Cursor plan.
- Create `discussion/` notes or ADRs only when supporting context or decisions need separate files.
- Update `{{task-generate-name}}.md` status/path/log fields after planning.

It does not perform original work intake and does not execute implementation changes.

## Typical Flow

```text
work-intake-automation: source request -> {{task-generate-name}}.md
plan-intake-automation: {{task-generate-name}}.md -> {{plan-generate-name}}.md / Cursor plan / discussion docs
coding or another execution skill: plan -> implementation
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

When Cursor is the execution owner, write the executable Cursor plan to:

```text
<repo>/.cursor/plans/<slug>_<short-id>.plan.md
```

Cursor plan files use YAML frontmatter with `name`, `overview`, `todos`, and `isProject`.

## Discussion Docs

Use `discussion/` only for supporting context:

```text
Projects/my-project/20260525-add-export-button/discussion/
├── notes.md
└── adr-0001-<decision>.md
```

Keep executable todos in `{{plan-generate-name}}.md` or the Cursor plan frontmatter, not in discussion docs.
