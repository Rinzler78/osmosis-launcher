#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$1"
if [ ! -d "$TARGET_DIR" ]; then
  echo "[FAIL] Directory $TARGET_DIR does not exist."
  exit 1
fi
BUILD_DIR="."
GO_VERSION_SH="$SCRIPT_DIR/retrieve_required_go_version.sh"

# Detect OS and architecture for Go download
UNAME_OS="$(uname -s)"
UNAME_ARCH="$(uname -m)"

case "$UNAME_OS" in
  Linux)
    GO_OS="linux"
    ;;
  Darwin)
    GO_OS="darwin"
    ;;
  *)
    echo "[FAIL] Unsupported OS: $UNAME_OS"
    exit 1
    ;;
esac

case "$UNAME_ARCH" in
  x86_64|amd64)
    GO_ARCH="amd64"
    ;;
  arm64|aarch64)
    GO_ARCH="arm64"
    ;;
  *)
    echo "[FAIL] Unsupported architecture: $UNAME_ARCH"
    exit 1
    ;;
esac

# Backup the initial environment
OLD_PATH="$PATH"
OLD_GOROOT="$GOROOT"

# Detect the required Go version
GO_VERSION=$($GO_VERSION_SH "$TARGET_DIR")
if [ -z "$GO_VERSION" ]; then
  echo "[FAIL] Could not determine Go version for directory $TARGET_DIR."
  exit 1
fi

# Check the installed Go version
if command -v go >/dev/null 2>&1; then
  INSTALLED_GO=$(go version | awk '{print $3}' | sed 's/go//')
else
  INSTALLED_GO=""
fi

# Install Go if necessary
if [[ "$INSTALLED_GO" != "$GO_VERSION"* ]]; then
  echo "[INFO] Installing Go $GO_VERSION..."
  GO_TMP_DIR="/tmp/go-$GO_VERSION-$$"
  # Download the archive via the dedicated script
  GO_TARBALL_PATH=$("$SCRIPT_DIR/download_go_archive.sh" "$GO_VERSION" "$GO_OS" "$GO_ARCH" | tail -n1)
  tar -C /tmp -xzf "$GO_TARBALL_PATH"
  mv /tmp/go "$GO_TMP_DIR"
  export GOROOT="$GO_TMP_DIR"
  export PATH="$GO_TMP_DIR/bin:$PATH"
  GO_INSTALLED_BEFORE=1
fi

# Trap to delete Go if installed by the script
cleanup() {
  if [ "$GO_INSTALLED_BEFORE" = "1" ]; then
    echo "[CLEANUP] Deleting Go $GO_VERSION ($GO_TMP_DIR)."
    rm -rf "$GO_TMP_DIR" "$GO_TMP_DIR.tar.gz"
    export PATH="$OLD_PATH"
    export GOROOT="$OLD_GOROOT"
  fi
}
trap cleanup EXIT

# Compile the binary for the current platform
pushd "$TARGET_DIR"
export GOPROXY=direct
echo "[INFO] Compiling osmosisd binary for $(go env GOOS)/$(go env GOARCH)..."
make build
popd

# Copy the binary to the target directory
cp "$TARGET_DIR/build/osmosisd" $BUILD_DIR
