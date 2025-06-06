#!/bin/bash
# Test script for src/clone.sh
# Usage: ./test_clone.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
CLONE_SH="$ROOT_DIR/src/clone.sh"
LAST_TAG="$($ROOT_DIR/src/last_tag.sh)"

# Nettoyage à la sortie
cleanup() {
  rm -rf "$ROOT_DIR/.tmp"
}
trap cleanup EXIT

# Nettoyage initial
rm -rf "$ROOT_DIR/.tmp"

# 1. Test avec tag et dossier
TEST_DIR1="$ROOT_DIR/test1"
TAG1="$LAST_TAG"
"$CLONE_SH" "$TAG1" "$TEST_DIR1"
if [ ! -d "$TEST_DIR1/.git" ]; then
  echo "[ERROR] Test 1: Repo not cloned in $TEST_DIR1"
  exit 1
fi
CUR_TAG=$(cd "$TEST_DIR1" && git rev-parse --abbrev-ref HEAD || git describe --tags)
if ! (cd "$TEST_DIR1" && git describe --tags | grep "$TAG1" > /dev/null); then
  echo "[ERROR] Test 1: Tag $TAG1 not checked out in $TEST_DIR1"
  exit 1
fi

echo "[OK] Test 1: Clone with tag and dir => OK"

# 2. Test sans tag (doit prendre le dernier tag)
TEST_DIR2="$ROOT_DIR/test2"
"$CLONE_SH" "" "$TEST_DIR2"
if [ ! -d "$TEST_DIR2/.git" ]; then
  echo "[ERROR] Test 2: Repo not cloned in $TEST_DIR2"
  exit 1
fi
if ! (cd "$TEST_DIR2" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 2: Last tag $LAST_TAG not checked out in $TEST_DIR2"
  exit 1
fi

echo "[OK] Test 2: Clone with no tag => OK"

# 3. Test sans dossier (doit cloner dans osmosis)
DEFAULT_DIR="$ROOT_DIR/osmosis"
rm -rf "$DEFAULT_DIR"
"$CLONE_SH" "$LAST_TAG"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  echo "[ERROR] Test 3: Repo not cloned in $DEFAULT_DIR"
  exit 1
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 3: Tag $LAST_TAG not checked out in $DEFAULT_DIR"
  exit 1
fi

echo "[OK] Test 3: Clone with no dir => OK"

# 4. Test sans aucun argument (doit cloner le dernier tag dans osmosis)
rm -rf "$DEFAULT_DIR"
"$CLONE_SH"
if [ ! -d "$DEFAULT_DIR/.git" ]; then
  echo "[ERROR] Test 4: Repo not cloned in $DEFAULT_DIR"
  exit 1
fi
if ! (cd "$DEFAULT_DIR" && git describe --tags | grep "$LAST_TAG" > /dev/null); then
  echo "[ERROR] Test 4: Last tag $LAST_TAG not checked out in $DEFAULT_DIR"
  exit 1
fi

echo "[OK] Test 4: Clone with no args => OK"

# 5. Test avec un tag inexistant (doit échouer)
INVALID_TAG="v0.0.0-THIS-TAG-DOES-NOT-EXIST"
if "$CLONE_SH" "$INVALID_TAG" "$ROOT_DIR/should_not_exist" 2>err.log; then
  echo "[ERROR] Test 5: Script did not fail with invalid tag"
  exit 1
fi
if ! grep -q "does not exist in Osmosis repo." err.log; then
  echo "[ERROR] Test 5: Error message not found for invalid tag"
  exit 1
fi
rm -f err.log

echo "[OK] Test 5: Invalid tag is properly rejected => OK"

echo "[ALL TESTS PASSED]" 