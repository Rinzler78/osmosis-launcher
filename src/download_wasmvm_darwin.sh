#!/bin/bash
# Download libwasmvm for Darwin builds
set -e

WASMVM_VERSION="$1"
OUTPUT_PATH="${2:-./lib/libwasmvmstatic_darwin.a}"

if [ -z "$WASMVM_VERSION" ]; then
  echo "[FAIL] WASMVM_VERSION is required as first argument (e.g., v2.2.4)"
  exit 1
fi

# Check if already downloaded
if [ -f "$OUTPUT_PATH" ]; then
  echo "[INFO] libwasmvmstatic_darwin.a already exists at $OUTPUT_PATH"
  exit 0
fi

# Create output directory if needed
OUTPUT_DIR=$(dirname "$OUTPUT_PATH")
mkdir -p "$OUTPUT_DIR"

DOWNLOAD_URL="https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}/libwasmvmstatic_darwin.a"

echo "[INFO] Downloading libwasmvmstatic_darwin.a from CosmWasm ${WASMVM_VERSION}..."
echo "[INFO] URL: $DOWNLOAD_URL"

if ! wget -q "$DOWNLOAD_URL" -O "$OUTPUT_PATH"; then
  echo "[FAIL] Failed to download libwasmvmstatic_darwin.a from $DOWNLOAD_URL"
  rm -f "$OUTPUT_PATH"
  exit 1
fi

# Verify the file was downloaded and is not empty
if [ ! -s "$OUTPUT_PATH" ]; then
  echo "[FAIL] Downloaded file is empty"
  rm -f "$OUTPUT_PATH"
  exit 1
fi

FILE_SIZE=$(stat -c%s "$OUTPUT_PATH" 2>/dev/null || stat -f%z "$OUTPUT_PATH" 2>/dev/null)
echo "[OK] libwasmvmstatic_darwin.a downloaded successfully (size: $FILE_SIZE bytes)"
