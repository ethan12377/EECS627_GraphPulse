# EECS627 Final Project
# 8x8 crossbar
# TCL script for Design Compiler

# Load common variables, artisan standard cells
source -verbose "common.syn.tcl"

# Set top level name
set top_level "Xbar_PEToQ_wrapper"

# Read verilog files
read_file -f sverilog "../verilog/standard.vh ../verilog/Xbar_PEToQ_wrapper.sv ../verilog/Xbar_PEToQ.sv ../verilog/rr_arbiter.sv ../verilog/priority_arbiter.sv"
list_designs
current_design $top_level

# Clock period
set clk_period 10
set clk_uncertainty 0.1
set clk_transition 0.1

#Create real clock if clock port is found
if {[sizeof_collection [get_ports clk_i]] > 0} {
  set clk_name "clk_i"
  set clk_port "clk_i"
  #If no waveform is specified, 50% duty cycle is assumed
  create_clock -name $clk_name -period $clk_period [get_ports $clk_port] 
  set_drive 0 [get_clocks $clk_name] 
}

#If not real clock then create virtual clock
if {[sizeof_collection [get_ports clk_i]] == 0} {
  set clk_name "vclk"
  create_clock -name $clk_name -period $clk_period 
}

set_clock_uncertainty $clk_uncertainty [get_clocks $clk_name]
#Propagated clock used for gated clocks only
#set_propagated_clock [get_clocks $clk_name]
set_clock_transition $clk_transition [get_clocks $clk_name]

set_operating_conditions "typical" -library "typical" 
set_wire_load_model -name "ibm13_wl10" -library "typical" 
set_wire_load_mode "segmented" 

set typical_input_delay 0.100
set typical_output_delay 0.100
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
# set_optimize_registers
# compile -map_effort medium
compile_ultra -retime
optimize_registers

# Rename modules, signals according to the naming rules Used for tool exchange
source -verbose "naming_rules.syn.tcl"

# Generate structural verilog netlist
write -hierarchy -format verilog -output "${top_level}.syn.v"

# Generate Standard Delay Format (SDF) file
write_sdf -context verilog "${top_level}.syn.sdf"

# Generate timing constraints file
write_sdc "${top_level}.syn.sdc"

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
