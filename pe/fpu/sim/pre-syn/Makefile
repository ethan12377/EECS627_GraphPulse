all: gen_rand read_in calculate vcs read_out compare

gen_rand:
	echo "Generating random operations..."
	python3 random_ops.py > bin_input.txt

read_in:
	echo "Converting binary operations to decimal..."
	python3 convertFPUin.py bin_input.txt 

calculate:
	echo "Calculating expected results..."
	python3 calculate.py fpu_input.txt expected_output.txt

vcs:
	echo "Running operands on RTL..."
	vcs -f fp.include +v2k -R +lint=all -sverilog -full64 -debug_pp \
		-timescale=1ns/10ps -l fp.log

read_out:
	echo "Converting binary results to decimal..."
	python3 convertFPUout.py fp_output.txt

compare:
	echo "Comparing actual results to expected results..."
	python3 compare.py expected_output.txt

dve:
	dve -full64 -vpd vcdplus.vpd -session "session.vcdplus.vpd.tcl" &

bcalculate:
	python3 calculate.py benchmark_input.txt benchmark_output.txt

bcompare: 
	echo "Comparing actual results to expected results..."
	python3 compare.py benchmark_output.txt

clean:
	rm -rf __pycache__
	rm -rf ucli.key
	rm -rf csrc
	rm -rf simv.daidir
	rm -rf *.txt
	rm -rf session.vcdplus.vpd.tcl
	rm -rf fp.log
	rm -rf simv
	rm -rf vcdplus.vpd