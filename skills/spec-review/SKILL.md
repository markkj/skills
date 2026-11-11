---
name: spec-review
description: >-
  Review an existing specification for correctness, completeness, ambiguity,
  testability, scope, contradictions, constraints, and missing failure cases.
  Use when the user names spec-review, a new spec needs a check before design
  or plan, or a workflow reaches this stage.
---

# Spec Review

Review the requirement spec (`requirement-spec-<slug>.md` from [`requirement-spec`](../requirement-spec/SKILL.md)), not the implementation.

Ask: **Did we define the right thing clearly enough to design or execute?**

**Prose:** Sentences in the markdown follow [`humanizer`](../humanizer/SKILL.md). Keep this skill's headings, YAML, links, and checkboxes.

## Same folder as the task

Write the report **only** here:

```text
$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/spec-review-<slug>.md
```

That `reports/` folder is next to `task-*.md`, not at the git repo root. No task file → STOP; name [`work-intake-automation`](../work-intake-automation/SKILL.md) first.

Check:
- goal vs source task
- explicit non-goals
- acceptance criteria are observable/testable
- contradictions or ambiguous words
- missing constraints/dependencies
- missing failure/edge cases
- hidden solution decisions masquerading as requirements
- unresolved questions that block the next stage

## Verify every finding

Do not guess. A finding goes in the report only after you checked it against the source.

For each possible finding:

1. **Read the spec section itself**, not only its title or summary.
2. **Check the source.** Open the task, ticket, or source requirement the section comes from. Make sure the gap or conflict is real there too.
3. **Search the whole spec.** A missing case may be covered in another section, a non-goal, or a linked doc.
4. **Try to prove yourself wrong.** If another section or linked doc already answers it, drop the finding.

Then sort the result:

- **Confirmed** → you can quote the line that is wrong, missing, or in conflict. It goes in a fix list.
- **Not confirmed** → the answer depends on intent or a doc you cannot see. Put it in **Questions for you**. Say what you checked.
- **Disproved** → leave it out.

Fill **Checked:** on each finding with the sections and source docs you read, e.g. `spec §3, §5; task-login.md acceptance criteria`.

### Rules

- Never write "might", "could", or "probably" in a **Must fix** or **Should fix** item. If you are not sure, it is a question.
- Never quote or describe a document or file you did not open.

## Report

Return a **short** report using [`templates/review-report.md`](../../templates/review-report.md) — same shape in chat and in `reports/spec-review-<slug>.md`.

The user only fills **Your call:** (`fix` / `skip` / `need more info`). Do not dump this checklist into the report. Cap: 5 Must fix, 5 Should fix, 3 Nice to have.

Verdict in the report: `READY` | `READY WITH CHANGES` | `NOT READY` (map old `READY WITH ASSUMPTIONS` → `READY WITH CHANGES`).

List the file on the task. Do **not** put `status` on the spec or the review file. Log the verdict on `task-*.md`. Do not overwrite the spec unless explicitly asked to revise it. Extra questions go in **Questions for you** in the same report.

## Context Budget

**Required:** active spec, task record, and `context.md` if present.

**Read only when needed:** source requirements or adjacent contracts used to challenge completeness.

**Avoid loading:** implementation code unless necessary to identify a hard feasibility/compatibility constraint.

**Context update:** on accepted review findings, update only the compact unresolved/resolved state in `context.md`; authoritative changes belong in the spec. See [`../../CONTEXT.md`](../../CONTEXT.md).
