---
name: work-intake-automation
description: >-
  Automates AI-assisted work intake from Jira issues, typed user requests, pasted specs, or other task sources into a Project Path {{task-generate-name}}.md with pointers for where the user can later store {{plan-generate-name}}.md and discussion docs. Use when the user names work-intake-automation, asks for work intake, Jira-to-task capture, or task handoff before planning, or when new work has no task record yet and a later skill needs one.
---

# Work Intake Automation

Load this skill when the user names `work-intake-automation`, asks for work intake, Jira-to-task capture, or task tracking before planning, or when new work has no task record and a later skill needs one.

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

Use this skill when work starts outside the agent and must become a durable task record before the user plans it. The source may be Jira, a typed request, a pasted spec, Slack/email notes, or a verbal summary.

**Harness rule:** Run phases **in order**. Do not skip a phase. Do not start the next phase until the current phase **verify** passes. On **STOP**, report the blocker and wait — no silent fallbacks when `scripts/resolve-project-path.sh` is required.

## Harness phases

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Preconditions** | User named this skill; identify source type (Jira, typed request, other) | Source type and raw input captured | User did not name skill → do not run intake |
| **1 — Restate** | Restate goal, assumptions, unknowns in chat | Matches user intent; unknowns listed | — |
| **2 — Clarify** | If facts insufficient, ask **1–3** questions in chat **and** write `discussion/questions-intake-<slug>.md` from [`templates/open-questions.md`](../../templates/open-questions.md) | User can fill each **A:** line, or questions are recorded | Vault path unknown → STOP; do not invent answers |
| **3 — Paths** | Choose `work-id`, `PROJECT_NAME`, generate `task-<slug>.md` and future `plan-<slug>.md` paths | No literal `{{…}}` in filenames; paths follow [filename rules](#filename-generation) | Cannot infer project and user did not specify → ask |
| **4 — Roles** | Record intake, planning, execution, discussion owners in task template | Roles filled or marked TBD | — |
| **5 — Write** | Create task folder; write `{{task-generate-name}}.md`; if blocking questions exist, also write the questions file under `discussion/` | Read-back shows task (and questions file if any) | `scripts/resolve-project-path.sh` unset or write unverified → **STOP** |
| **6 — Handoff** | Emit [completion report](#completion-report) | User can find task file and future plan paths | — |

**Forbidden during any phase:** create plan files, notes, ADRs, or product code. A `discussion/questions-intake-*.md` file is allowed when there are blocking questions. Do not assume planning is next. If the task is unclear, recommend `grill-me`; if it needs a durable behavior contract, recommend `requirement-spec`; if it needs solution architecture, recommend `design`; if an executable plan is needed, recommend [`plan`](../plan/SKILL.md).

## Completion report

After phase 6, output this block in chat:

```markdown
## Work intake complete

- **Task:** `<project-relative path to task file>`
- **Work ID:** `<WORK_ID>`
- **Status:** Intake
- **Task folder (plans live here):** `<project-relative folder>` — many `plan-*.md` allowed later
- **Future discussion:** `<project-relative discussion folder>`
- **Blockers:** <none | path to `discussion/questions-intake-*.md`>
- **Next:** Choose the smallest needed next stage: direct execution, `grill-me`, `requirement-spec`, `design`, research/investigation, or `plan` when an executable plan is needed.
```

## Goal

Normalize every work request into:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Use `{{task-generate-name}}.md` as the intake contract. It records source facts and the **task folder** where later `spec-*.md`, `design-*.md`, `plan-*.md`, `context.md`, and `discussion/` **must** live. Later skills write into this same folder only.

## Same folder as the task

This skill **creates** the task folder. Every later file belongs here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/
├── task-<slug>.md
├── discussion/     ← questions-intake-*.md, notes, ADRs (needs user input)
├── reports/        ← reviews, verification, metric reports (results)
└── docs/           ← setup, runbooks, how-to (lasting reference)
```

None of these folders go at the repo root. Intake writes only `discussion/questions-intake-*.md`. Later skills create `reports/` and `docs/` when they need them.

Intake stops after the task is written. Start [`plan`](../plan/SKILL.md) or another stage next only when the user asks, or when the work needs it.

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
   - **Planning owner:** user | Claude Code | Other | TBD.
   - **Execution owner:** user | Claude Code | Other | TBD.
   - **Discussion owner:** user | Claude Code | Other | TBD.

**Phase 2 — Clarify:** If the request lacks enough facts, ask 1–3 questions in chat **and** write `discussion/questions-intake-<slug>.md` using [`templates/open-questions.md`](../../templates/open-questions.md). The user fills each **`A:`** line. List the file under **Open questions** on the task. Write the task when the vault path is known. Do not invent answers.

**Phase 3 — Paths:**

- **work-id:** Jira → issue key (e.g. `PROJ-123`); manual → `YYYYMMDD-short-slug`; other → native id if stable, else `YYYYMMDD-short-slug`. Do not put source names like `manual` or `jira` in folder names.
- **Filenames:** generate `task-<slug>.md` and future `plan-<slug>.md` per [filename rules](#filename-generation).
- **Folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/` — infer `<PROJECT_NAME>` from, in order: `--project`, `TASK_PROJECT`, git repo root name, current directory name.

**Phase 5 — Write:** create folder and task file. If there are blocking questions, also write `discussion/questions-intake-<slug>.md`. Do not create plan, spec, design, notes, or ADRs.

## Project Path writes

Run `scripts/resolve-project-path.sh`. It prints one absolute directory. If it exits non-zero, **STOP**. When `~/.config/markkj-skills/project-path` is missing and `OBSIDIAN_BASE_VAULT_PATH` points at an existing directory, the script creates `$OBSIDIAN_BASE_VAULT_PATH/Projects` and saves that path. An existing `project-path` file is left alone.

1. **Project Path:** Use the printed directory. If the script fails → **STOP** and report.
2. **Absolute path:** `$PROJECT_PATH/<project-relative-path>` (project-relative path has no leading slash).
3. **Create:** `mkdir -p` parent directories, then write the file.
4. **Verify:** Read back the file or `test -f` on the absolute path; content must match what was written.
5. **Updates:** Patch or overwrite existing `{{task-generate-name}}.md` at the same absolute path when status changes.

Example project-relative task path:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/
└── {{task-generate-name}}.md
```

Do not create planning files, notes, or ADRs during intake. A questions file under `discussion/` is allowed.

## `{{task-generate-name}}.md`

`{{task-generate-name}}.md` stores the durable work record and status, not the todo list. Keep task facts current during execution; put executable todos only in plan files (a task may have many; use **Active plan**). Store task properties in YAML frontmatter.

**Only the task file has work `status`.** Do not put `status` on spec, design, plan, grill-me, or review docs. Which artifact is current is the **Active spec / Active design / Active plan / Clarify** pointers plus the execution log.

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

- **Intake:** Claude Code | Other
- **Planning owner:** User | Claude Code | Other | TBD
- **Execution owner:** User | Claude Code | Other | TBD
- **Discussion owner:** User | Claude Code | Other | TBD

## Planning and Discussion Paths

- **Task folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/`
- **Specs:**
  - *(none yet — optional; created by `requirement-spec`)*
- **Active spec:** *(none)*
- **Designs:**
  - *(none yet — optional; created by `design`)*
- **Active design:** *(none)*
- **Plans:** (one task may have **many** plans; list grows over time)
  - *(none yet — optional; created by `plan`)*
- **Active plan:** *(none)*
- **Clarify / grill-me:**
  - *(none yet — optional; created by `grill-me`)*
- **Open questions:**
  - *(none yet — optional; `discussion/questions-<stage>-<slug>.md`)*
- **Discussion folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/discussion/`
- **Reports folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/` (reviews, verification, metric reports)
- **Docs folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/docs/` (setup, runbooks, how-to)

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

Intake records the **folder** and that plans will live there. Do not invent a single locked plan filename as the only plan; `plan` appends each new plan to **Plans** and sets **Active plan**.

Example after two plans exist:

```markdown
## Planning and Discussion Paths

- **Task folder:** `Projects/client-app/add-export-button/`
- **Plans:**
  - `plan-add-export-button.md`
  - `plan-add-export-button-2.md`
- **Active plan:** `plan-add-export-button-2.md`
- **Discussion folder:** `Projects/client-app/add-export-button/discussion/`
- **Reports folder:** `Projects/client-app/add-export-button/reports/`
- **Docs folder:** `Projects/client-app/add-export-button/docs/`
```

## Future Artifact Paths

This skill creates the durable task record and records where later artifacts may live. It does **not** assume every task needs planning. After intake, route the task to the smallest appropriate next stage: direct execution, `grill-me`, `requirement-spec`, `design`, research/investigation, or `plan`.

- **Task folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/`
- **Specs:** `requirement-spec-<short-slug>.md`, `requirement-spec-<short-slug>-2.md`, ...
- **Designs:** `design-<short-slug>.md`, `design-<short-slug>-2.md`, ...
- **Plans:** `plan-<short-slug>.md`, `plan-<short-slug>-2.md`, ...
- **Clarify:** `discussion/grill-me-<slug>.md` (optional; no `status` field)
- **Open questions:** `discussion/questions-<stage>-<slug>.md` — user fills each **A:** line; template: [`templates/open-questions.md`](../../templates/open-questions.md)
- **Discussion folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/discussion/`
- **Reports folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/` (reviews, verification, metric reports)
- **Docs folder:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/docs/` (setup, runbooks, how-to)

## Intake Rules

- Before writing `{{task-generate-name}}.md`, restate the current goal, assumptions, and unknowns.
- Treat `{{task-generate-name}}.md` as the task brief/status ledger and path index.
- Do not put checkboxes or implementation todos in `{{task-generate-name}}.md`; acceptance criteria there are descriptive criteria, not progress tracking.
- Do not create spec, design, plan, note, ADR, or product-code artifacts during intake. Intake captures and routes only. A `discussion/questions-intake-*.md` file is allowed when there are blocking questions. Start a later skill only when the user asks or the work needs it.
- Update `{{task-generate-name}}.md` whenever status changes, a blocker appears, task facts change, or completion evidence should be logged.
- Keep Task docs concise: facts, decisions, status, path pointers, and verification evidence.

## Context Budget

**Required:** the incoming source plus enough project metadata to create the durable task record.

**Read only when needed:** a small amount of source history needed to disambiguate the task.

**Avoid loading:** entire repositories, old task folders, archived plans, or broad project history during intake.

**Context update:** do **not** create `context.md` here; this skill preserves its existing invariant of writing only `task-*.md`. A later stage may create the task-scoped cache lazily. See [`../../CONTEXT.md`](../../CONTEXT.md).
