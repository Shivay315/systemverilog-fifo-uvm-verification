`timescale 1ns/1ps

interface fifo_if #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH = 4,
    parameter int unsigned COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1)
) (input logic clk);
    logic rst;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;
    logic full;
    logic empty;
    logic read_valid;
    logic overflow;
    logic underflow;
    logic [COUNT_WIDTH-1:0] count;
endinterface
