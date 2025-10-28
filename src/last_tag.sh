#!/bin/bash
# Print the latest tag (version) available from the Osmosis repo
# Excludes pre-release tags (rc, alpha, beta, etc.)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/tags.sh" | grep -v -E -- '-(rc|alpha|beta|test|mempool)' | tail -n 1 