#!/bin/bash

# shellcheck source=./utils.sh
. "$(dirname "$0")/utils.sh"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.tmp/root-make"
ROOT_MAKE_SH="$SCRIPT_DIR/../make.sh"

cleanup() {
  rm -rf "$ROOT_DIR"
}

write_stub() {
  local stub_path="$1"
  local label="$2"

  mkdir -p "$(dirname "$stub_path")"
  {
    printf '%s\n' '#!/bin/bash'
    printf '%s\n' 'set -euo pipefail'
    printf '%s\n' "printf '%s\\n' '$label' > \"\${STUB_LOG}\""
    printf '%s\n' "printf \"%s\\n\" \"\$@\" >> \"\${STUB_LOG}\""
  } > "$stub_path"
  chmod +x "$stub_path"
}

trap cleanup EXIT
cleanup
mkdir -p "$ROOT_DIR"

LOCAL_STUB="$ROOT_DIR/local.sh"
DOCKER_STUB="$ROOT_DIR/docker.sh"
FAKE_DOCKER="$ROOT_DIR/fake-docker"
write_stub "$LOCAL_STUB" "local"
write_stub "$DOCKER_STUB" "docker"
printf '%s\n' '#!/bin/bash' > "$FAKE_DOCKER"
printf '%s\n' 'exit 0' >> "$FAKE_DOCKER"
chmod +x "$FAKE_DOCKER"

STUB_LOG="$ROOT_DIR/local.log" \
LOCAL_BUILD_SCRIPT="$LOCAL_STUB" \
DOCKER_BUILD_SCRIPT="$DOCKER_STUB" \
DOCKER_COMMAND="$ROOT_DIR/does-not-exist" \
bash "$ROOT_MAKE_SH" --tag v1.2.3 --os linux --arch amd64 --target-dir "dir with spaces" >/dev/null
EXPECTED_LOCAL=$'local\n--tag\nv1.2.3\n--os\nlinux\n--arch\namd64\n--target-dir\ndir with spaces'
if [[ "$(cat "$ROOT_DIR/local.log")" = "$EXPECTED_LOCAL" ]]; then
  pass "root make.sh forwards named arguments to the local workflow"
else
  fail "root make.sh did not forward named arguments correctly"
fi

STUB_LOG="$ROOT_DIR/docker.log" \
LOCAL_BUILD_SCRIPT="$LOCAL_STUB" \
DOCKER_BUILD_SCRIPT="$DOCKER_STUB" \
DOCKER_COMMAND="$FAKE_DOCKER" \
bash "$ROOT_MAKE_SH" --tag v9.9.9 >/dev/null
EXPECTED_DOCKER=$'docker\n--tag\nv9.9.9'
if [[ "$(cat "$ROOT_DIR/docker.log")" = "$EXPECTED_DOCKER" ]]; then
  pass "root make.sh auto-selects Docker when available"
else
  fail "root make.sh did not auto-select Docker"
fi

STUB_LOG="$ROOT_DIR/positional.log" \
LOCAL_BUILD_SCRIPT="$LOCAL_STUB" \
DOCKER_BUILD_SCRIPT="$DOCKER_STUB" \
DOCKER_COMMAND="$ROOT_DIR/does-not-exist" \
bash "$ROOT_MAKE_SH" v2.0.0 linux arm64 custom-dir >/dev/null
EXPECTED_POSITIONAL=$'local\n--tag\nv2.0.0\n--os\nlinux\n--arch\narm64\n--target-dir\ncustom-dir'
if [[ "$(cat "$ROOT_DIR/positional.log")" = "$EXPECTED_POSITIONAL" ]]; then
  pass "root make.sh preserves documented positional compatibility"
else
  fail "root make.sh positional compatibility is broken"
fi

if LOCAL_BUILD_SCRIPT="$LOCAL_STUB" DOCKER_BUILD_SCRIPT="$DOCKER_STUB" DOCKER_COMMAND="$ROOT_DIR/does-not-exist" bash "$ROOT_MAKE_SH" --unknown >"$ROOT_DIR/unknown.out" 2>&1; then
  fail "root make.sh must reject unknown options"
fi
if grep -Fq 'Unknown option: --unknown' "$ROOT_DIR/unknown.out"; then
  pass "root make.sh rejects unknown options clearly"
else
  fail "root make.sh unknown-option error output is missing"
fi

if LOCAL_BUILD_SCRIPT="$LOCAL_STUB" DOCKER_BUILD_SCRIPT="$DOCKER_STUB" DOCKER_COMMAND="$ROOT_DIR/does-not-exist" bash "$ROOT_MAKE_SH" --docker >"$ROOT_DIR/docker-required.out" 2>&1; then
  fail "root make.sh must fail when Docker is required but unavailable"
fi
if grep -Fq 'Docker was explicitly requested but is not available.' "$ROOT_DIR/docker-required.out"; then
  pass "root make.sh reports missing required Docker"
else
  fail "root make.sh Docker requirement error output is missing"
fi

pass "root make.sh regression tests passed"
