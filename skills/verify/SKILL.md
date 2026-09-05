---
name: verify
description: >-
  Verify completed work against the task/spec/design/plan, not merely whether
  tests pass. Produces requirement-by-requirement evidence and identifies gaps.
  Explicit opt-in only.
disable-model-invocation: true
---

# Verify

Ask: **Did the work actually satisfy what we said should be true?**

Load the task and the relevant spec/design/active plan. Inspect implementation/test evidence when the work is coding-related.

Produce a verification matrix:

```markdown
| Requirement / Criterion | Evidence | Result |
|---|---|---|
| <criterion> | <test, command, observation, diff, metric> | PASS / FAIL / NOT VERIFIED |
```

Also verify relevant quality attributes, compatibility, failure cases, migrations, and operational behavior.

Never equate `tests exited 0` with task completion unless tests cover every acceptance criterion.

If persisted, append concise evidence to the task **Execution Log** and/or write `discussion/verification-<slug>.md` when details are large.

## Context Budget

**Required:** task acceptance criteria, active spec/design/plan as applicable, `context.md`, and concrete execution evidence.

**Read only when needed:** changed files, targeted tests/commands, runtime/metric evidence tied to a criterion.

**Avoid loading:** unrelated code, full development history, old discussions not needed to prove a criterion.

**Context update:** replace the `Verification Signals` section with concise evidence/results and preserve only remaining gaps. Detailed matrices may live in `discussion/verification-*.md`. See [`../../CONTEXT.md`](../../CONTEXT.md).
