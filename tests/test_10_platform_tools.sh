#!/bin/bash
# Test des scripts resolve_os.sh, resolve_arch.sh et validate_platform.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../src"
RESOLVE_OS_SH="$SRC_DIR/resolve_os.sh"
RESOLVE_ARCH_SH="$SRC_DIR/resolve_arch.sh"
VALIDATE_PLATFORM_SH="$SRC_DIR/validate_platform.sh"

pass() { echo "✅ [OK] $1"; }
fail() { echo "❌ [FAIL] $1"; exit 1; }

# Matrice de tests pour resolve_os.sh
os_cases=(
  "Linux:linux"
  "Darwin:darwin"
  "FreeBSD:freebsd"
  "OpenBSD:openbsd"
  "NetBSD:netbsd"
  "SunOS:solaris"
  "AIX:aix"
  "DragonFly:dragonfly"
  "NotARealOS:"
)

for case in "${os_cases[@]}"; do
  input="${case%%:*}"
  expected="${case#*:}"
  output=$(bash "$RESOLVE_OS_SH" "$input")
  if [ "$output" = "$expected" ]; then
    pass "resolve_os.sh $input => $expected"
  else
    fail "resolve_os.sh $input => '$output' (attendu: '$expected')"
  fi
done

# Matrice de tests pour resolve_arch.sh
arch_cases=(
  "x86_64:amd64"
  "amd64:amd64"
  "i386:386"
  "i686:386"
  "386:386"
  "arm64:arm64"
  "aarch64:arm64"
  "armv7l:arm"
  "armv6l:arm"
  "arm:arm"
  "mips:mips"
  "mipsle:mipsle"
  "mips64:mips64"
  "mips64le:mips64le"
  "ppc64:ppc64"
  "ppc64le:ppc64le"
  "s390x:s390x"
  "riscv64:riscv64"
  "loongarch64:loong64"
  "loong64:loong64"
  "NotARealArch:"
)

for case in "${arch_cases[@]}"; do
  input="${case%%:*}"
  expected="${case#*:}"
  output=$(bash "$RESOLVE_ARCH_SH" "$input")
  if [ "$output" = "$expected" ]; then
    pass "resolve_arch.sh $input => $expected"
  else
    fail "resolve_arch.sh $input => '$output' (attendu: '$expected')"
  fi
done

# Matrice de tests pour validate_platform.sh
# Format: os arch attendu (0=ok, 1=fail, msg si fail)
validate_cases=(
  "linux amd64 0"
  "darwin amd64 0"
  "linux notarch 1 Unsupported architecture"
  "notos amd64 1 Unsupported OS"
  "darwin mips 1 Unsupported platform combination"
  "notos notarch 1 Unsupported OS"
  "linux 386 0"
  "windows arm64 0"
  "js wasm 0"
  "plan9 arm 0"
)

for case in "${validate_cases[@]}"; do
  set -- $case
  os="$1"; arch="$2"; expected_code="$3"; expected_msg="$4"
  if [ "$expected_code" = "0" ]; then
    if bash "$VALIDATE_PLATFORM_SH" "$os" "$arch"; then
      pass "validate_platform.sh $os $arch (ok)"
    else
      fail "validate_platform.sh $os $arch (devrait réussir)"
    fi
  else
    if bash "$VALIDATE_PLATFORM_SH" "$os" "$arch" 2>err.txt; then
      fail "validate_platform.sh $os $arch (devrait échouer)"
    else
      if grep -q "$expected_msg" err.txt; then
        pass "validate_platform.sh $os $arch (échec attendu: $expected_msg)"
      else
        fail "validate_platform.sh $os $arch: message attendu '$expected_msg' absent"
      fi
    fi
  fi
  rm -f err.txt
done

echo "✅ [OK] Platform tools tests passed." 