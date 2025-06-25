#!/bin/bash
# Usage: ./validate_platform.sh <os> <arch>
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SUPPORTED_PLATFORMS_JSON="$ROOT_DIR/supported_platforms.json"

OS="$1"
ARCH="$2"

if [ -z "$OS" ] || [ -z "$ARCH" ]; then
  echo "[FAIL] Usage: $0 <os> <arch>" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[FAIL] jq is required but not installed." >&2
  exit 1
fi

valid_os=$(jq -r --arg os "$OS" '.os[] | select(. == $os)' "$SUPPORTED_PLATFORMS_JSON")
if [ -z "$valid_os" ]; then
  echo "[FAIL] Unsupported OS: $OS (see supported_platforms.json)" >&2
  exit 1
fi

valid_arch=$(jq -r --arg arch "$ARCH" '.arch[] | select(. == $arch)' "$SUPPORTED_PLATFORMS_JSON")
if [ -z "$valid_arch" ]; then
  echo "[FAIL] Unsupported architecture: $ARCH (see supported_platforms.json)" >&2
  exit 1
fi

valid_combo=$(jq -r --arg os "$OS" --arg arch "$ARCH" '.platforms[$os][] | select(. == $arch)' "$SUPPORTED_PLATFORMS_JSON")
if [ -z "$valid_combo" ]; then
  echo "[FAIL] Unsupported platform combination: $OS/$ARCH (see supported_platforms.json)" >&2
  exit 1
fi

exit 0 