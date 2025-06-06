#!/bin/bash
set -e

TMP_DIR="$1"
if [ -z "$TMP_DIR" ]; then
  echo "Usage: $0 <tmp_dir>"
  exit 1
fi

# Get the Go version from go.mod
GO_VERSION=$(grep '^go ' "$TMP_DIR/go.mod" | awk '{print $2}')
echo "$GO_VERSION"