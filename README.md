# Parameterized FIFO Verification

A small hardware-verification portfolio project: synthesizable synchronous FIFO RTL plus a self-checking SystemVerilog testbench. It is designed to be easy to inspect, reproduce, extend, and defend in an interview.

> **Validation status:** user-reported Icarus Verilog runs passed for the baseline at depths 1, 3, and 4, and the user-reported `make mutations` regression detected all three deliberate mutants through expected checker failures. The packaging environment did not independently execute those simulations. A candidate UVM environment is included in `uvm/`, but it has not been compiled or simulated and is not yet verified.

## Project contents

```text
fifo-verification-project/
├── rtl/
│   ├── sync_fifo.sv          # Synthesizable FIFO RTL
│   └── mutants/              # Three deliberately buggy FIFO variants
├── tb/
│   └── tb_fifo.sv            # Queue-based self-checking testbench
├── uvm/
│   ├── fifo_if.sv            # UVM virtual interface
│   ├── fifo_uvm_pkg.sv       # Sequences, driver, monitor, agent, scoreboard, test
│   ├── tb_top.sv             # UVM simulation top
│   └── README.md             # UVM compile order/status
├── scripts/
│   ├── run_iverilog.sh       # Compile and run default test
│   ├── run_mutation.sh       # Compile/run and check one deliberate RTL mutant
│   ├── run_all_mutations.sh  # Run all three mutations in sequence
│   └── run_uvm_vcs.sh        # Candidate Synopsys VCS/UVM runner
├── rtl/mutants/              # Three deliberately buggy FIFO variants
├── docs/
│   ├── fifo_spec.md          # Contract: latency, flags, boundary semantics
│   ├── mutation_matrix.md    # Defects and expected detection mechanisms
│   ├── technical_report.md   # Decisions, test strategy, limitations
│   ├── validation_status.md  # What was checked and what was not
│   └── provenance.md         # Honest source provenance
└── Makefile
```

## FIFO contract

- Single clock, synchronous active-high reset.
- Configurable data width and depth, including non-power-of-two depth.
- Registered read output: data updates after the edge that accepts a read; `read_valid` pulses for that cycle.
- `full`, `empty`, and `count` reflect post-edge occupancy.
- Overflow/underflow pulse when a write/read request is rejected.
- Acceptance is based on pre-edge flags. At empty simultaneous read/write, write only is accepted; at full simultaneous read/write, read only is accepted; between the boundaries both are accepted.

Read `docs/fifo_spec.md` before making changes.

## Run it

Install Icarus Verilog with SystemVerilog support (`iverilog` and `vvp`) on your own machine, then from this directory:

```bash
make sim
```

To set a deterministic random seed:

```bash
SEED=12345 make sim
```

Additional parameter checks:

```bash
make sim-depth1
make sim-depth3
```

With Synopsys VCS configured for UVM 1.2, the candidate UVM environment can be built with:

```bash
./scripts/run_uvm_vcs.sh
```

The default regression uses width 8 and depth 4. The testbench will stop with `$fatal` at the first detected mismatch and print a final summary only if it reaches the end. A script exiting successfully is necessary but not a substitute for reviewing the log.

## Verification implemented

- Queue-based reference model.
- Expected accepted/rejected operation calculation from pre-edge occupancy.
- Checks for output data and hold behaviour, `read_valid`, overflow/underflow pulses, count, full, and empty.
- Directed scenarios for empty reads, simultaneous operations at empty/full/middle occupancy, filling, overflow attempts, pointer wraparound, and reset while populated.
- 1,000 deterministic randomized cycles controlled by `+SEED`.
- Diagnostic counters for accepted operations and boundary scenarios.

Scenario counters are not functional coverage percentages. The UVM candidate contains a covergroup; its report is unverified until simulated. Three deliberate RTL fault-injection variants were detected in user-reported local Icarus Verilog runs. See `docs/validation_status.md` for the observed checker failures.

## Current validation status

The user has reported successful Icarus Verilog runs for the default depth 4, depth 1, and depth 3 configurations using seed `324508639`. Exact cycle/check/operation counts are recorded in `docs/validation_status.md`. These are user-provided terminal results, not simulations independently executed in the package-generation environment.

## Limitations

- The mutant regression is reported as passing, but the `bad_empty` variant is caught immediately by the reset-flags check; deeper empty-transition behaviour should also be exercised independently.
- Candidate UVM source is included but has not been compiled or run; no UVM verification/compliance claim is made.
- No formal proof, coverage closure, synthesis, timing, area, power, or physical-design result is claimed.
- The RTL contract is a learning-project choice, especially the pre-state full/empty policy for simultaneous boundary operations.

## Recommended next milestone

Next, run additional deterministic seeds and review boundary coverage. The supplied mutation regression has been run successfully according to the user-provided terminal log. Then compile/run the included UVM layer only on a compatible simulator with UVM support.

## Résumé wording — only after validation

Do not use these as completed-work claims until the tests have actually run and the results are recorded. A safe draft, once validated, could be:

- Designed a parameterized synchronous FIFO in SystemVerilog with explicit reset, read-latency, overflow/underflow, and simultaneous-operation semantics.
- Developed a queue-based self-checking testbench with directed and seeded-random traffic, checking FIFO data integrity, occupancy, and boundary behaviour.
- Validated parameter configurations and documented detected fault cases using reproducible simulation scripts. *(Use only after those runs are complete.)*

## Controlled fault injection

Three deliberately incorrect variants are provided under `rtl/mutants/`: wrong empty-flag logic, early pointer wrap, and incorrectly accepting a write during simultaneous read/write at full. Do not use these variants as the design baseline. The clean baseline has already been reported to pass at depths 1, 3, and 4; the buggy variants still need their own demonstrated failures.

Run all three mutation tests with one command:

```bash
make mutations
```

Or run one mutant at a time:

```bash
./scripts/run_mutation.sh bad_empty
./scripts/run_mutation.sh bad_wrap
./scripts/run_mutation.sh bad_full_simultaneous
```

`bad_wrap` uses depth 3 to exercise non-power-of-two wraparound. The script requires both a nonzero simulation exit and an expected checker/error pattern in the saved log; a compile error or unrelated crash should not count as a detected mutant. Logs are written to `build/mutations/`. The `bad_empty` pattern accepts `reset flags incorrect` because the incorrect empty flag is observable immediately after reset. The user has now run `make mutations`; the wrapper reported that all three mutants were detected by expected checker patterns. This status is based on the terminal output supplied in the conversation, not an independent simulation in the packaging environment.
