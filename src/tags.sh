#!/bin/bash
# Displays the list of available tags (versions) from the Osmosis repo
REPO_URL=$(cat "$(dirname "$0")/repo_url.txt")
git ls-remote --tags --refs "$REPO_URL" | awk -F/ '{print $NF}' | sort -V 