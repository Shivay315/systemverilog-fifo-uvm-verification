# Validation status

## User-reported simulator runs (macOS, Icarus Verilog)

The following successful runs were reported from the user's Mac terminal on the project as generated. The full output was supplied in the conversation; these runs were not independently executed in the packaging environment.

| Configuration | Seed | Cycles | Checks | Accepted writes | Accepted reads | Rejected writes / overflow | Rejected reads / underflow | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| DATA_WIDTH=8, DEPTH=4 | 324508639 | 1033 | 8290 | 456 | 449 | 51 | 66 | PASS |
| DATA_WIDTH=8, DEPTH=1 | 324508639 | 1013 | 8130 | 262 | 261 | 233 | 245 | PASS |
| DATA_WIDTH=8, DEPTH=3 | 324508639 | 1027 | 8242 | 433 | 427 | 71 | 85 | PASS |

Scenario counters reported by the testbench:

- DEPTH=4: simultaneous-empty=32, simultaneous-middle=191, simultaneous-full=24.
- DEPTH=1: simultaneous-empty=124, simultaneous-middle=0, simultaneous-full=122. Zero middle cases are expected for a one-entry FIFO because its occupancy can only be empty or full.
- DEPTH=3: simultaneous-empty=42, simultaneous-middle=168, simultaneous-full=37.

All three runs used the same explicit random seed (`324508639`). The reported testbench reached its PASS summary and `$finish` in each case.

## What this establishes

- The baseline RTL/testbench completed successfully under the reported Icarus Verilog runs for depths 1, 3, and 4.
- The reported checks included data, accepted/rejected operations and status signals according to the testbench's checks.
- These are simulation results, not formal proof or exhaustive verification. Scenario counters are not functional-coverage percentages.

## User-reported mutation regression (macOS, Icarus Verilog)

The user ran `make mutations` after updating the mutation scripts. The wrapper completed successfully and printed `All three mutants were detected by expected checker patterns.` The pasted output contains the following observed failures:

| Mutant | Depth | Observed checker failure | Interpretation |
|---|---:|---|---|
| `bad_empty` | 4 | `reset flags incorrect` at 16,000 ps | The intentionally incorrect empty flag is already wrong immediately after reset. This proves the reset check kills this mutant, but does not independently demonstrate a later empty-transition scenario. |
| `bad_wrap` | 3 | `read data mismatch: expected 0x1, got 0x3` at 136,000 ps | Incorrect pointer wraparound corrupts read ordering. |
| `bad_full_simultaneous` | 4 | `count mismatch: model=3 DUT=4` at 146,000 ps | Incorrect full-boundary simultaneous operation is detected by the reference-model occupancy check. |

The `make mutations` wrapper reported all three as detected using expected checker patterns. These are user-provided terminal results and were not independently reproduced in the packaging environment.

## Still not performed / not yet evidenced

- UVM compile/run; a compatible simulator and UVM library have not been evidenced yet.
- Formal verification, synthesis, timing, area, power, or physical-design analysis.
- Independent inspection of the full log files beyond the terminal output pasted by the user.

Next steps: run additional deterministic seeds and review the detailed mutation logs. Specifically add an empty-transition test that does not fail first on reset to strengthen `bad_empty` scenario evidence. Compile UVM separately only after checking the installed simulator and UVM library.

