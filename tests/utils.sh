#!/bin/bash
# Utility functions for test scripts

pass() { echo "✅ [OK] $1"; }
fail() { echo "❌ [FAIL] $1"; exit 1; } 