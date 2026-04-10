#!/bin/bash
set -euo pipefail

PROTECTED_BRANCHES="${PROTECTED_BRANCHES:-master develop}"
EXPECTED_WORKTREE_ROOT_NAME="${EXPECTED_WORKTREE_ROOT_NAME:-.worktrees}"

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

git_toplevel() {
  git rev-parse --show-toplevel
}

git_common_dir() {
  git rev-parse --path-format=absolute --git-common-dir
}

git_branch() {
  git branch --show-current
}

is_protected_branch() {
  local branch="$1"
  local protected_branch
  for protected_branch in $PROTECTED_BRANCHES; do
    if [[ "$branch" == "$protected_branch" ]]; then
      return 0
    fi
  done

  return 1
}

is_main_worktree() {
  local toplevel="$1"
  local common_dir="$2"
  local common_parent

  common_parent="$(cd "$common_dir/.." && pwd)"
  [[ "$toplevel" == "$common_parent" ]]
}

main() {
  local toplevel
  local common_dir
  local branch
  local repo_root

  toplevel="$(git_toplevel)"
  common_dir="$(git_common_dir)"
  branch="$(git_branch)"
  repo_root="$(cd "$common_dir/.." && pwd)"

  if ! is_protected_branch "$branch"; then
    exit 0
  fi

  if ! is_main_worktree "$toplevel" "$common_dir"; then
    fail "Direct commits on protected branch '$branch' are forbidden. Create a feature or hotfix worktree under '$repo_root/$EXPECTED_WORKTREE_ROOT_NAME/' and commit from that worktree instead."
  fi

  fail "Direct commits on protected branch '$branch' are forbidden in the main worktree. Create a feature or hotfix worktree under '$repo_root/$EXPECTED_WORKTREE_ROOT_NAME/' and commit from that worktree instead."
}

main "$@"
