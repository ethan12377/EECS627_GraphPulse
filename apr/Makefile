STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v
TESTBENCH = mult_block_testbench.v
SIM_FILES = standard.vh mult.v reset_driver.v lfsr16.v signature_analyzer16.v mult_block.v
SIM_SYN_FILES = standard.vh ../syn/mult_block.syn.v reset_driver.v
SIM_APR_FILES   = standard.vh ../apr/mult_block.apr.v reset_driver.v

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays                    \
	       	+neg_tchk +incdir+$(VERIF) +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh 

ifdef WAVES
VVOPTS += +define+DUMP_VCD=1 +memcbk +vcs+dumparrays +sdfverbose
endif

ifdef GUI
VVOPTS += -gui
endif

all: clean sim lef run_syn sim_syn run_apr sim_apr

clean:
	rm -f verilog/ucli.key
	rm -f verilog/sim
	rm -f verilog/sim_syn
	rm -fr verilog/sim.daidir
	rm -fr verilog/sim_syn.daidir
	rm -f verilog/*.log
	rm -fr verilog/csrc
	rm -f verilog/testbench.txt
	rm -f verilog/testbench_functional.txt
	rm -f verilog/testbench_structural.txt
	rm -f verilog/signatures.txt
	rm -f verilog/signatures_behavioral.txt
	rm -f verilog/diff_functional.txt
	rm -f verilog/diff_structural.txt
	rm -f -r syn/dwsvf_*
	# rm -f syn/*.syn.v
	rm -f syn/output.txt
	rm -f syn/*.{log,sdf,svf,sdc}
	# rm -f apr/*.apr.v
	rm -f apr/output.txt
	rm -f apr/*.{log,sdf,svf,sdc}
	rm -rf syn/alib-52/
	rm -f *.log
	rm -f lib/*.{log,db,lib}
	rm -rf apr/*.{enc,cmd,log}*
	rm -rf apr/timingReports/
	rm -rf verilog/sim_apr.daidir/
	rm -rf verilog/*.txt
	rm -f verilog/sim_apr
	rm -f verilog/sdfAnnotateInfo

run_apr:
	rm -rf  Xbar_PEToQ_wrapper.*.enc*; innovus -init Xbar_PEToQ_wrapper.apr.tcl | tee output.txt 

sim_apr:
	cd verilog; $(VV) $(VVOPTS) +sdfverbose +define+APR=1 $(STD_CELLS) $(SIM_APR_FILES) $(TESTBENCH); ./$@
	cp verilog/signatures.txt verilog/signatures_apr.txt
	diff verilog/signatures_behavioral.txt verilog/signatures_apr.txt | tee verilog/diff_structural.txt
