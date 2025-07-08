#!/bin/bash

. "$(dirname "$0")/utils.sh"
# Test script for cross-platform build via make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAKE_SH="$SCRIPT_DIR/../make.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

# Clean up on exit
cleanup() {
  rm -rf buildx-out
}
trap 'echo_title; cleanup' EXIT

echo_title
echo "[INFO] Test make.sh (cross-platform build)"

# Clean initial state
rm -rf buildx-out

# 1. Build for linux/amd64
TAG=$($LAST_TAG_SH)
GO_OS="linux"
GO_ARCH="amd64"

if ! bash "$MAKE_SH" --tag "$TAG" --os "$GO_OS" --arch "$GO_ARCH"; then
  fail "make.sh failed to build osmosisd for $GO_OS/$GO_ARCH."
fi

# 2. Check binary
if [ ! -f buildx-out/build/osmosisd ]; then
  fail "osmosisd binary not found after cross-platform make.sh."
fi

pass "osmosisd cross-platform build test passed." 