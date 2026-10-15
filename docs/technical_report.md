# Technical report: Parameterized synchronous FIFO

## Status

- RTL: authored in this project.
- Verification testbench: user-reported Icarus Verilog runs passed for DATA_WIDTH=8 at DEPTH=1, DEPTH=3, and DEPTH=4 using seed 324508639. See `validation_status.md` for the exact reported metrics.
- UVM: candidate component-based environment is present under `../uvm/`, but it has not been compiled or simulated; see `../uvm/README.md`.
- No formal proof, coverage-closure, synthesis, timing, area, power, or signoff claims are made.

## Design decisions

The FIFO is a single-clock synchronous queue with configurable width and depth. Pointers wrap explicitly at `DEPTH-1`, allowing non-power-of-two depths. Occupancy is represented with enough bits for values from zero through `DEPTH`. The output register is cleared by reset and otherwise holds its value when no read is accepted.

Request acceptance uses the pre-edge full/empty state. This makes the boundary behaviour deterministic: a simultaneous read/write at empty accepts only the write and emits underflow; at full it accepts only the read and emits overflow. In the middle of the occupancy range, both operations are accepted, the old head is returned, and occupancy is unchanged.

## Test strategy

The plain-SystemVerilog testbench has a queue-based reference model and checks accepted reads/writes, output data, read-valid, overflow/underflow pulses, occupancy, and flags. Directed phases cover empty access, empty/full simultaneous requests, a partial-occupancy simultaneous request, wraparound, reset while occupied, and deterministic randomized traffic. The seed is set via `+SEED=<integer>`.

The plain testbench uses immediate assertion-style checks implemented with a common task that terminates on the first mismatch. Its scenario counters are diagnostic counts, not a functional-coverage percentage. A covergroup exists in the candidate UVM monitor, but its compilation and report are unverified.

## Limitations and next steps

1. Preserve the terminal logs from the already-reported depth 1, depth 3, and depth 4 runs as regression evidence.
2. The user-reported `make mutations` run detected all three intentionally buggy RTL variants through expected checker/scoreboard failures. The `bad_empty` variant was caught at the reset-flags check; add or run a separate test that targets an empty-to-nonempty / empty-read transition to strengthen the specific behavioral evidence.
3. Run additional deterministic seeds and record the exact command and result.
4. Confirm the candidate UVM covergroup compiles and produces a meaningful coverage report; add missing bins based on the actual report.
5. Compile and validate the candidate UVM transaction-level environment only after a compatible simulator and UVM library are available.
6. Synthesis inference and physical characteristics have not been evaluated.
