`timescale 1ns/1ps
package fifo_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter int unsigned DATA_WIDTH = 8;
    parameter int unsigned FIFO_DEPTH = 4;
    parameter int unsigned COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1);

    class fifo_seq_item extends uvm_sequence_item;
        rand bit rst;
        rand bit wr_en;
        rand bit rd_en;
        rand logic [DATA_WIDTH-1:0] data_in;

        `uvm_object_utils_begin(fifo_seq_item)
            `uvm_field_int(rst,    UVM_DEFAULT)
            `uvm_field_int(wr_en,  UVM_DEFAULT)
            `uvm_field_int(rd_en,  UVM_DEFAULT)
            `uvm_field_int(data_in, UVM_DEFAULT)
        `uvm_object_utils_end

        function new(string name = "fifo_seq_item");
            super.new(name);
            rst = 1'b0;
            wr_en = 1'b0;
            rd_en = 1'b0;
            data_in = '0;
        endfunction
    endclass

    class fifo_observation extends uvm_sequence_item;
        bit rst;
        bit wr_en;
        bit rd_en;
        logic [DATA_WIDTH-1:0] data_in;
        logic pre_full;
        logic pre_empty;
        logic [DATA_WIDTH-1:0] data_out;
        logic full;
        logic empty;
        logic read_valid;
        logic overflow;
        logic underflow;
        logic [COUNT_WIDTH-1:0] count;

        `uvm_object_utils_begin(fifo_observation)
            `uvm_field_int(rst,        UVM_DEFAULT)
            `uvm_field_int(wr_en,      UVM_DEFAULT)
            `uvm_field_int(rd_en,      UVM_DEFAULT)
            `uvm_field_int(data_in,    UVM_DEFAULT)
            `uvm_field_int(pre_full,   UVM_DEFAULT)
            `uvm_field_int(pre_empty,  UVM_DEFAULT)
            `uvm_field_int(data_out,   UVM_DEFAULT)
            `uvm_field_int(full,       UVM_DEFAULT)
            `uvm_field_int(empty,      UVM_DEFAULT)
            `uvm_field_int(read_valid, UVM_DEFAULT)
            `uvm_field_int(overflow,   UVM_DEFAULT)
            `uvm_field_int(underflow,  UVM_DEFAULT)
            `uvm_field_int(count,      UVM_DEFAULT)
        `uvm_object_utils_end

        function new(string name = "fifo_observation");
            super.new(name);
        endfunction
    endclass

    class fifo_sequencer extends uvm_sequencer #(fifo_seq_item);
        `uvm_component_utils(fifo_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    class fifo_driver extends uvm_driver #(fifo_seq_item);
        `uvm_component_utils(fifo_driver)
        virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH) vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH))::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "fifo_driver could not get virtual interface 'vif'")
        endfunction

        task run_phase(uvm_phase phase);
            fifo_seq_item req;
            forever begin
                seq_item_port.get_next_item(req);
                @(negedge vif.clk);
                vif.rst     = req.rst;
                vif.wr_en   = req.wr_en;
                vif.rd_en   = req.rd_en;
                vif.data_in = req.data_in;
                seq_item_port.item_done();
            end
        endtask
    endclass

    class fifo_monitor extends uvm_monitor;
        `uvm_component_utils(fifo_monitor)
        virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH) vif;
        uvm_analysis_port #(fifo_observation) ap;

        covergroup fifo_cg with function sample(bit wr, bit rd, bit was_full, bit was_empty, bit read_ok);
            cp_wr:       coverpoint wr       { bins off = {0}; bins on = {1}; }
            cp_rd:       coverpoint rd       { bins off = {0}; bins on = {1}; }
            cp_pre_full: coverpoint was_full { bins not_full = {0}; bins full = {1}; }
            cp_pre_empty:coverpoint was_empty{ bins not_empty = {0}; bins empty = {1}; }
            cp_read_ok:  coverpoint read_ok  { bins rejected_or_idle = {0}; bins accepted = {1}; }
            request_boundary_cross: cross cp_wr, cp_rd, cp_pre_full, cp_pre_empty;
        endgroup

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
            fifo_cg = new();
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH))::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "fifo_monitor could not get virtual interface 'vif'")
        endfunction

        task run_phase(uvm_phase phase);
            fifo_observation tr;
            forever begin
                @(posedge vif.clk);
                tr = fifo_observation::type_id::create("tr", this);
                // Capture inputs and pre-edge flags before the DUT's NBA updates.
                tr.rst       = vif.rst;
                tr.wr_en     = vif.wr_en;
                tr.rd_en     = vif.rd_en;
                tr.data_in   = vif.data_in;
                tr.pre_full  = vif.full;
                tr.pre_empty = vif.empty;
                #1;
                tr.data_out  = vif.data_out;
                tr.full      = vif.full;
                tr.empty     = vif.empty;
                tr.read_valid= vif.read_valid;
                tr.overflow  = vif.overflow;
                tr.underflow = vif.underflow;
                tr.count     = vif.count;
                ap.write(tr);
                if (!tr.rst)
                    fifo_cg.sample(tr.wr_en, tr.rd_en, tr.pre_full, tr.pre_empty, tr.read_valid);
            end
        endtask

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("FIFOCOV", $sformatf("Request/boundary covergroup coverage: %0.2f%%", fifo_cg.get_coverage()), UVM_LOW)
        endfunction
    endclass

    class fifo_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(fifo_scoreboard)
        uvm_analysis_imp #(fifo_observation, fifo_scoreboard) analysis_export;
        logic [DATA_WIDTH-1:0] model_q[$];
        logic [DATA_WIDTH-1:0] last_data_out;
        int unsigned checked_cycles;
        int unsigned accepted_reads;
        int unsigned accepted_writes;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
            last_data_out = '0;
            checked_cycles = 0;
            accepted_reads = 0;
            accepted_writes = 0;
        endfunction

        function void check_equal(bit condition, string message);
            if (!condition) `uvm_error("FIFO_SB", message)
        endfunction

        function void write(fifo_observation tr);
            int before_count;
            bit exp_read;
            bit exp_write;
            bit exp_overflow;
            bit exp_underflow;
            logic [DATA_WIDTH-1:0] expected_data;
            logic [DATA_WIDTH-1:0] discarded;

            checked_cycles++;
            if (tr.rst) begin
                model_q.delete();
                last_data_out = '0;
                check_equal(tr.count == 0, "count not reset to zero");
                check_equal(tr.empty === 1'b1 && tr.full === 1'b0, "flags incorrect during reset");
                check_equal(tr.data_out === '0, "data_out not reset to zero");
                check_equal(tr.read_valid === 1'b0, "read_valid asserted during reset");
                check_equal(tr.overflow === 1'b0 && tr.underflow === 1'b0, "error pulse asserted during reset");
                return;
            end

            before_count = model_q.size();
            check_equal(tr.pre_empty === (before_count == 0), "pre-edge empty disagrees with model");
            check_equal(tr.pre_full === (before_count == FIFO_DEPTH), "pre-edge full disagrees with model");
            exp_read = tr.rd_en && (before_count > 0);
            exp_write = tr.wr_en && (before_count < FIFO_DEPTH);
            exp_overflow = tr.wr_en && (before_count == FIFO_DEPTH);
            exp_underflow = tr.rd_en && (before_count == 0);
            expected_data = last_data_out;
            if (exp_read) expected_data = model_q[0];

            check_equal(tr.read_valid === exp_read, "read_valid does not match accepted read");
            check_equal(tr.overflow === exp_overflow, "overflow pulse incorrect");
            check_equal(tr.underflow === exp_underflow, "underflow pulse incorrect");
            if (exp_read) begin
                check_equal(tr.data_out === expected_data,
                    $sformatf("data mismatch: expected 0x%0h, got 0x%0h", expected_data, tr.data_out));
                discarded = model_q.pop_front();
                last_data_out = expected_data;
                accepted_reads++;
            end else begin
                check_equal(tr.data_out === last_data_out, "data_out changed without an accepted read");
            end

            if (exp_write) begin
                model_q.push_back(tr.data_in);
                accepted_writes++;
            end

            check_equal(tr.count == model_q.size(),
                $sformatf("count mismatch: model=%0d DUT=%0d", model_q.size(), tr.count));
            check_equal(tr.empty === (model_q.size() == 0), "empty flag disagrees with model");
            check_equal(tr.full === (model_q.size() == FIFO_DEPTH), "full flag disagrees with model");
            check_equal(model_q.size() <= FIFO_DEPTH, "reference queue exceeded FIFO capacity");
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("FIFO_SB", $sformatf("Observed cycles=%0d accepted writes=%0d accepted reads=%0d final occupancy=%0d", checked_cycles, accepted_writes, accepted_reads, model_q.size()), UVM_LOW)
        endfunction
    endclass

    class fifo_agent extends uvm_agent;
        `uvm_component_utils(fifo_agent)
        fifo_sequencer seqr;
        fifo_driver driver;
        fifo_monitor monitor;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seqr = fifo_sequencer::type_id::create("seqr", this);
            driver = fifo_driver::type_id::create("driver", this);
            monitor = fifo_monitor::type_id::create("monitor", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            driver.seq_item_port.connect(seqr.seq_item_export);
        endfunction
    endclass

    class fifo_env extends uvm_env;
        `uvm_component_utils(fifo_env)
        fifo_agent agent;
        fifo_scoreboard scoreboard;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agent = fifo_agent::type_id::create("agent", this);
            scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(scoreboard.analysis_export);
        endfunction
    endclass

    class fifo_base_sequence extends uvm_sequence #(fifo_seq_item);
        `uvm_object_utils(fifo_base_sequence)
        function new(string name = "fifo_base_sequence");
            super.new(name);
        endfunction

        task automatic send_cycle(bit r, bit w, bit rd, logic [DATA_WIDTH-1:0] d);
            fifo_seq_item req;
            req = fifo_seq_item::type_id::create("req");
            start_item(req);
            req.rst = r;
            req.wr_en = w;
            req.rd_en = rd;
            req.data_in = d;
            finish_item(req);
        endtask
    endclass

    class fifo_directed_sequence extends fifo_base_sequence;
        `uvm_object_utils(fifo_directed_sequence)
        function new(string name = "fifo_directed_sequence");
            super.new(name);
        endfunction

        task body();
            int i;
            // Reset, then release reset with one idle cycle.
            send_cycle(1, 0, 0, '0);
            send_cycle(1, 0, 0, '0);
            send_cycle(0, 0, 0, '0);

            // Empty read and simultaneous empty read/write.
            send_cycle(0, 0, 1, '0);
            send_cycle(0, 1, 1, DATA_WIDTH'(8'hA5));
            send_cycle(0, 0, 1, '0);

            // Fill, overflow attempt, and simultaneous R/W at full.
            send_cycle(1, 0, 0, '0);
            send_cycle(0, 0, 0, '0);
            for (i = 0; i < FIFO_DEPTH; i++) send_cycle(0, 1, 0, DATA_WIDTH'(i + 1));
            send_cycle(0, 1, 0, DATA_WIDTH'(8'hEE));
            send_cycle(0, 1, 1, DATA_WIDTH'(8'hD7));

            // Simultaneous access in the middle of the occupancy range when possible.
            if (FIFO_DEPTH > 1) begin
                send_cycle(0, 0, 1, '0);
                send_cycle(0, 1, 0, DATA_WIDTH'(8'h31));
                send_cycle(0, 1, 1, DATA_WIDTH'(8'h32));
            end

            // Reset while occupied, then verify empty behaviour again.
            send_cycle(1, 0, 0, '0);
            send_cycle(0, 0, 0, '0);
            send_cycle(0, 1, 0, DATA_WIDTH'(8'h91));
            send_cycle(1, 0, 0, '0);
            send_cycle(0, 0, 1, '0);
        endtask
    endclass

    class fifo_random_sequence extends fifo_base_sequence;
        `uvm_object_utils(fifo_random_sequence)
        int unsigned num_cycles = 1000;
        function new(string name = "fifo_random_sequence");
            super.new(name);
        endfunction

        task body();
            fifo_seq_item req;
            repeat (num_cycles) begin
                req = fifo_seq_item::type_id::create("req");
                start_item(req);
                if (!req.randomize() with { rst == 0; })
                    `uvm_fatal("RANDFAIL", "Could not randomize FIFO sequence item")
                finish_item(req);
            end
        endtask
    endclass

    class fifo_base_test extends uvm_test;
        `uvm_component_utils(fifo_base_test)
        fifo_env env;
        virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH) vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = fifo_env::type_id::create("env", this);
            if (!uvm_config_db#(virtual fifo_if #(DATA_WIDTH, FIFO_DEPTH))::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "fifo_base_test could not get virtual interface 'vif'")
        endfunction

        task run_phase(uvm_phase phase);
            fifo_directed_sequence directed;
            fifo_random_sequence random_seq;
            phase.raise_objection(this, "Running directed and random FIFO sequences");
            directed = fifo_directed_sequence::type_id::create("directed");
            directed.start(env.agent.seqr);
            random_seq = fifo_random_sequence::type_id::create("random_seq");
            random_seq.start(env.agent.seqr);
            // Allow the last driven item to be sampled and checked before ending run_phase.
            @(posedge vif.clk);
            #2;
            phase.drop_objection(this, "FIFO sequences finished");
        endtask
    endclass
endpackage
