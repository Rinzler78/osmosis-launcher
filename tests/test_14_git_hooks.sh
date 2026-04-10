#!/bin/bash

# shellcheck source=tests/utils.sh
. "$(dirname "$0")/utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp/git-hooks"
HOOK_SCRIPT="$SCRIPT_DIR/../src/git_hook_pre_commit.sh"
FAKE_GIT="$ROOT_DIR/fake-git"
FAKE_REPO_ROOT="$ROOT_DIR/repo"
FAKE_MAIN_TOPLEVEL="$FAKE_REPO_ROOT"
FAKE_WORKTREE_TOPLEVEL="$FAKE_REPO_ROOT/.worktrees/feature-x"
FAKE_COMMON_DIR="$FAKE_REPO_ROOT/.git"

cleanup() {
  rm -rf "$ROOT_DIR"
}

write_fake_git() {
  mkdir -p "$ROOT_DIR"
  cat > "$FAKE_GIT" <<'EOF'
#!/bin/bash
set -euo pipefail

case "$*" in
  "rev-parse --show-toplevel")
    printf '%s\n' "$FAKE_GIT_TOPLEVEL"
    ;;
  "rev-parse --path-format=absolute --git-common-dir")
    printf '%s\n' "$FAKE_GIT_COMMON_DIR"
    ;;
  "branch --show-current")
    printf '%s\n' "$FAKE_GIT_BRANCH"
    ;;
  *)
    echo "unexpected git invocation: $*" >&2
    exit 1
    ;;
esac
EOF
  chmod +x "$FAKE_GIT"
}

trap cleanup EXIT
cleanup
mkdir -p "$FAKE_COMMON_DIR" "$FAKE_WORKTREE_TOPLEVEL"
FAKE_GIT="$ROOT_DIR/git"
write_fake_git

if PATH="$ROOT_DIR:$PATH" FAKE_GIT_BRANCH="feature/test" FAKE_GIT_TOPLEVEL="$FAKE_MAIN_TOPLEVEL" FAKE_GIT_COMMON_DIR="$FAKE_COMMON_DIR" bash "$HOOK_SCRIPT" >"$ROOT_DIR/feature.out" 2>&1; then
  pass "pre-commit hook allows non-protected branches"
else
  fail "pre-commit hook should allow non-protected branches"
fi

if PATH="$ROOT_DIR:$PATH" FAKE_GIT_BRANCH="develop" FAKE_GIT_TOPLEVEL="$FAKE_MAIN_TOPLEVEL" FAKE_GIT_COMMON_DIR="$FAKE_COMMON_DIR" bash "$HOOK_SCRIPT" >"$ROOT_DIR/develop.out" 2>&1; then
  fail "pre-commit hook must block direct commits on develop"
fi
if grep -Fq "Direct commits on protected branch 'develop' are forbidden in the main worktree." "$ROOT_DIR/develop.out" && grep -Fq "$FAKE_REPO_ROOT/.worktrees/" "$ROOT_DIR/develop.out"; then
  pass "pre-commit hook blocks direct commits on develop in the main worktree"
else
  fail "pre-commit hook develop protection output is missing"
fi

if PATH="$ROOT_DIR:$PATH" FAKE_GIT_BRANCH="master" FAKE_GIT_TOPLEVEL="$FAKE_WORKTREE_TOPLEVEL" FAKE_GIT_COMMON_DIR="$FAKE_COMMON_DIR" bash "$HOOK_SCRIPT" >"$ROOT_DIR/master-worktree.out" 2>&1; then
  fail "pre-commit hook must block protected branches even inside linked worktrees"
fi
if grep -Fq "Direct commits on protected branch 'master' are forbidden." "$ROOT_DIR/master-worktree.out" && grep -Fq "$FAKE_REPO_ROOT/.worktrees/" "$ROOT_DIR/master-worktree.out"; then
  pass "pre-commit hook blocks protected branches in linked worktrees too"
else
  fail "pre-commit hook master protection output is missing"
fi

pass "git hook protection regression tests passed"
