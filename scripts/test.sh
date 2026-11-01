#!/bin/sh
# Run every shell test, then validate the plugin manifests.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
failed=0
for test in "$ROOT"/scripts/tests/*_test.sh; do
  name=$(basename "$test")
  if out=$(sh "$test" 2>&1); then
    echo "pass  $name"
  else
    echo "FAIL  $name"
    printf '%s\n' "$out" | sed 's/^/      /'
    failed=1
  fi
done

if command -v claude > /dev/null 2>&1; then
  if claude plugin validate "$ROOT" > /dev/null 2>&1; then
    echo "pass  claude plugin validate"
  else
    echo "FAIL  claude plugin validate"
    claude plugin validate "$ROOT" 2>&1 | sed 's/^/      /'
    failed=1
  fi
fi

exit $failed
