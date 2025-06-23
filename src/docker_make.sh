#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAG="${1-}"

# Deduction of the target platform
GO_OS="${GO_OS:-}"
GO_ARCH="${GO_ARCH:-}"

# OS
if [ -z "$GO_OS" ]; then
  UNAME_OS="$(uname -s)"
  case "$UNAME_OS" in
    Linux|Darwin|MINGW*|MSYS*|CYGWIN*) GO_OS="linux" ;;
    *) echo "[FAIL] Unsupported host OS: $UNAME_OS" && exit 1 ;;
  esac
fi

# ARCH
if [ -z "$GO_ARCH" ]; then
  UNAME_ARCH="$(uname -m)"
  case "$UNAME_ARCH" in
    x86_64|amd64)  GO_ARCH="amd64" ;;
    arm64|aarch64) GO_ARCH="arm64" ;;
    *) echo "[FAIL] Unsupported architecture: $UNAME_ARCH" && exit 1 ;;
  esac
fi

PLATFORM="${GO_OS}/${GO_ARCH}"
IMAGE_NAME="osmosis-launcher:build-${GO_OS}-${GO_ARCH}"
CONTAINER_NAME="osmosis-builder-${GO_OS}-${GO_ARCH}"

echo "[INFO] Target platform: $PLATFORM"
echo "[INFO] Docker image: $IMAGE_NAME"
echo "[INFO] Docker container: $CONTAINER_NAME"

# Check if binfmt is enabled
check_binfmt() {
  docker run --rm --privileged tonistiigi/binfmt --help >/dev/null 2>&1
}
if ! check_binfmt; then
  echo "[INFO] Activating cross-platform build support (binfmt)..."
  docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null
fi

# Rebuild image
echo "[INFO] Building image $IMAGE_NAME..."
docker build --platform="$PLATFORM" -t "$IMAGE_NAME" "$SCRIPT_DIR"

# Build command
BUILD_CMD="set -x && cd /workspace && src/make.sh"
[ -n "$TAG" ] && BUILD_CMD+=" $TAG"
BUILD_CMD+=" && cp osmosisd /output/"

echo "[INFO] Running build in container $CONTAINER_NAME..."
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# Run the build with full trace, and log at the same time
docker run --rm -it \
  --name "$CONTAINER_NAME" \
  -v "$PWD":/output \
  "$IMAGE_NAME" \
  bash -c "$BUILD_CMD"

# Check for binary presence
if [ ! -f osmosisd ]; then
  echo "[FAIL] osmosisd binary not found after Docker build."
  exit 1
fi

BUILT_VERSION=$(./osmosisd version 2>/dev/null | head -n 1)
if [ -n "$TAG" ]; then
  TAG_CLEANED="${TAG#v}"
  if [ "$BUILT_VERSION" != "$TAG_CLEANED" ]; then
    echo "[FAIL] osmosisd version ($BUILT_VERSION) does not match tag ($TAG_CLEANED)."
    exit 1
  fi
fi

echo "[OK] osmosisd built with version: $BUILT_VERSION"
