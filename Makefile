.PHONY: sim sim-depth1 sim-depth3 mutations clean

sim:
	./scripts/run_iverilog.sh

sim-depth1:
	mkdir -p build
	iverilog -g2012 -Wall -s tb_fifo -Ptb_fifo.DEPTH=1 -o build/tb_fifo_depth1.vvp rtl/sync_fifo.sv tb/tb_fifo.sv
	vvp build/tb_fifo_depth1.vvp +SEED=324508639

sim-depth3:
	mkdir -p build
	iverilog -g2012 -Wall -s tb_fifo -Ptb_fifo.DEPTH=3 -o build/tb_fifo_depth3.vvp rtl/sync_fifo.sv tb/tb_fifo.sv
	vvp build/tb_fifo_depth3.vvp +SEED=324508639

mutations:
	./scripts/run_all_mutations.sh

clean:
	rm -rf build
