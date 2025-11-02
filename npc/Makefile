all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	verilator --cc --exe --trace-fst --build -j 0 -Wall sim.cpp top.v
	./obj_dir/Vtop
	gtkwave ./obj_dir/wave.fst

include ../Makefile
