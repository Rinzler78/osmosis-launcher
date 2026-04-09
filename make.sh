#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BUILD_SCRIPT="${LOCAL_BUILD_SCRIPT:-$SCRIPT_DIR/src/make.sh}"
DOCKER_BUILD_SCRIPT="${DOCKER_BUILD_SCRIPT:-$SCRIPT_DIR/src/docker_make.sh}"
DOCKER_COMMAND="${DOCKER_COMMAND:-docker}"

usage() {
  cat >&2 <<'EOF'
Usage:
  ./make.sh [--docker|--local] [--tag <tag>] [--os <os>] [--arch <arch>] [--target-dir <dir>]

Compatibility positional forms:
  ./make.sh [--docker|--local] [TAG]
  ./make.sh [--docker|--local] TAG GO_OS GO_ARCH [TARGET_DIR]

Notes:
  - Named arguments are the canonical interface.
  - Auto mode uses Docker when available, otherwise the local build workflow.
  - Use --docker to require Docker or --local to force the local workflow.
EOF
  exit 1
}

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

docker_available() {
  if [[ "$DOCKER_COMMAND" == */* ]]; then
    [[ -x "$DOCKER_COMMAND" ]]
  else
    command -v "$DOCKER_COMMAND" >/dev/null 2>&1
  fi
}

MODE="auto"
USED_NAMED_ARGS=0
POSITIONAL_ARGS=()
PASSTHROUGH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker)
      [[ "$MODE" = "local" ]] && fail "--docker and --local cannot be used together."
      MODE="docker"
      shift
      ;;
    --local)
      [[ "$MODE" = "docker" ]] && fail "--docker and --local cannot be used together."
      MODE="local"
      shift
      ;;
    --tag|--os|--arch|--target-dir)
      [[ $# -lt 2 ]] && fail "Option '$1' requires a value."
      [[ "$2" == --* ]] && fail "Option '$1' requires a value."
      USED_NAMED_ARGS=1
      PASSTHROUGH_ARGS+=("$1" "$2")
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    --*)
      fail "Unknown option: $1"
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ $USED_NAMED_ARGS -eq 1 && ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  fail "Do not mix named arguments with positional compatibility arguments."
fi

if [[ $USED_NAMED_ARGS -eq 0 ]]; then
  case ${#POSITIONAL_ARGS[@]} in
    0)
      ;;
    1)
      PASSTHROUGH_ARGS+=("--tag" "${POSITIONAL_ARGS[0]}")
      ;;
    3)
      PASSTHROUGH_ARGS+=(
        "--tag" "${POSITIONAL_ARGS[0]}"
        "--os" "${POSITIONAL_ARGS[1]}"
        "--arch" "${POSITIONAL_ARGS[2]}"
      )
      ;;
    4)
      PASSTHROUGH_ARGS+=(
        "--tag" "${POSITIONAL_ARGS[0]}"
        "--os" "${POSITIONAL_ARGS[1]}"
        "--arch" "${POSITIONAL_ARGS[2]}"
        "--target-dir" "${POSITIONAL_ARGS[3]}"
      )
      ;;
    *)
      usage
      ;;
  esac
fi

SELECTED_SCRIPT="$LOCAL_BUILD_SCRIPT"
if [[ "$MODE" = "docker" ]]; then
  docker_available || fail "Docker was explicitly requested but is not available."
  SELECTED_SCRIPT="$DOCKER_BUILD_SCRIPT"
elif [[ "$MODE" = "auto" ]] && docker_available; then
  SELECTED_SCRIPT="$DOCKER_BUILD_SCRIPT"
fi

echo "[INFO] Delegating root build to $(basename "$SELECTED_SCRIPT")"
exec bash "$SELECTED_SCRIPT" "${PASSTHROUGH_ARGS[@]}"
