
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
# TESTBENCH = testbench.v
# TESTBENCH = Xbar_SchedToPE_tb.sv
# TESTBENCH = Xbar_PEToQ_tb.sv
TESTBENCH = qs_cu_tb.sv
# SIM_FILES = standard.vh graphpulse.v
# SIM_FILES = Xbar_SchedToPE.sv PE_freelist.sv
# SIM_FILES = Xbar_PEToQ.sv rr_arbiter.sv priority_arbiter.sv
SIM_FILES = standard.vh coalescing_unit.sv bin_func.sv event_queues.sv queue_scheduler.sv CU_fifo.sv priority_arbiter.sv rr_arbiter.sv ../pe/verilog/fp_add.sv

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
	rm -f ucli.key
	rm -f sim
	rm -f sim_syn
	rm -fr sim.daidir
	rm -fr sim_syn.daidir
	rm -f *.log
	rm -fr csrc

sim: $(STD_CELLS) $(SIM_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(COMMON) $(SIM_FILES) $(TESTBENCH); ./$@ > sim.out


synth:
	cd ../syn; dc_shell -tcl_mode -xg_mode -f qs.syn.tcl | tee output.txt 