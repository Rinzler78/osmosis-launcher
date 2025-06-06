#!/bin/bash
# Test script for src/patch.sh
# Usage: ./test_patch.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
PATCH_SH="$ROOT_DIR/src/patch.sh"
CLONE_SH="$ROOT_DIR/src/clone.sh"
LAST_TAG_SH="$ROOT_DIR/src/last_tag.sh"
LAUNCHER_GO_SRC="$ROOT_DIR/src/launcher.go"

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_patch"
  rm -f launcher.go
}
trap cleanup EXIT

# Clean initial state
rm -rf "$ROOT_DIR/test_patch"
rm -f launcher.go

# 1. Clone repo
TAG=$($LAST_TAG_SH)
TEST_DIR="$ROOT_DIR/test_patch"
$CLONE_SH "$TAG" "$TEST_DIR"

# 2. Copy launcher.go to current dir (patch.sh expects it here)
cp "$LAUNCHER_GO_SRC" launcher.go

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
BUILD_SH="$ROOT_DIR/src/build.sh"
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
if bash "$PATCH_SH" "/tmp/does_not_exist_$$" 2>err.log; then
  echo "[FAIL] patch.sh did not fail with non-existent directory."
  exit 1
fi
if ! grep -q "does not exist" err.log && ! grep -q "No such file or directory" err.log && ! grep -q "Target directory" err.log; then
  echo "[FAIL] Error message not found for non-existent directory."
  exit 1
fi
echo "[OK] patch.sh fails as expected with non-existent directory."

# 9. Error: main.go missing
BROKEN_DIR="$ROOT_DIR/test_patch_broken"
$CLONE_SH "$TAG" "$BROKEN_DIR"
rm -f "$BROKEN_DIR/cmd/osmosisd/main.go"
cp "$LAUNCHER_GO_SRC" launcher.go
if bash "$PATCH_SH" "$BROKEN_DIR" 2>err.log; then
  echo "[FAIL] patch.sh did not fail with missing main.go."
  exit 1
fi
if ! grep -q "not exists" err.log; then
  echo "[FAIL] Error message not found for missing main.go."
  exit 1
fi
rm -rf "$BROKEN_DIR" err.log

echo "[OK] patch.sh fails as expected with missing main.go."

echo "[ALL TESTS PASSED]" 