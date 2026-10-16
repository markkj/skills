---
name: workflow
description: >-
  Framework entry for this pack. Tells the user to pick /workflow-loop-fast or
  /workflow-high. Use when the user types /workflow or names workflow without
  a command. Does not run the work itself.
disable-model-invocation: true
---

# workflow

**Do not auto-apply.** This skill does not run the work. It picks a command.

| Command | What happens |
|---------|----------------|
| `/workflow-loop-fast` | The agent runs the smallest stage path until a result or a human gate. |
| `/workflow-high` | Intake only. The human finishes the task. That finish is the signal to start a high skill. |

If the user typed `/workflow` and did not name a command, ask once which one they want. Do not start intake, spec, design, or code until they answer.

Stage skills (`spec`, `coding-plan`, and the rest) stay separate. A mode reads each skill when that stage is actually called. File layout for task records lives in `work-intake-automation`, not here.
