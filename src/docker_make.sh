#!/bin/bash
set -e

# Usage: docker_make.sh <GOOS> <GOARCH>
GO_OS=${1:-linux}
GO_ARCH=${2:-amd64}
PLATFORM="${GO_OS}/${GO_ARCH}"
IMAGE_TAG="osmosis-builder-base-${GO_OS}-${GO_ARCH}"
CONTAINER_NAME="osmosis-build-${GO_OS}-${GO_ARCH}"

# Vérifie que docker est disponible
if ! command -v docker >/dev/null 2>&1; then
  echo "[FAIL] Docker n'est pas disponible."
  exit 1
fi

echo "[INFO] Build cross-platform via Docker pour $PLATFORM"

# Build l'image de base (si elle n'existe pas déjà)
docker build -f src/Dockerfile -t "$IMAGE_TAG" .

# Prépare le dossier de sortie
mkdir -p ./buildx-out/build/

# Lance le build cross-platform dans un conteneur nommé explicitement, sans --rm
docker run -it \
  --name "$CONTAINER_NAME" \
  -e GOOS="$GO_OS" \
  -e GOARCH="$GO_ARCH" \
  -v "$PWD/buildx-out/build:/workspace/build" \
  "$IMAGE_TAG" \
  bash src/make.sh "" "$GO_OS" "$GO_ARCH"

echo "[OK] Build terminé pour $PLATFORM. Binaire(s) dans ./buildx-out/build/"
