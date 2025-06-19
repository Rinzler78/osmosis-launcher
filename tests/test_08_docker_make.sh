#!/bin/bash
# Test script for docker_make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_MAKE_SH="$SCRIPT_DIR/../docker_make.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

cleanup() {
  rm -f osmosisd
}

trap 'echo_title; cleanup' EXIT

echo_title

echo "[INFO] Test docker_make"

# Skip if docker is not available
if ! command -v docker >/dev/null 2>&1; then
  echo "[SKIP] Docker command not found. Skipping docker_make test."
  exit 0
fi

# Attempt to build without specifying a tag (uses last tag)
if ! bash "$DOCKER_MAKE_SH"; then
  echo "[FAIL] docker_make.sh failed"
  exit 1
fi

if [ ! -f osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after docker_make.sh"
  exit 1
fi

# Basic check of the produced version
BUILT_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
if [ -z "$BUILT_VERSION" ]; then
  echo "[FAIL] Unable to read osmosisd version"
  exit 1
fi

echo "[OK] docker_make built osmosisd version $BUILT_VERSION"
