#!/bin/bash
set -e

# Usage: download_go_archive.sh --go-version <go_version> [--os <go_os>] [--arch <go_arch>]
# Ou en positionnel : <go_version> [go_os] [go_arch] (pour compatibilité)

GO_VERSION=""
GO_OS=""
GO_ARCH=""

# Parsing des arguments nommés
while [[ $# -gt 0 ]]; do
  case "$1" in
    --go-version)
      GO_VERSION="$2"
      shift 2
      ;;
    --os)
      GO_OS="$2"
      shift 2
      ;;
    --arch)
      GO_ARCH="$2"
      shift 2
      ;;
    --*)
      echo "[FAIL] Unknown option: $1"
      exit 1
      ;;
    *)
      # Arguments positionnels (pour compatibilité)
      if [ -z "$GO_VERSION" ]; then
        GO_VERSION="$1"
      elif [ -z "$GO_OS" ]; then
        GO_OS="$1"
      elif [ -z "$GO_ARCH" ]; then
        GO_ARCH="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$GO_VERSION" ]; then
  echo "Usage: $0 --go-version <go_version> [--os <go_os>] [--arch <go_arch>]"
  exit 1
fi

# Deduce GO_OS if not provided
if [ -z "$GO_OS" ]; then
  UNAME_OS="$(uname -s)"
  case "$UNAME_OS" in
    Linux)
      GO_OS="linux"
      ;;
    Darwin)
      GO_OS="darwin"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      GO_OS="windows"
      ;;
    *)
      echo "[FAIL] Unsupported OS: $UNAME_OS"
      exit 1
      ;;
  esac
fi

# Deduce GO_ARCH if not provided
if [ -z "$GO_ARCH" ]; then
  UNAME_ARCH="$(uname -m)"
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
fi

# Determine the extension according to the OS
if [ "$GO_OS" = "windows" ]; then
  EXT="zip"
else
  EXT="tar.gz"
fi

GO_TARBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.${EXT}"
FULL_URL="https://go.dev/dl/$GO_TARBALL"
GO_TMP_DIR="/tmp/go-$GO_VERSION-$GO_OS-$GO_ARCH-$$"
GO_TARBALL_PATH="$GO_TMP_DIR.$EXT"

mkdir -p "$(dirname "$GO_TARBALL_PATH")"

echo "[INFO] Downloading Go $GO_VERSION from $FULL_URL ..."
curl -sSL -o "$GO_TARBALL_PATH" "$FULL_URL"

echo "$GO_TARBALL_PATH" 