#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v iverilog >/dev/null 2>&1 || { echo "ERROR: iverilog is not installed or not on PATH." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "ERROR: vvp is not installed or not on PATH." >&2; exit 127; }
OUT="$ROOT/build"
mkdir -p "$OUT"
iverilog -g2012 -Wall -s tb_fifo -o "$OUT/tb_fifo.vvp" \
  "$ROOT/rtl/sync_fifo.sv" "$ROOT/tb/tb_fifo.sv"
vvp "$OUT/tb_fifo.vvp" +SEED="${SEED:-324508639}"
