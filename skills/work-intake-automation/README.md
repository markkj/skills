# Work Intake Automation

This skill turns a work request into an Obsidian task folder:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

`Projects/` is the Obsidian folder where all project task folders should be created.

The project folder is inferred automatically from the opened project. The user should not need to type it in normal use.

`{{task-generate-name}}.md` records the future paths for `{{plan-generate-name}}.md` and `discussion/`; those files are created later by the user or by the `plan-intake-automation` skill.

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders. Replace them with real kebab-case filenames. Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

Do not use literal placeholder filenames, `task.md`, or `plan.md`.

## Recommended Agent Path: Obsidian MCP

When an agent has access to the Obsidian MCP server, use MCP tools to create or update task files in the vault. MCP paths are relative to the vault root.

For agent-run task creation, Obsidian MCP is required. If Obsidian MCP cannot connect or cannot verify the created files, abort the operation and report the blocker. Do not fall back to shell writes or create a local folder.

Example MCP path:

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

## Agent Handoff Pattern

- `{{task-generate-name}}.md` stores source facts, status, acceptance criteria, constraints, agent roles, and the future paths for planning/discussion docs.
- The user or `plan-intake-automation` creates `{{plan-generate-name}}.md` when ready.
- The user or `plan-intake-automation` creates `discussion/` notes or ADRs when needed.

Example flow:

```text
Claude Code reads Jira -> writes {{task-generate-name}}.md
User or plan-intake-automation reads {{task-generate-name}}.md -> writes {{plan-generate-name}}.md when ready
Cursor reads {{task-generate-name}}.md + {{plan-generate-name}}.md -> executes when asked
plan-intake-automation writes discussion notes or ADRs only when asked
```
