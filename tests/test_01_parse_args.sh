#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARSE_ARGS_SH="$SCRIPT_DIR/../src/parse_args.sh"
LAST_TAG_SH="$SCRIPT_DIR/../src/last_tag.sh"
RESOLVE_OS_SH="$SCRIPT_DIR/../src/resolve_os.sh"
RESOLVE_ARCH_SH="$SCRIPT_DIR/../src/resolve_arch.sh"

TAG="vTEST"
GO_OS="linux"
GO_ARCH="amd64"
TARGET_DIR="mydir"
# shellcheck source=../src/parse_args.sh
source "$PARSE_ARGS_SH" --tag "$TAG" --os "$GO_OS" --arch "$GO_ARCH" --target-dir "$TARGET_DIR"
if [ "$TAG" = "vTEST" ] && [ "$GO_OS" = "linux" ] && [ "$GO_ARCH" = "amd64" ] && [ "$TARGET_DIR" = "mydir" ]; then
  pass "All named parameters parsed correctly"
else
  fail "Named parameters parsing failed"
fi

unset TAG GO_OS GO_ARCH TARGET_DIR
source "$PARSE_ARGS_SH" --arch "arm64" --target-dir "foo" --os "darwin" --tag "vRANDOM"
if [ "$TAG" = "vRANDOM" ] && [ "$GO_OS" = "darwin" ] && [ "$GO_ARCH" = "arm64" ] && [ "$TARGET_DIR" = "foo" ]; then
  pass "Order of named parameters does not matter"
else
  fail "Order of named parameters failed"
fi

unset TAG GO_OS GO_ARCH TARGET_DIR
source "$PARSE_ARGS_SH"
EXPECTED_TAG="$($LAST_TAG_SH)"
EXPECTED_OS="$($RESOLVE_OS_SH "$(uname -s)")"
EXPECTED_ARCH="$($RESOLVE_ARCH_SH "$(uname -m)")"
if [ "$TAG" = "$EXPECTED_TAG" ] && [ "$GO_OS" = "$EXPECTED_OS" ] && [ "$GO_ARCH" = "$EXPECTED_ARCH" ] && [ "$TARGET_DIR" = "osmosis" ]; then
  pass "Default values are set dynamically when not provided"
else
  fail "Default values are not set correctly"
fi

if bash -lc "source '$PARSE_ARGS_SH' --unknown-option" 2>"$SCRIPT_DIR/.parse_args.err"; then
  fail "Unknown options must fail"
fi
if grep -Fq "Unknown option: --unknown-option" "$SCRIPT_DIR/.parse_args.err"; then
  pass "Unknown options fail fast with an actionable error"
else
  fail "Unknown option error output is missing"
fi
rm -f "$SCRIPT_DIR/.parse_args.err"

if bash -lc "source '$PARSE_ARGS_SH' --tag" 2>"$SCRIPT_DIR/.parse_args.err"; then
  fail "Missing option values must fail"
fi
if grep -Fq "Option '--tag' requires a value." "$SCRIPT_DIR/.parse_args.err"; then
  pass "Missing option values fail fast"
else
  fail "Missing-value error output is missing"
fi
rm -f "$SCRIPT_DIR/.parse_args.err"

pass "parse_args.sh tests passed."
