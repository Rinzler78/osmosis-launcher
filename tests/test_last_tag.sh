#!/bin/bash

# Teste le script last_tag.sh pour s'assurer qu'il retourne le dernier tag valide du repo Osmosis

OUTPUT=$(bash src/last_tag.sh)

# Vérifie que la sortie n'est pas vide
if [ -z "$OUTPUT" ]; then
  echo "[FAIL] No tag found."
  exit 1
fi

# Vérifie que la sortie ressemble à un tag de version (ex: 1.2.3 ou v1.2.3)
if [[ "$OUTPUT" =~ ^v?[0-9]+(\.[0-9]+)*$ ]]; then
  echo "[OK] Found last tag: $OUTPUT"
  exit 0
else
  echo "[FAIL] Invalid tag format: $OUTPUT"
  exit 1
fi 