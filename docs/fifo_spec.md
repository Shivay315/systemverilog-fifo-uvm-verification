# FIFO specification (version 1)

## Interface and reset

- Single clock, `clk`; all state changes occur on its rising edge.
- `rst` is synchronous and active-high. While sampled high, pointers and `count` are cleared, `data_out` is set to zero, and `read_valid`, `overflow`, and `underflow` are cleared. The storage array is not reset.
- `DATA_WIDTH >= 1`; `DEPTH >= 1`. Non-power-of-two depths are supported.
- `count` reports the occupancy after the most recent rising edge. `empty` is true exactly when `count == 0`; `full` is true exactly when `count == DEPTH`.

## Read latency

Reads are synchronous with a registered output. For a read accepted at rising edge *N*, `data_out` changes to the removed head element after that edge and `read_valid` is high during the ensuing cycle. If no read is accepted, `data_out` holds its previous value. Reset sets it to zero.

## Acceptance and boundary policy

Acceptance decisions use `full` and `empty` **before** the active edge:

| `wr_en` | `rd_en` | Pre-edge occupancy | Accepted action | Result |
|---:|---:|---|---|---|
| 0 | 0 | Any | None | Occupancy unchanged |
| 1 | 0 | Below full | Write | Occupancy + 1 |
| 1 | 0 | Full | None | `overflow` pulse; occupancy unchanged |
| 0 | 1 | Above empty | Read | `read_valid` pulse; occupancy - 1 |
| 0 | 1 | Empty | None | `underflow` pulse; occupancy unchanged |
| 1 | 1 | Empty | Write only | `underflow` pulse; occupancy + 1 |
| 1 | 1 | Full | Read only | `overflow` pulse; occupancy - 1 |
| 1 | 1 | Neither empty nor full | Read and write | Old head is returned; new input is appended; occupancy unchanged |

`overflow` and `underflow` are one-cycle pulses for rejected write/read requests respectively. A simultaneous request can therefore produce one error pulse at a boundary. Requests are not retried automatically.

## Parameter and implementation notes

- Pointer wrap is explicit at `DEPTH-1`, so power-of-two depth is not required.
- `count` is wide enough to represent `0..DEPTH`.
- The design is intended as a synthesizable RTL exercise; inferred memory/register implementation depends on the synthesis tool and target technology.
- This specification deliberately chooses the common pre-state acceptance policy. It does not accept a write on a full FIFO merely because a read is also requested in that cycle.
