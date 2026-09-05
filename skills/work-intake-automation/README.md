# Work Intake Automation

**Opt-in only.** The agent loads this skill when the user explicitly names `work-intake-automation` or asks for work intake.

**Harness:** Phases 0–6 in `SKILL.md` — preconditions → restate → clarify → paths → roles → write (vault via `$OBSIDIAN_BASE_VAULT_PATH`) → completion report. STOP if env var unset or write unverified.

This skill turns a work request into an Obsidian task folder:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

`Projects/` is the Obsidian folder where all project task folders should be created.

The project folder is inferred automatically from the opened project. The user should not need to type it in normal use.

`{{task-generate-name}}.md` is the durable work record. Later artifacts are optional: the task may go directly to execution, through `grill-me`, to `spec`, `design`, research/investigation, or to `plan-intake-automation`. Planning is not assumed.

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders. Replace them with real kebab-case filenames. Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

Do not use literal placeholder filenames, `task.md`, or `plan.md`.

## Vault writes

Write directly to the Obsidian vault. Set `$OBSIDIAN_BASE_VAULT_PATH` to the vault root. If unset, abort and report the blocker.

Absolute path: `$OBSIDIAN_BASE_VAULT_PATH/Projects/<PROJECT_NAME>/<WORK_ID>/{{task-generate-name}}.md`

Vault-relative path (for ledger and handoff):

```text
Projects/<PROJECT_NAME>/<WORK_ID>/{{task-generate-name}}.md
```

## Project Detection

The user should not need to type the project in normal use. Detection order:

1. `--project`, for one-off overrides.
2. `TASK_PROJECT`, if set in the shell environment.
3. Current git repository root folder name.
4. Current directory name.

Example: if Cursor or Claude Code is opened in `/Users/<you>/work/client-app`, then tasks go under:

```text
Projects/client-app/<WORK_ID>/
```

## Routing / Handoff Pattern

- `{{task-generate-name}}.md` stores source facts, status, acceptance criteria, constraints, agent roles, and the future paths for planning/discussion docs.
- The user explicitly names `plan-intake-automation` to create `{{plan-generate-name}}.md` when ready.
- The user explicitly names `plan-intake-automation` to create `discussion/` notes or ADRs when needed.

Example flows:

```text
small task:      work-intake -> execute
unclear task:    work-intake -> grill-me -> next appropriate stage
feature:         work-intake -> spec -> design? -> plan-intake -> coding-plan -> execute
research:        work-intake -> research/investigate -> findings
high-risk code:  work-intake -> grill-me -> spec -> spec-review -> design -> design-review -> plan-intake -> coding-plan -> plan-review -> execute -> verify -> code-review
```
