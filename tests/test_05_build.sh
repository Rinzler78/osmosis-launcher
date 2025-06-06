#!/bin/bash
# Test script for src/build.sh
# Usage: ./test_build.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
BUILD_SH="$ROOT_DIR/src/build.sh"
CLONE_SH="$ROOT_DIR/src/clone.sh"
PATCH_SH="$ROOT_DIR/src/patch.sh"
LAST_TAG_SH="$ROOT_DIR/src/last_tag.sh"
GO_VERSION_SH="$ROOT_DIR/src/retrieve_required_go_version.sh"

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_build"
  rm -f osmosisd
}
trap cleanup EXIT

# Clean initial state
rm -rf "$ROOT_DIR/test_build"
rm -f osmosisd

# 1. Clone repo
TAG=$($LAST_TAG_SH)
TEST_DIR="$ROOT_DIR/test_build"
$CLONE_SH "$TAG" "$TEST_DIR"

# 2. Build
export GET_LAST_TAG_SH="$LAST_TAG_SH"
export GO_VERSION_SH="$GO_VERSION_SH"

if ! bash "$BUILD_SH" "$TEST_DIR" "$TAG"; then
  echo "[FAIL] build.sh failed to build osmosisd."
  exit 1
fi

# 3. Check binary
if [ ! -f osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after build."
  exit 1
fi

# 3b. Check version matches tag
OSMOSISD_VERSION_OUTPUT=$(./osmosisd version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION_OUTPUT" != "$TAG_CLEANED" ]; then
  echo "[FAIL] osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match tag ($TAG_CLEANED)."
  exit 1
fi

echo "[OK] osmosisd version matches tag: $OSMOSISD_VERSION_OUTPUT"

# 4. Check that build.sh fails if directory does not exist
if bash "$BUILD_SH" "/tmp/does_not_exist_$$" 2>err.log; then
  echo "[FAIL] build.sh did not fail with non-existent directory."
  exit 1
fi
if ! grep -q "No such file or directory" err.log && ! grep -q "does not exist" err.log; then
  echo "[FAIL] Error message not found for non-existent directory."
  exit 1
fi
rm -f err.log

echo "[OK] build.sh fails as expected with non-existent directory."

echo "[OK] build.sh tests passed." 