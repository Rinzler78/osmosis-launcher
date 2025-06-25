#!/bin/bash
# Usage: ./resolve_os.sh <uname_s>
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
SUPPORTED_PLATFORMS_JSON="$ROOT_DIR/supported_platforms.json"

UNAME_S="$1"

case "$UNAME_S" in
  Linux)
    OS="linux"
    ;;
  Darwin)
    OS="darwin"
    ;;
  FreeBSD)
    OS="freebsd"
    ;;
  OpenBSD)
    OS="openbsd"
    ;;
  NetBSD)
    OS="netbsd"
    ;;
  SunOS)
    OS="solaris"
    ;;
  AIX)
    OS="aix"
    ;;
  DragonFly)
    OS="dragonfly"
    ;;
  *)
    OS=""
    ;;
esac

if [ -n "$OS" ]; then
  valid_os=$(jq -r --arg os "$OS" '.os[] | select(. == $os)' "$SUPPORTED_PLATFORMS_JSON")
  if [ -n "$valid_os" ]; then
    echo "$OS"
  fi
fi 