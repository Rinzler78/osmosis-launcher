#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp/patch-tests"
PATCH_SH="$SCRIPT_DIR/../src/patch.sh"

cleanup() {
  rm -rf "$ROOT_DIR"
}

make_tree() {
  local target_dir="$1"
  local main_body="$2"

  mkdir -p "$target_dir/cmd/osmosisd"
  printf '%s\n' "$main_body" > "$target_dir/cmd/osmosisd/main.go"
}

trap cleanup EXIT
cleanup
mkdir -p "$ROOT_DIR"

SUCCESS_DIR="$ROOT_DIR/success"
make_tree "$SUCCESS_DIR" 'package main

func main() {
	rootCmd := cmd.NewRootCmd()
	_ = rootCmd
}'

bash "$PATCH_SH" --target-dir "$SUCCESS_DIR" >/dev/null
if [ -f "$SUCCESS_DIR/cmd/osmosisd/launcher.go" ]; then
  pass "patch.sh copies launcher.go into the Osmosis tree"
else
  fail "patch.sh did not copy launcher.go"
fi

if grep -Fq 'wait_for_launcher()' "$SUCCESS_DIR/cmd/osmosisd/main.go"; then
  pass "patch.sh injects wait_for_launcher()"
else
  fail "patch.sh did not inject wait_for_launcher()"
fi

bash "$PATCH_SH" --target-dir "$SUCCESS_DIR" >/dev/null
WAIT_CALL_COUNT="$(grep -Fc 'wait_for_launcher()' "$SUCCESS_DIR/cmd/osmosisd/main.go")"
if [ "$WAIT_CALL_COUNT" = "1" ]; then
  pass "patch.sh is idempotent"
else
  fail "patch.sh duplicated the launcher injection"
fi

MISSING_INJECTION_DIR="$ROOT_DIR/missing-injection"
make_tree "$MISSING_INJECTION_DIR" 'package main

func main() {
	println("no injection point here")
}'

if bash "$PATCH_SH" --target-dir "$MISSING_INJECTION_DIR" >"$ROOT_DIR/missing.out" 2>&1; then
  fail "patch.sh must fail when the injection point is missing"
fi
if grep -Fq "Injection point 'cmd.NewRootCmd()' was not found" "$ROOT_DIR/missing.out"; then
  pass "patch.sh reports a missing injection point"
else
  fail "patch.sh did not explain the missing injection point"
fi

SPACED_DIR="$ROOT_DIR/dir with spaces"
make_tree "$SPACED_DIR" 'package main

func main() {
	rootCmd := cmd.NewRootCmd()
	_ = rootCmd
}'

bash "$PATCH_SH" --target-dir "$SPACED_DIR" >/dev/null
if grep -Fq 'wait_for_launcher()' "$SPACED_DIR/cmd/osmosisd/main.go"; then
  pass "patch.sh handles target directories containing spaces"
else
  fail "patch.sh failed for a target directory containing spaces"
fi

if bash "$PATCH_SH" --target-dir "$ROOT_DIR/does-not-exist" >"$ROOT_DIR/not-found.out" 2>&1; then
  fail "patch.sh must fail for a missing target directory"
fi
if grep -Fq "Target directory '$ROOT_DIR/does-not-exist' does not exist." "$ROOT_DIR/not-found.out"; then
  pass "patch.sh reports missing target directories clearly"
else
  fail "patch.sh missing-directory error is unclear"
fi

pass "patch.sh tests passed."
