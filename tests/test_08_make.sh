#!/bin/bash

. "$(dirname "$0")/utils.sh"
# Test script for src/make.sh
# Usage: ./test_07_make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
MAKE_SH="$SCRIPT_DIR/../src/make.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
TAGS_SH="$SCRIPT_DIR/../src/tags.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

TAG=$($LAST_TAG_SH)
GO_OS=""
GO_ARCH=""
TARGET_DIR="$ROOT_DIR/test_make"

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_make"
  rm -f osmosisd
}

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

echo_title

echo "[INFO] Test src/make.sh (native build)"

trap 'echo_title; cleanup' EXIT

# Clean initial state
rm -rf "$ROOT_DIR/test_make"
rm -f osmosisd

# 1. Build (plateforme courante)
if ! bash "$MAKE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  fail "src/make.sh failed to build osmosisd (native platform)."
fi

# 2. Check binary
if [ ! -f osmosisd ]; then
  fail "osmosisd binary not found after src/make.sh."
fi

# 3. Check version matches tag
OSMOSISD_VERSION_OUTPUT=$(./osmosisd version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION_OUTPUT" != "$TAG_CLEANED" ]; then
  fail "osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match tag ($TAG_CLEANED)."
fi

pass "osmosisd version matches tag: $OSMOSISD_VERSION_OUTPUT"

pass "src/make.sh native build test passed."

# 2. Build with explicit tag
cleanup
EXPLICIT_TAG="v29.0.2"
if ! $TAGS_SH | grep -q "$EXPLICIT_TAG"; then
  echo "[SKIP] Tag $EXPLICIT_TAG not present, skipping explicit tag test."
else
  echo "[INFO] Building with explicit tag $EXPLICIT_TAG"
  if ! bash "$MAKE_SH" --tag "$EXPLICIT_TAG" --target-dir "$TARGET_DIR"; then
    fail "src/make.sh failed with explicit tag."
  fi
  if [ ! -f osmosisd ]; then
    fail "osmosisd binary not found after src/make.sh with explicit tag."
  fi
  OSMOSISD_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
  TAG_CLEANED=${EXPLICIT_TAG#v}
  if [ "$OSMOSISD_VERSION" != "$TAG_CLEANED" ]; then
    fail "osmosisd version ($OSMOSISD_VERSION) does not match tag ($TAG_CLEANED) for explicit tag."
  fi
  pass "src/make.sh built osmosisd with correct version for explicit tag: $OSMOSISD_VERSION"
fi

# 3. Build with non-existent tag (should fail)
cleanup
NON_EXISTENT_TAG="v0.0.0-NOTAG"
echo "[INFO] Building with non-existent tag $NON_EXISTENT_TAG (should fail)"
if bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR"; then
  fail "src/make.sh did not fail with non-existent tag."
fi
if ! bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1 | grep -q "does not exist" && ! bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1 | grep -q "No such file or directory" && ! bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1 | grep -q "ERROR"; then
  fail "Error message not found for non-existent tag."
fi
pass "src/make.sh fails as expected with non-existent tag."

cleanup

pass "src/make.sh tests passed." 