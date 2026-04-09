#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/parse_args.sh" "$@"

TAG="${TAG:-}"
GO_OS="${GO_OS:-}"
GO_ARCH="${GO_ARCH:-}"
TARGET_DIR="${TARGET_DIR:-}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "[FAIL] Directory $TARGET_DIR does not exist."
  exit 1
fi
BUILD_DIR="."
GO_VERSION_SH="$SCRIPT_DIR/retrieve_required_go_version.sh"
VALIDATE_PLATFORM_SH="$SCRIPT_DIR/validate_platform.sh"
RESOLVE_OS_SH="$SCRIPT_DIR/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/resolve_arch.sh"
GO_TARBALL_PATH=""
GO_EXTRACT_DIR=""

# Détection OS/ARCH si non fournis
if [ -z "$GO_OS" ]; then
  GO_OS=$("$RESOLVE_OS_SH" "$(uname -s)")
  if [ -z "$GO_OS" ]; then
    echo "[FAIL] Could not resolve a supported OS from 'uname -s' ($(uname -s))."
    exit 1
  fi
fi
if [ -z "$GO_ARCH" ]; then
  GO_ARCH=$("$RESOLVE_ARCH_SH" "$(uname -m)")
  if [ -z "$GO_ARCH" ]; then
    echo "[FAIL] Could not resolve a supported architecture from 'uname -m' ($(uname -m))."
    exit 1
  fi
fi
if ! "$VALIDATE_PLATFORM_SH" "$GO_OS" "$GO_ARCH"; then
  echo "[FAIL] The platform $GO_OS/$GO_ARCH is not supported."
  exit 1
fi

# Delegate to build_darwin.sh only for cross-compilation (Linux -> Darwin)
# For native Darwin builds, continue with standard build process below
CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$GO_OS" = "darwin" ] && [ "$CURRENT_OS" != "darwin" ]; then
  echo "[INFO] Delegating to build_darwin.sh for Darwin cross-compilation..."
  exec "$SCRIPT_DIR/build_darwin.sh" "$@"
fi

# Backup the initial environment
OLD_PATH="$PATH"
OLD_GOROOT="${GOROOT:-}"
GO_INSTALLED_BEFORE=0

# Detect the required Go version
GO_VERSION="$("$GO_VERSION_SH" "$TARGET_DIR")"
if [ -z "$GO_VERSION" ]; then
  echo "[FAIL] Could not determine Go version for directory $TARGET_DIR."
  exit 1
fi

# Toujours télécharger Go pour la plateforme du conteneur
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
  GO_EXTRACT_DIR="$(mktemp -d /tmp/go-extract-XXXXXX)"
  # Download the archive via le dedicated script (toujours pour la plateforme du conteneur)
  GO_TARBALL_PATH="$("$SCRIPT_DIR/download_go_archive.sh" "$GO_VERSION" "$GO_DL_OS" "$GO_DL_ARCH" | tail -n1)"
  tar -C "$GO_EXTRACT_DIR" -xzf "$GO_TARBALL_PATH"
  mv "$GO_EXTRACT_DIR/go" "$GO_TMP_DIR"
  export GOROOT="$GO_TMP_DIR"
  export PATH="$GO_TMP_DIR/bin:$PATH"
  GO_INSTALLED_BEFORE=1
fi

# Trap to delete Go if installed by the script
cleanup() {
  if [ "$GO_INSTALLED_BEFORE" = "1" ]; then
    echo "[CLEANUP] Deleting Go $GO_VERSION ($GO_TMP_DIR)."
    rm -rf "$GO_TMP_DIR" "$GO_EXTRACT_DIR"
    if [ -n "$GO_TARBALL_PATH" ]; then
      rm -f "$GO_TARBALL_PATH"
    fi
    export PATH="$OLD_PATH"
    export GOROOT="$OLD_GOROOT"
  fi
}
trap cleanup EXIT

# Compile the binary pour la plateforme cible
pushd "$TARGET_DIR" >/dev/null

# Use default GOPROXY if not set, allows fallback to proxy.golang.org
if [ -z "${GOPROXY:-}" ]; then
  export GOPROXY="https://proxy.golang.org,direct"
fi

export GOOS="$GO_OS"
export GOARCH="$GO_ARCH"
export GOTOOLCHAIN=local

# Download dependencies first with proper error handling
echo "[INFO] Downloading Go dependencies..."
if [ -z "${GOSUMDB:-}" ]; then
  export GOSUMDB="sum.golang.org"
fi
if ! go mod download 2>&1; then
  echo "[WARN] Initial download failed, attempting go mod tidy..."
  if ! go mod tidy 2>&1; then
    echo "[ERROR] go mod tidy failed"
  fi
  if ! go mod download 2>&1; then
    echo "[ERROR] Dependency download failed after tidy, build may fail"
  fi
fi

echo "[INFO] Compiling osmosisd binary for $GO_OS/$GO_ARCH..."
make build
popd >/dev/null

# Copy the binary to the target directory
cp "$TARGET_DIR/build/osmosisd" "$BUILD_DIR"
