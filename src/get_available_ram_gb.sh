#!/bin/bash
# Print available RAM in GB (integer, multiplatform: Linux/macOS)

if [ -f /proc/meminfo ]; then
  # Linux
  MEM_AVAILABLE_KB=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
  MEM_AVAILABLE_GB=$((MEM_AVAILABLE_KB / 1024 / 1024))
  echo "$MEM_AVAILABLE_GB"
elif command -v vm_stat >/dev/null 2>&1; then
  # macOS
  PAGES_FREE=$(vm_stat | awk '/Pages free/ {print $3}' | sed 's/\.//')
  PAGES_INACTIVE=$(vm_stat | awk '/Pages inactive/ {print $3}' | sed 's/\.//')
  PAGE_SIZE=$(vm_stat | grep 'page size of' | awk '{print $8}')
  MEM_AVAILABLE_BYTES=$(( (PAGES_FREE + PAGES_INACTIVE) * PAGE_SIZE ))
  MEM_AVAILABLE_GB=$((MEM_AVAILABLE_BYTES / 1024 / 1024 / 1024))
  echo "$MEM_AVAILABLE_GB"
else
  # Unknown platform
  echo 0
fi 