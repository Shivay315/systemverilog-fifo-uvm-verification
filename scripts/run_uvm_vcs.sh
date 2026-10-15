#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v vcs >/dev/null 2>&1 || { echo "ERROR: Synopsys VCS is not installed or not on PATH." >&2; exit 127; }
OUT="$ROOT/build/uvm_vcs"
mkdir -p "$OUT"
cd "$ROOT"
vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
  -top tb_top -o "$OUT/simv" \
  rtl/sync_fifo.sv uvm/fifo_if.sv uvm/fifo_uvm_pkg.sv uvm/tb_top.sv
"$OUT/simv" +ntb_random_seed="${SEED:-324508639}"
