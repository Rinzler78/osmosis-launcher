#!/bin/bash
set -e

# Principales combinaisons OS/ARCH/EXT (10 max)
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
  SCRIPT_PATH="$(dirname "$0")/../src/download_go_archive.sh"
  ARCHIVE_PATH=$($SCRIPT_PATH "$GO_VERSION" "$GO_OS" "$GO_ARCH" | tail -n1)
  # Vérifier l'extension attendue
  if [[ "$ARCHIVE_PATH" != *.$EXT ]]; then
    echo "[TEST FAIL] $GO_VERSION $GO_OS $GO_ARCH: Mauvaise extension ($ARCHIVE_PATH, attendu: $EXT)"
    FAIL=$((FAIL+1))
    continue
  fi
  if [ -f "$ARCHIVE_PATH" ]; then
    echo "[TEST PASS] $GO_VERSION $GO_OS $GO_ARCH: $ARCHIVE_PATH"
    rm -f "$ARCHIVE_PATH"
    SUCCESS=$((SUCCESS+1))
  else
    echo "[TEST FAIL] $GO_VERSION $GO_OS $GO_ARCH: $ARCHIVE_PATH not found"
    FAIL=$((FAIL+1))
  fi
done

echo "\nRésumé : $SUCCESS succès, $FAIL échecs."
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi 