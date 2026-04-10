#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] '$REPO_ROOT' is not a Git repository." >&2
  exit 1
fi

chmod +x "$HOOKS_DIR"/*
git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "[OK] Git hooks enabled via core.hooksPath=.githooks"
