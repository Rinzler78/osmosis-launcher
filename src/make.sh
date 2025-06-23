#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="osmosis"
TAG=$1

# Automatic cleaning of the cloned folder at the end
cleanup() {
  echo "[CLEANUP] Deleting $TARGET_DIR."
  rm -rf "$TARGET_DIR"
}
trap cleanup EXIT 

# If TAG is not defined, we take the last tag
if [ -z "$TAG" ]; then
  TAG="$("$SCRIPT_DIR/last_tag.sh")"
  echo "[INFO] No tag provided, using last tag: $TAG"
else
  # Check if the tag exists
  if ! "$SCRIPT_DIR/tags.sh" | grep -Fxq "$TAG"; then
    echo "[ERROR] The specified tag '$TAG' was not found in the Osmosis repository. Use './src/tags.sh' to list available tags."
    exit 3
  fi
fi

# Clone the repo
if ! "$SCRIPT_DIR/clone.sh" "$TAG" "$TARGET_DIR"; then
  echo "Cannot clone the repo"
  exit 1
fi

# Patch the repo
if ! "$SCRIPT_DIR/patch.sh" "$TARGET_DIR"
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

# Build
if ! "$SCRIPT_DIR/build.sh" "$TARGET_DIR"
then
    echo "Cannot build osmosis-launcher"
    exit 1
fi

# Compare versions
# Checking the binary version
OSMOSISD_VERSION_OUTPUT=$("./osmosisd" version 2>/dev/null | head -n 1)
if [ "$OSMOSISD_VERSION_OUTPUT" != "${TAG#v}" ]; then
  echo "[FAIL] Built osmosisd version ($OSMOSISD_VERSION_OUTPUT) does not match requested version (${TAG#v})."
  exit 1
else
  echo "[OK] osmosisd version check passed: $OSMOSISD_VERSION_OUTPUT"
fi