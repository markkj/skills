---
name: code-review
description: >-
  Review the actual code diff against the task, spec, design, and plan. Focuses
  on correctness, requirement compliance, maintainability, failure handling,
  concurrency, performance, compatibility, observability, and test quality.
  Explicit opt-in only.
disable-model-invocation: true
---

# Code Review

Review **the implementation**, using earlier artifacts as the contract.

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

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `discussion/code-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map `APPROVE` → `READY`, `APPROVE WITH NITS` → `READY WITH CHANGES`, `CHANGES REQUIRED` → `NOT READY`).

List the file on the task. Findings stay in the report; fixes stay in code. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** actual diff/changed files, task/spec/design/plan contract, verification evidence, and `context.md`.

**Read only when needed:** direct callers/callees, affected tests, interfaces, migrations, and operational code relevant to a finding.

**Avoid loading:** unrelated repo areas or old conversations simply to gain confidence.

**Context update:** record only unresolved review blockers or final approval state/evidence. Findings themselves belong in the review output; source-of-truth fixes remain in code/artifacts. See [`../../CONTEXT.md`](../../CONTEXT.md).
