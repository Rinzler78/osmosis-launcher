#!/bin/bash
# Affiche la liste des tags (versions) disponibles du repo Osmosis
REPO_URL=$(cat "$(dirname "$0")/repo_url.txt")
git ls-remote --tags --refs "$REPO_URL" | awk -F/ '{print $NF}' | sort -V 