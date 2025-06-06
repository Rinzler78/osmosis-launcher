#!/bin/bash
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
$CLONE_SH "$TAG" "$TEST_DIR"

# 3. Run patch.sh
if ! bash "$PATCH_SH" "$TEST_DIR"; then
  echo "[FAIL] patch.sh failed."
  exit 1
fi

# 4. Check launcher.go copied
if [ ! -f "$TEST_DIR/cmd/osmosisd/launcher.go" ]; then
  echo "[FAIL] launcher.go not copied to cmd/osmosisd."
  exit 1
fi

# 5. Check main.go modified
if ! grep -q 'wait_for_launcher()' "$TEST_DIR/cmd/osmosisd/main.go"; then
  echo "[FAIL] main.go not patched with wait_for_launcher()."
  exit 1
fi

# 6. Build the patched repo

export GO_VERSION_SH="$ROOT_DIR/src/retrieve_required_go_version.sh"
if ! bash "$BUILD_SH" "$TEST_DIR"; then
  echo "[FAIL] build.sh failed after patch."
  exit 1
fi

# 7. Check osmosisd version with and without --launcher
OSMOSISD_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
OSMOSISD_LAUNCHER_VERSION=$(./osmosisd --launcher version 2>/dev/null | head -n 1)
if [ "$OSMOSISD_VERSION" != "$OSMOSISD_LAUNCHER_VERSION" ]; then
  echo "[FAIL] osmosisd version ($OSMOSISD_VERSION) != osmosisd --launcher version ($OSMOSISD_LAUNCHER_VERSION)"
  exit 1
fi

echo "[OK] osmosisd version is the same with and without --launcher: $OSMOSISD_VERSION"

# 8. Check error on non-existent directory
ERROR_MSG1="[FAIL] Impossible de déterminer la version de Go pour le dossier"
ERROR_MSG2="[FAIL] Target directory"
# The error messages above are in French, let's check for English equivalents
if bash "$PATCH_SH" "/tmp/does_not_exist_$$" 2>&1 | grep -q "\[FAIL\] Target directory .\+ does not exist."; then
  echo "[OK] Error message found for non-existent directory."
else
  echo "[FAIL] Error message not found for non-existent directory."
  exit 1
fi

# 9. Error: main.go missing
BROKEN_DIR="$ROOT_DIR/test_patch_broken"
$CLONE_SH "$TAG" "$BROKEN_DIR"
rm -f "$BROKEN_DIR/cmd/osmosisd/main.go"
cp "$LAUNCHER_GO_SRC" launcher.go
if bash "$PATCH_SH" "$BROKEN_DIR"; then
  echo "[FAIL] patch.sh did not fail with missing main.go."
  exit 1
fi
if ! bash "$PATCH_SH" "$BROKEN_DIR" 2>&1 | grep -q "not exists"; then
  echo "[FAIL] Error message not found for missing main.go."
  exit 1
fi
rm -rf "$BROKEN_DIR"

echo "[OK] patch.sh fails as expected with missing main.go."

echo "[ALL TESTS PASSED]" 