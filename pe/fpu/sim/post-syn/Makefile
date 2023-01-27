all: vcs read_out compare
	
# Note: random ops are generated in and read from pre-syn folder
vcs:
	@ echo "Running operands on RTL..."
	@ vcs -f fp.include +v2k -R +lint=all -sverilog -full64 -debug_pp \
		-timescale=1ns/10ps -l fp.log

read_out:
	@ echo "Converting binary results to decimal..."
	@ python3 convertFPUout.py fp_output.txt
#	cat fp_output_dec.txt

compare:
	@ echo "Comparing actual results to expected results..."
	@ python3 compare.py output.txt

dve:
	dve -full64 -vpd vcdplus.vpd &

bcalculate:
	python3 calculate.py benchmark_input.txt benchmark_output.txt

bcompare: 
	@ echo "Comparing actual results to expected results..."
	@ python3 compare.py benchmark_output.txt
