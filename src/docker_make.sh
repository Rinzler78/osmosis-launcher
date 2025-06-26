#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Usage: docker_make.sh <GOOS> <GOARCH>
if [ -z "${1-}" ]; then
  GO_OS=$("$SCRIPT_DIR/resolve_os.sh" "$(uname -s)")
else
  GO_OS="$1"
fi
if [ -z "${2-}" ]; then
  GO_ARCH=$("$SCRIPT_DIR/resolve_arch.sh" "$(uname -m)")
else
  GO_ARCH="$2"
fi
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

# Vérifie si le conteneur existe déjà
if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  echo "[INFO] Le conteneur $CONTAINER_NAME existe déjà. Utilisation de ce conteneur."
  docker start "$CONTAINER_NAME"
  docker exec -it "$CONTAINER_NAME" bash src/make.sh "" "$GO_OS" "$GO_ARCH"
else
  # Lance le build cross-platform dans un conteneur nommé explicitement, sans --rm
  docker run -it \
    --name "$CONTAINER_NAME" \
    -e GOOS="$GO_OS" \
    -e GOARCH="$GO_ARCH" \
    -v "$PWD/buildx-out/build:/workspace/build" \
    "$IMAGE_TAG" \
    bash src/make.sh "" "$GO_OS" "$GO_ARCH"
fi

echo "[OK] Build terminé pour $PLATFORM. Binaire(s) dans ./buildx-out/build/"
