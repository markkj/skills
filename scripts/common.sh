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
