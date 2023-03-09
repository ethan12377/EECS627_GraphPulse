STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v

TESTBENCH = ../verilog/Xbar_PEToQ_tb.sv
COMMON = ../verilog/standard.vh
SIM_FILES = Xbar_PEToQ.sv rr_arbiter.sv priority_arbiter.sv
SIM_SYNTH_FILES = Xbar_PEToQ.syn.sv rr_arbiter.sv priority_arbiter.sv

synth:
	dc_shell -tcl_mode -xg_mode -f Xbar_PEToQ.syn.tcl | tee output.txt 


