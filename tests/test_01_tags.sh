#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

trap echo_title EXIT

echo_title

echo "[INFO] Test retrieving tags"

OUTPUT=$(bash $SCRIPT_DIR/../src/tags.sh)

# Check that there is at least one line in the output
if [ -z "$OUTPUT" ]; then
  echo "[FAIL] No tags found."
  exit 1
else
  TAG_COUNT=$(echo "$OUTPUT" | wc -l | tr -d ' ')
  echo "[INFO] Number of tags: $TAG_COUNT"
  echo "[INFO] Found tags:"
  echo "$OUTPUT"
  echo "[INFO] Test OK"
  exit 0
fi 