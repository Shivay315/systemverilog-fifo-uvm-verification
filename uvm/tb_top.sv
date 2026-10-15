`timescale 1ns/1ps
module tb_top;
    import uvm_pkg::*;
    import fifo_uvm_pkg::*;

    logic clk = 1'b0;
    always #5 clk = ~clk;

    fifo_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) vif(clk);

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) dut (
        .clk(clk), .rst(vif.rst), .wr_en(vif.wr_en), .rd_en(vif.rd_en),
        .data_in(vif.data_in), .data_out(vif.data_out), .full(vif.full),
        .empty(vif.empty), .read_valid(vif.read_valid),
        .overflow(vif.overflow), .underflow(vif.underflow), .count(vif.count)
    );

    initial begin
        vif.rst = 1'b1;
        vif.wr_en = 1'b0;
        vif.rd_en = 1'b0;
        vif.data_in = '0;
        uvm_config_db#(virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH))::set(null, "*", "vif", vif);
        run_test("fifo_base_test");
    end
endmodule
