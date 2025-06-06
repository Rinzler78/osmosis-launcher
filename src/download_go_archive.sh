#!/bin/bash
set -e

# Usage: download_go_archive.sh <go_version> [go_os] [go_arch]

GO_VERSION="$1"
GO_OS="$2"
GO_ARCH="$3"

if [ -z "$GO_VERSION" ]; then
  echo "Usage: $0 <go_version> [go_os] [go_arch]"
  exit 1
fi

# Déduire GO_OS si non fourni
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

# Déduire GO_ARCH si non fourni
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

# Déterminer l'extension selon l'OS
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