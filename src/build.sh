#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$1"
BUILD_DIR="."
GO_VERSION_SH="$SCRIPT_DIR/retrieve_required_go_version.sh"


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
  GO_TARBALL="go$GO_VERSION.darwin-amd64.tar.gz"
  curl -sSL -o "$GO_TMP_DIR.tar.gz" "https://go.dev/dl/$GO_TARBALL"
  tar -C /tmp -xzf "$GO_TMP_DIR.tar.gz"
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
