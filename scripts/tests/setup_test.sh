#!/bin/sh
# setup.sh installs and updates the plugin, passes --per-session through,
# and links the center CLAUDE.md.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "fail: $1" >&2
  exit 1
}

cat > "$TMP/claude" <<'STUB'
#!/bin/sh
echo "$*" >> "$CLAUDE_LOG"
STUB
chmod +x "$TMP/claude"
export CLAUDE_BIN="$TMP/claude"
export CLAUDE_LOG="$TMP/log"
export MARKKJ_SHELL_RC="$TMP/zshrc"
export CLAUDE_SKILLS_DIR="$TMP/skills"
export CLAUDE_CENTER_FILE="$TMP/claude-home/CLAUDE.md"

sh "$ROOT/scripts/setup.sh" --per-session > /dev/null
grep -q "plugin install markkj-skills@markkj-skills" "$CLAUDE_LOG" || fail "plugin not installed"
grep -q "plugin update markkj-skills@markkj-skills" "$CLAUDE_LOG" || fail "plugin not updated"
grep -q "plugin disable markkj-skills@markkj-skills" "$CLAUDE_LOG" || fail "--per-session not passed through"
[ "$(readlink "$CLAUDE_CENTER_FILE")" = "$ROOT/CLAUDE.md" ] || fail "center CLAUDE.md not linked"

# A second run must not fail on the link it made the first time.
sh "$ROOT/scripts/setup.sh" --per-session > /dev/null || fail "second run failed"

echo "ok"
