#!/usr/bin/env bash
set -euo pipefail

# Links shippable skills from this repo into an agent skills directory.
#
# Layout:
#   skills/<skill-name>/SKILL.md
#   skills/<bucket>/<skill-name>/SKILL.md   (symlink name = <skill-name>)
#
# Skipped: deprecated/, in-progress/, personal/, examples/, _template/
#
# Usage:
#   ./scripts/link-skills.sh [cursor|claude|all]
#   ./scripts/link-skills.sh status [cursor|claude]

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$REPO/scripts/common.sh"

TARGET="${1:-cursor}"

link_into() {
  local dest="$1"
  local label="$2"
  local count=0
  local expected_names=()

  if [ -L "$dest" ]; then
    local resolved
    resolved="$(readlink -f "$dest" 2>/dev/null || readlink "$dest")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $dest is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$dest\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi

  mkdir -p "$dest"

  while IFS= read -r -d '' skill_md; do
    count=$((count + 1))
    local src link_name target
    src="$(dirname "$skill_md")"
    link_name="$(skill_name_from_md "$skill_md")"
    target="$dest/$link_name"
    expected_names+=("$link_name")

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "[$label] linked $link_name -> $src"
  done < <(skill_find "$REPO" -print0)

  if [ "$count" -gt 0 ]; then
    skill_prune_stale_links "$dest" "$REPO" "${expected_names[@]}"
  fi

  if [ "$count" -eq 0 ]; then
    echo "[$label] no shippable skills under skills/ (add skills/<name>/SKILL.md)" >&2
    return 1
  fi

  echo "[$label] done — $count skill(s)"
}

show_status() {
  local dest="$1"
  local label="$2"

  echo "=== $label ($dest) ==="

  while IFS= read -r -d '' skill_md; do
    local link_name target
    link_name="$(skill_name_from_md "$skill_md")"
    target="$dest/$link_name"
    rel="${skill_md#"$REPO"/}"

    if [ -L "$target" ]; then
      echo "  ✓ $link_name  -> $(readlink "$target")  ($rel)"
    elif [ -e "$target" ]; then
      echo "  ! $link_name  exists but is not a symlink ($rel)" >&2
    else
      echo "  · $link_name  not linked ($rel)"
    fi
  done < <(skill_find "$REPO" -print0)

  echo
}

CURSOR_DEST="$(cursor_skills_dir)"
LEGACY_CURSOR="$HOME/.cursor/skills"

case "$TARGET" in
  cursor)
    link_into "$CURSOR_DEST" "cursor"
    if [ "$CURSOR_DEST" != "$LEGACY_CURSOR" ]; then
      mkdir -p "$LEGACY_CURSOR"
      link_into "$LEGACY_CURSOR" "cursor-legacy"
    fi
    ;;
  claude)
    link_into "$HOME/.claude/skills" "claude"
    ;;
  all)
    link_into "$CURSOR_DEST" "cursor"
    if [ "$CURSOR_DEST" != "$LEGACY_CURSOR" ]; then
      mkdir -p "$LEGACY_CURSOR"
      link_into "$LEGACY_CURSOR" "cursor-legacy"
    fi
    link_into "$HOME/.claude/skills" "claude"
    ;;
  status)
    AGENT="${2:-cursor}"
    case "$AGENT" in
      cursor) show_status "$CURSOR_DEST" "cursor" ;;
      claude) show_status "$HOME/.claude/skills" "claude" ;;
      all)
        show_status "$CURSOR_DEST" "cursor"
        show_status "$HOME/.claude/skills" "claude"
        ;;
      *)
        echo "usage: $0 status [cursor|claude|all]" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "usage: $0 [cursor|claude|all|status]" >&2
    echo "  cursor|claude|all  — symlink into ~/.agents/skills (cursor) or ~/.claude/skills" >&2
    echo "  CURSOR_SKILLS_DIR    — override cursor destination (default: ~/.agents/skills)" >&2
    echo "  status [agent]     — show which skills are linked" >&2
    exit 1
    ;;
esac
