#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/parse_args.sh" "$@"

LAUNCHER_GO_SRC="$SCRIPT_DIR/launcher.go"
MAIN_FILE_PATH="$TARGET_DIR/cmd/osmosisd/main.go"
TARGET_LAUNCHER_GO_FILE="$TARGET_DIR/cmd/osmosisd/launcher.go"
ROOT_CMD_LINE="cmd.NewRootCmd()"
WAIT_FOR_LAUNCHER_CALL="wait_for_launcher()"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "[FAIL] Target directory '$TARGET_DIR' does not exist." >&2
  exit 1
fi

if [[ ! -f "$MAIN_FILE_PATH" ]]; then
  echo "[FAIL] '$MAIN_FILE_PATH' does not exist." >&2
  exit 1
fi

cp "$LAUNCHER_GO_SRC" "$TARGET_LAUNCHER_GO_FILE"

if grep -Fq "$WAIT_FOR_LAUNCHER_CALL" "$MAIN_FILE_PATH"; then
  echo "[INFO] Launcher injection already present in '$MAIN_FILE_PATH'."
else
  if ! grep -Fq "$ROOT_CMD_LINE" "$MAIN_FILE_PATH"; then
    echo "[FAIL] Injection point '$ROOT_CMD_LINE' was not found in '$MAIN_FILE_PATH'." >&2
    exit 1
  fi

  TEMP_FILE="$(mktemp)"
  if ! awk -v root_call="$ROOT_CMD_LINE" -v wait_call="$WAIT_FOR_LAUNCHER_CALL" '
    index($0, root_call) && !done {
      print $0
      print "\t" wait_call
      done = 1
      next
    }
    { print $0 }
    END {
      if (!done) {
        exit 42
      }
    }
  ' "$MAIN_FILE_PATH" > "$TEMP_FILE"; then
    rm -f "$TEMP_FILE"
    echo "[FAIL] Failed to inject launcher call into '$MAIN_FILE_PATH'." >&2
    exit 1
  fi

  mv "$TEMP_FILE" "$MAIN_FILE_PATH"
fi

if ! grep -Fq "$WAIT_FOR_LAUNCHER_CALL" "$MAIN_FILE_PATH"; then
  echo "[FAIL] Launcher injection verification failed for '$MAIN_FILE_PATH'." >&2
  exit 1
fi

echo "[OK] Launcher patch applied successfully in '$TARGET_DIR'."
