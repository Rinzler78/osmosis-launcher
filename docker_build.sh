#!/bin/bash
# Build osmosisd inside a Docker container matching the host architecture
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"

docker build --platform="$ARCH" -t osmosis-launcher-build "$SCRIPT_DIR"
# Build inside the container and copy the resulting binary back to the host
docker run --rm -v "$PWD":/output osmosis-launcher-build \
  bash -c "cd /workspace && src/build.sh osmosis && cp osmosisd /output/"

echo "[OK] osmosisd built in $(pwd)/osmosisd"
