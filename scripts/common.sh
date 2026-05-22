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
  # [[:space:]] — portable; BSD sed does not treat \s as whitespace
  name="$(grep -E '^name:[[:space:]]*' "$skill_md" 2>/dev/null | head -1 \
    | sed -E 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")"
  name="${name#"${name%%[![:space:]]*}"}"
  name="${name%"${name##*[![:space:]]}"}"
  if [ -n "$name" ]; then
    echo "$name"
  else
    basename "$(dirname "$skill_md")"
  fi
}

# Drop symlinks in dest that point into repo/skills/ but are not in expected_names
skill_prune_stale_links() {
  local dest="$1"
  local repo="$2"
  shift 2
  local expected=("$@")
  local entry base target keep

  [ -d "$dest" ] || return 0

  for entry in "$dest"/*; do
    [ -L "$entry" ] || continue
    target="$(readlink "$entry")"
    case "$target" in
      "$repo/skills"|"$repo"/skills/*)
        base="$(basename "$entry")"
        keep=false
        for name in "${expected[@]}"; do
          if [ "$base" = "$name" ]; then
            keep=true
            break
          fi
        done
        if ! $keep; then
          rm "$entry"
          echo "[prune] removed stale $base (-> $target)"
        fi
        ;;
    esac
  done
}

skill_dir_name() {
  basename "$(dirname "$1")"
}
