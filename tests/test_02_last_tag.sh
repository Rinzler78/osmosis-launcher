#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash $FORMAT_TITLE_SH "$(basename "$0")"
}

trap echo_title EXIT

echo_title

echo "[INFO] Test retrieving last tag"

LAST_TAG_OUTPUT=$(bash $SCRIPT_DIR/../src/last_tag.sh)
TAGS_OUTPUT=$(bash $SCRIPT_DIR/../src/tags.sh)
LAST_TAG_FROM_TAGS=$(echo "$TAGS_OUTPUT" | tail -n 1)

# Check that both outputs are not empty
if [ -z "$LAST_TAG_OUTPUT" ] || [ -z "$LAST_TAG_FROM_TAGS" ]; then
  echo "[FAIL] No tag found."
  exit 1
fi

# Check that both outputs are identical
if [ "$LAST_TAG_OUTPUT" = "$LAST_TAG_FROM_TAGS" ]; then
  echo "[OK] last_tag.sh and tags.sh outputs match: $LAST_TAG_OUTPUT"
  exit 0
else
  echo "[FAIL] Outputs do not match: last_tag.sh='$LAST_TAG_OUTPUT', tags.sh='$LAST_TAG_FROM_TAGS'"
  exit 1
fi 