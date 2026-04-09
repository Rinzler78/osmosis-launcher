#!/bin/bash
# Usage: source parse_args.sh "$@"
# Exports: TAG, GO_OS, GO_ARCH, TARGET_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

parse_args_fail() {
  echo "[ERROR] $1" >&2
  return 1
}

require_option_value() {
  local option_name="$1"
  local option_value="${2:-}"

  if [[ -z "$option_value" || "$option_value" == --* ]]; then
    parse_args_fail "Option '$option_name' requires a value."
    return 1
  fi
}

TAG="${TAG:-}"
GO_OS="${GO_OS:-}"
GO_ARCH="${GO_ARCH:-}"
TARGET_DIR="${TARGET_DIR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      require_option_value "$1" "${2:-}" || return 1
      TAG="$2"
      shift 2
      ;;
    --os)
      require_option_value "$1" "${2:-}" || return 1
      GO_OS="$2"
      shift 2
      ;;
    --arch)
      require_option_value "$1" "${2:-}" || return 1
      GO_ARCH="$2"
      shift 2
      ;;
    --target-dir)
      require_option_value "$1" "${2:-}" || return 1
      TARGET_DIR="$2"
      shift 2
      ;;
    --help|-h)
      parse_args_fail "This script does not provide a standalone help screen. See the caller usage instead."
      return 1
      ;;
    --*)
      parse_args_fail "Unknown option: $1"
      return 1
      ;;
    *)
      parse_args_fail "Unexpected positional argument: $1"
      return 1
      ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  TARGET_DIR="osmosis"
fi

if [[ -z "$TAG" ]]; then
  TAG="$("$SCRIPT_DIR/last_tag.sh")"
fi

if [[ -z "$GO_OS" ]]; then
  GO_OS="$("$SCRIPT_DIR/resolve_os.sh" "$(uname -s)")"
fi

if [[ -z "$GO_ARCH" ]]; then
  GO_ARCH="$("$SCRIPT_DIR/resolve_arch.sh" "$(uname -m)")"
fi

export TAG GO_OS GO_ARCH TARGET_DIR
