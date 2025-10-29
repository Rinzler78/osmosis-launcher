#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/parse_args.sh" "$@"

PLATFORM="${GO_OS}/${GO_ARCH}"
IMAGE_TAG="osmosis-builder-base-${GO_OS}-${GO_ARCH}"
CONTAINER_NAME="osmosis-build-${GO_OS}-${GO_ARCH}"

# Vérifie que docker est disponible
if ! command -v docker >/dev/null 2>&1; then
  echo "[FAIL] Docker n'est pas disponible."
  exit 1
fi

echo "[INFO] Build cross-platform via Docker pour $PLATFORM"

# Select appropriate Dockerfile based on target OS
if [ "$GO_OS" = "darwin" ]; then
  DOCKERFILE="src/Dockerfile.darwin"
  echo "[INFO] Using goreleaser-cross image for Darwin build"
else
  DOCKERFILE="src/Dockerfile"
  echo "[INFO] Using standard Ubuntu image for Linux build"
fi

# Build l'image de base (si elle n'existe pas déjà)
docker build -f "$DOCKERFILE" -t "$IMAGE_TAG" .

# Vérifie si le conteneur existe déjà
if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  # Si le conteneur est en cours d'exécution, on le stoppe d'abord
  if docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
    echo "[INFO] Le conteneur $CONTAINER_NAME est en cours d'exécution. Arrêt..."
    docker kill "$CONTAINER_NAME" 2>/dev/null || true
  fi
  echo "[INFO] Suppression du conteneur $CONTAINER_NAME."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || echo "[WARN] Could not remove container (may already be removed)"
  # Wait a bit for the removal to complete
  sleep 2
fi

# Détection de la RAM disponible via script standardisé
MEM_AVAILABLE_GB=$(bash "$SCRIPT_DIR/get_available_ram_gb.sh")

USE_TMPFS=0
if [ "$MEM_AVAILABLE_GB" -ge 10 ]; then
  USE_TMPFS=1
  echo "[INFO] Assez de RAM disponible ($MEM_AVAILABLE_GB Go), build dans un volume RAM (tmpfs 10G)."
else
  echo "[INFO] RAM disponible insuffisante ($MEM_AVAILABLE_GB Go), build classique sur disque."
fi

# Dossier cible pour le clone et le build (déjà géré par parse_args.sh)

# For Darwin builds, we need special configuration to use static wasmvm library
DARWIN_ENV=""
if [ "$GO_OS" = "darwin" ]; then
  # Pass only the extra tag (static_wasm) to use libwasmvmstatic_darwin.a
  # Do NOT pass LINK_STATICALLY as macOS doesn't support full static linking
  DARWIN_ENV="-e BUILD_TAGS=static_wasm"
fi

# Lance le build cross-platform dans un conteneur nommé explicitement, sans --rm et sans volume disque
if [ "$USE_TMPFS" -eq 1 ]; then
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    -e GOOS="$GO_OS" \
    -e GOARCH="$GO_ARCH" \
    $DARWIN_ENV \
    --tmpfs /workspace/$TARGET_DIR:rw,size=10g \
    --entrypoint bash \
    "$IMAGE_TAG" \
    -c "make.sh --os '$GO_OS' --arch '$GO_ARCH' --target-dir '$TARGET_DIR'")
else
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    -e GOOS="$GO_OS" \
    -e GOARCH="$GO_ARCH" \
    $DARWIN_ENV \
    --entrypoint bash \
    "$IMAGE_TAG" \
    -c "make.sh --os '$GO_OS' --arch '$GO_ARCH' --target-dir '$TARGET_DIR'")
fi

# Attendre la fin du build
EXIT_CODE=$(docker wait "$CONTAINER_ID")
if [ "$EXIT_CODE" != "0" ]; then
  echo "[FAIL] Build failed in container with exit code $EXIT_CODE"
  echo "[DEBUG] Container logs:"
  docker logs "$CONTAINER_ID"
  docker rm "$CONTAINER_ID" > /dev/null 2>&1
  exit 1
fi

echo "[DEBUG] Build completed successfully. Container logs:"
docker logs "$CONTAINER_ID" | tail -20

# Copier le binaire depuis le conteneur vers le répertoire courant
if docker cp "$CONTAINER_ID":/workspace/osmosisd . 2>/dev/null; then
  echo "[OK] Binaire copié depuis le conteneur vers le répertoire courant."
else
  echo "[FAIL] Impossible de copier le binaire depuis le conteneur."
  exit 1
fi

# Nettoyer le conteneur
docker rm "$CONTAINER_ID" > /dev/null

echo "[OK] Build terminé pour $PLATFORM. Binaire: ./osmosisd"
