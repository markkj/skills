#!/bin/sh
# Proves Project Path is created from the old vault, and an existing path is left alone.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
RESOLVE="$ROOT/scripts/resolve-project-path.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "fail: $1" >&2
  exit 1
}

if env -u PROJECT_PATH -u OBSIDIAN_BASE_VAULT_PATH MARKKJ_CONFIG_DIR="$TMP/cfg1" "$RESOLVE" >/dev/null 2>"$TMP/err1"; then
  fail "missing paths should exit non-zero"
fi
grep -q "PROJECT_PATH" "$TMP/err1" || fail "error should name PROJECT_PATH"

mkdir -p "$TMP/vault"
got=$(env -u PROJECT_PATH MARKKJ_CONFIG_DIR="$TMP/cfg2" OBSIDIAN_BASE_VAULT_PATH="$TMP/vault" "$RESOLVE")
[ "$got" = "$TMP/vault/Projects" ] || fail "expected vault/Projects, got $got"
[ -d "$TMP/vault/Projects" ] || fail "Projects directory was not created"
[ "$(cat "$TMP/cfg2/project-path")" = "$TMP/vault/Projects" ] || fail "project-path file mismatch"

printf '%s\n' "$TMP/keep" > "$TMP/cfg2/project-path"
got=$(env -u PROJECT_PATH MARKKJ_CONFIG_DIR="$TMP/cfg2" OBSIDIAN_BASE_VAULT_PATH="$TMP/vault-other" "$RESOLVE")
[ "$got" = "$TMP/keep" ] || fail "existing project-path was replaced: $got"

mkdir -p "$TMP/envpath"
got=$(env MARKKJ_CONFIG_DIR="$TMP/cfg3" PROJECT_PATH="$TMP/envpath" "$RESOLVE")
[ "$got" = "$TMP/envpath" ] || fail "PROJECT_PATH env not used: $got"
[ "$(cat "$TMP/cfg3/project-path")" = "$TMP/envpath" ] || fail "env path was not saved"

echo "ok"
