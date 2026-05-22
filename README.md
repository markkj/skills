# markkj-skills

Your personal **Agent Skills** repo for Cursor and Claude Code.

| Mechanism | What it does |
|-----------|----------------|
| [`CLAUDE.md`](CLAUDE.md) | Always-on: understand → plan, **Socratic + refs/examples** |
| [`skills/socratic/SKILL.md`](skills/socratic/SKILL.md) | Full Socratic method (question types, escalation, synthesis) |
| [`skills/coding/SKILL.md`](skills/coding/SKILL.md) | Coding: Cursor Plan, test-first, match project |

## Quick start

```bash
# 1. CLAUDE.md — base + always-on Socratic rules

# 2. Install skills globally
./scripts/link-skills.sh cursor

# 3. Confirm
./scripts/list-skills.sh
./scripts/link-skills.sh status
```

Copy `CLAUDE.md` to any project root for the same always-on behavior.

## Layout

```
CLAUDE.md
skills/
├── socratic/          # question-first, refs/examples (always in CLAUDE.md too)
└── coding/            # test-first coding workflow
```

## Install

| Command | Target |
|---------|--------|
| `./scripts/link-skills.sh cursor` | `~/.agents/skills/` and `~/.cursor/skills/` (rsync copy each run) |
| `./scripts/link-skills.sh claude` | `~/.claude/skills/` |
| `./scripts/link-skills.sh all` | both |
| `./scripts/link-skills.sh status` | show what is linked |

Per-project (optional): copy or symlink `skills/<name>/` into `.cursor/skills/<name>/`.

Re-run `./scripts/link-skills.sh cursor` after editing skills in this repo so installed copies update.
