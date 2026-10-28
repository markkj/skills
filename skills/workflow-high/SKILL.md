---
name: workflow-high
description: >-
  High-rigor path. Run work-intake, then stop for the human to finish the task.
  When the human says the task is ready, that is the signal to start one high
  skill. When the task needs steps, that skill is plan, which opens coding-plan
  only for a clear code change. A clear code change still reviews the test
  input and output before any production code. When how it should work is
  still open, start design. Use when the user types /workflow-high or names
  workflow-high.
disable-model-invocation: true
---

# workflow-high

**Do not auto-apply.** Load only when the user types `/workflow-high` or names `workflow-high`.

This path is **not a loop**. Do not walk requirement-spec, design, plan, and execute on your own.

## Steps

1. Read [`work-intake-automation`](../work-intake-automation/SKILL.md) and do that stage once. The task file is the record.
2. **Stop.** The human finishes the task: goal, scope, and what done means. You may answer questions. You do not open the next skill.
3. Resume only when the human says the task is ready (for example “task ready”, “go high”, or they name the next skill).
4. That sentence is the **signal**. Start exactly one skill. If they named one, start that skill.
5. If they did not name one, start **one** skill from [One skill](#one-skill).

## One skill

Same two choices as the fast loop after the requirement spec. Start one. Do not chain them.

| Start | When |
|-------|------|
| [`design`](../design/SKILL.md) | How it should work is still open. |
| [`plan`](../plan/SKILL.md) | The approach is known, or the task clearly asks to write or change code. `plan` opens `coding-plan` only for that code job. |

If design vs plan would change the work and you cannot tell, ask once. Record the choice on the task.

## Software signal: test case first

When `plan` opens `coding-plan`, add this gate **before** production code. Then follow that skill’s own harness.

1. Add a todo whose only job is the test case. State the **input** and the **output** the test must show. Do not write the test file yet.
2. **Stop.** The user reviews that input and output.
3. After they accept, write the failing test. **Stop again** before production code.
4. Continue `coding-plan` from its plan harness. The last todo is still a manual check of the real user path.

If the user opts out of tests, write that on the task and follow `coding-plan` without this gate.

Product code happens only inside [`coding-plan`](../coding-plan/SKILL.md). If the work is code and `plan` did not open it, stop and open `coding-plan`. Do not edit the repo from this skill.

## Sub-agent

You still own the task file and the test gates above. After the user accepts the failing test, the implementation todos are a different job. Spawn a sub-agent for them. Do the same when the one skill you started is a review or a research spike.

The brief has four lines: **Goal**, **Read**, **Write**, **Do not change**. The sub-agent may write only **Write**. An empty **A:** or **Your call** stays here for the user.

## Boundary

| Do | Do not |
|----|--------|
| Intake, then wait | Run the fast loop |
| Treat “task ready” as the signal for one skill | Invent a skill the task does not need |
| Start `design` or `plan` | Chain them |
| Open `coding-plan` before any product code | Write code from this skill |
| For code, show input and output before writing the test | Write production code before the user accepts the test |
| Spawn a sub-agent for implementation, review, or a spike | Hand that sub-agent the task ledger or an empty **Your call** |
