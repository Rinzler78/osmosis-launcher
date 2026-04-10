#!/bin/bash

# shellcheck source=tests/utils.sh
. "$(dirname "$0")/utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR_BASE="$SCRIPT_DIR/.tmp"
mkdir -p "$ROOT_DIR_BASE"
ROOT_DIR="$(mktemp -d "$ROOT_DIR_BASE/test_04_clone.XXXXXX")"
CLONE_SH="$SCRIPT_DIR/../src/clone.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

TAG="$($LAST_TAG_SH)"
TARGET_DIR="$ROOT_DIR/test_clone_dir"

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

cleanup() {
  rm -rf "$ROOT_DIR"
}

echo_title
echo "[INFO] Test clone.sh with named parameters"

trap cleanup EXIT

if ! bash "$CLONE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  fail "clone.sh failed with named parameters"
fi

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  fail "Target directory '$TARGET_DIR' was not created by clone.sh"
fi

pass "clone.sh test with named parameters passed"

WORKSPACE_DEFAULT_1="$ROOT_DIR/workspace-default-1"
mkdir -p "$WORKSPACE_DEFAULT_1"
(
  cd "$WORKSPACE_DEFAULT_1"
  bash "$CLONE_SH" --tag "$TAG"
)
[[ -d "$WORKSPACE_DEFAULT_1/osmosis/.git" ]] || fail "Test 3: Repo not cloned in 'osmosis'"
if (cd "$WORKSPACE_DEFAULT_1/osmosis" && git describe --tags | grep "$TAG" >/dev/null); then
  pass "Test 1: Clone with explicit tag and default target dir => OK"
else
  fail "Test 1: Tag '$TAG' not checked out in 'osmosis'"
fi

INVALID_TAG="v0.0.0-THIS-TAG-DOES-NOT-EXIST"
if OUTPUT="$(bash "$CLONE_SH" --tag "$INVALID_TAG" --target-dir "$ROOT_DIR/should_not_exist" 2>&1)"; then
  fail "Test 2: Script did not fail with invalid tag"
fi
if echo "$OUTPUT" | grep -q "was not found in the Osmosis repository."; then
  pass "Test 2: Invalid tag is properly rejected => OK"
else
  fail "Test 2: Error message not found for invalid tag"
fi

TEST_DIR3="$ROOT_DIR/test3"
bash "$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR3"
OUTPUT2="$(bash "$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR3" 2>&1)"
if echo "$OUTPUT2" | grep -q "Already on tag '$TAG'. Repository left unchanged."; then
  pass "Test 3: Already on tag/branch => OK"
else
  fail "Test 3: Script did not detect already-on-tag state"
fi

echo "dirty" >> "$TEST_DIR3/README.md"
if bash "$CLONE_SH" --tag "$TAG" --target-dir "$TEST_DIR3" >"$ROOT_DIR/clone-dirty.out" 2>&1; then
  fail "Test 4: Dirty repositories must require --force-reset"
fi
if grep -Fq "contains local changes. Re-run with --force-reset" "$ROOT_DIR/clone-dirty.out"; then
  pass "Test 4: Dirty repository protection => OK"
else
  fail "Test 4: Dirty repository protection message missing"
fi

bash "$CLONE_SH" --force-reset --tag "$TAG" --target-dir "$TEST_DIR3" >/dev/null
if (cd "$TEST_DIR3" && ! git diff --quiet); then
  fail "Test 5: --force-reset did not restore a clean worktree"
fi
pass "Test 5: --force-reset allows explicit destructive reset => OK"

pass "ALL TESTS PASSED"
