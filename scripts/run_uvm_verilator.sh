#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UVM_HOME="${UVM_HOME:-$HOME/uvm_libs/uvm-core-2020.3.1/src}"
BUILD_DIR="${BUILD_DIR:-/tmp/fifo-uvm-verilator}"
BIN="$BUILD_DIR/Vtb_top"
MODE="${1:-run}"

if [[ "$MODE" == "--build" ]]; then
  shift
elif [[ "$MODE" != "run" ]]; then
  echo "Usage: $0 [run|--build]" >&2
  exit 2
else
  shift || true
fi

if [[ "$MODE" == "--build" || ! -x "$BIN" ]]; then
  command -v verilator >/dev/null 2>&1 || {
    echo "ERROR: verilator was not found on PATH." >&2
    exit 127
  }
  command -v z3 >/dev/null 2>&1 || {
    echo "ERROR: z3 was not found on PATH; UVM randomization requires it in this setup." >&2
    exit 127
  }
  [[ -f "$UVM_HOME/uvm_pkg.sv" ]] || {
    echo "ERROR: cannot find $UVM_HOME/uvm_pkg.sv. Set UVM_HOME to the UVM src directory." >&2
    exit 2
  }

  mkdir -p "$BUILD_DIR"
  cd "$ROOT"
  verilator --binary --timing -Wno-fatal \
    --top-module tb_top \
    --Mdir "$BUILD_DIR" \
    "+incdir+$UVM_HOME" \
    +define+UVM_NO_DPI \
    "$UVM_HOME/uvm_pkg.sv" \
    rtl/sync_fifo.sv \
    uvm/fifo_if.sv \
    uvm/fifo_uvm_pkg.sv \
    uvm/tb_top.sv
fi

if [[ ! -x "$BIN" ]]; then
  echo "ERROR: executable not found at $BIN" >&2
  exit 2
fi

SEED="${SEED:-324508639}"
exec "$BIN" +UVM_TESTNAME=fifo_base_test "+verilator+seed+$SEED" "$@"
