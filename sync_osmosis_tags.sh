k#!/bin/bash
set -e

REPO_URL="https://github.com/osmosis-labs/osmosis.git"
DRY_RUN=false
PUSH_TAGS=true

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      ;;
    --no-push)
      PUSH_TAGS=false
      ;;
    *)
      echo " Usage : $0 [--dry-run] [--no-push]"
      exit 1
      ;;
  esac
done

echo " Recherche des tags osmosis au format strict vX.X.X..."

# 1) Rcuprer tous les tags vX.X.X de osmosis (tag sha)
OSMOSIS_TAGS=$(git ls-remote --tags "$REPO_URL" \
  | grep -v '\^{}' \
  | grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' \
  | awk '{ sub("refs/tags/", "", $2); print $2 " " $1 }' \
  | sort -u)

# 2) Rcuprer tous les tags locaux
LOCAL_TAGS=$(git tag)

NEW_TAGS=0

# 3) Pour chaque tag osmosis vX.X.X
while read -r tag sha; do
  if [[ -z "$tag" || -z "$sha" ]]; then
    continue
  fi

  # 4) Skip sil est dj en local
  if echo "$LOCAL_TAGS" | grep -qx "$tag"; then
    echo " $tag dj prsent localement"
    continue
  fi

  echo " Nouveau tag manquant localement : $tag ($sha)"

  if [ "$DRY_RUN" = true ]; then
    echo " [dry-run] git fetch $REPO_URL $sha"
    echo " [dry-run] git tag $tag $sha"
    [ "$PUSH_TAGS" = true ] && echo " [dry-run] git push origin $tag"
  else
    git fetch --quiet "$REPO_URL" "$sha"
    git tag "$tag" "$sha"
    if [ "$PUSH_TAGS" = true ]; then
      git push origin "$tag"
      echo " $tag cr et pouss"
    else
      echo " $tag cr localement (--no-push)"
    fi
  fi

  ((NEW_TAGS++))
done <<< "$OSMOSIS_TAGS"

# Rsum
if [[ $NEW_TAGS -eq 0 ]]; then
  echo " Aucun nouveau tag  synchroniser."
else
  if [ "$DRY_RUN" = true ]; then
    echo " [dry-run] $NEW_TAGS tag(s) seraient synchroniss."
  elif [ "$PUSH_TAGS" = false ]; then
    echo " $NEW_TAGS tag(s) crs localement (--no-push)"
  else
    echo " $NEW_TAGS tag(s) synchronis(s) avec succs."
  fi
fi

