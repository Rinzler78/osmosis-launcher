#!/bin/bash
# Build patched osmosisd using Docker and src/make.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAG="${1-}"
ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"

# Build the image for the host architecture
docker build --platform="$ARCH" -t osmosis-launcher-build "$SCRIPT_DIR"

# Run make.sh inside the container and copy the result back
if [ -n "$TAG" ]; then
  BUILD_CMD="cd /workspace && src/make.sh $TAG && cp osmosisd /output/"
else
  BUILD_CMD="cd /workspace && src/make.sh && cp osmosisd /output/"
fi

docker run --rm -v "$PWD":/output osmosis-launcher-build bash -c "$BUILD_CMD"

# Verify the built binary
if [ ! -f osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after Docker build."
  exit 1
fi
BUILT_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
if [ -n "$TAG" ]; then
  TAG_CLEANED=${TAG#v}
  if [ "$BUILT_VERSION" != "$TAG_CLEANED" ]; then
    echo "[FAIL] osmosisd version ($BUILT_VERSION) does not match tag ($TAG_CLEANED)."
    exit 1
  fi
fi

echo "[OK] osmosisd built with version: $BUILT_VERSION"
