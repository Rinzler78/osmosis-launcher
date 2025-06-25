#!/bin/bash
# Usage: ./resolve_arch.sh <uname_m>
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SUPPORTED_PLATFORMS_JSON="$ROOT_DIR/supported_platforms.json"

UNAME_M="$1"

case "$UNAME_M" in
  x86_64|amd64)
    ARCH="amd64"
    ;;
  i386|i686|386)
    ARCH="386"
    ;;
  arm64|aarch64)
    ARCH="arm64"
    ;;
  armv7l|armv6l|arm)
    ARCH="arm"
    ;;
  mips)
    ARCH="mips"
    ;;
  mipsle)
    ARCH="mipsle"
    ;;
  mips64)
    ARCH="mips64"
    ;;
  mips64le)
    ARCH="mips64le"
    ;;
  ppc64)
    ARCH="ppc64"
    ;;
  ppc64le)
    ARCH="ppc64le"
    ;;
  s390x)
    ARCH="s390x"
    ;;
  riscv64)
    ARCH="riscv64"
    ;;
  loongarch64|loong64)
    ARCH="loong64"
    ;;
  *)
    ARCH=""
    ;;
esac

if [ -n "$ARCH" ]; then
  valid_arch=$(jq -r --arg arch "$ARCH" '.arch[] | select(. == $arch)' "$SUPPORTED_PLATFORMS_JSON")
  if [ -n "$valid_arch" ]; then
    echo "$ARCH"
  fi
fi 