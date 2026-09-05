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

Report findings first, ordered by severity with concrete file/line references when possible. Avoid generic praise. State whether the implementation is `APPROVE`, `APPROVE WITH NITS`, or `CHANGES REQUIRED`.

## Context Budget

**Required:** actual diff/changed files, task/spec/design/plan contract, verification evidence, and `context.md`.

**Read only when needed:** direct callers/callees, affected tests, interfaces, migrations, and operational code relevant to a finding.

**Avoid loading:** unrelated repo areas or old conversations simply to gain confidence.

**Context update:** record only unresolved review blockers or final approval state/evidence. Findings themselves belong in the review output; source-of-truth fixes remain in code/artifacts. See [`../../CONTEXT.md`](../../CONTEXT.md).
