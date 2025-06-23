#!/bin/bash

# Deletes all tags that do not match the strict format vX.X.X.X
# Usage: ./delete_non_matching_tags.sh [--dry-run]

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

echo "Searching for non-compliant tags (vX.X.X.X)..."

# Invalid local tags
INVALID_TAGS=$(git tag | grep -vE '^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

if [[ -z "$INVALID_TAGS" ]]; then
  echo "No invalid tags found."
  exit 0
fi

echo
echo "Tags to delete (local + remote if present):"
echo "$INVALID_TAGS"
echo

if $DRY_RUN; then
  echo "--dry-run active: no tags will be deleted."
else
  echo "Deleting invalid tags..."

  while read -r tag; do
    echo "Deleting local tag: $tag"
    git tag -d "$tag"

    # Check if the tag exists on the remote
    if git ls-remote --tags origin | grep -q "refs/tags/$tag$"; then
      echo "Deleting remote tag: $tag"
      git push origin ":refs/tags/$tag"
    fi
  done <<< "$INVALID_TAGS"

  echo
  echo "All invalid tags have been deleted."
fi

