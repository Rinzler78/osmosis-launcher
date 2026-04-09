#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMAT_TITLE_SH="$SCRIPT_DIR/../src/format_title.sh"

echo_title() {
  bash "$FORMAT_TITLE_SH" "$(basename "$0")"
}

trap echo_title EXIT

echo_title

echo "[INFO] Test retrieving last tag"

LAST_TAG_OUTPUT=$(bash "$SCRIPT_DIR/../src/last_tag.sh")
TAGS_OUTPUT=$(bash "$SCRIPT_DIR/../src/tags.sh")

# Get the last stable tag (filtering out pre-releases like last_tag.sh does)
LAST_STABLE_TAG=$(echo "$TAGS_OUTPUT" | grep -v -E -- '-(rc|alpha|beta|test|mempool)' | tail -n 1)

# Check that last_tag.sh output is not empty
if [ -z "$LAST_TAG_OUTPUT" ]; then
  fail "last_tag.sh returned no tag."
fi

# Check that the tag exists in the list of all tags
if ! echo "$TAGS_OUTPUT" | grep -Fxq "$LAST_TAG_OUTPUT"; then
  fail "Tag '$LAST_TAG_OUTPUT' from last_tag.sh not found in tags list."
fi

# Check that last_tag.sh returns a stable version (no pre-release suffixes)
if echo "$LAST_TAG_OUTPUT" | grep -qE -- '-(rc|alpha|beta|test|mempool)'; then
  fail "last_tag.sh returned a pre-release tag: $LAST_TAG_OUTPUT"
fi

# Check that last_tag.sh returns the last stable tag
if [ "$LAST_TAG_OUTPUT" = "$LAST_STABLE_TAG" ]; then
  pass "last_tag.sh correctly returns the last stable tag: $LAST_TAG_OUTPUT"
else
  fail "last_tag.sh='$LAST_TAG_OUTPUT' does not match last stable tag='$LAST_STABLE_TAG'"
fi 
