#!/bin/bash

# shellcheck source=tests/utils.sh
. "$(dirname "$0")/utils.sh"

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR_BASE="$SCRIPT_DIR/.tmp"
mkdir -p "$ROOT_DIR_BASE"
ROOT_DIR="$(mktemp -d "$ROOT_DIR_BASE/test_08_make.XXXXXX")"
WORK_DIR="$ROOT_DIR/workdir"
mkdir -p "$WORK_DIR"
MAKE_SH="$SCRIPT_DIR/../src/make.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

TAG="$($LAST_TAG_SH)"
TARGET_DIR="$ROOT_DIR/test_make"

cleanup() {
  rm -rf "$ROOT_DIR"
}

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

echo_title
echo "[INFO] Test src/make.sh (native build)"

trap 'echo_title; cleanup' EXIT

if ! (
  cd "$WORK_DIR"
  bash "$MAKE_SH" --tag "$TAG" --target-dir "$TARGET_DIR"
); then
  fail "src/make.sh failed to build osmosisd (native platform)."
fi

if [ ! -f "$WORK_DIR/osmosisd" ]; then
  fail "osmosisd binary not found after src/make.sh."
fi

OSMOSISD_VERSION_OUTPUT=$("$WORK_DIR/osmosisd" version 2>/dev/null | head -n 1)
TAG_CLEANED=${TAG#v}
if [ "$OSMOSISD_VERSION_OUTPUT" != "$TAG_CLEANED" ]; then
  fail "osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match tag ($TAG_CLEANED)."
fi

pass "osmosisd version matches tag: $OSMOSISD_VERSION_OUTPUT"
pass "src/make.sh native build test passed."

# Keep heavy build regression coverage bounded to the latest stable tag.
# Older tag compatibility remains covered by the shared tag resolution and clone logic.

cleanup
mkdir -p "$WORK_DIR"
NON_EXISTENT_TAG="v0.0.0-NOTAG"
echo "[INFO] Building with non-existent tag $NON_EXISTENT_TAG (should fail)"
if (
  cd "$WORK_DIR"
  bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR"
); then
  fail "src/make.sh did not fail with non-existent tag."
fi
if ! (
  cd "$WORK_DIR"
  bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1
) | grep -q "does not exist" && ! (
  cd "$WORK_DIR"
  bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1
) | grep -q "No such file or directory" && ! (
  cd "$WORK_DIR"
  bash "$MAKE_SH" --tag "$NON_EXISTENT_TAG" --target-dir "$TARGET_DIR" 2>&1
) | grep -q "ERROR"; then
  fail "Error message not found for non-existent tag."
fi
pass "src/make.sh fails as expected with non-existent tag."

cleanup
mkdir -p "$WORK_DIR"
pass "src/make.sh tests passed."
