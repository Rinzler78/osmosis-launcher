#!/bin/bash

# Teste le script tags.sh pour s'assurer qu'il retourne des tags valides du repo Osmosis

OUTPUT=$(bash src/tags.sh)

# Vérifie qu'il y a au moins une ligne dans la sortie
if [ -z "$OUTPUT" ]; then
  echo "[FAIL] No tags found."
  exit 1
fi

# Vérifie que la première ligne ressemble à un tag de version (ex: 1.2.3 ou v1.2.3)
FIRST_TAG=$(echo "$OUTPUT" | head -n 1)
if [[ "$FIRST_TAG" =~ ^v?[0-9]+(\.[0-9]+)*$ ]]; then
  echo "[OK] Found tag: $FIRST_TAG"
  exit 0
else
  echo "[FAIL] Invalid tag format: $FIRST_TAG"
  exit 1
fi 