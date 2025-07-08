#!/bin/bash

. "$(dirname "$0")/utils.sh"
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
RESOLVE_OS_SH="$SCRIPT_DIR/../src/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/../src/resolve_arch.sh"

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
$CLONE_SH --tag "$TAG" --target-dir "$TEST_DIR"

# 2. Build (plateforme courante uniquement)
if ! bash "$BUILD_SH" --target-dir "$TEST_DIR"; then
  fail "build.sh failed to build osmosisd (native platform)."
fi

# 3. Check binary (pour la dernière build)
if [ ! -f osmosisd ]; then
  fail "osmosisd binary not found after build."
fi

# 3b. Check version matches tag
OSMOSISD_VERSION_OUTPUT=$(./osmosisd version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION_OUTPUT" != "$TAG_CLEANED" ]; then
  fail "osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match tag ($TAG_CLEANED)."
fi

pass "osmosisd version matches tag: $OSMOSISD_VERSION_OUTPUT"

# 4. Check that build.sh fails if directory does not exist
if bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$"; then
  fail "build.sh did not fail with non-existent directory."
fi
if ! bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$" 2>&1 | grep -q "No such file or directory" && ! bash "$BUILD_SH" --target-dir "/tmp/does_not_exist_$$" 2>&1 | grep -q "does not exist"; then
  fail "Error message not found for non-existent directory."
fi

pass "build.sh fails as expected with non-existent directory."

pass "build.sh tests passed."

TAG=$($LAST_TAG_SH)
GO_OS=$($RESOLVE_OS_SH "$(uname -s)")
GO_ARCH=$($RESOLVE_ARCH_SH "$(uname -m)")
TARGET_DIR="test_build_dir"

echo_title
echo "[INFO] Test build.sh (paramètres nommés)"

# Clean initial state
rm -rf "$TARGET_DIR" osmosisd

# Clone d'abord
if ! bash "$CLONE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  fail "clone.sh failed for build test."
fi

# Build
if ! bash "$BUILD_SH" --target-dir "$TARGET_DIR" --os "$GO_OS" --arch "$GO_ARCH"; then
  fail "build.sh failed with named parameters."
fi

if [ ! -f osmosisd ]; then
  fail "osmosisd binary not found after build.sh."
fi

pass "build.sh test with named parameters passed." 