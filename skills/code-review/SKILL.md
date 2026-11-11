---
name: code-review
description: >-
  Review the actual code diff against the task, spec, design, and plan. Focuses
  on correctness, requirement compliance, maintainability, failure handling,
  concurrency, performance, compatibility, observability, and test quality.
  Use when the user names code-review, finished code needs a review, or a
  workflow reaches this stage.
---

# Code Review

Review **the implementation**, using earlier artifacts as the contract.

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

## Same folder as the task

Write the report **only** here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/code-review-<slug>.md
```

That `reports/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Load when available:
- task record
- current spec
- current design
- active/chosen plan
- git diff / changed files
- tests and verification evidence

Prioritize:
1. requirement/spec violations
2. correctness and data-loss risks
3. race/concurrency/failure-path bugs
4. compatibility/migration/operational issues
5. missing or misleading tests
6. maintainability / needless complexity

## Verify every finding

Do not guess. A finding goes in the report only after you checked it in the code.

For each possible finding:

1. **Read the changed code itself**, not only the diff lines. Read the whole function and the code around it.
2. **Trace callers.** Search for every place that calls the changed function, type, or field (`grep`/`rg`, go-to-definition). Check that each caller still works with the new behavior: arguments, return values, errors, nulls.
3. **Trace callees.** Open the functions the changed code calls. Check what they really return, throw, or change. Do not trust a name.
4. **Check the tests.** Find the tests that cover this path. Note what they prove and what they miss.
5. **Try to prove yourself wrong.** Look for a guard, a check, a type, or a test that already stops the problem. If you find one, drop the finding.

Then sort the result:

- **Confirmed** → you can name the input or state that breaks it, and the line where it goes wrong. It goes in **Must fix** / **Should fix** / **Nice to have**.
- **Not confirmed** → you could not see the code that decides it (another repo, runtime config, missing access), or the answer depends on intent. Put it in **Questions for you**. Say what you checked and what you could not see.
- **Disproved** → leave it out.

In each finding, add one line under **Where:**:

```markdown
**Checked:** callers `a.ts:40`, `b.ts:12`; callee `save()` in `db.ts:88`; test `save.test.ts` (no null case)
```

### Rules

- Never write "might", "could", or "probably" in a **Must fix** or **Should fix** item. If you are not sure, it is a question.
- Never say how a function behaves without opening it.
- Never claim a test passes or fails without its output.

## Report

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `reports/code-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map `APPROVE` → `READY`, `APPROVE WITH NITS` → `READY WITH CHANGES`, `CHANGES REQUIRED` → `NOT READY`).

List the file on the task. Findings stay in the report; fixes stay in code. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** actual diff/changed files, task/spec/design/plan contract, verification evidence, and `context.md`.

**Required per finding:** the direct callers, callees, and tests of the code the finding is about (see **Verify every finding**).

**Read only when needed:** interfaces, migrations, and operational code relevant to a finding.

**Avoid loading:** unrelated repo areas or old conversations simply to gain confidence.

**Context update:** record only unresolved review blockers or final approval state/evidence. Findings themselves belong in the review output; source-of-truth fixes remain in code/artifacts. See [`../../CONTEXT.md`](../../CONTEXT.md).
