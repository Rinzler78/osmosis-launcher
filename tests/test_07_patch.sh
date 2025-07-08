#!/bin/bash

. "$(dirname "$0")/utils.sh"
# Test script for src/patch.sh
# Usage: ./test_patch.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
PATCH_SH="$SCRIPT_DIR/../src/patch.sh"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
LAUNCHER_GO_SRC="$SCRIPT_DIR/../src/launcher.go"
BUILD_SH="$SCRIPT_DIR/../src/build.sh"

FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_patch"
  rm -f launcher.go
}

echo_title

echo "[INFO] Test patching"

trap 'echo_title; cleanup' EXIT

# Clean initial state
rm -rf "$ROOT_DIR/test_patch"
rm -f launcher.go

# 1. Clone repo
TAG=$($LAST_TAG_SH)
TEST_DIR="$ROOT_DIR/test_patch"
$CLONE_SH --tag "$TAG" --target-dir "$TEST_DIR"

# 3. Run patch.sh
if ! bash "$PATCH_SH" --target-dir "$TEST_DIR"; then
  fail "patch.sh failed."
fi

# 4. Check launcher.go copied
if [ ! -f "$TEST_DIR/cmd/osmosisd/launcher.go" ]; then
  fail "launcher.go not copied to cmd/osmosisd."
fi

# 5. Check main.go modified
if ! grep -q 'wait_for_launcher()' "$TEST_DIR/cmd/osmosisd/main.go"; then
  fail "main.go not patched with wait_for_launcher()."
fi

# 6. Build the patched repo

export GO_VERSION_SH="$ROOT_DIR/src/retrieve_required_go_version.sh"
if ! bash "$BUILD_SH" "$TEST_DIR"; then
  fail "build.sh failed after patch."
fi

# 7. Check osmosisd version with and without --launcher
OSMOSISD_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
OSMOSISD_LAUNCHER_VERSION=$(./osmosisd --launcher version 2>/dev/null | head -n 1)
if [ "$OSMOSISD_VERSION" != "$OSMOSISD_LAUNCHER_VERSION" ]; then
  fail "osmosisd version ($OSMOSISD_VERSION) != osmosisd --launcher version ($OSMOSISD_LAUNCHER_VERSION)"
fi

pass "osmosisd version is the same with and without --launcher: $OSMOSISD_VERSION"

# 8. Check error on non-existent directory
if bash "$PATCH_SH" --target-dir "/tmp/does_not_exist_$$" 2>&1 | grep -q "\[FAIL\] Target directory .\+ does not exist."; then
  pass "Error message found for non-existent directory."
else
  fail "Error message not found for non-existent directory."
fi

# 9. Error: main.go missing
BROKEN_DIR="$ROOT_DIR/test_patch_broken"
$CLONE_SH --tag "$TAG" --target-dir "$BROKEN_DIR"
rm -f "$BROKEN_DIR/cmd/osmosisd/main.go"
cp "$LAUNCHER_GO_SRC" launcher.go
if bash "$PATCH_SH" --target-dir "$BROKEN_DIR"; then
  fail "patch.sh did not fail with missing main.go."
fi
if ! bash "$PATCH_SH" --target-dir "$BROKEN_DIR" 2>&1 | grep -q "does not exist"; then
  fail "Error message not found for missing main.go."
fi
rm -rf "$BROKEN_DIR"

pass "patch.sh fails as expected with missing main.go."

pass "ALL TESTS PASSED"

TAG=$($LAST_TAG_SH)
TARGET_DIR="test_patch_dir"

cleanup() {
  rm -rf "$TARGET_DIR"
}
trap cleanup EXIT

echo_title

echo "[INFO] Test patch.sh (paramètre nommé)"

# Clean initial state
rm -rf "$TARGET_DIR"

# Clone d'abord
if ! bash "$CLONE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  fail "clone.sh failed for patch test."
fi

# Patch
if ! bash "$PATCH_SH" --target-dir "$TARGET_DIR"; then
  fail "patch.sh failed with named parameter."
fi

pass "patch.sh test with named parameter passed." 