#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_SLOW_TESTS="${RUN_SLOW_TESTS:-0}"

is_slow_test() {
  case "$(basename "$1")" in
    test_09_docker_make.sh|test_10_make_cross.sh)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

shopt -s nullglob
for test_script in "$SCRIPT_DIR"/test_*.sh; do
  if [[ "$test_script" = "$0" || "$(basename "$test_script")" = "$(basename "$0")" ]]; then
    continue
  fi

  if is_slow_test "$test_script" && [[ "$RUN_SLOW_TESTS" != "1" ]]; then
    printf '\n[SKIP] %s (set RUN_SLOW_TESTS=1 to include slow Docker integration tests)\n' "$test_script"
    continue
  fi

  printf '\n===============================\n'
  printf 'Running %s\n' "$test_script"
  printf '===============================\n\n'
  bash "$test_script"
done

printf '\nAll tests completed successfully.\n'
