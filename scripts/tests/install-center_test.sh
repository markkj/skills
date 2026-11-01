#!/bin/sh
# install-center.sh links CLAUDE.md into place, is safe to re-run, and never
# replaces a CLAUDE.md that is not this repo's.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "fail: $1" >&2
  exit 1
}

export CLAUDE_CENTER_FILE="$TMP/claude/CLAUDE.md"
"$ROOT/scripts/install-center.sh" > /dev/null
"$ROOT/scripts/install-center.sh" > /dev/null
[ "$(readlink "$CLAUDE_CENTER_FILE")" = "$ROOT/CLAUDE.md" ] || fail "CLAUDE.md not linked to this repo"

rm "$CLAUDE_CENTER_FILE"
echo "# mine" > "$CLAUDE_CENTER_FILE"
if "$ROOT/scripts/install-center.sh" > /dev/null 2>&1; then
  fail "replaced a CLAUDE.md it does not own"
fi
grep -q '^# mine$' "$CLAUDE_CENTER_FILE" || fail "own CLAUDE.md was changed"

echo "ok"
