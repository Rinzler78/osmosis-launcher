#!/bin/bash
# Test script for src/build.sh
# Usage: ./test_build.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
BUILD_SH="$SCRIPT_DIR/../src/build.sh"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
PATCH_SH="$SCRIPT_DIR/../src/patch.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
GO_VERSION_SH="$SCRIPT_DIR/../src/retrieve_required_go_version.sh"

FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_build"
  rm -f osmosisd
}

echo_title

echo "[INFO] Test building osmosisd"

trap 'echo_title; cleanup' EXIT

# Clean initial state
rm -rf "$ROOT_DIR/test_build"
rm -f osmosisd

# 1. Clone repo
TAG=$($LAST_TAG_SH)
TEST_DIR="$ROOT_DIR/test_build"
$CLONE_SH "$TAG" "$TEST_DIR"

# 2. Build (plateforme courante uniquement)
if ! bash "$BUILD_SH" "$TEST_DIR"; then
  echo "[FAIL] build.sh failed to build osmosisd (native platform)."
  exit 1
fi

# 3. Check binary (pour la dernière build)
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
if bash "$BUILD_SH" "/tmp/does_not_exist_$$"; then
  echo "[FAIL] build.sh did not fail with non-existent directory."
  exit 1
fi
if ! bash "$BUILD_SH" "/tmp/does_not_exist_$$" 2>&1 | grep -q "No such file or directory" && ! bash "$BUILD_SH" "/tmp/does_not_exist_$$" 2>&1 | grep -q "does not exist"; then
  echo "[FAIL] Error message not found for non-existent directory."
  exit 1
fi

echo "[OK] build.sh fails as expected with non-existent directory."

echo "[OK] build.sh tests passed." 