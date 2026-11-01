#!/bin/sh
# The installer adds the marketplace and installs the plugin. With
# --per-session it also turns the plugin off and writes one claude-mk alias,
# and a second run replaces the alias instead of adding another.
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
if [ "$1 $2 $3" = "plugin marketplace list" ]; then
  echo "${STUB_MARKETPLACES:-}"
fi
STUB
chmod +x "$TMP/claude"
export CLAUDE_BIN="$TMP/claude"
export CLAUDE_LOG="$TMP/log"
export MARKKJ_SHELL_RC="$TMP/zshrc"
echo "# mine" > "$MARKKJ_SHELL_RC"

# Old link-skills.sh copies load beside the plugin's skills, so the installer
# removes them. A skill without the marker is someone else's and stays.
export CLAUDE_SKILLS_DIR="$TMP/skills"
mkdir -p "$CLAUDE_SKILLS_DIR/plan" "$CLAUDE_SKILLS_DIR/impeccable"
echo "/old/repo" > "$CLAUDE_SKILLS_DIR/plan/.markkj-skills-installed"
echo "# other" > "$CLAUDE_SKILLS_DIR/impeccable/SKILL.md"

sh "$ROOT/scripts/install-claude-plugin.sh" > /dev/null
grep -q "plugin marketplace add $ROOT/" "$CLAUDE_LOG" || fail "marketplace not added: $(cat "$CLAUDE_LOG")"
grep -q "plugin install markkj-skills@markkj-skills" "$CLAUDE_LOG" || fail "plugin not installed"
[ -e "$CLAUDE_SKILLS_DIR/plan" ] && fail "old copied skill not removed"
[ -f "$CLAUDE_SKILLS_DIR/impeccable/SKILL.md" ] || fail "removed a skill this pack does not own"
grep -q "plugin disable" "$CLAUDE_LOG" && fail "plain install must not disable the plugin"
grep -q "claude-mk" "$MARKKJ_SHELL_RC" && fail "plain install must not add the alias"

: > "$CLAUDE_LOG"
STUB_MARKETPLACES="  ❯ markkj-skills" sh "$ROOT/scripts/install-claude-plugin.sh" --per-session > /dev/null
STUB_MARKETPLACES="  ❯ markkj-skills" sh "$ROOT/scripts/install-claude-plugin.sh" --per-session > /dev/null
grep -q "plugin marketplace update markkj-skills" "$CLAUDE_LOG" || fail "known marketplace not updated"
grep -q "plugin disable markkj-skills@markkj-skills" "$CLAUDE_LOG" || fail "plugin not turned off by default"
count=$(grep -c "^alias claude-mk=" "$MARKKJ_SHELL_RC")
[ "$count" = "1" ] || fail "expected one claude-mk alias, got $count"
grep -q '^# mine$' "$MARKKJ_SHELL_RC" || fail "existing rc lines lost"
grep -q 'enabledPlugins' "$MARKKJ_SHELL_RC" || fail "alias does not turn the plugin on"

echo "ok"
