#!/bin/bash
# This script formats a string by adding stars before and after it

if [ $# -eq 0 ]; then
  echo "Usage: $0 <string>"
  exit 1
fi

INPUT="$*"
echo "*************** $INPUT ***************" 