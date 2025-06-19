#!/bin/bash
set -e

echo " Nettoyage des tags locaux non prsents sur origin..."

# Liste des tags locaux
LOCAL_TAGS=$(git tag)

# Liste des tags prsents sur origin
REMOTE_TAGS=$(git ls-remote --tags origin | awk '{print $2}' | sed 's#refs/tags/##' | sort -u)

# Supprimer les tags locaux absents de origin
TAGS_TO_DELETE=$(comm -23 <(echo "$LOCAL_TAGS" | sort) <(echo "$REMOTE_TAGS" | sort))

if [[ -z "$TAGS_TO_DELETE" ]]; then
  echo " Tous les tags locaux sont synchroniss avec origin."
else
  echo " Suppression des tags suivants non prsents sur origin :"
  echo "$TAGS_TO_DELETE"
  echo

  for tag in $TAGS_TO_DELETE; do
    git tag -d "$tag"
  done

  echo " Nettoyage termin."
fi

