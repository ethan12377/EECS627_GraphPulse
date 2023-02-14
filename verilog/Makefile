
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
TESTBENCH = testbench.v
SIM_FILES = standard.vh graphpulse.v

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays                    \
	       	+neg_tchk +incdir+$(VERIF) +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh 

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

sim:
	$(VV) $(VVOPTS) $(STD_CELLS) $(SIM_FILES) $(TESTBENCH); ./$@
