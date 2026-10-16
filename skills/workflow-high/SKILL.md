---
name: workflow-high
description: >-
  High-rigor path. Run work-intake, then stop for the human to finish the task.
  When the human says the task is ready, that is the signal to start one high
  skill. For software, the high skill is coding-plan and the first step is a
  reviewed test case (input and output) before any production code. Use when
  the user types /workflow-high or names workflow-high.
disable-model-invocation: true
---

# workflow-high

**Do not auto-apply.** Load only when the user types `/workflow-high` or names `workflow-high`.

This path is **not a loop**. Do not walk spec, design, plan, and execute on your own.

## Steps

1. Read [`work-intake-automation`](../work-intake-automation/SKILL.md) and do that stage once. The task file is the record.
2. **Stop.** The human finishes the task: goal, scope, and what done means. You may answer questions. You do not open the next skill.
3. Resume only when the human says the task is ready (for example “task ready”, “go high”, or they name the next skill).
4. That sentence is the **signal**. Start exactly one high skill. If they did not name one, ask once. For a software change, the default signal is [`coding-plan`](../coding-plan/SKILL.md).

## Software signal: test case first

When the signal is `coding-plan`, add this gate **before** production code. Then follow that skill’s own harness.

1. Add a todo whose only job is the test case. State the **input** and the **output** the test must show. Do not write the test file yet.
2. **Stop.** The user reviews that input and output.
3. After they accept, write the failing test. **Stop again** before production code.
4. Continue `coding-plan` from its plan harness. The last todo is still a manual check of the real user path.

If the user opts out of tests, write that on the task and follow `coding-plan` without this gate.

## Boundary

| Do | Do not |
|----|--------|
| Intake, then wait | Run the fast loop |
| Treat “task ready” as the signal for one high skill | Invent the next skill |
| For code, show input and output before writing the test | Write production code before the user accepts the test |
