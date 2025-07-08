#!/bin/bash
set -e

. "$(dirname "$0")/utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

echo_title

echo "[INFO] Test downloading Go archive"

trap 'echo_title' EXIT

# Main OS/ARCH/EXT combinations (max 10)
PLATFORMS=(
  "linux amd64 tar.gz"
  "linux arm64 tar.gz"
  "linux 386 tar.gz"
  "darwin amd64 tar.gz"
  "darwin arm64 tar.gz"
  "windows amd64 zip"
  "windows arm64 zip"
)

GO_VERSION="1.21.6"
SUCCESS=0
FAIL=0

for entry in "${PLATFORMS[@]}"; do
  set -- $entry
  GO_OS=$1
  GO_ARCH=$2
  EXT=$3
  SCRIPT_PATH="$SCRIPT_DIR/../src/download_go_archive.sh"
  echo "[INFO] Testing $GO_VERSION $GO_OS $GO_ARCH"
  ARCHIVE_PATH=$($SCRIPT_PATH --go-version "$GO_VERSION" --os "$GO_OS" --arch "$GO_ARCH" | tail -n1)
  # Check the expected extension
  if [[ "$ARCHIVE_PATH" != *.$EXT ]]; then
    fail "$GO_VERSION $GO_OS $GO_ARCH: Wrong extension ($ARCHIVE_PATH, expected: $EXT)"
    continue
  fi
  if [ -f "$ARCHIVE_PATH" ]; then
    pass "$GO_VERSION $GO_OS $GO_ARCH: $ARCHIVE_PATH"
    rm -f "$ARCHIVE_PATH"
    SUCCESS=$((SUCCESS+1))
  else
    fail "$GO_VERSION $GO_OS $GO_ARCH: $ARCHIVE_PATH not found"
    FAIL=$((FAIL+1))
  fi
done

pass "Summary: $SUCCESS success, $FAIL failures."
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi 