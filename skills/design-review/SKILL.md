---
name: design-review
description: >-
  Adversarially review an existing design against its task/spec for correctness,
  unnecessary complexity, failure modes, compatibility, operability,
  observability, scaling, migration, and missing tradeoffs. Use when the user
  names design-review, a new design needs a check before planning, or a
  workflow reaches this stage.
---

# Design Review

Ask: **Is this a sound way to satisfy the spec?**

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

## Same folder as the task

Write the report **only** here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/design-review-<slug>.md
```

That `reports/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Review:
- traceability to every important requirement
- correctness and invariants
- failure/retry/concurrency behavior
- reliability and scaling assumptions
- data/API/event compatibility
- security boundaries when relevant
- observability and operations
- rollout, migration, rollback
- complexity / simpler alternatives
- decisions hidden or deferred into implementation

## Verify every finding

Do not guess. A finding goes in the report only after you checked it against the source.

For each possible finding:

1. **Read the design section itself**, plus the spec requirement it is meant to meet.
2. **Check the real system.** When the finding depends on how an existing component, API, or schema behaves, open that code or contract. Do not trust a name or a diagram.
3. **Search the whole design.** A missing failure case or rollback may be covered in another section.
4. **Try to prove yourself wrong.** If the design, spec, or existing code already handles it, drop the finding.

Then sort the result:

- **Confirmed** → you can name the scenario that breaks it and the section (or code) where it goes wrong. It goes in a fix list.
- **Not confirmed** → you could not see the code, config, or contract that decides it. Put it in **Questions for you**. Say what you checked and what you could not see.
- **Disproved** → leave it out.

Fill **Checked:** on each finding with the sections, spec items, and code you read, e.g. `design §4; spec AC-2; api/orders.ts:30`.

### Rules

- Never write "might", "could", or "probably" in a **Must fix** or **Should fix** item. If you are not sure, it is a question.
- Never quote or describe a document or file you did not open.

## Report

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `reports/design-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY`.

List the file on the task. Do **not** put `status` on the design or the review file. Log the verdict on `task-*.md`. Do not silently rewrite the design. Extra questions (if any) go in **Questions for you** in the same report — do not create a second questions file unless the user asks.

## Context Budget

**Required:** active design, its spec/task contract, and `context.md`.

**Read only when needed:** exact components/contracts needed to validate a claim or risk.

**Avoid loading:** broad implementation context not relevant to the design decisions under review.

**Context update:** compact accepted findings/remaining blockers into `context.md`; actual design corrections belong in `design-*.md`. See [`../../CONTEXT.md`](../../CONTEXT.md).
