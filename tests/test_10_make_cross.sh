#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"
# Test script for cross-platform build via make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKE_SH="$SCRIPT_DIR/../make.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
ROOT_DIR_BASE="$SCRIPT_DIR/.tmp"
mkdir -p "$ROOT_DIR_BASE"
ROOT_DIR="$(mktemp -d "$ROOT_DIR_BASE/test_10_make_cross.XXXXXX")"
WORK_DIR="$ROOT_DIR/workdir"
mkdir -p "$WORK_DIR"

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

cleanup() {
  rm -rf "$ROOT_DIR"
}
trap 'echo_title; cleanup' EXIT

echo_title
echo "[INFO] Test make.sh (cross-platform build)"

TAG="$($LAST_TAG_SH)"
GO_OS="linux"
GO_ARCH="amd64"

if ! (
  cd "$WORK_DIR"
  bash "$MAKE_SH" "$TAG" "$GO_OS" "$GO_ARCH"
); then
  fail "make.sh failed to build osmosisd for $GO_OS/$GO_ARCH."
fi

if [ ! -f "$WORK_DIR/osmosisd" ]; then
  fail "osmosisd binary not found after cross-platform make.sh."
fi

pass "osmosisd cross-platform build test passed."
