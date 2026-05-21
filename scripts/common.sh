#!/usr/bin/env bash
# Shared helpers for link-skills.sh and list-skills.sh

# Directories under skills/ that are never installed
SKILL_SKIP_DIRS=(deprecated in-progress personal examples _template)

# Cursor loads global skills from ~/.agents/skills (override with CURSOR_SKILLS_DIR)
cursor_skills_dir() {
  echo "${CURSOR_SKILLS_DIR:-$HOME/.agents/skills}"
}

skill_find() {
  local repo="$1"
  shift
  local path_expr=()

  for dir in "${SKILL_SKIP_DIRS[@]}"; do
    path_expr+=(-not -path "*/${dir}/*")
  done

  # shellcheck disable=SC2086
  find "$repo/skills" -name SKILL.md \
    -not -path '*/node_modules/*' \
    "${path_expr[@]}" \
    "$@"
}

skill_name_from_md() {
  local skill_md="$1"
  local name
  name="$(grep -E '^name:\s*' "$skill_md" 2>/dev/null | head -1 | sed -E 's/^name:\s*//' | tr -d '"' | tr -d "'")"
  if [ -n "$name" ]; then
    echo "$name"
  else
    basename "$(dirname "$skill_md")"
  fi
}

skill_dir_name() {
  basename "$(dirname "$1")"
}
