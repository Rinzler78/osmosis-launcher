#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../src"

if (cd "$SRC_DIR" && GO111MODULE=off go test launcher.go launcher_test.go >/dev/null); then
  pass "launcher stdin parsing regression tests passed"
else
  fail "launcher stdin parsing regression tests failed"
fi
