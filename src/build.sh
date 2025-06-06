#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$1"
BUILD_DIR="."
GO_VERSION_SH="$SCRIPT_DIR/retrieve_required_go_version.sh"

# Detect OS and architecture for Go download
UNAME_OS="$(uname -s)"
UNAME_ARCH="$(uname -m)"

case "$UNAME_OS" in
  Linux)
    GO_OS="linux"
    ;;
  Darwin)
    GO_OS="darwin"
    ;;
  *)
    echo "[FAIL] Unsupported OS: $UNAME_OS"
    exit 1
    ;;
esac

case "$UNAME_ARCH" in
  x86_64|amd64)
    GO_ARCH="amd64"
    ;;
  arm64|aarch64)
    GO_ARCH="arm64"
    ;;
  *)
    echo "[FAIL] Unsupported architecture: $UNAME_ARCH"
    exit 1
    ;;
esac

# Sauvegarder l'environnement initial
OLD_PATH="$PATH"
OLD_GOROOT="$GOROOT"

# Détecter la version de Go requise
GO_VERSION=$($GO_VERSION_SH "$TARGET_DIR")
if [ -z "$GO_VERSION" ]; then
  echo "[FAIL] Impossible de déterminer la version de Go pour le dossier $TARGET_DIR."
  exit 1
fi

# Vérifier la version de Go installée
if command -v go >/dev/null 2>&1; then
  INSTALLED_GO=$(go version | awk '{print $3}' | sed 's/go//')
else
  INSTALLED_GO=""
fi

# Installer Go si nécessaire
if [[ "$INSTALLED_GO" != "$GO_VERSION"* ]]; then
  echo "[INFO] Installation de Go $GO_VERSION ..."
  GO_TMP_DIR="/tmp/go-$GO_VERSION-$$"
  # Télécharger l'archive via le script dédié
  GO_TARBALL_PATH=$("$SCRIPT_DIR/download_go_archive.sh" "$GO_VERSION" "$GO_OS" "$GO_ARCH" | tail -n1)
  tar -C /tmp -xzf "$GO_TARBALL_PATH"
  mv /tmp/go "$GO_TMP_DIR"
  export GOROOT="$GO_TMP_DIR"
  export PATH="$GO_TMP_DIR/bin:$PATH"
  GO_INSTALLED_BEFORE=1
fi

# Trap pour supprimer Go si installé par le script
cleanup() {
  if [ "$GO_INSTALLED_BEFORE" = "1" ]; then
    echo "[CLEANUP] Suppression de Go temporaire."
    rm -rf "$GO_TMP_DIR" "$GO_TMP_DIR.tar.gz"
    export PATH="$OLD_PATH"
    export GOROOT="$OLD_GOROOT"
  fi
}
trap cleanup EXIT

# Compiler le binaire pour la plateforme courante
pushd "$TARGET_DIR"
echo "[INFO] Compilation du binaire osmosisd pour $(go env GOOS)/$(go env GOARCH) ..."
make build
popd

# Copier le binaire dans le dossier cible
cp "$TARGET_DIR/build/osmosisd" $BUILD_DIR
