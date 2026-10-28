---
name: workflow-loop-fast
description: >-
  Fast path. The agent runs the smallest stage path from a task or feature
  idea until the user has a result. Pauses only at human gates (empty A:
  lines, review Your call, coding-plan diagram confirm). After the
  requirement spec, the next step is design or plan. plan opens coding-plan
  only for a clear code job. A sub-agent runs a stage only when that stage is
  a different job from this loop. Use when the user types /workflow-loop-fast,
  names workflow-loop-fast, or asks the agent to run the workflow loop.
disable-model-invocation: true
---

# workflow-loop-fast

**Do not auto-apply.** Load only when the user types `/workflow-loop-fast` or names `workflow-loop-fast`.

This skill **controls** the other stage skills. It does not replace them.

Naming this skill **is** permission to run each stage on the chosen path. Read that stage’s `SKILL.md` and follow it. Do not redo its rules inside this file.

**Harness rule:** One path. Stages in order. Do not ask “continue?” between stages. On a **human gate**, stop and wait. On the user’s next message, resume — do not start over.

## Loop

| Phase | Do | Verify | STOP if |
|-------|-----|--------|---------|
| **0 — Input** | Take the user’s task or feature idea. If a task file already exists, resume it. | Idea or task path is known | Neither an idea nor a task file |
| **1 — Route** | Pick the smallest path in [Routes](#routes). Record it on the task. | Route name is one of the four | Small vs normal would change the work and the user did not say which → ask once |
| **2 — Stage** | Read that stage’s `SKILL.md`. If [Sub-agent](#sub-agent) says this stage is a different job, spawn one. Otherwise do the stage here. Update the [loop ledger](#loop-ledger). | Stage’s own verify passed, or the sub-agent’s file is on the task | Stage STOP, or a [human gate](#human-gates) |
| **3 — Advance** | Next stage on the route. Skip a stage only when its “only if” line is false. | Ledger stage matches where you are | — |
| **4 — Result** | When the route’s last stage is done and gates are clear, mark the task `Done` and emit [Loop done](#loop-done). | User can open the result | A gate is still open |

Keep going through phases 2–3 in this chat until a gate or **Loop done**.

## Routes

Use the **minimum** path. Do not run every skill.

| Route | Use when | Stages |
|-------|----------|--------|
| **small** | One clear code change. Place and success check are already known. | `work-intake-automation` → `coding-plan` → `verify` → `code-review` only if the change can break users or the user asked |
| **normal** | A feature or behavior that is not written down yet. | `work-intake-automation` → `grill-me` only if outcome, scope, or acceptance is unclear → `requirement-spec` → [one next step](#after-the-requirement-spec) |
| **high-risk** | Auth, money, data loss, migration, public API, or the user says high-risk. Prefer [`workflow-high`](../workflow-high/SKILL.md) when the human should finish the task before any high skill runs. | **normal**, and always `grill-me` and `spec-review`. Add `design-review` only when the next step includes `design` |
| **non-coding** | The result is not a software change. | `work-intake-automation` → `grill-me` only if unclear → `requirement-spec` only if a durable contract is needed → do the work → `verify` if there is a checkable outcome |

## After the requirement spec

Pick **one** next step. Do not run both.

| Next step | When | Then |
|-----------|------|------|
| [`design`](../design/SKILL.md) | How it should work is still open. | Stop. The result is the design. Ledger: `normal (design)`. |
| [`plan`](../plan/SKILL.md) | The approach is known, or the task clearly asks to write or change code. | Follow `plan`. That skill opens [`coding-plan`](../coding-plan/SKILL.md) only for a clear code job. Ledger: `normal (plan)`. |

If design vs plan would change the work and you cannot tell, ask once.

When `plan` opened `coding-plan`, continue `plan-review` only if that plan should be pressure-tested, then execute, `verify`, and `code-review`. Otherwise stop. The result is the plan.

**Execute** means the [coding-plan](../coding-plan/SKILL.md) execution harness (worktree, test-first, todos). There is no separate execute skill. Any product code loads `coding-plan` first, including the **small** route.

**Execute** for non-coding work means produce the outcome named on the task. Do not open `coding-plan`.

If the user said “feature idea”, start at **normal** unless they also said high-risk. If they gave one exact code change, start at **small**.

## Sub-agent

This chat owns the route, the task ledger, and every human gate. Spawn a sub-agent only when the next stage is a different job.

| Spawn | Stage |
|-------|--------|
| Yes | `spec-review`, `design-review`, `plan-review`, or `code-review` of a file this chat just wrote |
| Yes | Research or a spike whose notes would bury this loop |
| Yes | `coding-plan` execution (the todos after the plan exists) |
| No | The next step of the same skill |
| No | A human gate is open (empty **A:** or **Your call**) |
| No | The brief would have to invent the requirement spec or the design |

Write this brief on the task before the spawn. The sub-agent may write only **Write**.

```markdown
## Sub-agent brief

- **Goal:** <one sentence>
- **Read:** <task path, and the artifact paths>
- **Write:** <one file path>
- **Do not change:** <the ledger, other artifacts, product code unless Write is the code>
```

When it returns, read **Write**, update the ledger, and continue. If that file has an empty **A:** or **Your call**, pause here. The sub-agent does not fill those lines.

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

On the task file only (same folder as `task-*.md`). Add this block on first run. Update it after every stage. Do not put a second work `status` on requirement-spec, design, plan, or discussion files.

```markdown
## Workflow loop

- **Route:** small | normal | normal (design) | normal (plan) | high-risk | non-coding
- **Stage:** <skill name now>
- **Waiting:** none | <path to the questions or review file> | diagram
- **Result:** pending | <path the user should open>
```

Also append one line to **Execution Log**: `YYYY-MM-DD HH:MM - workflow-loop-fast: <stage> done | paused on <file>.`

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
| After the requirement spec, run design or `plan` | Run both |
| Load `coding-plan` before any product code | Write code from this skill |
| Read and follow each stage skill | Copy stage procedures into this file |
| Pause at human gates | Fill **A:** or **Your call** yourself |
| Spawn a sub-agent only for a different job | Spawn one for the next step of the same skill |
| Resume from the ledger | Restart intake on continue |
| Mark the task `Done` only when the result exists | Call tests-green a result when `verify` is on the route |
