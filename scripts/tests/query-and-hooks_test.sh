#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fail() { echo "fail: $1" >&2; exit 1; }

mkdir -p "$TMP/root/alpha/W1" "$TMP/root/beta/W2" "$TMP/root/Daily Log"
echo $'---\nstatus: Planned\npriority: "1"\ndate: 2026-10-01\n---\n# Alpha\n\n## Goal\n\nShip alpha.' > "$TMP/root/alpha/W1/task-alpha.md"
echo $'---\nstatus: In Progress\npriority: "2"\ndate: 2026-10-02\n---\n# Beta\n\n## Goal\n\nShip beta.' > "$TMP/root/beta/W2/task-beta.md"

out=$(PROJECT_PATH="$TMP/root" python3 "$ROOT/skills/daily-check-in/scripts/query-tasks.py")
printf '%s\n' "$out" | grep -q 'projects=2' || fail "expected 2 projects: $out"
printf '%s\n' "$out" | grep -q 'alpha/W1/task-alpha.md' || fail "missing alpha"
printf '%s\n' "$out" | grep -q 'beta/W2/task-beta.md' || fail "missing beta"

# Claude hooks: every event names a script in hooks/ that can run.
node - "$ROOT" <<'JS' || fail "claude hooks config is wrong"
const fs = require("fs");
const root = process.argv[2];
const config = require(`${root}/hooks/claude-hooks.json`);
for (const event of ["Stop", "SubagentStop", "UserPromptSubmit"]) {
  const command = config.hooks[event][0].hooks[0].command;
  const file = command.replace(/"/g, "").replace("${CLAUDE_PLUGIN_ROOT}", root);
  fs.accessSync(file, fs.constants.X_OK);
}
JS

echo "ok"
