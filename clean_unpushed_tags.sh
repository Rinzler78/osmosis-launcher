#!/bin/bash
set -e

echo "Cleaning up local tags not present on origin..."

# List of local tags
LOCAL_TAGS=$(git tag)

# List of tags present on origin
REMOTE_TAGS=$(git ls-remote --tags origin | awk '{print $2}' | sed 's#refs/tags/##' | sort -u)

# Delete local tags not present on origin
TAGS_TO_DELETE=$(comm -23 <(echo "$LOCAL_TAGS" | sort) <(echo "$REMOTE_TAGS" | sort))

if [[ -z "$TAGS_TO_DELETE" ]]; then
  echo "All local tags are synchronized with origin."
else
  echo "Deleting the following tags not present on origin:"
  echo "$TAGS_TO_DELETE"
  echo

  for tag in $TAGS_TO_DELETE; do
    git tag -d "$tag"
  done

  echo "Cleanup finished."
fi

