#!/bin/bash
# Clone le repo Osmosis à un tag donné dans un dossier cible
# Usage: ./clone.sh <tag> <dossier_cible>

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAG="$1"
TARGET_DIR="$2"
REPO_URL=$(cat "$(dirname "$0")/repo_url.txt")
DEFAULT_BRANCH="main"

# Si TAG n'est pas défini, on prend le dernier tag
if [ -z "$TAG" ]; then
  TAG="$("$SCRIPT_DIR/last_tag.sh")"
  echo "[INFO] No tag provided, using last tag: $TAG"
else
  # Vérifie que le tag existe
  if ! "$SCRIPT_DIR/tags.sh" | grep -Fxq "$TAG"; then
    echo "[ERROR] Tag $TAG does not exist in Osmosis repo."
    exit 3
  fi
fi

# Si TARGET_DIR n'est pas défini, on met osmosis
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
  GIT_LFS_SKIP_SMUDGE=1 git fetch --all --tags
  git checkout "$TAG"
  exit 0
fi

# Clone la branche principale puis checkout le tag
echo "[INFO] Cloning Osmosis repo to $TARGET_DIR"
GIT_LFS_SKIP_SMUDGE=1 git clone --branch "$DEFAULT_BRANCH" --depth 1 "$REPO_URL" "$TARGET_DIR" > /dev/null 2>&1
cd "$TARGET_DIR"
echo "[INFO] Fetching tags and checking out tag $TAG"
GIT_LFS_SKIP_SMUDGE=1 git fetch --all --tags > /dev/null 2>&1
git checkout "$TAG" > /dev/null 2>&1
cd - > /dev/null

if [ -d "$TARGET_DIR" ]; then
  echo "[OK] Repo Osmosis cloné dans $TARGET_DIR à la version $TAG."
else
  echo "[ERROR] Le clonage a échoué."
  exit 2
fi 