STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v

TESTBENCH = ../verilog/testbench.sv ../verilog/mem.sv
SIM_FILES = ../verilog/standard.vh ../verilog/graphpulse.v ../verilog/mem.sv
SIM_FILES += ../verilog/center.sv ../verilog/EQ_wrapper_half.sv
SIM_FILES += ../verilog/priority_arbiter.sv ../verilog/rr_arbiter.sv 
SIM_FILES += ../verilog/fp_add.sv ../verilog/fp_div.sv ../verilog/fp_mul.sv ../verilog/fpu.sv ../verilog/mc.sv ../verilog/int16_to_float16.sv ../verilog/pe.sv
SIM_FILES += ../verilog/Xbar_SchedToPE.sv ../verilog/PE_Freelist.sv ../verilog/Xbar_PEToQ.sv
SIM_FILES += ../verilog/output_buffer.sv ../verilog/OB_bubble_squeezer.sv ../verilog/OB_fifo.sv
SIM_FILES += ../verilog/coalescing_unit.sv ../verilog/bin_func.sv ../verilog/event_queues_half.sv ../verilog/queue_scheduler.sv ../verilog/CU_fifo.sv


COMMON = ../verilog/standard.vh
SIM_SYNTH_FILES = graphpulse.syn.v 

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
	dc_shell -tcl_mode -xg_mode -f graphpulse.syn.tcl | tee output.txt 

sim: $(STD_CELLS) $(COMMON) $(SIM_SYNTH_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(COMMON) $(SIM_SYNTH_FILES) $(TESTBENCH); ./$@ > sim.out
