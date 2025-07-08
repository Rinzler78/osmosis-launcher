#!/bin/bash

. "$(dirname "$0")/utils.sh"
# Test script for src/clone.sh
# Usage: ./test_clone.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

TAG=$($LAST_TAG_SH)
TARGET_DIR="test_clone_dir"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

cleanup() {
  rm -rf "$ROOT_DIR"
  rm -rf "$TARGET_DIR"
}

echo_title

echo "[INFO] Test clone.sh (paramètres nommés)"

trap cleanup EXIT

# Clean initial state
rm -rf "$TARGET_DIR"

if ! bash "$CLONE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  fail "clone.sh failed with named parameters."
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
  fail "Target directory $TARGET_DIR was not created by clone.sh."
fi

pass "clone.sh test with named parameters passed."

# 1. Test with tag and directory
TEST_DIR1="$ROOT_DIR/test1"
TAG1="$TAG"
"$CLONE_SH" --tag "$TAG1" --target-dir "$TEST_DIR1"
if [ ! -d "$TEST_DIR1/.git" ]; then
  fail "Test 1: Repo not cloned in $TEST_DIR1"
fi
CUR_TAG=$(cd "$TEST_DIR1" && git rev-parse --abbrev-ref HEAD || git describe --tags)
if ! (cd "$TEST_DIR1" && git describe --tags | grep "$TAG1" > /dev/null); then
  fail "Test 1: Tag $TAG1 not checked out in $TEST_DIR1"
fi
pass "Test 1: Clone with tag and dir => OK"

# 2. Test without tag (should take the last tag)
TEST_DIR2="$ROOT_DIR/test2"
"$CLONE_SH" --target-dir "$TEST_DIR2"
if [ ! -d "$TEST_DIR2/.git" ]; then
  fail "Test 2: Repo not cloned in $TEST_DIR2"
fi
if ! (cd "$TEST_DIR2" && git describe --tags | grep "$TAG" > /dev/null); then
  fail "Test 2: Tag $TAG not checked out in $TEST_DIR2"
fi
pass "Test 2: Clone with no tag => OK"

# 3. Test without directory (should clone in osmosis)
DEFAULT_DIR="osmosis"
rm -rf "$DEFAULT_DIR"
"$CLONE_SH" --tag "$TAG"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  fail "Test 3: Repo not cloned in $DEFAULT_DIR"
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$TAG" > /dev/null); then
  fail "Test 3: Tag $TAG not checked out in $DEFAULT_DIR"
fi
pass "Test 3: Clone with no dir => OK"

# 4. Test without any argument (should clone the last tag in osmosis)
rm -rf "$DEFAULT_DIR"
"$CLONE_SH"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  fail "Test 4: Repo not cloned in $DEFAULT_DIR"
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$TAG" > /dev/null); then
  fail "Test 4: Tag $TAG not checked out in $DEFAULT_DIR"
fi
pass "Test 4: Clone with no args => OK"

# 5. Test with an invalid tag (should fail)
INVALID_TAG="v0.0.0-THIS-TAG-DOES-NOT-EXIST"
OUTPUT=$("$CLONE_SH" --tag "$INVALID_TAG" --target-dir "$ROOT_DIR/should_not_exist" 2>&1) && {
  fail "Test 5: Script did not fail with invalid tag"
}
echo "$OUTPUT" | grep -q "was not found in the Osmosis repository." || {
  fail "Test 5: Error message not found for invalid tag"
}
pass "Test 5: Invalid tag is properly rejected => OK"

# 6. Test if already on the right tag, script exits immediately
TEST_DIR3="$ROOT_DIR/test3"
"$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR3"
# Re-run the script, it should detect that we are already on the right tag and exit without error
OUTPUT2=$("$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR3" 2>&1)
echo "$OUTPUT2" | grep -q "Already on tag/branch $TAG" || {
  fail "Test 6: Script did not detect already on tag/branch"
}
pass "Test 6: Already on tag/branch => OK"

pass "ALL TESTS PASSED" 