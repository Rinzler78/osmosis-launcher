#!/bin/bash
# Test script for src/make.sh
# Usage: ./test_make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
MAKE_SH="$SCRIPT_DIR/../src/make.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
TAGS_SH="$SCRIPT_DIR/../src/tags.sh"

FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

# Clean up on exit
cleanup() {
  rm -rf "$ROOT_DIR/test_make"
  rm -f osmosisd
}

echo_title

echo "[INFO] Test make"

trap 'echo_title; cleanup' EXIT

# 1. Build with no tag (should use last tag)
cleanup
TAG=$($LAST_TAG_SH)
echo "[INFO] Building with no tag (should use $TAG)"
if ! bash "$MAKE_SH"; then
  echo "[FAIL] make.sh failed with no tag."
  exit 1
fi
if [ ! -f osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after make.sh."
  exit 1
fi
OSMOSISD_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION" != "$TAG_CLEANED" ]; then
  echo "[FAIL] osmosisd version ($OSMOSISD_VERSION) does not match tag ($TAG_CLEANED)."
  exit 1
fi
echo "[OK] make.sh built osmosisd with correct version: $OSMOSISD_VERSION"

# 2. Build with explicit tag
cleanup
EXPLICIT_TAG="v29.0.2"
if ! $TAGS_SH | grep -q "$EXPLICIT_TAG"; then
  echo "[SKIP] Tag $EXPLICIT_TAG not present, skipping explicit tag test."
else
  echo "[INFO] Building with explicit tag $EXPLICIT_TAG"
  if ! bash "$MAKE_SH" "$EXPLICIT_TAG"; then
    echo "[FAIL] make.sh failed with explicit tag."
    exit 1
  fi
  if [ ! -f osmosisd ]; then
    echo "[FAIL] osmosisd binary not found after make.sh with explicit tag."
    exit 1
  fi
  OSMOSISD_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
  TAG_CLEANED=${EXPLICIT_TAG#v}
  if [ "$OSMOSISD_VERSION" != "$TAG_CLEANED" ]; then
    echo "[FAIL] osmosisd version ($OSMOSISD_VERSION) does not match tag ($TAG_CLEANED) for explicit tag."
    exit 1
  fi
  echo "[OK] make.sh built osmosisd with correct version for explicit tag: $OSMOSISD_VERSION"
fi

# 3. Build with non-existent tag (should fail)
cleanup
NON_EXISTENT_TAG="v0.0.0-NOTAG"
echo "[INFO] Building with non-existent tag $NON_EXISTENT_TAG (should fail)"
if bash "$MAKE_SH" "$NON_EXISTENT_TAG"; then
  echo "[FAIL] make.sh did not fail with non-existent tag."
  exit 1
fi
if ! bash "$MAKE_SH" "$NON_EXISTENT_TAG" 2>&1 | grep -q "does not exist" && ! bash "$MAKE_SH" "$NON_EXISTENT_TAG" 2>&1 | grep -q "No such file or directory" && ! bash "$MAKE_SH" "$NON_EXISTENT_TAG" 2>&1 | grep -q "ERROR"; then
  echo "[FAIL] Error message not found for non-existent tag."
  exit 1
fi
echo "[OK] make.sh fails as expected with non-existent tag."

cleanup

echo "[OK] make.sh tests passed." 