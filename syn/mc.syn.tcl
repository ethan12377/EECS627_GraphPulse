# Load common variables, artisan standard cells
source -verbose "common.syn.tcl"

# Set top level name
# set top_level "fp_add"
set top_level "mc"

# Read verilog files
read_file -f sverilog [list "../verilog/standard.vh ../verilog/priority_arbiter.sv ../verilog/rr_arbiter.sv ../verilog/mc.sv"]
list_designs
current_design $top_level

# Clock period
set clk_period 10
set clk_uncertainty 0.1
set clk_transition 0.1

set clk_name "clk_i"
set clk_port "clk_i"
#If no waveform is specified, 50% duty cycle is assumed
create_clock -name $clk_name -period $clk_period [get_ports $clk_port] 
set_drive 0 [get_clocks $clk_name]

set_clock_uncertainty $clk_uncertainty [get_clocks $clk_name]
set_clock_transition $clk_transition [get_clocks $clk_name]

set_operating_conditions "typical" -library "typical" 
set_wire_load_model -name "ibm13_wl10" -library "typical" 
set_wire_load_mode "segmented" 

set typical_input_delay 0.15
set typical_output_delay 0.15
set typical_wire_load 0.010 

# Link the design
link

# Set maximum fanout of gates
set_max_fanout 16 $top_level 

# Configure the clock network
set_fix_hold [all_clocks] 
set_dont_touch_network $clk_port

# Set delays: Input, Output
set_driving_cell -lib_cell INVX2TR [all_inputs]
set_input_delay $typical_input_delay [all_inputs] -clock $clk_name 
remove_input_delay -clock $clk_name [find port $clk_port]
set_output_delay $typical_output_delay [all_outputs] -clock $clk_name 

# Set loading of outputs 
set_load $typical_wire_load [all_outputs] 

# Verify the design
check_design

# Uniquify repeated modules
uniquify

# Synthesize the design
compile_ultra -retime
optimize_registers
# compile -map_effort medium
# set_optimize_registers -sync_transform multiclass -async_transform multiclass
# compile_ultra -retime
# compile_ultra -retime -incremental

# Rename modules, signals according to the naming rules Used for tool exchange
source -verbose "naming_rules.syn.tcl"

# Generate structural verilog netlist
write -hierarchy -format verilog -output "${top_level}.syn.v"

# Generate Standard Delay Format (SDF) file
write_sdf -context verilog "${top_level}.syn.sdf"

# Generate report file
set maxpaths 20
set rpt_file "${top_level}.syn.rpt"

check_design > $rpt_file
report_area  >> ${rpt_file}
report_power -hier -analysis_effort medium >> ${rpt_file}
report_design >> ${rpt_file}
report_cell >> ${rpt_file}
report_port -verbose >> ${rpt_file}
report_compile_options >> ${rpt_file}
report_constraint -all_violators -verbose >> ${rpt_file}
report_timing -path full -delay max -max_paths $maxpaths -nworst 100 >> ${rpt_file}

# Exit dc_shell
quit
