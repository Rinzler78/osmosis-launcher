#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/parse_args.sh" "$@"
VALIDATE_PLATFORM_SH="$SCRIPT_DIR/validate_platform.sh"
RESOLVE_OS_SH="$SCRIPT_DIR/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/resolve_arch.sh"

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

# Automatic cleaning of the cloned folder at the end
cleanup() {
  echo "[CLEANUP] Deleting $TARGET_DIR."
  rm -rf "$TARGET_DIR"
}
trap cleanup EXIT 

# If TAG is not defined, we take the last tag
if [ -z "$TAG" ]; then
  TAG="$($SCRIPT_DIR/last_tag.sh)"
  echo "[INFO] No tag provided, using last tag: $TAG"
else
  # Check if the tag exists
  if ! "$SCRIPT_DIR/tags.sh" | grep -Fxq "$TAG"; then
    echo "[ERROR] The specified tag '$TAG' was not found in the Osmosis repository. Use './src/tags.sh' to list available tags."
    exit 3
  fi
fi

# Dossier cible pour le clone et le build (paramètre 4 ou 'osmosis' par défaut)
if [ -n "${4-}" ]; then
  TARGET_DIR="$4"
else
  TARGET_DIR="osmosis"
fi

# Clone the repo
if ! "$SCRIPT_DIR/clone.sh" --tag "$TAG" --target-dir "$TARGET_DIR"; then
  echo "Cannot clone the repo"
  exit 1
fi

# Patch the repo
if ! "$SCRIPT_DIR/patch.sh" --target-dir "$TARGET_DIR"
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

# Build
if ! "$SCRIPT_DIR/build.sh" --target-dir "$TARGET_DIR" --os "$GO_OS" --arch "$GO_ARCH"
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

# Compare versions
# Checking the binary version
CUR_OS=$("$RESOLVE_OS_SH" "$(uname -s)")
CUR_ARCH=$("$RESOLVE_ARCH_SH" "$(uname -m)")
if [ "$GO_OS" = "$CUR_OS" ] && [ "$GO_ARCH" = "$CUR_ARCH" ]; then
  OSMOSISD_VERSION_OUTPUT=$(./osmosisd version 2>/dev/null | head -n 1)
  if [ "$OSMOSISD_VERSION_OUTPUT" != "${TAG#v}" ]; then
    echo "[FAIL] Built osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match requested version (${TAG#v})."
    exit 1
  else
    echo "[OK] osmosisd version check passed: $OSMOSISD_VERSION_OUTPUT"
  fi
else
  echo "[INFO] Skipping osmosisd version check: cannot run binary for $GO_OS/$GO_ARCH on current platform $CUR_OS/$CUR_ARCH."
fi