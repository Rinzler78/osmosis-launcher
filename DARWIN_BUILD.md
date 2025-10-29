# Darwin (macOS) Cross-Compilation Support

## Overview

This implementation enables proper cross-compilation from Linux to macOS (darwin/amd64 and darwin/arm64) using the goreleaser-cross Docker image with OSXCross toolchain.

## Problem Solved

Previously, `docker_make.sh` attempted to cross-compile to macOS using a standard Ubuntu image, which resulted in binaries that crashed at runtime with:
```
panic: not implemented, please build with cgo enabled or nolink_libwasmvm disabled
```

The issue was that:
- Cross-compiling to macOS requires the OSXCross toolchain (`o64-clang` for amd64, `oa64-clang` for arm64)
- macOS builds need `libwasmvmstatic_darwin.a` instead of `libwasmvm_muslc.{arch}.a`
- Build tags must be `static_wasm` instead of `muslc` for Darwin
- CGO must be properly configured with macOS-specific flags

## Implementation

### New Files

1. **`src/Dockerfile.darwin`**
   - Based on `ghcr.io/goreleaser/goreleaser-cross:v1.23`
   - Contains OSXCross toolchain for macOS cross-compilation
   - Includes all necessary build tools (gcc, jq, wget, bash)

2. **`src/download_wasmvm_darwin.sh`**
   - Downloads `libwasmvmstatic_darwin.a` from CosmWasm releases
   - Extracts wasmvm version from go.mod
   - Caches the library to avoid re-downloading

3. **`src/build_darwin.sh`**
   - Specialized build script for Darwin targets
   - Configures OSXCross toolchain:
     - `CC=o64-clang` for darwin/amd64
     - `CC=oa64-clang` for darwin/arm64
   - Sets CGO flags:
     ```bash
     export CGO_ENABLED=1
     export CGO_CFLAGS="-mmacosx-version-min=10.12"
     export CGO_LDFLAGS="-L/lib -mmacosx-version-min=10.12"
     ```
   - Uses build tags: `netgo,ledger,static_wasm`
   - Downloads and links libwasmvmstatic_darwin.a

### Modified Files

1. **`src/build.sh`**
   - Added delegation to `build_darwin.sh` for Darwin targets
   - Detects `GO_OS=darwin` and executes `build_darwin.sh` instead

2. **`src/docker_make.sh`**
   - Added automatic Dockerfile selection based on target OS
   - Uses `Dockerfile.darwin` for Darwin builds
   - Uses `Dockerfile` (Ubuntu) for Linux builds

## Usage

### Build for macOS from any platform

```bash
# Build for macOS amd64
./src/docker_make.sh --os darwin --arch amd64

# Build for macOS arm64 (Apple Silicon)
./src/docker_make.sh --os darwin --arch arm64

# Auto-detect current platform
./src/docker_make.sh
```

### What happens

1. **Docker image selection**:
   - Darwin: Uses goreleaser-cross (~2-3GB, downloads once)
   - Linux: Uses Ubuntu image (~200MB)

2. **Build process**:
   - Downloads wasmvm library for Darwin
   - Configures OSXCross toolchain
   - Compiles with proper CGO settings
   - Produces working macOS binary

3. **Output**:
   - Binary: `./osmosisd`
   - Format: Mach-O 64-bit executable
   - Can be executed on macOS

## Testing

### Quick test
```bash
./test_darwin_binary.sh
```

### Manual test
```bash
# Check binary format
file ./osmosisd
# Should show: Mach-O 64-bit executable x86_64 (or arm64)

# Test execution (on macOS only)
./osmosisd version
./osmosisd --launcher version
```

## Technical Details

### OSXCross Toolchain

The goreleaser-cross image includes:
- `o64-clang`: Cross-compiler for darwin/amd64
- `oa64-clang`: Cross-compiler for darwin/arm64
- macOS SDK for proper linking
- Support for CGO and native libraries

### Build Tags

For Darwin builds, we use:
- `netgo`: Pure Go networking (no cgo for net package)
- `ledger`: Ledger hardware wallet support
- `static_wasm`: Static linking of wasmvm for Darwin

**NOT** `muslc` which is Linux-specific (musl libc).

### LibWasmVM

Darwin builds require:
- **Library**: `libwasmvmstatic_darwin.a`
- **Source**: https://github.com/CosmWasm/wasmvm/releases
- **Version**: Extracted from go.mod (currently v2.2.4)
- **Location**: `/lib/libwasmvmstatic_darwin.a`

Linux builds use:
- **Library**: `libwasmvm_muslc.{x86_64|aarch64}.a`
- **Build tag**: `muslc`

### Performance Notes

**First build**:
- Downloads goreleaser-cross image (~2-3GB)
- Takes 5-10 minutes depending on network
- Image is cached for subsequent builds

**Subsequent builds**:
- Image already cached
- Build time similar to Linux builds (~3-5 minutes)

## Limitations

1. **Image size**: goreleaser-cross is large (~2-3GB)
2. **First build**: Slow due to image download
3. **Platforms**: Only supports darwin/amd64 and darwin/arm64

## Future Improvements

1. Could add support for building Windows binaries
2. Could optimize image size with custom Dockerfile
3. Could cache Go modules in Docker volume

## References

- [goreleaser-cross](https://github.com/goreleaser/goreleaser-cross)
- [OSXCross](https://github.com/tpoechtrager/osxcross)
- [Osmosis .goreleaser.yaml](https://github.com/osmosis-labs/osmosis/blob/main/.goreleaser.yaml)
- [CosmWasm wasmvm](https://github.com/CosmWasm/wasmvm)
