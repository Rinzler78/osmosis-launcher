#!/bin/bash
# Clones the Osmosis repo at a given tag in a target directory.
# Usage: ./clone.sh [--force-reset] --tag <tag> --target-dir <dir>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export GIT_LFS_SKIP_SMUDGE=1

FORCE_RESET=0
PARSE_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-reset)
      FORCE_RESET=1
      shift
      ;;
    *)
      PARSE_ARGS+=("$1")
      shift
      ;;
  esac
done

# shellcheck disable=SC1091
if [[ ${#PARSE_ARGS[@]} -gt 0 ]]; then
  source "$SCRIPT_DIR/parse_args.sh" "${PARSE_ARGS[@]}"
else
  source "$SCRIPT_DIR/parse_args.sh"
fi

REPO_URL="$(<"$SCRIPT_DIR/repo_url.txt")"
DEFAULT_BRANCH="main"

if ! "$SCRIPT_DIR/tags.sh" | grep -Fxq "$TAG"; then
  echo "[ERROR] The specified tag '$TAG' was not found in the Osmosis repository. Use './src/tags.sh' to list available tags." >&2
  exit 3
fi

ensure_clean_repo_or_fail() {
  if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    if [[ $FORCE_RESET -eq 1 ]]; then
      echo "[WARN] Forcing reset of local changes in '$TARGET_DIR'."
      git reset --hard HEAD
      git clean -fd
    else
      echo "[ERROR] Target directory '$TARGET_DIR' contains local changes. Re-run with --force-reset to allow a destructive reset." >&2
      exit 1
    fi
  fi
}

if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "[INFO] Target directory '$TARGET_DIR' already exists. Refreshing repository state for tag '$TAG'."
  pushd "$TARGET_DIR" >/dev/null

  ORIGIN_URL="$(git remote get-url origin)"
  if [[ "$ORIGIN_URL" != "$REPO_URL" ]]; then
    echo "[ERROR] Remote 'origin' URL ($ORIGIN_URL) does not match expected ($REPO_URL)." >&2
    exit 1
  fi

  git fetch --all --tags
  ensure_clean_repo_or_fail

  CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
  if [[ "$CURRENT_TAG" = "$TAG" ]]; then
    echo "[INFO] Already on tag '$TAG'. Repository left unchanged."
    popd >/dev/null
    exit 0
  fi

  git checkout "$TAG"
  if [[ $FORCE_RESET -eq 1 ]]; then
    git reset --hard "$TAG"
  fi
  popd >/dev/null
  exit 0
fi

echo "[INFO] Cloning Osmosis repo to '$TARGET_DIR'"
git clone --branch "$DEFAULT_BRANCH" --depth 1 "$REPO_URL" "$TARGET_DIR"
pushd "$TARGET_DIR" >/dev/null
echo "[INFO] Fetching tags and checking out tag '$TAG'"
git fetch --all --tags >/dev/null 2>&1
git checkout "$TAG" >/dev/null 2>&1
git reset --hard "$TAG" >/dev/null 2>&1
popd >/dev/null

if [[ -d "$TARGET_DIR" ]]; then
  echo "[OK] Osmosis repo cloned in '$TARGET_DIR' at version '$TAG'."
else
  echo "[ERROR] Cloning failed." >&2
  exit 2
fi
