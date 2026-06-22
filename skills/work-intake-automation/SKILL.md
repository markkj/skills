---
name: work-intake-automation
description: >-
  Automates AI-assisted work intake from Jira issues, typed user requests, pasted specs, or other task sources into an Obsidian {{task-generate-name}}.md with pointers for where the user can later store {{plan-generate-name}}.md and discussion docs. Use only when the user explicitly names work-intake-automation, asks for work intake, Jira-to-task capture, or Obsidian task handoff before planning.
disable-model-invocation: true
---

# Work Intake Automation

**Do not auto-apply.** Load this skill only when the user explicitly names `work-intake-automation`, asks for work intake, Jira-to-task capture, or Obsidian task tracking before planning.

Use this skill when work starts outside the agent and must become a durable task record before the user plans it. The source may be Jira, a typed request, a pasted spec, Slack/email notes, or a verbal summary.

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent shell fallbacks when Obsidian MCP is required.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named this skill; identify source type (Jira, typed request, other) | Source type and raw input captured | User did not name skill → do not run intake |
| **1 — Restate** | Restate goal, assumptions, unknowns in chat | Matches user intent; unknowns listed | — |
| **2 — Clarify** | If facts insufficient for a useful task record, ask **1–3** focused questions | User answered or said proceed with stated assumptions | Critical gap unresolved → STOP; do not write task file |
| **3 — Paths** | Choose `work-id`, `PROJECT_NAME`, generate `task-<slug>.md` and future `plan-<slug>.md` paths | No literal `{{…}}` in filenames; paths follow [filename rules](#filename-generation) | Cannot infer project and user did not specify → ask |
| **4 — Roles** | Record intake, planning, execution, discussion owners in task template | Roles filled or marked TBD | — |
| **5 — Write** | Create task folder; write **only** `{{task-generate-name}}.md` via Obsidian MCP | MCP read-back shows file at vault-relative path | MCP unavailable or write unverified → **STOP**; do not shell-write to vault |
| **6 — Handoff** | Emit [completion report](#completion-report) | User can find task file and future plan paths | — |

**Forbidden during any phase:** create plan files, `~/.cursor/plans/*.plan.md`, `discussion/`, notes, ADRs, or product code. If user asks for planning → tell them to name [`plan-intake-automation`](../plan-intake-automation/SKILL.md).

## Completion report

After phase 6, output this block in chat:

```markdown
## Work intake complete

- **Task:** `<vault-relative path to task file>`
- **Work ID:** `<WORK_ID>`
- **Status:** Intake
- **Future plan path:** `<vault-relative plan path>`
- **Future discussion:** `<vault-relative discussion folder>`
- **Blockers:** <none | list>
- **Next:** Name `plan-intake-automation` when ready to plan.
```

## Goal

Normalize every work request into:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Use `{{task-generate-name}}.md` as the intake contract. It records the source facts and the paths where the user or a later planning agent should store `{{plan-generate-name}}.md` and `discussion/` docs. When the user is ready to plan, they must explicitly request [`plan-intake-automation`](../plan-intake-automation/SKILL.md) — do not auto-switch.

## Filename Generation

`{{task-generate-name}}` and `{{plan-generate-name}}` are placeholders. Replace them with real generated basenames before writing files.

Rules:

- Generate a short kebab-case slug from the work title or issue summary.
- Prefix the slug with the artifact type:
  - task file: `task-<short-slug>.md`
  - plan file: `plan-<short-slug>.md`
- Include an issue key only when it helps uniqueness.
- Do not use source names like `manual` or `jira`.
- Never write literal placeholder filenames like `{{task-generate-name}}.md`.
- Never fall back to generic names like `task.md` or `plan.md`.

Example:

```text
Task: Projects/client-app/add-export-button/task-add-export-button.md
```

## Intake Workflow

Follow [Harness phases](#harness-phases). Details per phase:

**Phase 0 — Source** — identify:
   - **Jira:** issue key, title, link, description, comments, acceptance criteria, labels, assignee, priority.
   - **Typed request:** user goal, context, constraints, acceptance criteria, examples, deadline.
   - **Other source:** capture source name, link/path if available, and raw notes.

**Phase 4 — Roles** — record in task file (intake only; planning and execution happen later):
   - **Intake agent:** reads the source and writes `{{task-generate-name}}.md`, e.g. Claude Code reads Jira.
   - **Planning owner:** user | Cursor | Claude Code | Codex | Other | TBD.
   - **Execution owner:** user | Cursor | Claude Code | Codex | Other | TBD.
   - **Discussion owner:** user | Claude Code | Cursor | Other | TBD.

**Phase 2 — Clarify:** If the request lacks enough facts for a useful task record, ask 1-3 focused questions before writing `{{task-generate-name}}.md`.

**Phase 3 — Paths:**

- **work-id:** Jira → issue key (e.g. `PROJ-123`); manual → `YYYYMMDD-short-slug`; other → native id if stable, else `YYYYMMDD-short-slug`. Do not put source names like `manual` or `jira` in folder names.
- **Filenames:** generate `task-<slug>.md` and future `plan-<slug>.md` per [filename rules](#filename-generation).
- **Folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/` — infer `<PROJECT_NAME>` from, in order: `--project`, `TASK_PROJECT`, git repo root name, current directory name.

**Phase 5 — Write:** create folder and task file only. Record future plan and discussion paths in the task file. Do not create plan, `~/.cursor/plans/*.plan.md`, `discussion/`, notes, or ADRs.

## Obsidian Writes

When an Obsidian MCP server is available, prefer it for creating or updating task files in the vault. Use vault-relative paths, not absolute shell paths.

For agent-run Obsidian task creation, Obsidian MCP is required. If the MCP server is unavailable, cannot connect, or cannot verify the created files, abort the operation and report the blocker. Do not silently fall back to shell writes or a local folder.

Example vault-relative task path:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Use the MCP append/create operation for new task files and patch/update operations for existing `{{task-generate-name}}.md` files. Verify the created file with the MCP list/read operations when practical. Do not create planning or discussion files during intake.

## `{{task-generate-name}}.md`

`{{task-generate-name}}.md` stores the durable work record and status, not the todo list. Keep task facts current during execution; put executable todos only in the active plan file. Store task properties in Obsidian YAML frontmatter.

```markdown
---
status: Intake | Planned | In Progress | Blocked | Done | Cancelled
date: YYYY-MM-DD
tags:
priority: "3"
source: Jira | Manual | Slack | Email | Other
source_ref: <issue key, link, path, or "typed by user">
project: <project folder or "unspecified">
owner: <person or agent>
---

# <Work ID>: <Title>

## Agent Roles

- **Intake:** Claude Code | Cursor | Codex | Other
- **Planning owner:** User | Claude Code | Cursor | Codex | Other | TBD
- **Execution owner:** User | Claude Code | Cursor | Codex | Other | TBD
- **Discussion owner:** User | Claude Code | Cursor | Other | TBD

## Planning and Discussion Paths

- **Task folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/`
- **Plan file:** `Projects/<PROJECT_NAME>/<WORK_ID>/{{plan-generate-name}}.md`
- **Discussion folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/discussion/`
- **Cursor plan file, if used:** `~/.cursor/plans/<slug>_<short-id>.plan.md` (canonical; Obsidian plan path is usually a symlink to this file — see `plan-intake-automation`)

## Goal

<One paragraph describing the outcome.>

## Acceptance Criteria

- <User-visible outcome or verification condition>

## Context

<Relevant facts copied or summarized from the source.>

## Constraints

- <Deadline, tech boundary, risk, policy, dependency>

## Execution Log

- YYYY-MM-DD HH:MM - Created task folder.
```

## Future Plan and Discussion Paths

This skill only records where future planning artifacts should go. The user creates them later or explicitly asks an agent to use [`plan-intake-automation`](../plan-intake-automation/SKILL.md).

- `{{plan-generate-name}}.md` path: `Projects/<PROJECT_NAME>/<WORK_ID>/{{plan-generate-name}}.md`
- `discussion/` path: `Projects/<PROJECT_NAME>/<WORK_ID>/discussion/`
- Cursor plan path, if the user chooses Cursor: `~/.cursor/plans/<slug>_<short-id>.plan.md` (canonical; `{{plan-generate-name}}.md` in the task folder should symlink here when planned with `plan-intake-automation`)

## Intake Rules

- Before writing `{{task-generate-name}}.md`, restate the current goal, assumptions, and unknowns.
- Treat `{{task-generate-name}}.md` as the task brief/status ledger and path index.
- Do not put checkboxes or implementation todos in `{{task-generate-name}}.md`; acceptance criteria there are descriptive criteria, not progress tracking.
- Do not create or edit `{{plan-generate-name}}.md`, `~/.cursor/plans/*.plan.md`, `discussion/`, notes, or ADR files during intake. If the user asks for planning, tell them to name [`plan-intake-automation`](../plan-intake-automation/SKILL.md) — do not apply that skill unless they do.
- Update `{{task-generate-name}}.md` whenever status changes, a blocker appears, task facts change, or completion evidence should be logged.
- Keep Obsidian docs concise: facts, decisions, status, path pointers, and verification evidence.
