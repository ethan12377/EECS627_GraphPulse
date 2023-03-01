
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
# TESTBENCH = testbench.v
# TESTBENCH = Xbar_SchedToPE_tb.sv
TESTBENCH = Xbar_PEToQ_tb.sv
COMMON = standard.vh
# SIM_FILES = standard.vh graphpulse.v
# SIM_FILES = Xbar_SchedToPE.sv PE_freelist.sv
SIM_FILES = Xbar_PEToQ.sv rr_arbiter.sv priority_arbiter.sv

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays                    \
	       	+neg_tchk +incdir+$(VERIF) +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh -v2k_generate

ifdef WAVES
VVOPTS += +define+DUMP_VCD=1 +memcbk +vcs+dumparrays +sdfverbose
endif

ifdef GUI
VVOPTS += -gui
endif

all: clean sim

clean:
	rm -f verilog/ucli.key
	rm -f verilog/sim
	rm -f verilog/sim_syn
	rm -fr verilog/sim.daidir
	rm -fr verilog/sim_syn.daidir
	rm -f verilog/*.log
	rm -fr verilog/csrc

sim: $(STD_CELLS) $(COMMON) $(SIM_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(COMMON) $(SIM_FILES) $(TESTBENCH); ./$@ > sim.out
