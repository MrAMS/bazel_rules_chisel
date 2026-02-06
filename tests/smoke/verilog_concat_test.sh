#!/usr/bin/env bash
set -euo pipefail

merged="$1"

grep -q "module dummy0;" "$merged"
grep -q "module dummy1;" "$merged"

if grep -q "IGNORE_THIS_LINE" "$merged"; then
  echo "non-verilog content leaked into merged output"
  exit 1
fi
