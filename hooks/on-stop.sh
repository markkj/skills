#!/bin/sh
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
exec node "$ROOT/hooks/record-turn.js"
