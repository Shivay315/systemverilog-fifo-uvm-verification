`timescale 1ns/1ps

module tb_fifo;
    parameter int unsigned DATA_WIDTH = 8;
    parameter int unsigned DEPTH = 4;
    localparam int unsigned COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1);

    logic clk = 1'b0;
    logic rst = 1'b0;
    logic wr_en = 1'b0;
    logic rd_en = 1'b0;
    logic [DATA_WIDTH-1:0] data_in = '0;
    logic [DATA_WIDTH-1:0] data_out;
    logic full, empty, read_valid, overflow, underflow;
    logic [COUNT_WIDTH-1:0] count;

    logic [DATA_WIDTH-1:0] model_q[$];
    logic [DATA_WIDTH-1:0] last_data_out = '0;

    int unsigned seed = 32'h13579BDF;
    int unsigned total_cycles = 0;
    int unsigned accepted_reads = 0;
    int unsigned accepted_writes = 0;
    int unsigned overflow_events = 0;
    int unsigned underflow_events = 0;
    int unsigned simultaneous_middle = 0;
    int unsigned simultaneous_empty = 0;
    int unsigned simultaneous_full = 0;
    int unsigned assertion_checks = 0;

    always #5 clk = ~clk;

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst(rst), .wr_en(wr_en), .rd_en(rd_en),
        .data_in(data_in), .data_out(data_out), .full(full), .empty(empty),
        .read_valid(read_valid), .overflow(overflow), .underflow(underflow),
        .count(count)
    );

    task automatic check(input bit condition, input string message);
        begin
            assertion_checks++;
            assert (condition) else begin
                $error("ASSERTION FAILED at %0t: %s", $time, message);
                $fatal(1, "%s", message);
            end
        end
    endtask

    task automatic reset_fifo;
        begin
            @(negedge clk);
            rst = 1'b1;
            wr_en = 1'b0;
            rd_en = 1'b0;
            data_in = '0;
            model_q.delete();
            last_data_out = '0;
            @(posedge clk);
            #1;
            check(count == 0, "reset must clear count");
            check(empty === 1'b1 && full === 1'b0, "reset flags incorrect");
            check(data_out == '0, "reset must clear data_out");
            check(read_valid === 1'b0, "reset must clear read_valid");
            check(overflow === 1'b0 && underflow === 1'b0, "reset must clear error pulses");
            @(negedge clk);
            rst = 1'b0;
        end
    endtask

    // Drive at a falling edge, allow the DUT's rising-edge NBA updates to settle,
    // and compare against a queue model computed from pre-edge occupancy.
    task automatic step(input bit wr, input bit rd, input logic [DATA_WIDTH-1:0] din);
        int before_count;
        bit exp_read;
        bit exp_write;
        bit exp_overflow;
        bit exp_underflow;
        logic [DATA_WIDTH-1:0] expected_data;
        logic [DATA_WIDTH-1:0] discarded;
        begin
            @(negedge clk);
            rst = 1'b0;
            wr_en = wr;
            rd_en = rd;
            data_in = din;
            before_count = model_q.size();
            exp_read = rd && (before_count > 0);
            exp_write = wr && (before_count < DEPTH);
            exp_overflow = wr && (before_count == DEPTH);
            exp_underflow = rd && (before_count == 0);
            expected_data = last_data_out;
            if (exp_read)
                expected_data = model_q[0];

            if (wr && rd) begin
                if (before_count == 0) simultaneous_empty++;
                else if (before_count == DEPTH) simultaneous_full++;
                else simultaneous_middle++;
            end

            @(posedge clk);
            #1;

            check(read_valid === exp_read, "read_valid does not match accepted read");
            check(overflow === exp_overflow, "overflow pulse incorrect");
            check(underflow === exp_underflow, "underflow pulse incorrect");
            if (exp_read) begin
                check(data_out === expected_data, $sformatf("read data mismatch: expected 0x%0h, got 0x%0h", expected_data, data_out));
                accepted_reads++;
            end else begin
                check(data_out === last_data_out, "data_out should hold when no read is accepted");
            end

            // Queue model update occurs only after the expected head is captured.
            if (exp_read) discarded = model_q.pop_front();
            if (exp_write) begin
                model_q.push_back(din);
                accepted_writes++;
            end
            if (exp_overflow) overflow_events++;
            if (exp_underflow) underflow_events++;
            if (exp_read) last_data_out = expected_data;

            check(count == model_q.size(), $sformatf("count mismatch: model=%0d DUT=%0d", model_q.size(), count));
            check(empty === (model_q.size() == 0), "empty flag disagrees with reference queue");
            check(full === (model_q.size() == DEPTH), "full flag disagrees with reference queue");
            check(model_q.size() <= DEPTH, "reference model occupancy exceeded capacity");
            total_cycles++;
        end
    endtask

    task automatic write_one(input logic [DATA_WIDTH-1:0] din);
        step(1'b1, 1'b0, din);
    endtask

    task automatic read_one;
        step(1'b0, 1'b1, '0);
    endtask

    int i;
    int unsigned rand_word;
    initial begin
        if ($value$plusargs("SEED=%d", seed)) begin end
        if (seed == 0) seed = 1;

        $display("FIFO test start: DATA_WIDTH=%0d DEPTH=%0d SEED=%0d", DATA_WIDTH, DEPTH, seed);
        reset_fifo();

        // Empty read and empty simultaneous R/W: read rejected, write accepted.
        read_one();
        step(1'b1, 1'b1, DATA_WIDTH'(8'hA5));
        read_one();
        read_one();

        // Reset, fill to full, test rejected write and simultaneous request at full.
        reset_fifo();
        for (i = 0; i < DEPTH; i++) write_one(DATA_WIDTH'(i + 1));
        check(full === 1'b1, "directed fill did not reach full");
        write_one(DATA_WIDTH'(8'hEE));
        step(1'b1, 1'b1, DATA_WIDTH'(8'hD7));

        // Read/write with occupancy strictly between empty and full.
        reset_fifo();
        if (DEPTH > 1) begin
            write_one(DATA_WIDTH'(8'h11));
            if (DEPTH > 2) write_one(DATA_WIDTH'(8'h22));
            step(1'b1, 1'b1, DATA_WIDTH'(8'h33));
        end

        // Force both pointers around the end of the array.
        reset_fifo();
        for (i = 0; i < DEPTH; i++) write_one(DATA_WIDTH'(i + 16));
        for (i = 0; i < (DEPTH / 2); i++) read_one();
        for (i = 0; i < (DEPTH / 2); i++) write_one(DATA_WIDTH'(i + 64));
        for (i = 0; i < DEPTH; i++) read_one();

        // Reset while occupied; all previously queued data must be discarded.
        write_one(DATA_WIDTH'(8'h91));
        if (DEPTH > 1) write_one(DATA_WIDTH'(8'h92));
        reset_fifo();
        read_one();

        // Deterministic randomized traffic, including independent R/W requests.
        for (i = 0; i < 1000; i++) begin
            rand_word = $urandom(seed);
            step(rand_word[0], rand_word[1], DATA_WIDTH'(rand_word >> 8));
        end

        // Drain model to make the final state and count visible/reproducible.
        for (i = 0; i < DEPTH + 1; i++) read_one();

        $display("PASS: cycles=%0d checks=%0d writes=%0d reads=%0d overflow=%0d underflow=%0d", total_cycles, assertion_checks, accepted_writes, accepted_reads, overflow_events, underflow_events);
        $display("Scenario counts: sim_empty=%0d sim_middle=%0d sim_full=%0d", simultaneous_empty, simultaneous_middle, simultaneous_full);
        $display("Note: these are generated only when this testbench is run in a compatible simulator.");
        $finish;
    end
endmodule
