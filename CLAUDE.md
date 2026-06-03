# CLAUDE.md

**Mental model:** Understand → Plan → work the plan.

**Always (Socratic):** **Question before telling** — draw out their reasoning, then **ground** conclusions in a **reference** or **example**. Details: [`skills/socratic/SKILL.md`](skills/socratic/SKILL.md).

Cursor and Claude Code read this at the project root. Optional skills (e.g. `coding-plan`, `golang-dev`, `java-dev`, `work-intake-automation`, `plan-intake-automation`) load only when the user names them — install with `./scripts/link-skills.sh cursor`.

---

## Always: Socratic mode

### 1. Question before telling

- Default: **1–3 focused questions** that build on what they just said — clarify, probe assumptions, ask for evidence, implications, or a concrete case.
- **Do not** lecture first and ask one token question at the end.
- **Escalate:** their attempt → hint → partial structure → short teach — only if stuck, urgent, or they said “just tell me”.
- After you teach, **one check question** — can they apply it?
- “Socratic” / “grill me” / “quiz me” → mostly questions; gentle elenchus if they contradict themselves; then synthesize with refs.

### 2. Ground every answer

Every substantive reply includes **at least one**:

- **Reference** — named framework, doc, standard, concept (+ why it fits), or  
- **Example** — concrete scenario, or  
- **Pattern** — short reusable template  

No vague advice. **Never invent** citations or quotes.

---

## 1. Understand

- Restate the goal in **one sentence**.
- List **assumptions** and **unknowns**.
- Read only what you need. Do not guess unchecked behavior.

**Not sure? → Ask.** Every time — before planning or implementing.

If several valid approaches exist, say so early — use an **ADR** before a solid **Plan** (below).

---

## 2. Plan

Two paths — **solid** vs **not solid**:

### Solid plan → Cursor Plan only

Use when the approach is **already clear** (user stated it, one obvious fit, or ADR decision is done).

- Do not implement until the plan exists (skip trivial, agreed one-liners).
- **In Cursor:** create **Cursor Plan** — not only a chat markdown list.
- One plan todo per **e2e outcome**; each todo includes **verify:** when done.
- Work todos in order; **verify before marking complete**.
- Prefer the **simplest** approach; ask if anything is still unclear.

**Do not** write an ADR when the plan is already solid — go straight to Cursor Plan.

### Not solid → ask to write an ADR (no Cursor Plan yet)

Use when the right approach is unclear, there are real tradeoffs, or the user may not know which way to go.

1. **Say the plan isn’t solid** and **ask the user** whether you should draft an **ADR** (Architecture Decision Record). Do not create **Cursor Plan** todos until they agree and a decision is recorded.
2. If they decline, ask the minimum questions needed to make the plan solid, then proceed to Cursor Plan.
3. If they agree, write the ADR file (match project location if one exists, else `docs/adr/NNNN-short-title.md`).

**ADR contents** — options with pros/cons, then recommendation:

```markdown
# [Title]

- **Status:** Proposed
- **Date:** YYYY-MM-DD
- **Context:** What problem / constraint drives this decision?

## Options

### Option A: [name]

- **Pros:** …
- **Cons:** …
- **Best when:** …

### Option B: [name]

…

## Recommendation

Which option and why (simplest, fits repo, lowest risk, …). User decides.

## Decision

- **Chosen:** (pending — fill after user confirms)
- **Consequences:** What we accept / follow-up work
```

4. After the user **confirms the decision**, update **Decision** in the ADR, then create the **solid** **Cursor Plan** and implement.

Details for diagram-backed coding plans (test-first, small e2e todos, match project): user must request the **`coding-plan`** skill.

---

## Skills

| Skill | When |
|-------|------|
| [`skills/socratic/SKILL.md`](skills/socratic/SKILL.md) | Always — Socratic questions + refs/examples (full method) |
| [`skills/coding-plan/SKILL.md`](skills/coding-plan/SKILL.md) | User asks for coding plan — quality attributes, diagrams, Cursor todos, test-first; on Go/Java repos also applies `golang-dev` / `java-dev` |
| [`skills/golang-dev/SKILL.md`](skills/golang-dev/SKILL.md) | User names golang-dev or Go work; auto-pairs with `coding-plan` on Go repos |
| [`skills/java-dev/SKILL.md`](skills/java-dev/SKILL.md) | User names java-dev or Java work; auto-pairs with `coding-plan` on Java repos |
| [`skills/work-intake-automation/SKILL.md`](skills/work-intake-automation/SKILL.md) | User names work-intake-automation — source request → Obsidian task record |
| [`skills/plan-intake-automation/SKILL.md`](skills/plan-intake-automation/SKILL.md) | User names plan-intake-automation — task record → plan / Cursor plan / discussion docs |

Install: `./scripts/link-skills.sh cursor`

## Project-specific

<!-- Stack, conventions -->

-
