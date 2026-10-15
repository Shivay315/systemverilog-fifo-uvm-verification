# Validation status

Results below are based on terminal output reported by the project owner. They were not independently reproduced in the packaging environment.

## Plain-SystemVerilog baseline — macOS, Icarus Verilog

| Configuration | Seed | Cycles | Checks | Accepted writes | Accepted reads | Rejected writes / overflow | Rejected reads / underflow | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| DATA_WIDTH=8, DEPTH=4 | 324508639 | 1033 | 8290 | 456 | 449 | 51 | 66 | PASS |
| DATA_WIDTH=8, DEPTH=1 | 324508639 | 1013 | 8130 | 262 | 261 | 233 | 245 | PASS |
| DATA_WIDTH=8, DEPTH=3 | 324508639 | 1027 | 8242 | 433 | 427 | 71 | 85 | PASS |

Scenario counters reported by the testbench:

- DEPTH=4: simultaneous-empty=32, simultaneous-middle=191, simultaneous-full=24.
- DEPTH=1: simultaneous-empty=124, simultaneous-middle=0, simultaneous-full=122. Zero middle cases are expected for a one-entry FIFO because its occupancy can only be empty or full.
- DEPTH=3: simultaneous-empty=42, simultaneous-middle=168, simultaneous-full=37.

All three baseline runs used seed `324508639` and reached their PASS summary and `$finish`.

## Mutation regression — macOS, Icarus Verilog

The owner reported that `make mutations` completed and printed `All three mutants were detected by expected checker patterns.` The pasted terminal output showed:

| Mutant | Depth | Observed checker failure | Interpretation |
|---|---:|---|---|
| `bad_empty` | 4 | `reset flags incorrect` at 16,000 ps | The intentionally incorrect empty flag is already wrong immediately after reset. This proves the reset check catches this mutant, but does not independently demonstrate a later empty-transition scenario. |
| `bad_wrap` | 3 | `read data mismatch: expected 0x1, got 0x3` at 136,000 ps | Incorrect pointer wraparound corrupts read ordering. |
| `bad_full_simultaneous` | 4 | `count mismatch: model=3 DUT=4` at 146,000 ps | Incorrect full-boundary simultaneous operation is caught by the reference-model occupancy check. |

## UVM simulation — macOS, Verilator + Accellera UVM-core

Reported environment:

- Verilator `5.052`.
- Accellera UVM-core `2020.3.1`.
- `UVM_NO_DPI` enabled; Z3 installed to support randomization.
- Test: `fifo_base_test`.
- Seed: `324508639`.

Reported result:

| Metric | Observed value |
|---|---:|
| Observed cycles | 1,023 |
| Accepted writes | 438 |
| Accepted reads | 431 |
| Final occupancy | 3 |
| UVM errors | 0 |
| UVM fatals | 0 |
| UVM warnings | 2 |
| Reported functional coverage | 0.00% |

The simulation reached `$finish` at 10 us. Verilator also printed a system-stack-size warning, and the UVM run warned about disabled DPI-based functionality. The successful run is evidence that this test completed under this particular Verilator/UVM setup; it is not a claim of simulator portability, formal proof, or coverage closure.

## What has and has not been established

- Reported Icarus simulations completed at FIFO depths 1, 3, and 4.
- The reported mutation regression detected all three intentionally buggy variants, with the `bad_empty` caveat above.
- The reported Verilator/UVM simulation completed with zero UVM errors/fatals.
- Functional coverage is **not** considered validated or closed: the reported covergroup percentage was 0.00% and coverage instrumentation/configuration needs investigation.
- No formal verification, synthesis, timing, area, power, DRC/LVS, or physical-design result is claimed for this FIFO project.
- The VCS runner is included but no VCS run has been reported.

## Recommended next steps

1. Investigate why the UVM coverage report is 0.00% and enable/report coverage correctly before making coverage claims.
2. Add a separate empty-transition test so the `bad_empty` mutant is not caught only by the reset check.
3. If simulator portability is important, compile and run the UVM environment with a commercial simulator as a separate validation step.
