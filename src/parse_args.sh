#!/bin/bash
# Usage: source parse_args.sh "$@"
# Exporte : TAG, GO_OS, GO_ARCH, TARGET_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parsing des arguments nommés
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      TAG="$2"
      shift 2
      ;;
    --os)
      GO_OS="$2"
      shift 2
      ;;
    --arch)
      GO_ARCH="$2"
      shift 2
      ;;
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="osmosis"
fi

# Valeur par défaut pour TAG (dynamique)
if [ -z "$TAG" ]; then
  TAG="$($SCRIPT_DIR/last_tag.sh)"
fi

# Valeur par défaut pour GO_OS et GO_ARCH (dynamique)
if [ -z "$GO_OS" ]; then
  GO_OS="$($SCRIPT_DIR/resolve_os.sh "$(uname -s)")"
fi
if [ -z "$GO_ARCH" ]; then
  GO_ARCH="$($SCRIPT_DIR/resolve_arch.sh "$(uname -m)")"
fi

export TAG GO_OS GO_ARCH TARGET_DIR 