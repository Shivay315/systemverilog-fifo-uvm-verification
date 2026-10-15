# UVM verification layer

The UVM testbench has been run once on macOS with Verilator 5.052 and Accellera UVM-core 2020.3.1. The run completed and reported zero UVM errors and fatals. It used `UVM_NO_DPI` and produced warnings, so this result should not be treated as proof of portability to every simulator or as full UVM compliance validation.

## Components

- `fifo_seq_item`: reset, read/write requests, and input data.
- `fifo_directed_sequence`: reset, empty access, simultaneous empty/full cases, fill, overflow attempt, occupied reset.
- `fifo_random_sequence`: 1,000 random request cycles with reset constrained inactive.
- `fifo_driver`: drives the interface on falling edges.
- `fifo_monitor`: captures pre-edge state and post-edge outputs and sends analysis transactions.
- `fifo_scoreboard`: queue reference model; compares data, occupancy, flags, and request pulses.
- `fifo_agent`, `fifo_env`, `fifo_base_test`: conventional UVM component hierarchy.
- Functional covergroup: read/write request combinations crossed with pre-edge full/empty state.

## Reported test result

- Simulator: Verilator 5.052.
- UVM library: Accellera UVM-core 2020.3.1.
- Test: `fifo_base_test`.
- Observed cycles: 1,023.
- Accepted writes / reads: 438 / 431.
- Final occupancy: 3.
- UVM errors / fatals: 0 / 0.
- UVM warnings: 2.
- Functional coverage report: 0.00%; coverage is unresolved and no coverage-closure claim is made.

The run used `UVM_NO_DPI`; Verilator also reported a stack-size warning. See `../docs/validation_status.md` for context and limitations.

## Reproduce with Verilator and Accellera UVM-core

Dependencies are Verilator with timing support, Z3, and Accellera UVM-core 2020.3.1. The script defaults to this UVM source path:

```bash
$HOME/uvm_libs/uvm-core-2020.3.1/src
```

If needed, override it with `UVM_HOME`:

```bash
UVM_HOME="$HOME/path/to/uvm-core/src" ./scripts/run_uvm_verilator.sh --build
```

Run an already-built executable or compile if one is not present:

```bash
./scripts/run_uvm_verilator.sh
```

Force a full rebuild (the first C++ build can take a long time):

```bash
./scripts/run_uvm_verilator.sh --build
```

The script writes generated C++/binary files under `/tmp/fifo-uvm-verilator`, outside the repository.

## Compile order

1. `rtl/sync_fifo.sv`
2. `uvm/fifo_if.sv`
3. `uvm/fifo_uvm_pkg.sv`
4. `uvm/tb_top.sv`

## Important caveats

- The demonstrated run was with Verilator and `UVM_NO_DPI`; commercial simulator behavior has not been verified by this result.
- The Accellera UVM-core distribution documents deviations from IEEE 1800.2-2020; consult its `DEVIATIONS.md` for details.
- The reported functional coverage was 0.00%. Investigate coverage instrumentation/reporting and do not claim coverage closure until verified.
- No formal verification, synthesis, timing, area, power, or physical-design result is claimed by this UVM run.
