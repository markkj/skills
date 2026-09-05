# Context Management Policy

This skill pack uses a **bounded, task-scoped context cache** to reduce repeated repository scans and long conversation replay.

The durable source of truth remains the task/spec/design/plan artifacts. `context.md` is only a compact handoff cache.

## Context file

For work that benefits from multi-stage handoff, use:

```text
Projects/<PROJECT_NAME>/<WORK_ID>/context.md
```

Create it lazily when the first clarification/spec/design/planning/review stage needs persistent handoff context. `work-intake-automation` still creates **only** the task file.

## Rules

1. **Load minimum context first.** Start from `task-*.md`, `context.md` if present, and the active artifact for the current stage.
2. **Progressive disclosure.** Inspect only named/referenced repo files and direct dependencies first; expand search only when blocked.
3. **Do not replay resolved history.** Prefer compact decisions/facts in `context.md` over old chat, Jira comment history, archived plans, or discussion files.
4. **Artifacts beat summaries.** When a detail matters for correctness, read the authoritative spec/design/plan rather than trusting a summary.
5. **Keep the cache bounded.** Target `context.md` at <= ~1,200 words. Replace stale detail; do not append forever.
6. **Link, don't duplicate.** Record artifact paths and file/symbol references instead of copying large bodies.
7. **Preserve unresolved items.** Open questions and blockers stay until resolved, then collapse them into a decision/fact or remove them.
8. **No hidden decisions.** Any durable product/architecture decision belongs in spec/design/plan/ADR; `context.md` may summarize it but must not be its only record.

## Loading order

Default order for a stage:

```text
1. task-*.md
2. context.md (if present)
3. active artifact for this stage
4. directly referenced code/docs
5. direct callers/callees / neighboring examples
6. broader repo history/search only if needed
```

## Context compaction

After a stage reaches a stable result, update `context.md` by **rewriting the compact state**, not by appending a transcript. Keep only what the next stage is likely to need.
