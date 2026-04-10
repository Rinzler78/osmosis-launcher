#!/bin/bash

# shellcheck source=tests/utils.sh
. "$(dirname "$0")/utils.sh"

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR_BASE="$SCRIPT_DIR/.tmp"
mkdir -p "$ROOT_DIR_BASE"
ROOT_DIR="$(mktemp -d "$ROOT_DIR_BASE/test_06_build.XXXXXX")"
WORK_DIR="$ROOT_DIR/workdir"
mkdir -p "$WORK_DIR"
BUILD_SH="$SCRIPT_DIR/../src/build.sh"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

cleanup() {
  rm -rf "$ROOT_DIR"
}

echo_title
echo "[INFO] Test building osmosisd"

trap 'echo_title; cleanup' EXIT

TAG="$($LAST_TAG_SH)"
TEST_DIR="$ROOT_DIR/test_build"
bash "$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR"

if ! (
  cd "$WORK_DIR"
  bash "$BUILD_SH" --target-dir "$TEST_DIR"
); then
  fail "build.sh failed to build osmosisd (native platform)."
fi

if [ ! -f "$WORK_DIR/osmosisd" ]; then
  fail "osmosisd binary not found after build."
fi

OSMOSISD_VERSION_OUTPUT=$("$WORK_DIR/osmosisd" version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION_OUTPUT" != "$TAG_CLEANED" ]; then
  fail "osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match tag ($TAG_CLEANED)."
fi

pass "osmosisd version matches tag: $OSMOSISD_VERSION_OUTPUT"

if bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$"; then
  fail "build.sh did not fail with non-existent directory."
fi
if ! bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$" 2>&1 | grep -q "No such file or directory" && ! bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$" 2>&1 | grep -q "does not exist"; then
  fail "Error message not found for non-existent directory."
fi

pass "build.sh fails as expected with non-existent directory."
pass "build.sh tests passed."

# Keep heavy build coverage bounded to one native build on the latest stable tag.
# Named argument parsing is already covered by tests/test_01_parse_args.sh.
