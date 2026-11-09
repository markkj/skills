#!/bin/sh
# One command to install or update everything from this repo:
# the plugin (new skills included) and the center CLAUDE.md link.
#
#   ./scripts/setup.sh                 plugin on in every session
#   ./scripts/setup.sh --per-session   plugin off by default; use claude-kj
#
# Run it again after a pull to pick up new skills.
set -eu

REPO=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

sh "$REPO/scripts/install-claude-plugin.sh" "$@"
sh "$REPO/scripts/install-center.sh"

echo "Done. Restart Claude Code to load the new skills."
