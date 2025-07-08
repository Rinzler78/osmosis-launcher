#!/bin/bash

# Run all test scripts in the current directory in order
# Each test script output is prefixed by its name

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for test_script in $(ls $SCRIPT_DIR/test_*.sh | sort); do
  echo "\n==============================="
  echo "Running $test_script"
  echo "===============================\n"
  bash "$test_script"
done

echo "\nAll tests completed successfully." 