
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
TESTBENCH = qs_cu_tb.sv
SIM_FILES = standard.vh graphpulse.v mem.sv
SIM_FILES += priority_arbiter.sv rr_arbiter.sv 
SIM_FILES += fp_add.sv fp_div.sv fp_mul.sv fpu.sv mc.sv int16_to_float16.sv pe.sv
SIM_FILES += Xbar_SchedToPE.sv PE_Freelist.sv Xbar_PEToQ.sv
SIM_FILES += output_buffer.sv OB_bubble_squeezer.sv OB_fifo.sv
SIM_FILES += coalescing_unit.sv bin_func.sv event_queues.sv queue_scheduler.sv CU_fifo.sv

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays -debug_access+r -kdb\
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
	rm -rf sim.out
	rm -rf csr.txt
	rm -rf verdi*
	rm -rf novas*
	rm -rf inter.fsdb

sim: $(STD_CELLS) $(SIM_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(SIM_FILES) $(TESTBENCH); ./$@

sim_synth:
	$(VV) $(VVOPTS) $(STD_CELLS) $(SIM_SYNTH_FILES) $(TESTBENCH); ./$@

verdi: ./sim_synth
	./sim_synth -gui=verdi