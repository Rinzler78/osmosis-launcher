#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage:" >&2
  echo "  $0 [--docker] [TAG]                 # Build local (OS/ARCH courant)" >&2
  echo "  $0 [--docker] TAG GO_OS GO_ARCH     # Build cross-platform via Docker" >&2
  exit 1
}

# Default: do not force docker
FORCE_DOCKER=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--docker" ]; then
    FORCE_DOCKER=1
  else
    ARGS+=("$arg")
  fi
done

set -- "${ARGS[@]:-}"

if [ $# -eq 0 ]; then
  # Aucun paramètre : build local, tag auto
  if [ $FORCE_DOCKER -eq 1 ]; then
    bash "$SCRIPT_DIR/src/docker_make.sh"
  else
    bash "$SCRIPT_DIR/src/make.sh"
  fi
elif [ $# -eq 1 ]; then
  # Un tag : build local
  TAG="$1"
  if [ $FORCE_DOCKER -eq 1 ]; then
    bash "$SCRIPT_DIR/src/docker_make.sh" "" "" "$TAG"
  else
    bash "$SCRIPT_DIR/src/make.sh" "$TAG"
  fi
elif [ $# -eq 3 ]; then
  # Cross-platform
  TAG="$1"
  GO_OS="$2"
  GO_ARCH="$3"
  bash "$SCRIPT_DIR/src/docker_make.sh" "$GO_OS" "$GO_ARCH" "$TAG"
else
  usage
fi 