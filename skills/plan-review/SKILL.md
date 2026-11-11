---
name: plan-review
description: >-
  Review an implementation plan before execution. Checks that plan steps trace
  to the spec/design, are ordered safely, use small end-to-end feedback loops,
  include tests and verification, and cover migrations/rollback/observability.
  Use when the user names plan-review, a new plan needs a check before code
  starts, or a workflow reaches this stage.
---

# Plan Review

Ask: **Can this design/spec be implemented safely from this plan?**

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

## Same folder as the task

Write the report **only** here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/plan-review-<slug>.md
```

That `reports/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Load the task, active/chosen plan, and spec/design when present.

Check:
- every required behavior has a plan step
- no plan step contradicts design/spec
- todo order respects dependencies
- todos are small end-to-end increments, not layer-only batches
- behavior changes have failing-test-first steps unless explicitly waived
- each todo has concrete verification
- migrations, compatibility, rollout/rollback and observability are covered where relevant
- repo/worktree assumptions are correct
- no implementation-critical decision is left vague

## Verify every finding

Do not guess. A finding goes in the report only after you checked it against the source.

For each possible finding:

1. **Read the plan step itself**, plus the spec or design item it should cover.
2. **Check the repo.** When a step names a file, function, command, or test, open it. Make sure it exists and does what the plan assumes.
3. **Search the whole plan.** A missing test or migration may sit in a later step.
4. **Try to prove yourself wrong.** If another step or the repo already covers it, drop the finding.

Then sort the result:

- **Confirmed** → you can name the step and the requirement, file, or order that is wrong or missing. It goes in a fix list.
- **Not confirmed** → you could not see the code or doc that decides it. Put it in **Questions for you**. Say what you checked.
- **Disproved** → leave it out.

Fill **Checked:** on each finding with the steps, spec or design items, and repo files you read, e.g. `plan todo 3, 5; design §2; db/migrate/`.

### Rules

- Never write "might", "could", or "probably" in a **Must fix** or **Should fix** item. If you are not sure, it is a question.
- Never quote or describe a document or file you did not open.

## Report

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `reports/plan-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map `READY TO EXECUTE` → `READY`).

List the file on the task. Do **not** put `status` on the plan or the review file. Log the verdict on `task-*.md`. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** active plan plus task/spec/design contract and `context.md`.

**Read only when needed:** exact repo files/symbols needed to validate risky plan assumptions.

**Avoid loading:** broad repo exploration already completed by `coding-plan` unless review discovers a specific gap.

**Context update:** keep only accepted plan-review decisions and unresolved blockers; corrections belong in the plan. See [`../../CONTEXT.md`](../../CONTEXT.md).
