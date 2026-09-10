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

MARKKJ_SKILLS_MARKER=".markkj-skills-installed"

# Copy skill dir into dest (replaces symlinks and prior installs from this repo)
skill_sync_into() {
  local src="$1"
  local target="$2"
  local repo="$3"

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    if [ -f "$target/$MARKKJ_SKILLS_MARKER" ] \
      && [ "$(cat "$target/$MARKKJ_SKILLS_MARKER")" = "$repo" ]; then
      rm -rf "$target"
    else
      echo "error: $target exists and is not managed by link-skills.sh" >&2
      echo "Move it aside or remove it, then re-run." >&2
      return 1
    fi
  fi

  mkdir -p "$target"
  rsync -a --delete "$src/" "$target/"
  echo "$repo" > "$target/$MARKKJ_SKILLS_MARKER"
}

# Remove installs from this repo that are no longer in expected_names
skill_prune_stale_installs() {
  local dest="$1"
  local repo="$2"
  shift 2
  local expected=("$@")
  local entry base keep

  [ -d "$dest" ] || return 0

  for entry in "$dest"/*; do
    [ -e "$entry" ] || continue
    if [ -L "$entry" ]; then
      base="$(basename "$entry")"
      case "$(readlink "$entry")" in
        "$repo/skills"|"$repo"/skills/*)
          rm "$entry"
          echo "[prune] removed stale symlink $base"
          ;;
      esac
      continue
    fi
    [ -d "$entry" ] || continue
    [ -f "$entry/$MARKKJ_SKILLS_MARKER" ] || continue
    [ "$(cat "$entry/$MARKKJ_SKILLS_MARKER")" = "$repo" ] || continue

    base="$(basename "$entry")"
    keep=false
    for name in "${expected[@]}"; do
      if [ "$base" = "$name" ]; then
        keep=true
        break
      fi
    done
    if ! $keep; then
      rm -rf "$entry"
      echo "[prune] removed stale $base"
    fi
  done
}

skill_dir_name() {
  basename "$(dirname "$1")"
}

# Center file (CLAUDE.md) — global install for Claude Code + Cursor
CENTER_MARKER="markkj-skills-center:"
cursor_center_rule() {
  echo "${CURSOR_CENTER_RULE:-$HOME/.cursor/rules/markkj-skills-center.mdc}"
}

claude_center_file() {
  echo "${CLAUDE_CENTER_FILE:-$HOME/.claude/CLAUDE.md}"
}

# Symlink ~/.claude/CLAUDE.md -> repo CLAUDE.md
install_claude_center() {
  local repo="$1"
  local src="$repo/CLAUDE.md"
  local dest
  dest="$(claude_center_file)"

  if [ ! -f "$src" ]; then
    echo "error: missing center file $src" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    local resolved
    resolved="$(readlink "$dest")"
    case "$resolved" in
      "$src"|"$repo/CLAUDE.md") ;;
      *)
        echo "error: $dest is a symlink to $resolved (not this repo)." >&2
        echo "Move it aside, then re-run." >&2
        return 1
        ;;
    esac
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "error: $dest exists and is not a symlink to this repo's CLAUDE.md" >&2
    echo "Move it aside, then re-run." >&2
    return 1
  fi

  ln -sfn "$src" "$dest"
  echo "[claude] center CLAUDE.md -> $src"
}

# Write ~/.cursor/rules/*.mdc with frontmatter + CLAUDE.md body
install_cursor_center() {
  local repo="$1"
  local src="$repo/CLAUDE.md"
  local dest
  dest="$(cursor_center_rule)"

  if [ ! -f "$src" ]; then
    echo "error: missing center file $src" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] && ! grep -q "$CENTER_MARKER" "$dest" 2>/dev/null; then
    echo "error: $dest exists and is not managed by link-skills.sh" >&2
    echo "Move it aside, then re-run." >&2
    return 1
  fi

  {
    cat <<EOF
---
description: MarkKJ skills pack center — always-on workflow and default thinking
alwaysApply: true
---

<!-- $CENTER_MARKER $repo -->

EOF
    cat "$src"
  } > "$dest"

  echo "[cursor] center rule $dest <- $src"
}

show_center_status() {
  local repo="$1"
  local claude_dest cursor_dest
  claude_dest="$(claude_center_file)"
  cursor_dest="$(cursor_center_rule)"

  echo "=== center file ($repo/CLAUDE.md) ==="

  if [ -L "$claude_dest" ]; then
    echo "  ✓ claude  $claude_dest -> $(readlink "$claude_dest")"
  elif [ -e "$claude_dest" ]; then
    echo "  ! claude  $claude_dest exists but is not this repo's symlink" >&2
  else
    echo "  · claude  $claude_dest not installed"
  fi

  if [ -f "$cursor_dest" ] && grep -q "$CENTER_MARKER $repo" "$cursor_dest" 2>/dev/null; then
    echo "  ✓ cursor  $cursor_dest"
  elif [ -e "$cursor_dest" ]; then
    echo "  ! cursor  $cursor_dest exists but is not managed by this repo" >&2
  else
    echo "  · cursor  $cursor_dest not installed"
  fi

  echo
}
