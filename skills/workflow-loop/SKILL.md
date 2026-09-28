---
name: workflow-loop
description: >-
  Drive this pack from a task or feature idea until the user has a result.
  Picks the smallest path in CLAUDE.md, runs each stage skill in order, and
  pauses only at human gates (empty A: lines, review Your call, coding-plan
  diagram confirm). Use when the user names workflow-loop, says run the
  workflow, or asks to take an idea or task until they have the result.
disable-model-invocation: true
---

# Workflow Loop

**Do not auto-apply.** Load only when the user names `workflow-loop`, says “run the workflow”, or asks to take a task or feature idea until they have a result.

This skill **controls** the other stage skills. It does not replace them.

Naming this skill **is** permission to run each stage on the chosen path. Read that stage’s `SKILL.md` and follow it. Do not redo its rules inside this file.

**Harness rule:** One path. Stages in order. Do not ask “continue?” between stages. On a **human gate**, stop and wait. On the user’s next message, resume — do not start over.

## Loop

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Input** | Take the user’s task or feature idea. If a task file already exists, resume it. | Idea or task path is known | Neither an idea nor a task file |
| **1 — Route** | Pick the smallest path in [Routes](#routes). Record it on the task. | Route name is one of the four | Small vs normal would change the work and the user did not say which → ask once |
| **2 — Stage** | Read that stage’s `SKILL.md`. Do the stage. Update the [loop ledger](#loop-ledger). | Stage’s own verify passed | Stage STOP, or a [human gate](#human-gates) |
| **3 — Advance** | Next stage on the route. Skip a stage only when its “only if” line is false. | Ledger stage matches where you are | — |
| **4 — Result** | When the route’s last stage is done and gates are clear, mark the task `Done` and emit [Loop done](#loop-done). | User can open the result | A gate is still open |

Keep going through phases 2–3 in this chat until a gate or **Loop done**.

## Routes

Use the **minimum** path from [`CLAUDE.md`](../../CLAUDE.md). Do not run every skill.

| Route | Use when | Stages |
|-------|----------|--------|
| **small** | One clear code change. Place and success check are already known. | `work-intake-automation` → execute → `verify` → `code-review` only if the change can break users or the user asked |
| **normal** | A feature or behavior that is not written down yet. | `work-intake-automation` → `grill-me` only if outcome, scope, or acceptance is unclear → `spec` → `design` only if more than one way matters → `plan-intake-automation` → `coding-plan` → `plan-review` → execute → `verify` → `code-review` |
| **high-risk** | Auth, money, data loss, migration, public API, or the user says high-risk. | **normal**, but always `grill-me`, `spec-review`, and `design-review` |
| **non-coding** | The result is not a software change. | `work-intake-automation` → `grill-me` only if unclear → `spec` only if a durable contract is needed → do the work → `verify` if there is a checkable outcome |

**Execute** for a coding plan means the [coding-plan](../coding-plan/SKILL.md) execution harness (worktree, test-first, todos). There is no separate execute skill.

**Execute** for non-coding work means produce the outcome named on the task. Do not open `coding-plan`.

If the user said “feature idea”, start at **normal** unless they also said high-risk. If they gave one exact code change, start at **small**.

## Human gates

Pause the loop. Do not invent the answer. Set task `status: Blocked`. Emit [Loop paused](#loop-paused).

| Gate | Where | Resume when |
|------|--------|-------------|
| Open question | `discussion/questions-*.md` has an empty **A:** | User filled **A:**, or said proceed |
| Review call | Report **Must fix** has an empty **Your call** | User wrote `fix`, `skip`, or `need more info` and said the file is filled |
| Diagram | `coding-plan` phase 4 asks the user to confirm | User confirms or asks for a change |
| Tooling | A stage STOP for `$OBSIDIAN_BASE_VAULT_PATH`, dirty git, or a missing repo | User fixes it or tells you the path |

When they answer:

- **A: filled** — continue the stage that asked. Do not skip it.
- **proceed** with a blank **A:** — write that assumption on the task **Constraints**, then continue.
- **fix** — revise the artifact that review looks at, then run **that review** again. If new **Must fix** items appear, pause again.
- **skip** — leave the item, go to the next stage.
- **need more info** — stay on that item. Ask that question. Do not advance.

`should fix` and `nice to have` do not block the next stage unless the user marked them `fix`.

## Loop ledger

On the task file only (same folder as `task-*.md`). Add this block on first run. Update it after every stage. Do not put a second work `status` on spec, design, plan, or discussion files.

```markdown
## Workflow loop

- **Route:** small | normal | high-risk | non-coding
- **Stage:** <skill name now>
- **Waiting:** none | <path to the questions or review file> | diagram
- **Result:** pending | <path the user should open>
```

Also append one line to **Execution Log**: `YYYY-MM-DD HH:MM - workflow-loop: <stage> done | paused on <file>.`

Task `status`: `In Progress` while moving, `Blocked` while waiting, `Done` when the result is delivered.

## Resume

On “continue”, “filled”, or a new answer in the same work:

1. Read `task-*.md` **Workflow loop** and `context.md` if it exists.
2. Read the **Waiting** file. Apply the user’s reply using [Human gates](#human-gates).
3. Continue at **Stage**. Do not run `work-intake-automation` again.

A different idea is a new task. If you cannot tell, ask once: same work, or a new idea?

## Chat reports

After a gate:

```markdown
## Loop paused

- **Task:** `<vault-relative task path>`
- **Stage done:** <skill>
- **Waiting on you:** `<file>` — fill **A:** or **Your call**
- **Next after you answer:** <skill>
```

When the route is finished:

```markdown
## Loop done

- **Task:** `<vault-relative task path>`
- **Result:** `<path to open>`
- **What you have:** <one sentence>
```

For software, **Result** is the worktree branch plus the verify report. For anything else, **Result** is the file or outcome the route produced.

## Boundary

| Do | Do not |
|----|--------|
| Pick the smallest route and run it | Run every stage “to be safe” |
| Read and follow each stage skill | Copy stage procedures into this file |
| Pause at human gates | Fill **A:** or **Your call** yourself |
| Resume from the ledger | Restart intake on continue |
| Mark the task `Done` only when the result exists | Call tests-green a result when `verify` is on the route |
