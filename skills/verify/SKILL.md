---
name: verify
description: >-
  Verify completed work against the task/spec/design/plan, not merely whether
  tests pass. Produces requirement-by-requirement evidence and identifies gaps.
  Use when the user names verify, finished work must be checked against its
  criteria, or a workflow reaches this stage.
---

# Verify

Ask: **Did the work actually satisfy what we said should be true?**

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

## Same folder as the task

Write the report **only** here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/verification-<slug>.md
```

That `reports/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Load the task and the relevant spec/design/active plan. Inspect implementation/test evidence when the work is coding-related.

Write a **short** report using [`templates/review-report.md`](../../templates/review-report.md) in chat and in `reports/verification-<slug>.md`.

- Put each FAIL / NOT VERIFIED criterion as a **Must fix** item (**Where** = the evidence).
- Keep a tiny matrix only if it helps; do not paste a huge table as the whole report.
- User fills **Your call:** (`fix` / `skip` / `need more info`).
- Verdict: `READY` if all PASS, `NOT READY` if any FAIL, `READY WITH CHANGES` if gaps remain but are accepted.

Cap: 5 Must fix. Extra questions go in **Questions for you** in the same report (do not also create `questions-verify-*.md` unless the user asks).

Never equate `tests exited 0` with task completion unless tests cover every acceptance criterion.

Append a one-line verdict to the task **Execution Log**.

## Context Budget

**Required:** task acceptance criteria, active spec/design/plan as applicable, `context.md`, and concrete execution evidence.

**Read only when needed:** changed files, targeted tests/commands, runtime/metric evidence tied to a criterion.

**Avoid loading:** unrelated code, full development history, old discussions not needed to prove a criterion.

**Context update:** replace the `Verification Signals` section with concise evidence/results and preserve only remaining gaps. Detailed matrices may live in `reports/verification-*.md`. See [`../../CONTEXT.md`](../../CONTEXT.md).
