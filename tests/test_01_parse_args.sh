#!/bin/bash

. "$(dirname "$0")/utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_ARGS_SH="$SCRIPT_DIR/../src/parse_args.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
RESOLVE_OS_SH="$SCRIPT_DIR/../src/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/../src/resolve_arch.sh"

# Test 1: Tous les paramètres nommés
TAG="vTEST"
GO_OS="linux"
GO_ARCH="amd64"
TARGET_DIR="mydir"
source "$PARSE_ARGS_SH" --tag "$TAG" --os "$GO_OS" --arch "$GO_ARCH" --target-dir "$TARGET_DIR"
[ "$TAG" = "vTEST" ] && [ "$GO_OS" = "linux" ] && [ "$GO_ARCH" = "amd64" ] && [ "$TARGET_DIR" = "mydir" ] \
  && pass "All named parameters parsed correctly" \
  || fail "Named parameters parsing failed"

# Test 2: Ordre aléatoire
unset TAG GO_OS GO_ARCH TARGET_DIR
source "$PARSE_ARGS_SH" --arch "arm64" --target-dir "foo" --os "darwin" --tag "vRANDOM"
[ "$TAG" = "vRANDOM" ] && [ "$GO_OS" = "darwin" ] && [ "$GO_ARCH" = "arm64" ] && [ "$TARGET_DIR" = "foo" ] \
  && pass "Order of named parameters does not matter" \
  || fail "Order of named parameters failed"

# Test 3: Valeurs par défaut dynamiques
unset TAG GO_OS GO_ARCH TARGET_DIR
source "$PARSE_ARGS_SH"
EXPECTED_TAG=$($LAST_TAG_SH)
EXPECTED_OS=$($RESOLVE_OS_SH "$(uname -s)")
EXPECTED_ARCH=$($RESOLVE_ARCH_SH "$(uname -m)")
[ "$TAG" = "$EXPECTED_TAG" ] && [ "$GO_OS" = "$EXPECTED_OS" ] && [ "$GO_ARCH" = "$EXPECTED_ARCH" ] && [ "$TARGET_DIR" = "osmosis" ] \
  && pass "Default values are set dynamically when not provided" \
  || fail "Default values are not set correctly"

pass "parse_args.sh tests passed." 