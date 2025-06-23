#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TAG="${1-}"

if docker info >/dev/null 2>&1; then
  echo "[INFO] Docker is available and running. Running docker_make.sh"
  bash "$SCRIPT_DIR/src/docker_make.sh" "$TAG"
else
  echo "[INFO] Docker is not available or not running. Running local make.sh"
  bash "$SCRIPT_DIR/src/make.sh" "$TAG"
fi 