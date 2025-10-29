#!/bin/bash
# Build script specifically for Darwin (macOS) cross-compilation using OSXCross
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/parse_args.sh" "$@"

if [ ! -d "$TARGET_DIR" ]; then
  echo "[FAIL] Directory $TARGET_DIR does not exist."
  exit 1
fi

BUILD_DIR="."
GO_VERSION_SH="$SCRIPT_DIR/retrieve_required_go_version.sh"
VALIDATE_PLATFORM_SH="$SCRIPT_DIR/validate_platform.sh"
DOWNLOAD_WASMVM_SH="$SCRIPT_DIR/download_wasmvm_darwin.sh"

# Validate that this is a darwin build
if [ "$GO_OS" != "darwin" ]; then
  echo "[FAIL] build_darwin.sh should only be called for darwin builds, got GO_OS=$GO_OS"
  exit 1
fi

# Validate platform
if ! "$VALIDATE_PLATFORM_SH" "$GO_OS" "$GO_ARCH"; then
  echo "[FAIL] The platform $GO_OS/$GO_ARCH is not supported."
  exit 1
fi

# Backup the initial environment
OLD_PATH="$PATH"
OLD_GOROOT="$GOROOT"

# Detect the required Go version
GO_VERSION=$($GO_VERSION_SH "$TARGET_DIR")
if [ -z "$GO_VERSION" ]; then
  echo "[FAIL] Could not determine Go version for directory $TARGET_DIR."
  exit 1
fi

# Always download Go for the container platform (Linux)
RESOLVE_OS_SH="$SCRIPT_DIR/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/resolve_arch.sh"
GO_DL_OS=$("$RESOLVE_OS_SH" "$(uname -s)")
GO_DL_ARCH=$("$RESOLVE_ARCH_SH" "$(uname -m)")

# Check the installed Go version
if command -v go >/dev/null 2>&1; then
  INSTALLED_GO=$(go version | awk '{print $3}' | sed 's/go//')
else
  INSTALLED_GO=""
fi

# Install Go if necessary
if [[ "$INSTALLED_GO" != "$GO_VERSION"* ]]; then
  echo "[INFO] Installing Go $GO_VERSION ($GO_DL_OS/$GO_DL_ARCH)..."
  GO_TMP_DIR="/tmp/go-$GO_VERSION-$$"
  GO_TARBALL_PATH=$("$SCRIPT_DIR/download_go_archive.sh" "$GO_VERSION" "$GO_DL_OS" "$GO_DL_ARCH" | tail -n1)
  tar -C /tmp -xzf "$GO_TARBALL_PATH"
  mv /tmp/go "$GO_TMP_DIR"
  export GOROOT="$GO_TMP_DIR"
  export PATH="$GO_TMP_DIR/bin:$PATH"
  GO_INSTALLED_BEFORE=1
fi

# Cleanup trap
cleanup() {
  if [ "$GO_INSTALLED_BEFORE" = "1" ]; then
    echo "[CLEANUP] Deleting Go $GO_VERSION ($GO_TMP_DIR)."
    rm -rf "$GO_TMP_DIR" "$GO_TMP_DIR.tar.gz"
    export PATH="$OLD_PATH"
    export GOROOT="$OLD_GOROOT"
  fi
}
trap cleanup EXIT

# Extract wasmvm version from go.mod
pushd "$TARGET_DIR" > /dev/null
WASMVM_VERSION=$(grep 'github.com/CosmWasm/wasmvm' go.mod | awk '{print $2}' | head -1)
popd > /dev/null

if [ -z "$WASMVM_VERSION" ]; then
  echo "[FAIL] Could not determine wasmvm version from go.mod"
  exit 1
fi

echo "[INFO] Detected wasmvm version: $WASMVM_VERSION"

# Download libwasmvmstatic_darwin.a
if ! bash "$DOWNLOAD_WASMVM_SH" "$WASMVM_VERSION" "/lib/libwasmvmstatic_darwin.a"; then
  echo "[FAIL] Failed to download libwasmvmstatic_darwin.a"
  exit 1
fi

# Configure OSXCross toolchain based on architecture
if [ "$GO_ARCH" = "amd64" ]; then
  export CC=o64-clang
  export CXX=o64-clang++
elif [ "$GO_ARCH" = "arm64" ]; then
  export CC=oa64-clang
  export CXX=oa64-clang++
else
  echo "[FAIL] Unsupported darwin architecture: $GO_ARCH"
  exit 1
fi

# Configure CGO for Darwin cross-compilation
export CGO_ENABLED=1
export CGO_CFLAGS="-mmacosx-version-min=10.12"
export CGO_LDFLAGS="-L/lib -mmacosx-version-min=10.12"

# Set target platform
export GOOS="$GO_OS"
export GOARCH="$GO_ARCH"

# Use default GOPROXY if not set
if [ -z "$GOPROXY" ]; then
  export GOPROXY="https://proxy.golang.org,direct"
fi

# Build osmosisd with darwin-specific configuration
pushd "$TARGET_DIR"

# Download dependencies
echo "[INFO] Downloading Go dependencies..."
if ! go mod download 2>&1; then
  echo "[WARN] Initial download failed, attempting go mod tidy..."
  if ! go mod tidy 2>&1; then
    echo "[ERROR] go mod tidy failed"
  fi
  if ! go mod download 2>&1; then
    echo "[ERROR] Dependency download failed after tidy, build may fail"
  fi
fi

echo "[INFO] Compiling osmosisd binary for $GO_OS/$GO_ARCH with OSXCross..."

# Use BUILD_TAGS from environment if provided (via docker_make.sh)
# The Makefile already includes "netgo ledger" so we only add extra tags
if [ -n "$BUILD_TAGS" ]; then
  # Extract only the extra tags not already in the Makefile (static_wasm)
  export build_tags="static_wasm"
  echo "[INFO] Using CC=$CC, CGO_ENABLED=1, build tags: netgo,ledger,static_wasm"
else
  echo "[INFO] Using CC=$CC, CGO_ENABLED=1, build tags: netgo,ledger"
fi

# Build with darwin-specific configuration
# Note: We use the existing Makefile but with modified environment
make build

popd

# Copy the binary to the target directory
cp "$TARGET_DIR/build/osmosisd" $BUILD_DIR

echo "[OK] Darwin build completed successfully for $GO_OS/$GO_ARCH"
