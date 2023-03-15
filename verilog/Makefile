
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
# TESTBENCH = testbench.v
# TESTBENCH = Xbar_SchedToPE_tb.sv
# TESTBENCH = Xbar_PEToQ_tb.sv
# TESTBENCH = output_buffer_tb.sv
TESTBENCH = pe_tb.sv
COMMON = standard.vh
# SIM_FILES = standard.vh graphpulse.v
# SIM_FILES = Xbar_SchedToPE.sv PE_freelist.sv
# SIM_FILES = Xbar_PEToQ.sv rr_arbiter.sv priority_arbiter.sv
# SIM_FILES = output_buffer.sv OB_bubble_squeezer.sv OB_fifo.sv
SIM_FILES = mem.sv fp_add.sv fp_div.sv fp_mul.sv fpu.sv priority_arbiter.sv rr_arbiter.sv mc.sv evqueue_sim.sv pe.sv

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
	rm -rf edge_cache.mem
	rm -rf verdi*
	rm -rf novas*
	rm -rf inter.fsdb

mem:
	python3 pagerank_mem_init.py

sim: $(STD_CELLS) $(COMMON) $(SIM_FILES) $(TESTBENCH)
	$(VV) $(VVOPTS) $(STD_CELLS) $(COMMON) $(SIM_FILES) $(TESTBENCH); ./$@ > sim.out

verdi: ./sim
	./sim -gui=verdi
