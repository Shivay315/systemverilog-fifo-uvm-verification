# UVM verification layer (candidate implementation; not run here)

This folder contains a UVM-style transaction-based environment for the FIFO interface. It is provided as a candidate second layer after the plain-SystemVerilog baseline. **It has not been compiled or simulated in this environment** because no compatible commercial simulator or UVM library is installed here. Treat any compile/runtime issue as unresolved until verified with your simulator version.

## Components

- `fifo_seq_item`: reset, read/write requests, and input data.
- `fifo_directed_sequence`: reset, empty access, simultaneous empty/full cases, fill, overflow attempt, occupied reset.
- `fifo_random_sequence`: 1,000 random request cycles with reset constrained inactive.
- `fifo_driver`: drives the interface on falling edges.
- `fifo_monitor`: captures pre-edge state and post-edge outputs and sends analysis transactions.
- `fifo_scoreboard`: queue reference model; compares data, occupancy, flags, and request pulses.
- `fifo_agent`, `fifo_env`, `fifo_base_test`: conventional UVM component hierarchy.
- Functional covergroup: read/write request combinations crossed with pre-edge full/empty state.

## Compile-order guidance

Use a simulator that supports UVM 1.2 or IEEE 1800.2 and supply its UVM include/library options. Compile in this order:

1. `../rtl/sync_fifo.sv`
2. `fifo_if.sv`
3. `fifo_uvm_pkg.sv`
4. `tb_top.sv`

Set `tb_top` as top and run `fifo_base_test`. Consult your simulator's UVM setup instructions for its required compile and runtime switches. No UVM pass result is claimed.

## Important caveats

- The testbench is a candidate implementation, not yet simulator-validated; resolve compiler diagnostics before relying on it.
- Random seed control and coverage report details differ by simulator and may require simulator-specific options.
- The functional coverage model is not a claim of coverage closure. Inspect the actual coverage report and add bins/tests for any uncovered requirements.
- Do not list UVM experience on a résumé until you can explain the component hierarchy and demonstrate a clean compile/run on a compatible simulator.
