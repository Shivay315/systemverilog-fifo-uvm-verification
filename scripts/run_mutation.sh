#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MUTANT="${1:-}"
case "$MUTANT" in
  bad_empty|bad_wrap|bad_full_simultaneous) ;;
  *) echo "Usage: $0 {bad_empty|bad_wrap|bad_full_simultaneous}" >&2; exit 2 ;;
esac
command -v iverilog >/dev/null 2>&1 || { echo "ERROR: iverilog is not installed or not on PATH." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "ERROR: vvp is not installed or not on PATH." >&2; exit 127; }
mkdir -p "$ROOT/build/mutations"
DEPTH=4
EXPECTED_PATTERN=''
case "$MUTANT" in
  bad_empty)
    EXPECTED_PATTERN='reset flags incorrect|read_valid does not match accepted read|underflow pulse incorrect|empty flag disagrees with reference queue'
    ;;
  bad_wrap)
    DEPTH=3
    EXPECTED_PATTERN='read data mismatch|count mismatch|empty flag disagrees with reference queue|full flag disagrees with reference queue'
    ;;
  bad_full_simultaneous)
    EXPECTED_PATTERN='count mismatch|read data mismatch|empty flag disagrees with reference queue|full flag disagrees with reference queue'
    ;;
esac
OUT="$ROOT/build/mutations/$MUTANT.vvp"
LOG="$ROOT/build/mutations/$MUTANT.log"
echo "== Compiling mutant: $MUTANT (DEPTH=$DEPTH) =="
iverilog -g2012 -Wall -s tb_fifo -Ptb_fifo.DEPTH="$DEPTH" \
  -o "$OUT" "$ROOT/rtl/mutants/$MUTANT.sv" "$ROOT/tb/tb_fifo.sv"
echo "== Running mutant: $MUTANT =="
set +e
vvp "$OUT" +SEED="${SEED:-324508639}" 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}
set -e
if [[ $STATUS -eq 0 ]]; then
  echo "FAIL: mutant unexpectedly completed without a fatal simulation exit." >&2
  exit 1
fi
if ! grep -Eiq "$EXPECTED_PATTERN" "$LOG"; then
  echo "FAIL: simulation exited nonzero, but expected checker pattern was not found." >&2
  echo "Inspect log: $LOG" >&2
  exit 1
fi
echo "PASS: $MUTANT was killed by an expected checker failure."
echo "Log: $LOG"
