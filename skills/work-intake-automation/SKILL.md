---
name: work-intake-automation
description: >-
  Automates AI-assisted work intake from Jira issues, typed user requests, pasted specs, or other task sources into an Obsidian {{task-generate-name}}.md with pointers for where the user can later store {{plan-generate-name}}.md and discussion docs. Use only when the user explicitly names work-intake-automation, asks for work intake, Jira-to-task capture, or Obsidian task handoff before planning.
disable-model-invocation: true
---

# Work Intake Automation

**Do not auto-apply.** Load this skill only when the user explicitly names `work-intake-automation`, asks for work intake, Jira-to-task capture, or Obsidian task tracking before planning.

Use this skill when work starts outside the agent and must become a durable task record before the user plans it. The source may be Jira, a typed request, a pasted spec, Slack/email notes, or a verbal summary.

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent fallbacks when `$OBSIDIAN_BASE_VAULT_PATH` is required.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named this skill; identify source type (Jira, typed request, other) | Source type and raw input captured | User did not name skill → do not run intake |
| **1 — Restate** | Restate goal, assumptions, unknowns in chat | Matches user intent; unknowns listed | — |
| **2 — Clarify** | If facts insufficient for a useful task record, ask **1–3** focused questions | User answered or said proceed with stated assumptions | Critical gap unresolved → STOP; do not write task file |
| **3 — Paths** | Choose `work-id`, `PROJECT_NAME`, generate `task-<slug>.md` and future `plan-<slug>.md` paths | No literal `{{…}}` in filenames; paths follow [filename rules](#filename-generation) | Cannot infer project and user did not specify → ask |
| **4 — Roles** | Record intake, planning, execution, discussion owners in task template | Roles filled or marked TBD | — |
| **5 — Write** | Create task folder; write **only** `{{task-generate-name}}.md` to vault via `$OBSIDIAN_BASE_VAULT_PATH` | Read-back shows file at vault-relative path | `$OBSIDIAN_BASE_VAULT_PATH` unset or write unverified → **STOP** |
| **6 — Handoff** | Emit [completion report](#completion-report) | User can find task file and future plan paths | — |

**Forbidden during any phase:** create plan files, `~/.cursor/plans/*.plan.md`, `discussion/`, notes, ADRs, or product code. Do not assume planning is next. If the task is unclear, recommend `grill-me`; if it needs a durable behavior contract, recommend `spec`; if it needs solution architecture, recommend `design`; if an executable plan is needed, recommend [`plan-intake-automation`](../plan-intake-automation/SKILL.md).

## Completion report

After phase 6, output this block in chat:

```markdown
## Work intake complete

- **Task:** `<vault-relative path to task file>`
- **Work ID:** `<WORK_ID>`
- **Status:** Intake
- **Task folder (plans live here):** `<vault-relative folder>` — many `plan-*.md` allowed later
- **Future discussion:** `<vault-relative discussion folder>`
- **Blockers:** <none | list>
- **Next:** Choose the smallest needed next stage: direct execution, `grill-me`, `spec`, `design`, research/investigation, or `plan-intake-automation` when an executable plan is needed.
```

## Goal

Normalize every work request into:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Use `{{task-generate-name}}.md` as the intake contract. It records source facts and the task folder where later optional `spec-*.md`, `design-*.md`, `plan-*.md`, and `discussion/` artifacts may live. When the user is ready to plan, they must explicitly request [`plan-intake-automation`](../plan-intake-automation/SKILL.md) — do not auto-switch.

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

## Obsidian Vault Writes

Write directly to the Obsidian vault filesystem. Do not use Obsidian MCP for vault content.

1. **Vault root:** Read from `$OBSIDIAN_BASE_VAULT_PATH`. If unset or empty → **STOP** and report.
2. **Absolute path:** `$OBSIDIAN_BASE_VAULT_PATH/<vault-relative-path>` (vault-relative path has no leading slash).
3. **Create:** `mkdir -p` parent directories, then write the file.
4. **Verify:** Read back the file or `test -f` on the absolute path; content must match what was written.
5. **Updates:** Patch or overwrite existing `{{task-generate-name}}.md` at the same absolute path when status changes.

Example vault-relative task path:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Do not create planning or discussion files during intake.

## `{{task-generate-name}}.md`

`{{task-generate-name}}.md` stores the durable work record and status, not the todo list. Keep task facts current during execution; put executable todos only in plan files (a task may have many; use **Active plan**). Store task properties in Obsidian YAML frontmatter.

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
- **Specs:**
  - *(none yet — optional; created by `spec`)*
- **Active spec:** *(none)*
- **Designs:**
  - *(none yet — optional; created by `design`)*
- **Active design:** *(none)*
- **Plans:** (one task may have **many** plans; list grows over time)
  - *(none yet — optional; created by `plan-intake-automation`)*
- **Active plan:** *(none)*
- **Discussion folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/discussion/`

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

Intake records the **folder** and that plans will live there. Do not invent a single locked plan filename as the only plan; `plan-intake-automation` appends each new plan to **Plans** and sets **Active plan**.

Example after two plans exist:

```markdown
## Planning and Discussion Paths

- **Task folder:** `Projects/client-app/add-export-button/`
- **Plans:**
  - `plan-add-export-button.md` → Cursor `~/.cursor/plans/add-export_a1b2.plan.md`
  - `plan-add-export-button-2.md` → Cursor `~/.cursor/plans/add-export_c3d4.plan.md`
- **Active plan:** `plan-add-export-button-2.md`
- **Discussion folder:** `Projects/client-app/add-export-button/discussion/`
```

## Future Artifact Paths

This skill creates the durable task record and records where later artifacts may live. It does **not** assume every task needs planning. After intake, route the task to the smallest appropriate next stage: direct execution, `grill-me`, `spec`, `design`, research/investigation, or `plan-intake-automation`.

- **Task folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/`
- **Specs:** `spec-<short-slug>.md`, `spec-<short-slug>-2.md`, ...
- **Designs:** `design-<short-slug>.md`, `design-<short-slug>-2.md`, ...
- **Plans:** `plan-<short-slug>.md`, `plan-<short-slug>-2.md`, ...
- **Discussion folder:** `Projects/<PROJECT_NAME>/<WORK_ID>/discussion/`
- **Cursor plan path(s):** each Cursor-linked plan gets its own `~/.cursor/plans/<slug>_<short-id>.plan.md` symlink → that vault origin

## Intake Rules

- Before writing `{{task-generate-name}}.md`, restate the current goal, assumptions, and unknowns.
- Treat `{{task-generate-name}}.md` as the task brief/status ledger and path index.
- Do not put checkboxes or implementation todos in `{{task-generate-name}}.md`; acceptance criteria there are descriptive criteria, not progress tracking.
- Do not create spec, design, plan, Cursor plan, discussion, note, ADR, or product-code artifacts during intake. Intake captures and routes only. Later skills remain explicit opt-in.
- Update `{{task-generate-name}}.md` whenever status changes, a blocker appears, task facts change, or completion evidence should be logged.
- Keep Obsidian docs concise: facts, decisions, status, path pointers, and verification evidence.

## Context Budget

**Required:** the incoming source plus enough project metadata to create the durable task record.

**Read only when needed:** a small amount of source history needed to disambiguate the task.

**Avoid loading:** entire repositories, old task folders, archived plans, or broad project history during intake.

**Context update:** do **not** create `context.md` here; this skill preserves its existing invariant of writing only `task-*.md`. A later stage may create the task-scoped cache lazily. See [`../../CONTEXT.md`](../../CONTEXT.md).
