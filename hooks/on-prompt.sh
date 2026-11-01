#!/bin/sh
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
exec node "$ROOT/hooks/wrap-prompt.js"
