#!/bin/sh
# Install markkj-skills as a Claude Code plugin from this repo.
#
#   ./scripts/install-claude-plugin.sh                 on in every session
#   ./scripts/install-claude-plugin.sh --per-session   off by default; start a
#                                                      markkj session with claude-mk
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
CLAUDE=${CLAUDE_BIN:-claude}
PLUGIN="markkj-skills@markkj-skills"
PER_SESSION=false

for arg in "$@"; do
  case "$arg" in
    --per-session) PER_SESSION=true ;;
    *) echo "usage: $0 [--per-session]" >&2; exit 2 ;;
  esac
done

# The CLI wants ./path, not a bare path; the trailing slash marks it local.
if "$CLAUDE" plugin marketplace list 2>/dev/null | grep -q "markkj-skills"; then
  "$CLAUDE" plugin marketplace update markkj-skills
else
  "$CLAUDE" plugin marketplace add "$REPO/"
fi
"$CLAUDE" plugin install "$PLUGIN"

# Copies made by the old link-skills.sh load beside the plugin's own skills
# (each skill listed twice, and loaded even with the plugin off). Only folders
# with this pack's marker are ours to remove.
SKILLS_DIR=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}
for marker in "$SKILLS_DIR"/*/.markkj-skills-installed; do
  [ -f "$marker" ] || continue
  copy=$(dirname "$marker")
  rm -rf "$copy"
  echo "removed old copy $copy"
done

if ! $PER_SESSION; then
  echo "markkj-skills is on in every Claude Code session."
  exit 0
fi

"$CLAUDE" plugin disable "$PLUGIN"

if [ -n "${MARKKJ_SHELL_RC:-}" ]; then
  RC=$MARKKJ_SHELL_RC
else
  case "${SHELL:-}" in
    */bash) RC="$HOME/.bashrc" ;;
    *) RC="$HOME/.zshrc" ;;
  esac
fi

BEGIN="# >>> markkj-skills claude-mk >>>"
END="# <<< markkj-skills claude-mk <<<"
touch "$RC"
TMP_RC="$RC.markkj.$$"
awk -v begin="$BEGIN" -v end="$END" '
  $0 == begin { skip = 1; next }
  $0 == end { skip = 0; next }
  !skip { print }
' "$RC" > "$TMP_RC"
{
  echo "$BEGIN"
  echo "alias claude-mk='claude --settings '\"'\"'{\"enabledPlugins\":{\"$PLUGIN\":true}}'\"'\"''"
  echo "$END"
} >> "$TMP_RC"
mv "$TMP_RC" "$RC"

echo "markkj-skills is off by default. Run claude-mk for a markkj session."
echo "Open a new shell or run: source $RC"
