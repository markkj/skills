#!/bin/sh
# Print the Project Path. Create it from OBSIDIAN_BASE_VAULT_PATH when no path is saved yet.
set -eu

config_dir() {
  if [ -n "${MARKKJ_CONFIG_DIR:-}" ]; then
    printf '%s\n' "$MARKKJ_CONFIG_DIR"
    return
  fi
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    printf '%s\n' "$XDG_CONFIG_HOME/markkj-skills"
    return
  fi
  printf '%s\n' "$HOME/.config/markkj-skills"
}

CONFIG=$(config_dir)
FILE="$CONFIG/project-path"

if [ -f "$FILE" ]; then
  existing=$(sed -n '1p' "$FILE" | tr -d '\r')
  if [ -n "$existing" ]; then
    printf '%s\n' "$existing"
    exit 0
  fi
fi

if [ -n "${PROJECT_PATH:-}" ]; then
  mkdir -p "$CONFIG" "$PROJECT_PATH"
  printf '%s\n' "$PROJECT_PATH" > "$FILE"
  printf '%s\n' "$PROJECT_PATH"
  exit 0
fi

vault=${OBSIDIAN_BASE_VAULT_PATH:-}
if [ -n "$vault" ] && [ -d "$vault" ]; then
  dest="$vault/Projects"
  mkdir -p "$CONFIG" "$dest"
  printf '%s\n' "$dest" > "$FILE"
  printf '%s\n' "$dest"
  exit 0
fi

echo "PROJECT_PATH is unset. Set PROJECT_PATH, or set OBSIDIAN_BASE_VAULT_PATH to an existing directory so this script can create Project Path from it." >&2
exit 1
