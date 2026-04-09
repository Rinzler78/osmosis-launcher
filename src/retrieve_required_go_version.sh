#!/bin/bash
set -euo pipefail

TMP_DIR="$1"
if [ -z "$TMP_DIR" ]; then
  echo "Usage: $0 <tmp_dir>" >&2
  exit 1
fi

GO_MOD_PATH="$TMP_DIR/go.mod"
if [ ! -f "$GO_MOD_PATH" ]; then
  echo "[FAIL] '$GO_MOD_PATH' does not exist." >&2
  exit 1
fi

GO_VERSION="$(awk '/^go / { print $2; exit }' "$GO_MOD_PATH")"
TOOLCHAIN_VERSION="$(awk '/^toolchain go/ { sub(/^toolchain go/, "", $0); print $0; exit }' "$GO_MOD_PATH")"

if [ -n "$TOOLCHAIN_VERSION" ]; then
  echo "$TOOLCHAIN_VERSION"
elif [ -n "$GO_VERSION" ]; then
  echo "$GO_VERSION"
else
  echo "[FAIL] Could not determine a Go version from '$GO_MOD_PATH'." >&2
  exit 1
fi
