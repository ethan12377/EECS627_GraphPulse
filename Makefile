
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
TESTBENCH = qs_cu_tb.sv
SIM_FILES = standard.vh
SIM_FILES += priority_arbiter.sv rr_arbiter.sv 
SIM_FILES += ../pe/verilog/fp_add.sv
SIM_FILES += coalescing_unit.sv bin_func.sv event_queues.sv queue_scheduler.sv CU_fifo.sv

SIM_SYNTH_FILES = standard.vh
SIM_SYNTH_FILES += ../syn/event_queues.syn.v ../syn/queue_scheduler.syn.v

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays -debug_access+r -kdb\
	       	+neg_tchk +incdir+$(VERIF) +lint=TFIPC-L +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh -v2k_generate

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
	rm -rf sim.out
	rm -rf csr.txt
	rm -rf verdi*
	rm -rf novas*
	rm -rf inter.fsdb


synth:
	cd syn; dc_shell -tcl_mode -xg_mode -f queue_scheduler.syn.tcl | tee output.txt

sim_synth:
	cd verilog; $(VV) $(VVOPTS) $(STD_CELLS) $(SIM_SYNTH_FILES) $(TESTBENCH); ./$@  

verdi: ./sim_synth
	./sim_synth -gui=verdi