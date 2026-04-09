#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

shopt -s nullglob
for test_script in "$SCRIPT_DIR"/test_*.sh; do
  if [[ "$test_script" = "$0" || "$(basename "$test_script")" = "$(basename "$0")" ]]; then
    continue
  fi

  printf '\n===============================\n'
  printf 'Running %s\n' "$test_script"
  printf '===============================\n\n'
  bash "$test_script"
done

printf '\nAll tests completed successfully.\n'
