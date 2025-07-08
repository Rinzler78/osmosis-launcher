#!/bin/bash

. "$(dirname "$0")/utils.sh"
# Test script for docker_make.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKER_MAKE_SH="$SCRIPT_DIR/../src/docker_make.sh"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"
SUPPORTED_JSON="$SCRIPT_DIR/../supported_platforms.json"
RESOLVE_OS_SH="$SCRIPT_DIR/../src/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/../src/resolve_arch.sh"

ALL_PLATFORMS=false
if [ "$1" = "--all" ]; then
  ALL_PLATFORMS=true
fi

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

cleanup() {
  rm -rf buildx-out
}

trap 'echo_title; cleanup' EXIT

echo_title

echo "[INFO] Test docker_make"

# Skip if docker is not available
if ! command -v docker >/dev/null 2>&1; then
  echo "[SKIP] Docker command not found. Skipping docker_make test."
  exit 0
fi

if [ "$ALL_PLATFORMS" = false ]; then
  # Détection dynamique de la plateforme courante
  GO_OS=$("$RESOLVE_OS_SH" "$(uname -s)")
  GO_ARCH=$("$RESOLVE_ARCH_SH" "$(uname -m)")
  if [ -z "$GO_OS" ] || [ -z "$GO_ARCH" ]; then
    fail "Impossible de détecter la plateforme courante (GO_OS=$GO_OS, GO_ARCH=$GO_ARCH)"
  fi
  echo "[INFO] Plateforme courante détectée : $GO_OS/$GO_ARCH"
  if ! bash "$DOCKER_MAKE_SH" --os "$GO_OS" --arch "$GO_ARCH"; then
    fail "docker_make.sh failed"
  fi
  BINARY_PATH="buildx-out/build/osmosisd"
  if [ ! -f "$BINARY_PATH" ]; then
    fail "osmosisd binary not found after docker_make.sh in $BINARY_PATH"
  fi
  BUILT_VERSION=$("./$BINARY_PATH" version 2>/dev/null | head -n 1)
  if [ -z "$BUILT_VERSION" ]; then
    fail "Unable to read osmosisd version"
  fi
  pass "docker_make built osmosisd version $BUILT_VERSION"
else
  # --- Test cross-platform build for all supported OS/arch ---
  if ! command -v jq >/dev/null 2>&1; then
    fail "jq is required but not installed."
  fi
  PLATFORMS_TESTED=()
  for os in $(jq -r '.os[]' "$SUPPORTED_JSON"); do
    for arch in $(jq -r ".platforms[\"$os\"][]" "$SUPPORTED_JSON"); do
      echo "==== [TEST] Build for $os/$arch ===="
      OUTDIR="$SCRIPT_DIR/../buildx-out/${os}_${arch}"
      rm -rf "$OUTDIR"
      if bash "$DOCKER_MAKE_SH" "$os" "$arch"; then
        mkdir -p "$OUTDIR"
        if [ -d "$SCRIPT_DIR/../buildx-out/build" ]; then
          mv "$SCRIPT_DIR/../buildx-out/build"/* "$OUTDIR/" 2>/dev/null || true
        fi
        PLATFORMS_TESTED+=("$os/$arch")
        pass "Build for $os/$arch"
      else
        fail "Build for $os/$arch"
      fi
    done
  done
  echo "\n[SUMMARY] Platforms successfully built:"
  for p in "${PLATFORMS_TESTED[@]}"; do
    echo "  - $p"
  done
fi
