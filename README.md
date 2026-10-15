# Parameterized FIFO Verification

A small hardware-verification portfolio project: synthesizable synchronous FIFO RTL plus self-checking SystemVerilog and UVM testbenches. It is designed to be easy to inspect, reproduce, extend, and defend in an interview.

> **Validation status:** User-reported Icarus Verilog runs passed for the baseline at depths 1, 3, and 4, and the mutation regression detected all three deliberate mutants through expected checker failures. The UVM test also completed on macOS using Verilator 5.052 and Accellera UVM-core 2020.3.1 with `UVM_NO_DPI`: 1,023 observed cycles, 438 accepted writes, 431 accepted reads, final occupancy 3, and zero reported UVM errors or fatals. Two UVM warnings were reported. Functional coverage showed 0.00%; coverage is **not** claimed as measured or closed.

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
│   └── README.md             # UVM compile/run status
├── scripts/
│   ├── run_iverilog.sh       # Compile and run default test
│   ├── run_mutation.sh       # Compile/run and check one deliberate RTL mutant
│   ├── run_all_mutations.sh  # Run all three mutations in sequence
│   ├── run_uvm_vcs.sh        # Synopsys VCS/UVM runner
│   └── run_uvm_verilator.sh  # Verilator/UVM runner
├── docs/
│   ├── fifo_spec.md          # Contract: latency, flags, boundary semantics
│   ├── mutation_matrix.md    # Defects and expected detection mechanisms
│   ├── technical_report.md   # Decisions, test strategy, limitations
│   ├── validation_status.md  # Reported tests and limitations
│   └── provenance.md         # Source provenance
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

## Run the plain-SystemVerilog testbench

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

Run the mutation regression:

```bash
make mutations
```

## Run the UVM test

### Verilator + Accellera UVM-core

The reported local run used Verilator 5.052, Accellera UVM-core 2020.3.1, and Z3, with `UVM_NO_DPI` enabled. If these are already installed and `UVM_HOME` points to the UVM `src` directory, run:

```bash
./scripts/run_uvm_verilator.sh
```

To force a rebuild (the first C++ build can take a long time):

```bash
./scripts/run_uvm_verilator.sh --build
```

The script's default UVM path is `$HOME/uvm_libs/uvm-core-2020.3.1/src`. Override it if your installation differs:

```bash
UVM_HOME="$HOME/path/to/uvm-core/src" ./scripts/run_uvm_verilator.sh --build
```

### Synopsys VCS

With Synopsys VCS and UVM 1.2 configured, use:

```bash
./scripts/run_uvm_vcs.sh
```

The VCS flow is provided but has not been validated by the reported Verilator run.

## Verification implemented

- Queue-based reference model.
- Expected accepted/rejected operation calculation from pre-edge occupancy.
- Checks for output data and hold behaviour, `read_valid`, overflow/underflow pulses, count, full, and empty.
- Directed scenarios for empty reads, simultaneous operations at empty/full/middle occupancy, filling, overflow attempts, pointer wraparound, and reset while populated.
- 1,000 deterministic randomized cycles controlled by `+SEED` in the plain-SystemVerilog testbench.
- Diagnostic counters for accepted operations and boundary scenarios.
- UVM candidate environment with sequence, driver, monitor, scoreboard, and a functional covergroup.

Scenario counters are not functional coverage percentages. The UVM run reported 0.00% functional coverage, so do not claim coverage closure. See `docs/validation_status.md` for observed results and limitations.

## Current validation status

User-reported baseline Icarus Verilog runs passed for depth 1, 3, and 4 with seed `324508639`. The mutation regression reported expected checker failures for all three deliberately buggy variants. The UVM test completed using Verilator 5.052 and Accellera UVM-core 2020.3.1 with zero UVM errors/fatals, but 0.00% reported coverage. These are user-provided terminal results rather than results independently reproduced by the package author. See `docs/validation_status.md`.

## Limitations

- The `bad_empty` mutant is caught immediately by the reset-flags check; a separate empty-transition test would strengthen the evidence for that scenario.
- The Verilator/UVM run used `UVM_NO_DPI` and emitted UVM warnings; behavior can differ from a commercial simulator. The UVM implementation also references the Accellera UVM-core project's documented deviations.
- No formal proof, coverage closure, synthesis, timing, area, power, DRC/LVS, or physical-design result is claimed for this FIFO project.
- The RTL contract is a learning-project choice, especially the pre-state full/empty policy for simultaneous boundary operations.

## Example résumé wording

Use wording you can explain and defend in an interview:

- Designed a parameterized synchronous FIFO in SystemVerilog with defined reset, read-latency, overflow/underflow, and simultaneous-operation behavior.
- Developed a UVM verification environment with sequences, driver, monitor, and queue-based scoreboard; ran the test under Verilator with 1,023 observed cycles and zero reported UVM errors or fatals. Functional coverage remains unresolved.
- Built a self-checking plain-SystemVerilog testbench and used seeded simulation plus three injected RTL faults to exercise data integrity and boundary checks.

## Controlled fault injection

Three deliberately incorrect variants are provided under `rtl/mutants/`: wrong empty-flag logic, early pointer wrap, and incorrectly accepting a write during simultaneous read/write at full. Do not use these variants as the design baseline.

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

`bad_wrap` uses depth 3 to exercise non-power-of-two wraparound. The script requires both a nonzero simulation exit and an expected checker/error pattern in the saved log; a compile error or unrelated crash should not count as a detected mutant. Logs are written to `build/mutations/`. The reported terminal output showed all three mutants detected by expected checker patterns; see `docs/validation_status.md` for details.
