---
name: daily-check-in
description: >-
  Builds today's work list from every Obsidian project and writes a daily log.
  Use only when the user names daily-check-in, asks for a daily check-in,
  a daily log, or what to do today from project tasks.
disable-model-invocation: true
---

# Daily Check-in

**Do not auto-apply.** Load only when the user names `daily-check-in`, asks for a daily check-in, a daily log, or what to do today from project tasks.

Scan **every** project under `Projects/`. Rank a short Today list. Write one note under `Projects/Daily Log`. Read yesterday only when that file exists.

Do not create or edit `task-*.md`, specs, designs, or plans. Do not mark tasks Done.

## Paths

`$OBSIDIAN_BASE_VAULT_PATH` is the Obsidian vault root. If unset or empty → **STOP** and report. No other root.

Only look inside `Projects/`. Ignore the rest of the vault.

| Item | Vault-relative path |
|------|---------------------|
| Tasks | `Projects/<any project>/<WORK_ID>/task-*.md` |
| This log | `Projects/Daily Log/YYYY-MM-DD.md` |
| Template | [`templates/daily-log.md`](../../templates/daily-log.md) |
| Query | [`scripts/query-tasks.py`](scripts/query-tasks.py) next to this skill |

Do not filter by `TASK_PROJECT`, the git repo, or the current directory. `Daily Log` is the log folder, not a project.

## Phases

Run in order.

| Phase | Do | Verify | STOP if |
|-------|----|--------|---------|
| **1 — Query** | Run the script below. Do not open task files. | Exit 0 and a `today` line | Vault unset, or the script fails |
| **2 — Write** | `mkdir -p` `Projects/Daily Log`, fill the template from the script output | Read-back matches | Write failed |
| **3 — Report** | Short list in chat plus the vault path | User can open the file | — |

### 1 — Query

From the skill directory:

```bash
python3 scripts/query-tasks.py
```

The script uses the local calendar date. It walks every folder in `$OBSIDIAN_BASE_VAULT_PATH/Projects` except `Daily Log`, reads frontmatter plus the goal or active-plan line, and prints a ranked list. Closed tasks (`Done`, `Cancelled`) are counted and omitted. If `Projects/` is missing → **STOP**.

Do not re-sort. Do not open a task file to "add detail." Copy `next` from the script.

Columns after the header lines, tab-separated:

`section` `n` `why` `status` `priority` `date` `project` `title` `path` `ref` `next`

`ref` is the Obsidian wikilink: `[[Projects/<project>/<work-id>/task-<slug>|title]]`. Copy it next to `path` on every task line. Do not invent a different link.

| Script line | Meaning |
|-------------|---------|
| `today` / `yesterday` | Local dates |
| `yesterday_log` | Path or `none` |
| `today_log` | Path or `none` |
| `counts` | projects, tasks, open, closed, blocked |
| `yesterday_done` | Checked yesterday, or now closed |
| `today` | Today list, max 3. Carry-ins first, then In Progress, Planned, Intake. Priority `1` is first. Older date wins ties. |
| `blocked` | Every blocked task. Not in Today. |
| `later` | Next open tasks, max 15 |
| `later_omitted` | How many Later rows were cut |
| `notes<<` … `notes<<` | Existing Notes body. Copy it back unchanged. |

Rank rules live in the script. `why` is one of `carry from yesterday`, `already in progress`, `highest open priority`.

### 2 — Write

1. `mkdir -p "$OBSIDIAN_BASE_VAULT_PATH/Projects/Daily Log"`
2. Fill [`templates/daily-log.md`](../../templates/daily-log.md) from the script. No leftover `<placeholders>`.
3. Today rows use `- [ ]` so the next run can see what is still open. Each task row includes `ref` and `path`.
4. If `today_log` is not `none`, put the `notes<<` block under **Notes**.
5. Read the file back. Frontmatter `date` is the script `today` line. `project` is `all`. `previous` is `yesterday_log`.

## Chat report

```markdown
## Daily check-in

- **Log:** `Projects/Daily Log/YYYY-MM-DD.md`
- **Scope:** all projects (`counts`)
- **Yesterday:** <path | none>
- **Today:**
  1. <title> — <why>
- **Blocked:** <count>
- **Left out:** <later_omitted plus later rows>
```

## Example

Two projects, one carry-in. Script already ranked them.

```markdown
---
date: 2026-10-03
tags:
  - daily-log
project: all
previous: Projects/Daily Log/2026-10-02.md
---

# 2026-10-03

## Yesterday

- **Log:** `Projects/Daily Log/2026-10-02.md`
- **Done:** Export button spec
- **Still open:** Fix login timeout

## Today

- [ ] [[Projects/client-app/20261001-login-timeout/task-login-timeout|Fix login timeout]] — `In Progress` · priority `1` · `Projects/client-app/20261001-login-timeout/task-login-timeout.md`
  - Why: carry from yesterday
  - Next: Confirm the timeout is enforced on the session cookie
- [ ] [[Projects/client-app/add-export-button/task-add-export-button|Add export button]] — `Planned` · priority `2` · `Projects/client-app/add-export-button/task-add-export-button.md`
  - Why: highest open priority
  - Next: Open the task and pick the next step

## Blocked

- [[Projects/billing/20260928-billing-webhook/task-billing-webhook|Billing webhook]] — `Blocked` · priority `2` · `Projects/billing/20260928-billing-webhook/task-billing-webhook.md`
  - Next: see task

## Later

- *(none)*

## Notes

```
