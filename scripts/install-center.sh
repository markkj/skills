#!/usr/bin/env bash
set -euo pipefail

# Opt-in install of this repo's CLAUDE.md onto your machine.
# Refuses to replace a CLAUDE.md or Cursor rule that is not already ours.
#
# Usage:
#   ./scripts/install-center.sh [claude|cursor|all]

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$REPO/scripts/common.sh"

TARGET="${1:-all}"

case "$TARGET" in
  claude)
    install_claude_center "$REPO"
    ;;
  cursor)
    install_cursor_center "$REPO"
    ;;
  all)
    install_claude_center "$REPO"
    install_cursor_center "$REPO"
    ;;
  *)
    echo "usage: $0 [claude|cursor|all]" >&2
    echo "  Installs CLAUDE.md only if you ask. link-skills.sh does not." >&2
    exit 1
    ;;
esac
