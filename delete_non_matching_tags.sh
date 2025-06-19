#!/bin/bash

# Supprime tous les tags qui ne correspondent pas au format strict vX.X.X.X
# Usage : ./delete_non_matching_tags.sh [--dry-run]

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

echo " Recherche des tags non conformes ( vX.X.X.X)..."

# Tags locaux invalides
INVALID_TAGS=$(git tag | grep -vE '^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')

if [[ -z "$INVALID_TAGS" ]]; then
  echo " Aucun tag invalide trouv."
  exit 0
fi

echo
echo " Tags  supprimer (local + remote si prsent) :"
echo "$INVALID_TAGS"
echo

if $DRY_RUN; then
  echo " --dry-run actif : aucun tag ne sera supprim."
else
  echo " Suppression des tags invalides..."

  while read -r tag; do
    echo " Suppression locale : $tag"
    git tag -d "$tag"

    # Vrifie si le tag existe ct remote
    if git ls-remote --tags origin | grep -q "refs/tags/$tag$"; then
      echo " Suppression remote  : $tag"
      git push origin ":refs/tags/$tag"
    fi
  done <<< "$INVALID_TAGS"

  echo
  echo " Tous les tags invalides ont t supprims."
fi

