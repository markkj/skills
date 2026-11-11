# Review report

## How to use this file

1. Read **Verdict** (one line).
2. For each item, fill **Your call:** with `fix`, `skip`, or `need more info`.
3. Optional: write a short note under **Your note:**.
4. Tell the agent this file is filled.

Do not edit **What** / **Why** / **Where** / **Checked**. Those are for the reviewer.

Every finding was checked against the source before it went in. Anything the reviewer could not confirm is in **Questions for you**, not in the fix lists.

- **Kind:** spec-review | design-review | plan-review | code-review | verify
- **Looks at:** `<path to spec/design/plan/diff>`
- **Task:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/task-<slug>.md`
- **Write this file at:** `$PROJECT_PATH/<PROJECT_NAME>/<WORK_ID>/reports/<kind>-<slug>.md` (same folder as the task, never repo root)
- **Date:** YYYY-MM-DD

## Verdict

`NOT READY` | `READY WITH CHANGES` | `READY`

**In plain words:** <one sentence — what this means for the user>

**Next:** Fill **Your call** below. Then the agent updates the artifact (or skips).

---

## Must fix

Blockers. Do not go to the next stage until these are `fix` or you explicitly `skip`.

### 1
**What:** <one sentence>
**Why it matters:** <one short line>
**Where:** `<file or section>`
**Checked:** <what the reviewer read to confirm this: callers, callees, and tests for code; linked sections and source docs for a spec, design, or plan>
**Your call:**
**Your note:**

---

## Should fix

Important, but the work can continue if you `skip`.

*(none)*

---

## Nice to have

Optional. Ignore if you do not care.

*(none)*

---

## Questions for you

Only if a finding needs your decision, not a code/doc fix. Type on **A:**.

### Q1
Q: <one clear question>
Why it matters: <one short line>
A:
