`timescale 1ns/1ps

// Synchronous FIFO with a registered read output and pre-state acceptance rules.
// See docs/fifo_spec.md before changing boundary behaviour.
module sync_fifo #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 4,
    localparam int unsigned PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    localparam int unsigned COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1)
) (
    input  logic                     clk,
    input  logic                     rst,          // synchronous, active-high
    input  logic                     wr_en,
    input  logic                     rd_en,
    input  logic [DATA_WIDTH-1:0]    data_in,
    output logic [DATA_WIDTH-1:0]    data_out,
    output logic                     full,
    output logic                     empty,
    output logic                     read_valid,   // one-cycle pulse after accepted read
    output logic                     overflow,     // one-cycle pulse for write while full
    output logic                     underflow,    // one-cycle pulse for read while empty
    output logic [COUNT_WIDTH-1:0]   count
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0]  wr_ptr, rd_ptr;
    logic                  do_write, do_read;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Requests are accepted using FULL/EMPTY as they stood before this edge.
    // Thus, at empty + simultaneous R/W, only the write is accepted; at full
    // + simultaneous R/W, only the read is accepted. See the specification.
    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH == 0) $fatal(1, "DATA_WIDTH must be greater than zero");
        if (DEPTH == 0)      $fatal(1, "DEPTH must be greater than zero");
    end
`endif

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr     <= '0;
            rd_ptr     <= '0;
            count      <= '0;
            data_out   <= '0;
            read_valid <= 1'b0;
            overflow   <= 1'b0;
            underflow  <= 1'b0;
        end else begin
            // Error indicators describe rejected requests in the current cycle.
            overflow   <= wr_en && full;
            underflow  <= rd_en && empty;
            read_valid <= do_read;

            if (do_write) begin
                mem[wr_ptr] <= data_in;
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (do_read) begin
                data_out <= mem[rd_ptr];
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
