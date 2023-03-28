STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v

TESTBENCH = ../verilog/Xbar_PEToQ_tb.sv
COMMON = ../verilog/standard.vh
SIM_SYNTH_FILES = Xbar_PEToQ.syn.v 
# SIM_SYNTH_FILES = ../verilog/Xbar_PEToQ.sv ../verilog/rr_arbiter.sv ../verilog/priority_arbiter.sv
# SIM_SYNTH_FILES = ../verilog/Xbar_PEToQ.sv rr_arbiter.syn.v

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays -debug_access+r -kdb\
	       	+neg_tchk +incdir+$(VERIF) +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh -v2k_generate

ifdef WAVES
VVOPTS += +define+DUMP_VCD=1 +memcbk +vcs+dumparrays +sdfverbose
endif

ifdef GUI
VVOPTS += -gui
endif

synth:
	dc_shell -tcl_mode -xg_mode -f Xbar_PEToQ.syn.tcl | tee output.txt 

sim: $(STD_CELLS) $(COMMON) $(SIM_SYNTH_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(COMMON) $(SIM_SYNTH_FILES) $(TESTBENCH); ./$@ > sim.out
