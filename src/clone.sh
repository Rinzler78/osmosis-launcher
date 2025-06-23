#!/bin/bash
# Clones the Osmosis repo at a given tag in a target directory
# Usage: ./clone.sh <tag> <target_directory>

set -e
export GIT_LFS_SKIP_SMUDGE=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAG="$1"
TARGET_DIR="$2"
REPO_URL=$(cat "$(dirname "$0")/repo_url.txt")
DEFAULT_BRANCH="main"

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

# If TARGET_DIR is not defined, use osmosis
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="osmosis"
  echo "[INFO] No target directory provided, using default: $TARGET_DIR"
fi

if [ -d "$TARGET_DIR/.git" ]; then
  echo "[INFO] Target directory $TARGET_DIR already exists. Trying to fetch and checkout tag $TAG."
  cd "$TARGET_DIR"
  ORIGIN_URL=$(git remote get-url origin)
  if [ "$ORIGIN_URL" != "$REPO_URL" ]; then
    echo "[ERROR] Remote 'origin' URL ($ORIGIN_URL) does not match expected ($REPO_URL)."
    exit 1
  fi
  CURRENT_REF=$(git symbolic-ref --short -q HEAD || git describe --tags --exact-match 2>/dev/null)
  if [ "$CURRENT_REF" = "$TAG" ]; then
    echo "[INFO] Already on tag/branch $TAG. Performing hard reset to ensure clean state."
    git fetch
    git reset --hard "$TAG"
    exit 0
  fi
  git fetch --all --tags
  git checkout "$TAG"
  git reset --hard "$TAG"
  exit 0
fi

# Clone the main branch then checkout the tag
echo "[INFO] Cloning Osmosis repo to $TARGET_DIR"
git clone --branch "$DEFAULT_BRANCH" --depth 1 "$REPO_URL" "$TARGET_DIR"
cd "$TARGET_DIR"
echo "[INFO] Fetching tags and checking out tag $TAG"
git fetch --all --tags > /dev/null 2>&1
git checkout "$TAG" > /dev/null 2>&1
git reset --hard "$TAG" > /dev/null 2>&1
cd -

if [ -d "$TARGET_DIR" ]; then
  echo "[OK] Osmosis repo cloned in $TARGET_DIR at version $TAG."
else
  echo "[ERROR] Cloning failed."
  exit 2
fi 