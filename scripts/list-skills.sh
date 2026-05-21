#!/usr/bin/env bash
set -euo pipefail

# Lists SKILL.md files in this repo (shippable vs skipped).
#
# Usage:
#   ./scripts/list-skills.sh
#   ./scripts/list-skills.sh --all    # include skipped dirs too

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$REPO/scripts/common.sh"

SHOW_ALL=false
if [ "${1:-}" = "--all" ]; then
  SHOW_ALL=true
fi

echo "Shippable skills (installed by link-skills.sh):"
echo

found=0
while IFS= read -r -d '' skill_md; do
  found=$((found + 1))
  rel="${skill_md#"$REPO"/}"
  name="$(skill_name_from_md "$skill_md")"
  dir="$(skill_dir_name "$skill_md")"
  if [ "$name" != "$dir" ]; then
    printf "  %-20s %s  (dir: %s)\n" "$name" "$rel" "$dir"
  else
    printf "  %-20s %s\n" "$name" "$rel"
  fi
done < <(skill_find "$REPO" -print0)

if [ "$found" -eq 0 ]; then
  echo "  (none — add skills/<name>/SKILL.md)"
fi

if $SHOW_ALL; then
  echo
  echo "Skipped / not installed (${SKILL_SKIP_DIRS[*]}):"
  while IFS= read -r skill_md; do
    rel="${skill_md#"$REPO"/}"
    skipped=false
    for dir in "${SKILL_SKIP_DIRS[@]}"; do
      case "$rel" in
        skills/"$dir"/*) skipped=true; break ;;
      esac
    done
    if $skipped; then
      echo "  $rel"
    fi
  done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' 2>/dev/null | sort)
fi

echo
echo "$found shippable skill(s). Install: ./scripts/link-skills.sh cursor"
