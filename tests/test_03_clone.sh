#!/bin/bash
# Test script for src/clone.sh
# Usage: ./test_clone.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
LAST_TAG="$($SCRIPT_DIR/../src/last_tag.sh)"

FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

cleanup() {
  rm -rf "$ROOT_DIR"
  rm -rf "osmosis"
}

echo_title

echo "[INFO] Test cloning"

trap 'echo_title; cleanup' EXIT

# 1. Test with tag and directory
TEST_DIR1="$ROOT_DIR/test1"
TAG1="$LAST_TAG"
"$CLONE_SH" "$TAG1" "$TEST_DIR1"
if [ ! -d "$TEST_DIR1/.git" ]; then
  echo "[ERROR] Test 1: Repo not cloned in $TEST_DIR1"
  exit 1
fi
CUR_TAG=$(cd "$TEST_DIR1" && git rev-parse --abbrev-ref HEAD || git describe --tags)
if ! (cd "$TEST_DIR1" && git describe --tags | grep "$TAG1" > /dev/null); then
  echo "[ERROR] Test 1: Tag $TAG1 not checked out in $TEST_DIR1"
  exit 1
fi

echo "[OK] Test 1: Clone with tag and dir => OK"

# 2. Test without tag (should take the last tag)
TEST_DIR2="$ROOT_DIR/test2"
"$CLONE_SH" "" "$TEST_DIR2"
if [ ! -d "$TEST_DIR2/.git" ]; then
  echo "[ERROR] Test 2: Repo not cloned in $TEST_DIR2"
  exit 1
fi
if ! (cd "$TEST_DIR2" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 2: Last tag $LAST_TAG not checked out in $TEST_DIR2"
  exit 1
fi

echo "[OK] Test 2: Clone with no tag => OK"

# 3. Test without directory (should clone in osmosis)
DEFAULT_DIR="osmosis"
rm -rf "$DEFAULT_DIR"
"$CLONE_SH" "$LAST_TAG"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  echo "[ERROR] Test 3: Repo not cloned in $DEFAULT_DIR"
  exit 1
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 3: Tag $LAST_TAG not checked out in $DEFAULT_DIR"
  exit 1
fi

echo "[OK] Test 3: Clone with no dir => OK"

# 4. Test without any argument (should clone the last tag in osmosis)
rm -rf "$DEFAULT_DIR"
"$CLONE_SH"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  echo "[ERROR] Test 4: Repo not cloned in $DEFAULT_DIR"
  exit 1
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 4: Last tag $LAST_TAG not checked out in $DEFAULT_DIR"
  exit 1
fi

echo "[OK] Test 4: Clone with no args => OK"

# 5. Test with an invalid tag (should fail)
INVALID_TAG="v0.0.0-THIS-TAG-DOES-NOT-EXIST"
OUTPUT=$("$CLONE_SH" "$INVALID_TAG" "$ROOT_DIR/should_not_exist" 2>&1) && {
  echo "[ERROR] Test 5: Script did not fail with invalid tag"
  exit 1
}
echo "$OUTPUT" | grep -q "was not found in the Osmosis repository." || {
  echo "[ERROR] Test 5: Error message not found for invalid tag"
  exit 1
}
echo "[OK] Test 5: Invalid tag is properly rejected => OK"

# 6. Test if already on the right tag, script exits immediately
TEST_DIR3="$ROOT_DIR/test3"
"$CLONE_SH" "$LAST_TAG" "$TEST_DIR3"
# Re-run the script, it should detect that we are already on the right tag and exit without error
OUTPUT2=$("$CLONE_SH" "$LAST_TAG" "$TEST_DIR3" 2>&1)
echo "$OUTPUT2" | grep -q "Already on tag/branch $LAST_TAG" || {
  echo "[ERROR] Test 6: Script did not detect already on tag/branch"
  exit 1
}
echo "[OK] Test 6: Already on tag/branch => OK"

echo "[ALL TESTS PASSED]" 