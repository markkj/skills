#!/usr/bin/env python3
"""Compact daily-check-in query. Stdlib only.

$OBSIDIAN_BASE_VAULT_PATH is the Obsidian vault root.
Scans only vault/Projects, skips Projects/Daily Log, and prints a short ranked list.
The agent writes the log from this output and does not open each task file.
"""

from __future__ import annotations

import os
import re
import sys
from datetime import date, timedelta
from pathlib import Path

TODAY_CAP = 3
LATER_CAP = 15
STATUS_RANK = {"In Progress": 0, "Planned": 1, "Intake": 2}
CLOSED = {"Done", "Cancelled"}
NEXT_FALLBACK = "Open the task and pick the next step"
SKIP_DIR_NAMES = {"Daily Log"}


def die(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1].strip()
    return value


def frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end]
    fields: dict[str, str] = {}
    for line in block.splitlines():
        if not line or line[0] in " \t-#" or ":" not in line:
            continue
        key, _, raw = line.partition(":")
        key = key.strip()
        if key in {"status", "priority", "date", "project"}:
            fields[key] = unquote(raw)
    return fields


def h1(text: str) -> str:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def section_body(text: str, heading: str) -> str:
    marker = f"## {heading}"
    start = text.find(marker)
    if start == -1:
        return ""
    rest = text[start + len(marker) :]
    nxt = re.search(r"\n## ", rest)
    body = rest[: nxt.start()] if nxt else rest
    return body.strip()


def first_prose(body: str) -> str:
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("<") or line.startswith("-"):
            continue
        if line.startswith("*") and line.endswith("*"):
            continue
        return re.sub(r"\s+", " ", line)[:140]
    return ""


def active_plan(text: str) -> str:
    for line in text.splitlines():
        if "**Active plan:**" not in line:
            continue
        value = line.split("**Active plan:**", 1)[1].strip()
        if not value or "none" in value.lower():
            return ""
        return re.sub(r"`([^`]*)`", r"\1", value)[:140]
    return ""


def priority_key(raw: str) -> tuple[int, str]:
    try:
        return (int(raw), raw)
    except (TypeError, ValueError):
        return (99, raw or "")


def date_key(raw: str) -> str:
    return raw if re.fullmatch(r"\d{4}-\d{2}-\d{2}", raw or "") else "9999-99-99"


def task_ref(rel: str, title: str) -> str:
    """Obsidian wikilink. Path is vault-relative, without .md."""
    stem = rel[:-3] if rel.endswith(".md") else rel
    alias = (title or Path(stem).name).replace("|", " ").strip()
    return f"[[{stem}|{alias}]]"


def task_link(line: str) -> tuple[str, str] | None:
    """Return (vault path with .md, title) from a wikilink or a backticked path."""
    wiki = re.search(r"\[\[(Projects/[^\]|]*task-[^\]|]+)(?:\|([^\]]+))?\]\]", line)
    if wiki:
        rel = wiki.group(1).strip()
        if not rel.endswith(".md"):
            rel += ".md"
        return rel, (wiki.group(2) or "").strip()
    path_match = re.search(r"`(Projects/[^`]*task-[^`]+\.md)`", line)
    if not path_match:
        return None
    return path_match.group(1), ""


def task_paths(body: str) -> list[tuple[bool, str, str]]:
    """Return (checked, title, vault path) from a Yesterday/Today body."""
    found: list[tuple[bool, str, str]] = []
    for line in body.splitlines():
        linked = task_link(line)
        if not linked:
            continue
        rel, title = linked
        if not title:
            title_match = re.search(r"\*\*([^*]+)\*\*", line)
            title = title_match.group(1).strip() if title_match else rel
        checked = bool(re.match(r"\s*-\s+\[[xX]\]", line))
        found.append((checked, title, rel))
    return found


def load_task(path: Path, vault: Path) -> dict[str, str] | None:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"skip\t{path}\t{exc}", file=sys.stderr)
        return None
    rel = path.relative_to(vault).as_posix()
    parts = Path(rel).parts
    project = parts[1] if len(parts) > 1 and parts[0] == "Projects" else ""
    meta = frontmatter(text)
    goal = first_prose(section_body(text, "Goal"))
    plan = active_plan(text)
    title = h1(text) or path.stem
    return {
        "status": meta.get("status", ""),
        "priority": meta.get("priority", ""),
        "date": meta.get("date", ""),
        "project": project,
        "title": title,
        "path": rel,
        "ref": task_ref(rel, title),
        "next": plan or goal or NEXT_FALLBACK,
    }


def find_tasks(projects: Path, vault: Path) -> list[dict[str, str]]:
    tasks: list[dict[str, str]] = []
    if not projects.is_dir():
        return tasks
    for dirpath, dirnames, filenames in os.walk(projects):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIR_NAMES and not d.startswith(".")]
        if Path(dirpath) == projects:
            continue
        for name in filenames:
            if name.startswith("task-") and name.endswith(".md"):
                loaded = load_task(Path(dirpath) / name, vault)
                if loaded:
                    tasks.append(loaded)
    return tasks


def emit(rows: list[dict[str, str]], section: str, why_for) -> None:
    for i, row in enumerate(rows, 1):
        why = why_for(row) if why_for else ""
        print(
            "\t".join(
                [
                    section,
                    str(i),
                    why,
                    row["status"],
                    row["priority"] or "unset",
                    row["date"] or "unset",
                    row["project"],
                    row["title"],
                    row["path"],
                    row["ref"],
                    row["next"],
                ]
            )
        )


def main() -> None:
    vault_raw = os.environ.get("OBSIDIAN_BASE_VAULT_PATH", "").strip()
    if not vault_raw:
        die("OBSIDIAN_BASE_VAULT_PATH is unset or empty", 2)
    vault = Path(vault_raw).expanduser()
    if not vault.is_dir():
        die(f"vault not found: {vault}", 2)

    today = date.today()
    yesterday = today - timedelta(days=1)
    projects_dir = vault / "Projects"
    if not projects_dir.is_dir():
        die(f"Projects folder not found: {projects_dir}", 2)
    log_dir = projects_dir / "Daily Log"
    y_path = log_dir / f"{yesterday.isoformat()}.md"
    t_path = log_dir / f"{today.isoformat()}.md"

    tasks = find_tasks(projects_dir, vault)
    by_path = {t["path"]: t for t in tasks}
    projects = sorted({t["project"] for t in tasks})

    carry: list[dict[str, str]] = []
    done_titles: list[str] = []
    if y_path.is_file():
        y_text = y_path.read_text(encoding="utf-8")
        for checked, title, path in task_paths(section_body(y_text, "Today")):
            current = by_path.get(path)
            if checked or (current and current["status"] in CLOSED):
                done_titles.append(title)
                continue
            if current and current["status"] != "Blocked":
                carry.append(current)

    carry_paths = {t["path"] for t in carry}
    open_tasks = [t for t in tasks if t["status"] not in CLOSED]
    blocked = [t for t in open_tasks if t["status"] == "Blocked"]
    pool = [t for t in open_tasks if t["status"] != "Blocked" and t["path"] not in carry_paths]
    pool.sort(key=lambda t: (STATUS_RANK.get(t["status"], 9), priority_key(t["priority"]), date_key(t["date"]), t["path"]))
    blocked.sort(key=lambda t: (priority_key(t["priority"]), date_key(t["date"]), t["path"]))

    ranked = carry + pool
    today_rows = ranked[:TODAY_CAP]
    later_pool = ranked[TODAY_CAP:]
    later_rows = later_pool[:LATER_CAP]
    omitted = max(len(later_pool) - LATER_CAP, 0)
    closed_n = sum(1 for t in tasks if t["status"] in CLOSED)

    notes = ""
    if t_path.is_file():
        notes = section_body(t_path.read_text(encoding="utf-8"), "Notes")

    print(f"today\t{today.isoformat()}")
    print(f"yesterday\t{yesterday.isoformat()}")
    print(f"yesterday_log\t{y_path.relative_to(vault).as_posix() if y_path.is_file() else 'none'}")
    print(f"today_log\t{t_path.relative_to(vault).as_posix() if t_path.is_file() else 'none'}")
    print(
        "counts\t"
        + "\t".join(
            [
                f"projects={len(projects)}",
                f"tasks={len(tasks)}",
                f"open={len(open_tasks)}",
                f"closed={closed_n}",
                f"blocked={len(blocked)}",
            ]
        )
    )
    if done_titles:
        for title in done_titles:
            print(f"yesterday_done\t{title}")
    else:
        print("yesterday_done\t—")

    def why_today(row: dict[str, str]) -> str:
        if row["path"] in carry_paths:
            return "carry from yesterday"
        if row["status"] == "In Progress":
            return "already in progress"
        return "highest open priority"

    emit(today_rows, "today", why_today)
    emit(blocked, "blocked", None)
    emit(later_rows, "later", None)
    print(f"later_omitted\t{omitted}")
    print("notes<<")
    if notes:
        print(notes)
    print("notes<<")


if __name__ == "__main__":
    main()
