#!/bin/bash
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
if ! bash "$MAKE_SH" "$TAG" "$GO_OS" "$GO_ARCH"; then
  echo "[FAIL] make.sh failed to build osmosisd for $GO_OS/$GO_ARCH."
  exit 1
fi

# 2. Check binary
if [ ! -f buildx-out/build/osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after cross-platform make.sh."
  exit 1
fi

echo "[OK] osmosisd cross-platform build test passed." 