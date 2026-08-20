#!/usr/bin/env bash
set -euo pipefail

fir_file="$1"
sv_file="$2"
sv_dir="$3"

grep -q "firrtl.circuit \"SimpleAdder\"" "$fir_file"
grep -q "module SimpleAdder" "$sv_file"
grep -q "module SimpleAdder" "$sv_dir/SimpleAdder.sv"
