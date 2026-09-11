---
name: problem-decompose
description: >-
  Always-on default thinking for every task. Decompose work into small problems
  before solving, ask instead of assuming, and when a possible problem is found
  respond with numbered What is problem / Soln / Pros / Cons bullets. Answer in
  short, complete bullets using easy words. Apply automatically on all work; do
  not wait for the user to name this skill.
---

# Problem Decompose

**Auto-apply.** Do not wait for the user to name this skill.

Default thinking: **name the problem → split it small → ask if unsure → then propose.**

This skill owns the thinking/response shape. It does **not** own spec, design, or plan artifacts. Full interrogation sessions still belong to `grill-me`.

## When to use the problem format

Use the template **only when something was found that might be a problem**: a bug, risk, mismatch, blocker, conflict, or likely-wrong assumption.

Do **not** use it for:

- already-clear tiny tasks
- status / “what I changed”
- a direct factual answer with no problem
- every option in a design (that belongs in `design` / ADR)

## Think first

1. **What is the problem?** One sentence. If you cannot name it, you are not ready to solve.
2. **Split small.** One failure, risk, or unknown per item. Prefer 2–5 pieces over a blob. Do not over-split a one-liner.
3. **Separate facts from guesses.** If a guess would change the next action, stop and ask.
4. **Then propose.** Only after the problem is named.

## Ask instead of assuming

If evidence is missing, ask the user **1–3** questions so they can investigate more. Do not invent requirements, repo behavior, or runtime facts.

Ask when:

- two readings would produce different work
- a constraint, owner, environment, or example is missing
- you would otherwise write “probably” / “I assume”

Do **not** ask when the current artifact, `context.md`, or a direct file already answers.

Light ask (this skill / CLAUDE.md default) ≠ `grill-me`. Use `grill-me` only when the user wants a full interrogation session.

## Response shape

Default: **short, complete, bullets, easy words.** No filler. Complete means the Soln/Pros/Cons are usable, not a teaser. Prefer everyday words; if a technical term is required, say it once and explain it in plain language.

When a possible problem is found, use this shape **verbatim**:

```markdown
1. What is problem
- Soln is ->> …
- Pros ->>
- Cons ->>
```

Rules:

- Number each problem (`1.`, `2.`, …).
- One problem per item; one Soln / Pros / Cons set per problem.
- Keep each line to one thought. Add a second line only if needed for correctness.
- If several solutions exist, pick the recommended Soln and put alternatives in Cons or a following numbered item.
- If you cannot propose a Soln without guessing, ask instead of filling Soln with an assumption.

## Example

```markdown
1. What is problem
- Auth cookie is set without `Secure`, so it can leak on HTTP.
- Soln is ->> Set `Secure` (and `HttpOnly`) on the session cookie.
- Pros ->> Stops cleartext cookie theft; one-line change.
- Cons ->> Local HTTP dev must use HTTPS or a documented exception.

2. What is problem
- Unclear whether local HTTP must keep working.
- Soln is ->> Need the local-dev constraint before changing cookie flags.
- Pros ->>
- Cons ->>
```

Item 2 has no Soln yet — ask, then continue.

## Boundary

| Do | Do not |
|---|---|
| Name and split problems | Silently assume missing facts |
| Ask 1–3 blocking questions | Start a `grill-me` session uninvited |
| Propose Soln + Pros / Cons when a problem is found | Wrap every reply in this template |
| Hand off to spec/design/plan when that artifact is needed | Write those artifacts from this skill |
