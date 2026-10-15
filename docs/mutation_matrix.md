# Mutation plan and expected observability

These variants deliberately introduce defects; they are not passing designs. The expected detection below is a hypothesis from the FIFO contract, not a reported simulation result.

| Mutant | Injected defect | Test stimulus expected to expose it | Expected checker |
|---|---|---|---|
| `bad_empty.sv` | `empty` is asserted when count is 1 rather than 0 | Reset / first empty operation | Empty-flag check and pre-state acceptance/model comparison |
| `bad_wrap.sv` | Pointer wraps at `DEPTH-2`, so it skips the last entry for depth 3 | Fill, drain, refill and wraparound phases | Read-data scoreboard mismatch or occupancy/flag mismatch |
| `bad_full_simultaneous.sv` | Accepts a write despite pre-edge full when a read also occurs | Full + simultaneous read/write | Count/flag check after the boundary operation and later data check |

Run each mutation and save its actual log before asserting that it was detected. If a mutant exits because of an out-of-range array access or tool-specific runtime failure, report that separately from a clean scoreboard detection.


## Reproducible commands

Run all mutants using `make mutations`, or run an individual mutant using `./scripts/run_mutation.sh <mutant>`. Each run writes a log under `build/mutations/` and checks that the nonzero simulation exit includes a checker failure pattern associated with that mutant. This guard is a convenience, not a substitute for reviewing each log. The user-reported terminal log shows that `make mutations` completed and classified all three variants as detected. The packaging environment did not independently execute the HDL simulations.
