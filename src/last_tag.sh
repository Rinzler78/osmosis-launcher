#!/bin/bash
# Print the latest tag (version) available from the Osmosis repo
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/tags.sh" | tail -n 1 