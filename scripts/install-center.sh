#!/bin/sh
# Opt-in: link this repo's CLAUDE.md to ~/.claude/CLAUDE.md.
# It never replaces a CLAUDE.md that is not already a link to this repo.
#
#   ./scripts/install-center.sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SRC="$REPO/CLAUDE.md"
DEST=${CLAUDE_CENTER_FILE:-$HOME/.claude/CLAUDE.md}

if [ -L "$DEST" ]; then
  if [ "$(readlink "$DEST")" != "$SRC" ]; then
    echo "error: $DEST links to $(readlink "$DEST"), not this repo. Move it aside, then re-run." >&2
    exit 1
  fi
elif [ -e "$DEST" ]; then
  echo "error: $DEST exists and is not this repo's. Move it aside, then re-run." >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
ln -sfn "$SRC" "$DEST"
echo "CLAUDE.md $DEST -> $SRC"
