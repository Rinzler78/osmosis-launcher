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

# Build l'image de base (si elle n'existe pas déjà)
docker build -f src/Dockerfile -t "$IMAGE_TAG" .

# Prépare le dossier de sortie
mkdir -p ./buildx-out/build/

# Vérifie si le conteneur existe déjà
if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
  # Si le conteneur est en cours d'exécution, on le stoppe d'abord
  if docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
    echo "[INFO] Le conteneur $CONTAINER_NAME est en cours d'exécution. Arrêt..."
    docker kill "$CONTAINER_NAME"
  fi
  echo "[INFO] Suppression du conteneur $CONTAINER_NAME."
  docker rm -f "$CONTAINER_NAME"
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

# Lance le build cross-platform dans un conteneur nommé explicitement, sans --rm et sans volume disque
if [ "$USE_TMPFS" -eq 1 ]; then
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    -e GOOS="$GO_OS" \
    -e GOARCH="$GO_ARCH" \
    --tmpfs /workspace/$TARGET_DIR:rw,size=10g \
    "$IMAGE_TAG" \
    bash -c "make.sh --os '$GO_OS' --arch '$GO_ARCH' --target-dir '$TARGET_DIR'")
else
  CONTAINER_ID=$(docker run -d \
    --name "$CONTAINER_NAME" \
    -e GOOS="$GO_OS" \
    -e GOARCH="$GO_ARCH" \
    "$IMAGE_TAG" \
    bash -c "make.sh --os '$GO_OS' --arch '$GO_ARCH' --target-dir '$TARGET_DIR'")
fi

# Attendre la fin du build
if ! docker wait "$CONTAINER_ID" > /dev/null; then
  echo "[FAIL] Build failed in container. Voir les logs avec : docker logs $CONTAINER_ID"
  exit 1
fi

# DEBUG : Affiche le contenu des dossiers et les logs du build avant la copie
echo "[DEBUG] Contenu de /workspace :"
docker exec "$CONTAINER_ID" ls -l /workspace || true
echo "[DEBUG] Contenu de /workspace/build :"
docker exec "$CONTAINER_ID" ls -l /workspace/build || true
echo "[DEBUG] Log du build :"
docker logs "$CONTAINER_ID"

# Copier le binaire depuis le conteneur
if docker cp "$CONTAINER_ID":/workspace/build/osmosisd ./buildx-out/build/ 2>/dev/null; then
  echo "[OK] Binaire copié depuis le conteneur."
else
  echo "[FAIL] Impossible de copier le binaire depuis le conteneur."
  exit 1
fi

# Nettoyer le conteneur
docker rm "$CONTAINER_ID" > /dev/null

echo "[OK] Build terminé pour $PLATFORM. Binaire(s) dans ./buildx-out/build/"
